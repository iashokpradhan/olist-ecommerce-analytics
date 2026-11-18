-- =========================================================
-- File: 06_remediate_dimension_types.sql
-- Purpose: Safely alter dimension column types in-place
-- Context: Resolves type mismatch (ZIP as VARCHAR(5), state as CHAR(2))
--          while navigating view dependencies (dw.vw_sales_obt).
-- =========================================================

-- Step 0: (Diagnostic) Query dependent views on target columns
-- Run this prior to altering any table column in Postgres:
/*
SELECT
    v.relname AS dependent_view_name,
    n.nspname AS view_schema,
    att.attname AS target_column
FROM pg_depend d
JOIN pg_rewrite r ON r.oid = d.objid
JOIN pg_class v ON v.oid = r.ev_class
JOIN pg_namespace n ON n.oid = v.relnamespace
JOIN pg_attribute att ON att.attrelid = d.refobjid AND att.attnum = d.refobjsubid
WHERE d.refobjid = 'dw.dim_customer'::regclass
  AND d.deptype = 'n'
  AND v.relkind = 'v';
*/

BEGIN;

-- Step 1: Drop dependent views before modifying referenced columns
DROP VIEW IF EXISTS dw.vw_sales_obt CASCADE;

-- Step 2: Alter dw.dim_customer
-- Using LPAD ensures any integer values that lost leading zeros are restored to 5-digit strings
ALTER TABLE dw.dim_customer
    ALTER COLUMN customer_zip_code_prefix TYPE VARCHAR(5)
        USING CASE 
            WHEN customer_zip_code_prefix IS NULL THEN NULL 
            ELSE LPAD(customer_zip_code_prefix::TEXT, 5, '0') 
        END,
    ALTER COLUMN customer_state TYPE CHAR(2);

-- Step 3: Alter dw.dim_seller
ALTER TABLE dw.dim_seller
    ALTER COLUMN seller_zip_code_prefix TYPE VARCHAR(5)
        USING CASE 
            WHEN seller_zip_code_prefix IS NULL THEN NULL 
            ELSE LPAD(seller_zip_code_prefix::TEXT, 5, '0') 
        END,
    ALTER COLUMN seller_state TYPE CHAR(2);

-- Step 4: Recreate dw.vw_sales_obt
CREATE VIEW dw.vw_sales_obt AS
SELECT
    f.order_id,
    f.order_item_id,
    f.order_status,
    od.full_date AS order_date,
    od.day_of_month AS order_day,
    od.day_name AS order_day_name,
    od.month_number AS order_month_number,
    od.month_name AS order_month_name,
    od.quarter_number AS order_quarter,
    od.year_number AS order_year,
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    p.product_id,
    p.product_category_name,
    p.product_category_name_english,
    p.product_weight_g,
    s.seller_id,
    s.seller_city,
    s.seller_state,
    f.item_price,
    f.freight_value,
    f.item_price + f.freight_value AS item_total_value,
    dd.full_date AS delivery_date,
    ed.full_date AS estimated_delivery_date,
    CASE
        WHEN dd.full_date IS NULL OR ed.full_date IS NULL THEN NULL
        WHEN dd.full_date <= ed.full_date THEN 'On Time or Early'
        ELSE 'Late'
    END AS delivery_status
FROM dw.fact_sales AS f
JOIN dw.dim_customer AS c ON f.customer_key = c.customer_key
JOIN dw.dim_product AS p ON f.product_key = p.product_key
JOIN dw.dim_seller AS s ON f.seller_key = s.seller_key
LEFT JOIN dw.dim_date AS od ON f.order_date_key = od.date_key
LEFT JOIN dw.dim_date AS dd ON f.delivery_date_key = dd.date_key
LEFT JOIN dw.dim_date AS ed ON f.estimated_delivery_date_key = ed.date_key;

COMMIT;

-- Step 5: Verification
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'dw' 
  AND table_name = 'dim_customer' 
  AND column_name IN ('customer_zip_code_prefix', 'customer_state');
