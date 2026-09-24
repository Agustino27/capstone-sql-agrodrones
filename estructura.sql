-- ============================================================================
-- Proyecto Capstone: Análisis Integrado Agrodrones Argentina (CRM vs. Operaciones)
-- Archivo: estructura.sql
-- Autor: Agustín Pérez Álvarez
-- Descripción: Creación de tablas e inserción de datos de CRM y Operaciones.
-- ============================================================================

-- Reset de tablas
DROP TABLE IF EXISTS operaciones_vuelo CASCADE;
DROP TABLE IF EXISTS crm_oportunidades CASCADE;
DROP TABLE IF EXISTS servicios_drones CASCADE;
DROP TABLE IF EXISTS crm_clientes CASCADE;

-- 1. CRM: Tabla de Clientes y Categoría Comercial
CREATE TABLE crm_clientes (
    cliente_id SERIAL PRIMARY KEY,
    razon_social VARCHAR(100) NOT NULL,
    cuit VARCHAR(13) UNIQUE NOT NULL,
    provincia VARCHAR(50) NOT NULL,
    localidad VARCHAR(50) NOT NULL,
    hectareas_totales NUMERIC(10,2),
    segmento_crm VARCHAR(20) DEFAULT 'Bronze', -- Gold, Silver, Bronze
    fecha_alta DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 2. CATÁLOGO: Servicios y Tecnología de Drones
CREATE TABLE servicios_drones (
    servicio_id SERIAL PRIMARY KEY,
    tipo_servicio VARCHAR(80) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    modelo_drone VARCHAR(50) NOT NULL,
    costo_op_usd_ha NUMERIC(10,2) NOT NULL,
    precio_lista_usd_ha NUMERIC(10,2) NOT NULL
);

-- 3. CRM: Promesas Comerciales / Oportunidades Cerradas
CREATE TABLE crm_oportunidades (
    oportunidad_id SERIAL PRIMARY KEY,
    cliente_id INT NOT NULL REFERENCES crm_clientes(cliente_id),
    servicio_id INT NOT NULL REFERENCES servicios_drones(servicio_id),
    vendedor VARCHAR(50) NOT NULL,
    ha_comprometidas NUMERIC(10,2) NOT NULL,
    monto_prometido_usd NUMERIC(10,2) NOT NULL,
    fecha_cierre_esperada DATE NOT NULL,
    estado_venta VARCHAR(20) DEFAULT 'Ganada'
);

-- 4. OPERACIONES: Registro de Vuelos Ejecutados en Campo
CREATE TABLE operaciones_vuelo (
    vuelo_id SERIAL PRIMARY KEY,
    oportunidad_id INT REFERENCES crm_oportunidades(oportunidad_id),
    cliente_id INT NOT NULL REFERENCES crm_clientes(cliente_id),
    servicio_id INT NOT NULL REFERENCES servicios_drones(servicio_id),
    piloto_asignado VARCHAR(50),
    fecha_ejecucion DATE, -- Contiene NULLs por demoras operativas o falta de parte diario
    ha_efectivas NUMERIC(10,2), -- Contiene NULLs a imputar/limpiar
    litros_aplicados NUMERIC(10,2),
    monto_facturado_usd NUMERIC(10,2), -- Contiene NULLs por facturación pendiente
    incidencia_clima BOOLEAN DEFAULT FALSE,
    estado_vuelo VARCHAR(20) DEFAULT 'Finalizado'
);

-- ============================================================================
-- Carga de Datos de Prueba (Escenario Realista Agro)
-- ============================================================================

-- A. Clientes CRM
INSERT INTO crm_clientes (razon_social, cuit, provincia, localidad, hectareas_totales, segmento_crm, fecha_alta) VALUES
('Agropecuaria El Sol S.A.', '30-71123456-8', 'Santa Fe', 'Venado Tuerto', 2500.00, 'Gold', '2025-09-10'),
('Estancia Don Pedro SRL', '30-65432187-9', 'Córdoba', 'Marcos Juárez', 1800.00, 'Silver', '2025-10-01'),
('Los Grobo Campos S.A.', '30-88991122-3', 'Buenos Aires', 'Pergamino', 4200.00, 'Gold', '2025-10-15'),
('La Bellaca Agropress', '30-55443322-1', 'Santa Fe', 'Rafaela', 950.00, 'Bronze', '2025-11-05'),
('Agrícola Del Sur', '30-99887766-5', 'Buenos Aires', 'Tandil', 3100.00, 'Gold', '2025-11-20'),
('Manantiales del Oeste', '30-11223344-6', 'Córdoba', 'Río Cuarto', 1200.00, 'Silver', '2026-01-10');

-- B. Servicios
INSERT INTO servicios_drones (tipo_servicio, categoria, modelo_drone, costo_op_usd_ha, precio_lista_usd_ha) VALUES
('Pulverización Selectiva de Malezas', 'Proteccion de Cultivos', 'DJI Agras T40', 6.50, 18.50),
('Siembra Aérea de Cover Crops', 'Siembra', 'XAG P100 Pro', 8.00, 22.00),
('Monitoreo Multiespectral NDVI', 'Telemetria', 'Mavic 3 Enterprise', 2.00, 8.00),
('Control Biológico de Plagas', 'Proteccion de Cultivos', 'DJI Agras T30', 5.00, 15.00);

-- C. Oportunidades Comerciales (Lo que vendió Ventas)
INSERT INTO crm_oportunidades (cliente_id, servicio_id, vendedor, ha_comprometidas, monto_prometido_usd, fecha_cierre_esperada) VALUES
(1, 1, 'Mateo Rossi', 500.00, 9250.00, '2025-11-01'),
(1, 3, 'Mateo Rossi', 1000.00, 8000.00, '2025-12-01'),
(2, 2, 'Sofia Gomez', 300.00, 6600.00, '2025-11-15'),
(3, 1, 'Lucas Peralta', 800.00, 14800.00, '2025-12-10'),
(3, 3, 'Lucas Peralta', 1500.00, 12000.00, '2026-01-05'),
(4, 1, 'Sofia Gomez', 200.00, 3700.00, '2026-01-15'),
(5, 2, 'Mateo Rossi', 600.00, 13200.00, '2026-02-01'),
(1, 1, 'Mateo Rossi', 400.00, 7400.00, '2026-02-15'),
(6, 4, 'Sofia Gomez', 350.00, 5250.00, '2026-02-20'),
(2, 1, 'Sofia Gomez', 250.00, 4625.00, '2026-03-01');

-- D. Operaciones de Vuelo (La realidad operativa en campo)
INSERT INTO operaciones_vuelo (oportunidad_id, cliente_id, servicio_id, piloto_asignado, fecha_ejecucion, ha_efectivas, litros_aplicados, monto_facturado_usd, incidencia_clima, estado_vuelo) VALUES
(1, 1, 1, 'Carlos Perez', '2025-11-04', 500.00, 2500.00, 9250.00, FALSE, 'Finalizado'),
(2, 1, 3, 'Juan Martinez', '2025-12-03', 1000.00, 0.00, 8000.00, FALSE, 'Finalizado'),
(3, 2, 2, 'Carlos Perez', '2025-11-20', 250.00, 1250.00, 5500.00, TRUE, 'Parcial'), -- Desviación comercial vs real por clima
(4, 3, 1, 'Gonzalo Lopez', '2025-12-15', 800.00, 4000.00, NULL, FALSE, 'Finalizado'), -- Monto facturado pendiente (NULL)
(5, 3, 3, 'Juan Martinez', NULL, 1500.00, 0.00, 12000.00, FALSE, 'Finalizado'), -- Fecha de ejecución NULL
(6, 4, 1, 'Gonzalo Lopez', '2026-01-18', NULL, 900.00, 3330.00, FALSE, 'Finalizado'), -- Hectáreas NULL (a imputar)
(7, 5, 2, 'Carlos Perez', '2026-02-05', 600.00, 3000.00, 13200.00, FALSE, 'Finalizado'),
(8, 1, 1, 'Carlos Perez', '2026-02-18', 400.00, 2000.00, 7400.00, FALSE, 'Finalizado'),
(9, 6, 4, 'Gonzalo Lopez', '2026-02-25', 300.00, 1500.00, 4500.00, TRUE, 'Parcial'),
(10, 2, 1, 'Juan Martinez', '2026-03-04', 250.00, 1250.00, 4625.00, FALSE, 'Finalizado');