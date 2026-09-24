# Proyecto Capstone: Análisis Integrado Agrodrones Argentina (CRM vs. Operaciones)

**Autor:** Agustín Pérez Álvarez  
**Curso:** Análisis de Datos / SQL  
**Tecnología:** PostgreSQL 18 / pgAdmin 4  

---

## 🎯 Contexto y Problema de Negocio

En el sector agrotecnológico de la Zona Núcleo argentina (Santa Fe, Córdoba y Buenos Aires), la adopción de servicios de pulverización selectiva, siembra aérea y monitoreo NDVI mediante drones agrícolas ha experimentado un crecimiento acelerado.

Durante mi análisis, identifiqué una problemática crítica en la compañía: **la brecha entre las promesas comerciales (CRM) y la ejecución real en campo (Operaciones)**. Factores climáticos, demoras logísticas y falta de partes diarios provocaban inconsistencias en la facturación y riesgo de abandono de clientes (*churn*).

Mi objetivo principal en este proyecto fue construir una arquitectura relacional en PostgreSQL para limpiar, consolidar y analizar los datos de ambas áreas, dando respuesta a tres preguntas estratégicas planteadas por la dirección.

---

## 📐 Estructura de la Base de Datos (Modelo Relacional)

Diseñé la base de datos `capstone_project` consolidando 4 fuentes principales interconectadas mediante claves primarias (`PK`) y foráneas (`FK`):

1. **`crm_clientes`**: Registro de productores y campos con su segmento comercial (*Gold*, *Silver*, *Bronze*).
2. **`servicios_drones`**: Catálogo de prestaciones técnicas, modelo de equipo asignado, costo operativo e ingreso de lista por hectárea.
3. **`crm_oportunidades`**: Compromisos comerciales cerrados por el equipo de ventas.
4. **`operaciones_vuelo`**: Partes de vuelo reales ejecutados por los pilotos, incluyendo variables como incidencias climáticas y hectáreas efectivas.

---

## 🧹 Etapa de Limpieza y Transformación (Data Cleaning)

Para resolver las inconsistencias y los valores nulos habituales que provienen del trabajo de campo, apliqué reglas de negocio utilizando la función `COALESCE` en mi script de análisis:

* **Fechas de Vuelo Nulas (`fecha_ejecucion`):** Las imputé utilizando la fecha de cierre estimada de la oportunidad comercial (`fecha_cierre_esperada`).
* **Hectáreas Nulas (`ha_efectivas`):** Ante la ausencia del reporte del piloto, tomé de manera preventiva las hectáreas comprometidas originalmente en la venta.
* **Monto Facturado Pendiente (`monto_facturado_usd`):** Lo recalculé dinámicamente multiplicando las hectáreas finales tratadas por el precio de lista oficial del servicio (`precio_lista_usd_ha`).

---

## 📊 Hallazgos Principales y Conclusiones del Análisis

### 1. Desviación Comercial vs. Realidad Operativa
* **Hallazgo:** Detecté diferencias puntuales entre las hectáreas contratadas y las efectivamente ejecutadas por factores climáticos (por ejemplo, en *Estancia Don Pedro SRL*, donde se contrataron 300 ha pero solo se ejecutaron 250 ha debido a condiciones adversas).
* **Propuesta Estratégica:** Sugiero implementar una cláusula de reprogramación automática en el CRM cuando la variable `incidencia_clima` sea `TRUE`, evitando pérdidas de facturación por servicios inconclusos.

### 2. Matriz de Recorrencia y Lealtad por Segmento
* **Hallazgo:** Utilizando Window Functions (`LAG` y `DENSE_RANK`), comprobé que los clientes del segmento *Gold* (como *Agropecuaria El Sol S.A.* y *Los Grobo Campos S.A.*) presentan contrataciones recurrentes con un intervalo promedio de 30 a 40 días entre servicios.
* **Propuesta Estratégica:** Recomiendo priorizar la asignación de flotas para el segmento *Gold* y activar un plan de fidelización a los 25 días del último vuelo para incentivar la recompra.

### 3. Eficiencia Operativa y Rentabilidad por Drone
* **Hallazgo:** Evalué el margen bruto por equipo y determiné que el modelo **DJI Agras T40** lidera el volumen de ingresos ($39.405 USD) y retorno operativo en Pulverización Selectiva, seguido por el **Mavic 3 Enterprise** en Telemetría NDVI.
* **Propuesta Estratégica:** Aconsejo orientar las próximas inversiones de capital (CAPEX) a la adquisición de unidades T40, dado su alto rendimiento por hectárea y eficiencia en campo.

---

## 🛠️ Instrucciones para Replicar el Proyecto

1. Abrir **pgAdmin 4** y conectar con el servidor local de PostgreSQL.
2. Crear la base de datos `capstone_project`:
   ```sql
   CREATE DATABASE capstone_project;
