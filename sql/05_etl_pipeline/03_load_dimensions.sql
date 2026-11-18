-- =========================================================
-- File: 03_load_dimensions.sql
-- Purpose: Load warehouse dimension tables
-- =========================================================

BEGIN;

-- =========================================================
-- 1. CUSTOMER DIMENSION
-- =========================================================

INSERT INTO dw.dim_customer (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state
FROM staging.stg_customers AS c
ON CONFLICT (customer_id)
DO UPDATE SET
    customer_unique_id = EXCLUDED.customer_unique_id,
    customer_zip_code_prefix = EXCLUDED.customer_zip_code_prefix,
    customer_city = EXCLUDED.customer_city,
    customer_state = EXCLUDED.customer_state;


-- =========================================================
-- 2. PRODUCT DIMENSION
-- =========================================================

INSERT INTO dw.dim_product (
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM staging.stg_products AS p
LEFT JOIN staging.stg_product_category_translation AS t
    ON p.product_category_name = t.product_category_name
ON CONFLICT (product_id)
DO UPDATE SET
    product_category_name = EXCLUDED.product_category_name,
    product_category_name_english =
        EXCLUDED.product_category_name_english,
    product_name_length = EXCLUDED.product_name_length,
    product_description_length =
        EXCLUDED.product_description_length,
    product_photos_qty = EXCLUDED.product_photos_qty,
    product_weight_g = EXCLUDED.product_weight_g,
    product_length_cm = EXCLUDED.product_length_cm,
    product_height_cm = EXCLUDED.product_height_cm,
    product_width_cm = EXCLUDED.product_width_cm;


-- =========================================================
-- 3. SELLER DIMENSION
-- =========================================================

INSERT INTO dw.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    s.seller_id,
    s.seller_zip_code_prefix,
    s.seller_city,
    s.seller_state
FROM staging.stg_sellers AS s
ON CONFLICT (seller_id)
DO UPDATE SET
    seller_zip_code_prefix = EXCLUDED.seller_zip_code_prefix,
    seller_city = EXCLUDED.seller_city,
    seller_state = EXCLUDED.seller_state;


-- =========================================================
-- 4. DATE DIMENSION
-- =========================================================

WITH source_dates AS (
    SELECT order_purchase_timestamp::DATE AS event_date
    FROM staging.stg_orders
    WHERE order_purchase_timestamp IS NOT NULL

    UNION ALL

    SELECT order_approved_at::DATE
    FROM staging.stg_orders
    WHERE order_approved_at IS NOT NULL

    UNION ALL

    SELECT order_delivered_customer_date::DATE
    FROM staging.stg_orders
    WHERE order_delivered_customer_date IS NOT NULL

    UNION ALL

    SELECT order_estimated_delivery_date::DATE
    FROM staging.stg_orders
    WHERE order_estimated_delivery_date IS NOT NULL

    UNION ALL

    SELECT review_creation_date::DATE
    FROM staging.stg_order_reviews
    WHERE review_creation_date IS NOT NULL

    UNION ALL

    SELECT review_answer_timestamp::DATE
    FROM staging.stg_order_reviews
    WHERE review_answer_timestamp IS NOT NULL
),
date_bounds AS (
    SELECT
        MIN(event_date) AS min_date,
        MAX(event_date) AS max_date
    FROM source_dates
),
calendar AS (
    SELECT
        generate_series(
            min_date::TIMESTAMP,
            max_date::TIMESTAMP,
            INTERVAL '1 day'
        )::DATE AS full_date
    FROM date_bounds
    WHERE min_date IS NOT NULL
      AND max_date IS NOT NULL
)
INSERT INTO dw.dim_date (
    date_key,
    full_date,
    day_of_month,
    day_of_week,
    day_name,
    week_of_year,
    month_number,
    month_name,
    quarter_number,
    year_number,
    is_weekend
)
SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INTEGER AS date_key,
    full_date,
    EXTRACT(DAY FROM full_date)::INTEGER,
    EXTRACT(ISODOW FROM full_date)::INTEGER,
    TO_CHAR(full_date, 'FMDay'),
    EXTRACT(WEEK FROM full_date)::INTEGER,
    EXTRACT(MONTH FROM full_date)::INTEGER,
    TO_CHAR(full_date, 'FMMonth'),
    EXTRACT(QUARTER FROM full_date)::INTEGER,
    EXTRACT(YEAR FROM full_date)::INTEGER,
    EXTRACT(ISODOW FROM full_date) IN (6, 7)
FROM calendar
ON CONFLICT (date_key)
DO NOTHING;

COMMIT;


-- =========================================================
-- VERIFY DIMENSIONS
-- =========================================================

SELECT 'dim_customer' AS table_name, COUNT(*) AS total_rows
FROM dw.dim_customer

UNION ALL

SELECT 'dim_product', COUNT(*)
FROM dw.dim_product

UNION ALL

SELECT 'dim_seller', COUNT(*)
FROM dw.dim_seller

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dw.dim_date

ORDER BY table_name;