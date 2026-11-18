-- =========================================================
-- File: 01_staging_tables.sql
-- Purpose: Create staging tables from source table structures
-- =========================================================

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.stg_customers AS
SELECT * FROM oltp.customers WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_orders AS
SELECT * FROM oltp.orders WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_order_items AS
SELECT * FROM oltp.order_items WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_products AS
SELECT * FROM oltp.products WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_sellers AS
SELECT * FROM oltp.sellers WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_order_payments AS
SELECT * FROM oltp.order_payments WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_order_reviews AS
SELECT * FROM oltp.order_reviews WHERE FALSE;

CREATE TABLE IF NOT EXISTS staging.stg_product_category_translation AS
SELECT * FROM oltp.product_category_translation WHERE FALSE;


-- Verify staging tables
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'staging'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;