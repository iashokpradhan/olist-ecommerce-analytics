-- =========================================================
-- File: 04_load_facts.sql
-- Purpose: Load warehouse fact tables
-- =========================================================

BEGIN;

-- Full refresh of fact tables.
-- Run after dimensions have been loaded successfully.
TRUNCATE TABLE
    dw.fact_sales,
    dw.fact_payments,
    dw.fact_reviews;


-- =========================================================
-- 1. LOAD SALES FACT
-- Grain: One row per order item
-- =========================================================

INSERT INTO dw.fact_sales (
    order_id,
    order_item_id,
    customer_key,
    product_key,
    seller_key,
    order_date_key,
    approval_date_key,
    delivery_date_key,
    estimated_delivery_date_key,
    order_status,
    item_price,
    freight_value
)
SELECT
    oi.order_id,
    oi.order_item_id,

    dc.customer_key,
    dp.product_key,
    ds.seller_key,

    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
        THEN TO_CHAR(
            o.order_purchase_timestamp::DATE,
            'YYYYMMDD'
        )::INTEGER
    END,

    CASE
        WHEN o.order_approved_at IS NOT NULL
        THEN TO_CHAR(
            o.order_approved_at::DATE,
            'YYYYMMDD'
        )::INTEGER
    END,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
        THEN TO_CHAR(
            o.order_delivered_customer_date::DATE,
            'YYYYMMDD'
        )::INTEGER
    END,

    CASE
        WHEN o.order_estimated_delivery_date IS NOT NULL
        THEN TO_CHAR(
            o.order_estimated_delivery_date::DATE,
            'YYYYMMDD'
        )::INTEGER
    END,

    o.order_status,
    oi.price,
    oi.freight_value

FROM staging.stg_order_items AS oi

JOIN staging.stg_orders AS o
    ON oi.order_id = o.order_id

JOIN dw.dim_customer AS dc
    ON o.customer_id = dc.customer_id

JOIN dw.dim_product AS dp
    ON oi.product_id = dp.product_id

JOIN dw.dim_seller AS ds
    ON oi.seller_id = ds.seller_id;


-- =========================================================
-- 2. LOAD PAYMENT FACT
-- Grain: One row per payment record
-- =========================================================

INSERT INTO dw.fact_payments (
    order_id,
    payment_sequential,
    payment_date_key,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    p.order_id,
    p.payment_sequential,

    -- Source data has no payment timestamp.
    -- Do not substitute purchase date as payment date.
    NULL AS payment_date_key,

    p.payment_type,
    p.payment_installments,
    p.payment_value

FROM staging.stg_order_payments AS p;


-- =========================================================
-- 3. LOAD REVIEW FACT
-- Grain: One row per source review record
-- =========================================================

INSERT INTO dw.fact_reviews (
    review_record_id,
    review_id,
    order_id,
    review_date_key,
    review_answer_date_key,
    review_score,
    has_comment
)
SELECT
    r.review_record_id,
    r.review_id,
    r.order_id,

    CASE
        WHEN r.review_creation_date IS NOT NULL
        THEN TO_CHAR(
            r.review_creation_date::DATE,
            'YYYYMMDD'
        )::INTEGER
    END,

    CASE
        WHEN r.review_answer_timestamp IS NOT NULL
        THEN TO_CHAR(
            r.review_answer_timestamp::DATE,
            'YYYYMMDD'
        )::INTEGER
    END,

    r.review_score,

    (
        NULLIF(BTRIM(r.review_comment_title), '') IS NOT NULL
        OR
        NULLIF(BTRIM(r.review_comment_message), '') IS NOT NULL
    ) AS has_comment

FROM staging.stg_order_reviews AS r;


COMMIT;


-- =========================================================
-- VERIFY FACT TABLE ROW COUNTS
-- =========================================================

SELECT 'fact_sales' AS table_name, COUNT(*) AS total_rows
FROM dw.fact_sales

UNION ALL

SELECT 'fact_payments', COUNT(*)
FROM dw.fact_payments

UNION ALL

SELECT 'fact_reviews', COUNT(*)
FROM dw.fact_reviews

ORDER BY table_name;