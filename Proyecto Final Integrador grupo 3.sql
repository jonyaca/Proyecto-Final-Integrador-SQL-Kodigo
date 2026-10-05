-- ============================================================
-- FASE 1 - CREACIÓN DEL ESQUEMA Y TABLA STAGING
-- ============================================================
/*
Delmy Elizabeth Chavarria Rivas 
Mauricio Alexis Yanme Reyes 
Miguel Ernesto Marmol Romero
Lyan Donovan Segovia Lopez
Jonathan Alexis Carrillo Aguirre
 */
CREATE SCHEMA IF NOT EXISTS ecommerce_dw;

-- Tabla temporal de recepción de los datos originales
CREATE TABLE ecommerce_dw.staging_ecommerce (
    InvoiceNo VARCHAR(50),
    StockCode VARCHAR(50),
    Description TEXT,
    Quantity INT,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(10,2),
    CustomerID VARCHAR(50),
    Country VARCHAR(100)
);


-- ============================================================
-- FASE 2 - CREACIÓN DEL MODELO DIMENSIONAL
-- ============================================================

-- Limpieza del entorno: eliminar tablas existentes
DROP TABLE IF EXISTS ecommerce_dw.fact_ventas CASCADE;
DROP TABLE IF EXISTS ecommerce_dw.dim_cliente CASCADE;
DROP TABLE IF EXISTS ecommerce_dw.dim_producto CASCADE;
DROP TABLE IF EXISTS ecommerce_dw.dim_tiempo CASCADE;


-- Dimensión de clientes
CREATE TABLE ecommerce_dw.dim_cliente (
    cliente_sk BIGSERIAL PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE,
    country VARCHAR(100)
);


-- Dimensión de productos
CREATE TABLE ecommerce_dw.dim_producto (
    producto_sk BIGSERIAL PRIMARY KEY,
    stock_code VARCHAR(50) UNIQUE,
    description TEXT
);


-- Dimensión de tiempo
CREATE TABLE ecommerce_dw.dim_tiempo (
    tiempo_sk BIGSERIAL PRIMARY KEY,
    invoice_date DATE UNIQUE,
    anio INT,
    mes INT,
    dia INT,
    trimestre INT
);


-- Tabla de hechos de ventas
CREATE TABLE ecommerce_dw.fact_ventas (
    venta_sk BIGSERIAL PRIMARY KEY,
    cliente_sk BIGINT REFERENCES ecommerce_dw.dim_cliente(cliente_sk),
    producto_sk BIGINT REFERENCES ecommerce_dw.dim_producto(producto_sk),
    tiempo_sk BIGINT REFERENCES ecommerce_dw.dim_tiempo(tiempo_sk),
    invoice_no VARCHAR(50),
    quantity INT,
    unit_price NUMERIC(10,2),
    total_amount NUMERIC(12,2)
);


-- ============================================================
-- CARGA DE LAS DIMENSIONES
-- ============================================================

-- Carga de la dimensión de clientes
INSERT INTO ecommerce_dw.dim_cliente (
    customer_id,
    country
)
SELECT DISTINCT
    CustomerID,
    Country
FROM ecommerce_dw.staging_ecommerce
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
ON CONFLICT (customer_id) DO NOTHING;


-- Carga de la dimensión de productos
INSERT INTO ecommerce_dw.dim_producto (
    stock_code,
    description
)
SELECT DISTINCT
    StockCode,
    Description
FROM ecommerce_dw.staging_ecommerce
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
ON CONFLICT (stock_code) DO NOTHING;


-- Carga de la dimensión de tiempo
INSERT INTO ecommerce_dw.dim_tiempo (
    invoice_date,
    anio,
    mes,
    dia,
    trimestre
)
SELECT DISTINCT
    CAST(InvoiceDate AS DATE),
    EXTRACT(YEAR FROM CAST(InvoiceDate AS DATE)),
    EXTRACT(MONTH FROM CAST(InvoiceDate AS DATE)),
    EXTRACT(DAY FROM CAST(InvoiceDate AS DATE)),
    EXTRACT(QUARTER FROM CAST(InvoiceDate AS DATE))
FROM ecommerce_dw.staging_ecommerce
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
ON CONFLICT (invoice_date) DO NOTHING;


-- ============================================================
-- ETL - LIMPIEZA Y CARGA DE LA TABLA DE HECHOS
-- ============================================================

WITH datos_limpios AS (
    SELECT
        InvoiceNo,
        StockCode,
        Quantity,
        CAST(InvoiceDate AS DATE) AS InvoiceDate_limpia,
        UnitPrice,
        CustomerID,
        (Quantity * UnitPrice) AS total_amount
    FROM ecommerce_dw.staging_ecommerce
    WHERE CustomerID IS NOT NULL
      AND Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
)

INSERT INTO ecommerce_dw.fact_ventas (
    cliente_sk,
    producto_sk,
    tiempo_sk,
    invoice_no,
    quantity,
    unit_price,
    total_amount
)
SELECT
    c.cliente_sk,
    p.producto_sk,
    t.tiempo_sk,
    d.InvoiceNo,
    d.Quantity,
    d.UnitPrice,
    d.total_amount
FROM datos_limpios d
JOIN ecommerce_dw.dim_cliente c
    ON d.CustomerID = c.customer_id
JOIN ecommerce_dw.dim_producto p
    ON d.StockCode = p.stock_code
JOIN ecommerce_dw.dim_tiempo t
    ON d.InvoiceDate_limpia = t.invoice_date;


-- ============================================================
-- FASE 3 - OPTIMIZACIÓN DE CONSULTAS
-- ============================================================

-- EL ANTES:
-- Eliminar el índice para evaluar el comportamiento
-- de la consulta sin optimización.

DROP INDEX IF EXISTS ecommerce_dw.idx_fk_cliente;


-- Consulta de prueba antes de crear el índice
EXPLAIN ANALYZE
SELECT
    t.anio,
    t.trimestre,
    c.country,
    SUM(f.total_amount) AS ingresos
FROM ecommerce_dw.fact_ventas f
JOIN ecommerce_dw.dim_cliente c
    ON f.cliente_sk = c.cliente_sk
JOIN ecommerce_dw.dim_tiempo t
    ON f.tiempo_sk = t.tiempo_sk
WHERE f.cliente_sk = 150
GROUP BY
    t.anio,
    t.trimestre,
    c.country;


-- LA OPTIMIZACIÓN:
-- Crear un índice B-Tree sobre la llave foránea
-- cliente_sk de la tabla de hechos.

CREATE INDEX idx_fk_cliente
ON ecommerce_dw.fact_ventas(cliente_sk);


-- EL DESPUÉS:
-- Ejecutar nuevamente la misma consulta para
-- comparar el plan de ejecución y el tiempo obtenido.

EXPLAIN ANALYZE
SELECT
    t.anio,
    t.trimestre,
    c.country,
    SUM(f.total_amount) AS ingresos
FROM ecommerce_dw.fact_ventas f
JOIN ecommerce_dw.dim_cliente c
    ON f.cliente_sk = c.cliente_sk
JOIN ecommerce_dw.dim_tiempo t
    ON f.tiempo_sk = t.tiempo_sk
WHERE f.cliente_sk = 150
GROUP BY
    t.anio,
    t.trimestre,
    c.country;