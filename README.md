# Proyecto-Final-Integrador-SQL-Kodigo
# Ecommerce Data Warehouse & Business Intelligence

Proyecto de **Data Warehouse y Business Intelligence** desarrollado a partir del dataset **Online Retail**, con el objetivo de transformar datos transaccionales de comercio electrónico en información estructurada para análisis y toma de decisiones.

El proyecto incluye las etapas de **Staging, ETL, modelado dimensional, optimización de consultas y visualización mediante Power BI**.

---

##  Fuente de datos

El proyecto utiliza el dataset **Online Retail**, publicado originalmente por el **UCI Machine Learning Repository** y disponible también en Kaggle.

**Dataset utilizado:**
Kaggle – Ecommerce Data
https://www.kaggle.com/datasets/carrie1/ecommerce-data

El conjunto contiene transacciones reales de una empresa de comercio electrónico del Reino Unido realizadas entre **diciembre de 2010 y diciembre de 2011**.

La información incluye datos como:

* Número de factura
* Código del producto
* Descripción
* Cantidad
* Fecha de transacción
* Precio unitario
* Identificación del cliente
* País

---

#  Objetivo del proyecto

El objetivo principal es construir una solución de análisis empresarial que permita transformar datos transaccionales en información útil para la toma de decisiones.

Para ello se desarrolló un flujo compuesto por:

1. Carga de datos en una tabla **Staging**.
2. Limpieza y transformación de los datos.
3. Construcción de un **modelo dimensional tipo Star Schema**.
4. Implementación de un proceso **ETL**.
5. Optimización de consultas mediante índices.
6. Construcción de un dashboard en **Power BI**.
7. Presentación de KPIs relevantes para el análisis del negocio.

---

#  Arquitectura del proyecto

El flujo general del proyecto puede representarse de la siguiente manera:

```text
Dataset Online Retail
        │
        ▼
   STAGING TABLE
        │
        ▼
 Limpieza y transformación
        │
        ▼
   DATA WAREHOUSE
        │
        ├───────────────┐
        ▼               ▼
 Dimensiones       Tabla de hechos
        │               │
        └───────┬───────┘
                ▼
          Power BI
                │
                ▼
       KPIs y Dashboard
```

---

#  Modelo dimensional

Se implementó un modelo de datos tipo **Star Schema**, compuesto por una tabla de hechos y tres dimensiones.

### Tabla de hechos

`fact_ventas`

Contiene las métricas principales de las transacciones:

* Cantidad vendida
* Precio unitario
* Importe total
* Número de factura

### Dimensiones

`dim_cliente`

Contiene información relacionada con los clientes:

* `customer_id`
* País
* Llave subrogada del cliente

`dim_producto`

Contiene información de los productos:

* `stock_code`
* Descripción
* Llave subrogada del producto

`dim_tiempo`

Permite analizar las ventas temporalmente:

* Fecha
* Año
* Mes
* Día
* Trimestre

---

#  Proceso ETL

El proceso ETL se divide en diferentes etapas.

## 1. Extract

Los datos originales son cargados en:

```sql
ecommerce_dw.staging_ecommerce
```

Esta tabla conserva la estructura original del dataset y funciona como punto de entrada para el proceso de transformación.

## 2. Transform

Durante la transformación se aplican diferentes reglas de limpieza:

* Se eliminan registros sin `CustomerID`.
* Se excluyen las facturas correspondientes a cancelaciones.
* Se eliminan cantidades menores o iguales a cero.
* Se eliminan precios menores o iguales a cero.
* Se convierte la fecha y hora de factura a una fecha de análisis.
* Se calcula el importe total mediante:

```text
total_amount = Quantity × UnitPrice
```

## 3. Load

Los datos transformados son cargados en las dimensiones y posteriormente en la tabla de hechos.

Las relaciones se realizan mediante **llaves subrogadas**, permitiendo separar las dimensiones de los datos transaccionales.

---

#  Optimización de consultas

Como parte del proyecto se realizó una prueba de optimización sobre la tabla:

```text
fact_ventas
```

Se evaluó una consulta que obtiene el historial de ventas de un cliente específico.

Inicialmente, sin un índice sobre `cliente_sk`, PostgreSQL utilizaba un:

```text
Parallel Seq Scan
```

Esto implicaba recorrer aproximadamente **176,000 registros** para localizar las transacciones correspondientes al cliente.

