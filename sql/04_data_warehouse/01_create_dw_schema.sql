-- =========================================================
-- File: 01_create_dw_schema.sql
-- Purpose: Create the data warehouse schema
-- Database: olist_analytics
-- =========================================================

CREATE SCHEMA IF NOT EXISTS dw;

COMMENT ON SCHEMA dw IS
'Analytical data warehouse for the Olist e-commerce project';

-- Verify schema creation
SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN ('oltp', 'dw')
ORDER BY schema_name;