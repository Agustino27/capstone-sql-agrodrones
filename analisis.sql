-- ============================================================================
-- Proyecto Capstone: Análisis Integrado Agrodrones Argentina
-- Archivo: analisis.sql
-- Autor: Agustín Pérez Álvarez
-- Descripción: Limpieza de datos, gestión de NULLs y consultas de negocio.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ETAPA 1: LIMPIEZA Y TRANSFORMACIÓN DE DATOS (DATA CLEANING)
-- ----------------------------------------------------------------------------

-- Consulta de verificación y vista limpia de la realidad operativa
-- Se gestionan nulos en fecha_ejecucion, ha_efectivas y monto_facturado_usd.

SELECT 
    v.vuelo_id,
    c.razon_social AS cliente,
    c.segmento_crm,
    s.tipo_servicio,
    -- 1. Gestión de fecha nula: si no hay fecha de vuelo, imputamos la fecha de la oportunidad
    COALESCE(v.fecha_ejecucion, o.fecha_cierre_esperada) AS fecha_vuelo_imputada,
    
    -- 2. Gestión de hectáreas nulas: si el parte no las registramos, tomamos las prometidas en la venta
    COALESCE(v.ha_efectivas, o.ha_comprometidas) AS hectareas_finales,
    
    -- 3. Gestión de monto nulo: si está pendiente de facturación, calculamos ha * precio_lista
    COALESCE(
        v.monto_facturado_usd, 
        (COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.precio_lista_usd_ha)
    ) AS monto_total_usd_calculado,
    
    v.incidencia_clima,
    v.estado_vuelo
FROM operaciones_vuelo v
JOIN crm_clientes c ON v.cliente_id = c.cliente_id
JOIN servicios_drones s ON v.servicio_id = s.servicio_id
JOIN crm_oportunidades o ON v.oportunidad_id = o.oportunidad_id;

-- ----------------------------------------------------------------------------
-- ETAPA 2: CONSULTAS DE ANÁLISIS ESTRATÉGICO DE NEGOCIO
-- ----------------------------------------------------------------------------

-- ============================================================================
-- PROBLEMA 1: Desviación Comercial vs. Realidad Operativa (Fuga de Valor)
-- Objetivo: Comparar hectáreas y montos prometidos en Ventas vs. lo ejecutado.
-- ============================================================================

SELECT 
    c.razon_social AS cliente,
    s.tipo_servicio,
    o.ha_comprometidas AS ha_vendidas,
    COALESCE(v.ha_efectivas, o.ha_comprometidas) AS ha_reales,
    (o.ha_comprometidas - COALESCE(v.ha_efectivas, o.ha_comprometidas)) AS brecha_hectareas,
    o.monto_prometido_usd AS facturacion_esperada,
    COALESCE(v.monto_facturado_usd, (COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.precio_lista_usd_ha)) AS facturacion_real,
    v.incidencia_clima
FROM crm_oportunidades o
JOIN crm_clientes c ON o.cliente_id = c.cliente_id
JOIN servicios_drones s ON o.servicio_id = s.servicio_id
LEFT JOIN operaciones_vuelo v ON o.oportunidad_id = v.oportunidad_id;


-- ============================================================================
-- PROBLEMA 2: Matriz de Recorrencia de Clientes y Frecuencia de Vuelo
-- Objetivo: Medir la lealtad por segmento usando Window Functions (LAG y RANK).
-- ============================================================================

WITH vuelos_ordenados AS (
    SELECT 
        v.vuelo_id,
        c.razon_social AS cliente,
        c.segmento_crm,
        COALESCE(v.fecha_ejecucion, o.fecha_cierre_esperada) AS fecha_vuelo,
        COALESCE(v.monto_facturado_usd, (COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.precio_lista_usd_ha)) AS monto_usd,
        -- Window Function 1: Calcular la fecha del vuelo anterior para medir intervalo
        LAG(COALESCE(v.fecha_ejecucion, o.fecha_cierre_esperada)) OVER (
            PARTITION BY v.cliente_id 
            ORDER BY COALESCE(v.fecha_ejecucion, o.fecha_cierre_esperada)
        ) AS fecha_vuelo_anterior,
        -- Window Function 2: Ranking de vuelos por gasto dentro de cada cliente
        DENSE_RANK() OVER (
            PARTITION BY v.cliente_id 
            ORDER BY COALESCE(v.monto_facturado_usd, (COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.precio_lista_usd_ha)) DESC
        ) AS ranking_monto_cliente
    FROM operaciones_vuelo v
    JOIN crm_clientes c ON v.cliente_id = c.cliente_id
    JOIN servicios_drones s ON v.servicio_id = s.servicio_id
    JOIN crm_oportunidades o ON v.oportunidad_id = o.oportunidad_id
)
SELECT 
    cliente,
    segmento_crm,
    fecha_vuelo,
    fecha_vuelo_anterior,
    (fecha_vuelo - fecha_vuelo_anterior) AS dias_entre_servicios,
    monto_usd,
    ranking_monto_cliente
FROM vuelos_ordenados;


-- ============================================================================
-- PROBLEMA 3: Rentabilidad y Eficiencia Operativa por Modelo de Drone
-- Objetivo: Evaluar margen bruto y volumen de hectáreas trabajadas por equipo.
-- ============================================================================

SELECT 
    s.modelo_drone,
    s.tipo_servicio,
    COUNT(v.vuelo_id) AS total_operaciones,
    SUM(COALESCE(v.ha_efectivas, o.ha_comprometidas)) AS total_hectareas,
    SUM(COALESCE(v.monto_facturado_usd, (COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.precio_lista_usd_ha))) AS ingreso_total_usd,
    SUM(COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.costo_op_usd_ha) AS costo_operativo_total_usd,
    ROUND(
        SUM(COALESCE(v.monto_facturado_usd, (COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.precio_lista_usd_ha))) - 
        SUM(COALESCE(v.ha_efectivas, o.ha_comprometidas) * s.costo_op_usd_ha), 2
    ) AS margen_bruto_usd
FROM operaciones_vuelo v
JOIN servicios_drones s ON v.servicio_id = s.servicio_id
JOIN crm_oportunidades o ON v.oportunidad_id = o.oportunidad_id
GROUP BY s.modelo_drone, s.tipo_servicio
ORDER BY margen_bruto_usd DESC;