Posteriormente se creó un índice B-Tree:

```sql
CREATE INDEX idx_fk_cliente
ON ecommerce_dw.fact_ventas(cliente_sk);
```

Después de la optimización, PostgreSQL utilizó un:

```text
Bitmap Index Scan
```

permitiendo acceder directamente a los registros relacionados con el cliente consultado.

---

#  Resultado de la optimización

Los resultados obtenidos mediante `EXPLAIN ANALYZE` fueron:

| Escenario  | Tiempo de ejecución |
| ---------- | ------------------: |
| Sin índice |            35.15 ms |
| Con índice |             0.79 ms |

Esto representa una reducción aproximada del:

**97% en el tiempo de ejecución.**

Además, el plan de ejecución pasó de realizar un escaneo secuencial paralelo sobre la tabla de hechos a utilizar el índice creado sobre `cliente_sk`.

Este resultado demuestra la importancia de utilizar índices adecuados para consultas altamente selectivas.

---

#  Power BI

Los datos procesados en el Data Warehouse fueron conectados posteriormente con **Power BI** para construir un dashboard de Business Intelligence.

El dashboard presenta los principales **KPIs considerados relevantes para la compañía**, permitiendo analizar diferentes perspectivas del negocio.

Entre los análisis realizados se encuentran:

* Ingresos
* Ventas
* Cantidad de productos vendidos
* Clientes
* Productos
* Evolución temporal
* Distribución geográfica
* Comportamiento de las ventas

El objetivo del dashboard es convertir los datos procesados mediante SQL en información visual que pueda ser utilizada para el análisis y la toma de decisiones.

---

#  Tecnologías utilizadas

| Tecnología      | Utilización                           |
| --------------- | ------------------------------------- |
| PostgreSQL      | Base de datos y Data Warehouse        |
| SQL             | Modelado, ETL y consultas             |
| EXPLAIN ANALYZE | Análisis y optimización               |
| Power BI        | Visualización y Business Intelligence |
| Kaggle / UCI    | Fuente de datos                       |

---

#  Estructura sugerida del proyecto

```text
ecommerce-datawarehouse/
│
├── README.md
│
├── sql/
│   └── ecommerce_dw.sql
│
├── data/
│   └── ecommerce_data.csv
│
└── powerbi/
    └── ecommerce_dashboard.pbix
```

---

#  Ejecución del proyecto

### 1. Crear el esquema

Ejecutar el script SQL en PostgreSQL para crear el esquema:

```text
ecommerce_dw
```

### 2. Cargar los datos

Cargar el dataset original en:

```text
ecommerce_dw.staging_ecommerce
```

### 3. Ejecutar el ETL

Ejecutar el proceso de creación y carga de:

```text
dim_cliente
dim_producto
dim_tiempo
fact_ventas
```

### 4. Ejecutar las pruebas de optimización

Ejecutar las consultas `EXPLAIN ANALYZE` antes y después de crear el índice:

```text
idx_fk_cliente
```

### 5. Conectar Power BI

Conectar Power BI con el Data Warehouse y utilizar las tablas dimensionales y la tabla de hechos para construir el modelo analítico y el dashboard.

---

#  Conclusiones

El proyecto permitió implementar un flujo completo de **Data Warehouse y Business Intelligence**, comenzando desde datos transaccionales hasta llegar a una solución orientada al análisis empresarial.

El modelo dimensional permitió organizar la información de manera estructurada mediante dimensiones de **cliente, producto y tiempo**, mientras que el proceso ETL permitió limpiar y transformar los datos antes de incorporarlos a la tabla de hechos.

La etapa de optimización también permitió comprobar, mediante `EXPLAIN ANALYZE`, el impacto de utilizar índices en consultas específicas, reduciendo el tiempo de ejecución de **35.15 ms a 0.79 ms**, aproximadamente un **97% de mejora**.

Finalmente, la integración con Power BI permitió convertir la información almacenada en el Data Warehouse en un conjunto de **KPIs y visualizaciones orientadas al negocio**, facilitando el análisis de ventas y proporcionando una base para apoyar la toma de decisiones.

---

## Proyecto académico

**Tema:** Data Warehouse, ETL, Optimización SQL y Business Intelligence

**Dataset:** Online Retail

**Herramientas:** PostgreSQL + SQL + Power BI
