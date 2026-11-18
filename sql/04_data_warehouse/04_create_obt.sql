-- =========================================================
-- File: 04_create_obt.sql
-- Purpose: Create a sales-oriented One Big Table view
-- =========================================================

-- Ensure clean tear-down and rebuild to prevent dependency locks
DROP VIEW IF EXISTS dw.vw_sales_obt CASCADE;

CREATE VIEW dw.vw_sales_obt AS

SELECT
    -- Order details
    f.order_id,
    f.order_item_id,
    f.order_status,

    -- Order date
    od.full_date AS order_date,
    od.day_of_month AS order_day,
    od.day_name AS order_day_name,
    od.month_number AS order_month_number,
    od.month_name AS order_month_name,
    od.quarter_number AS order_quarter,
    od.year_number AS order_year,

    -- Customer details
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    -- Product details
    p.product_id,
    p.product_category_name,
    p.product_category_name_english,
    p.product_weight_g,

    -- Seller details
    s.seller_id,
    s.seller_city,
    s.seller_state,

    -- Sales measures
    f.item_price,
    f.freight_value,
    f.item_price + f.freight_value AS item_total_value,

    -- Actual delivery date
    dd.full_date AS delivery_date,

    -- Estimated delivery date
    ed.full_date AS estimated_delivery_date,

    -- Delivery outcome
    CASE
        WHEN dd.full_date IS NULL
          OR ed.full_date IS NULL
        THEN NULL

        WHEN dd.full_date <= ed.full_date
        THEN 'On Time or Early'

        ELSE 'Late'
    END AS delivery_status

FROM dw.fact_sales AS f

JOIN dw.dim_customer AS c
    ON f.customer_key = c.customer_key

JOIN dw.dim_product AS p
    ON f.product_key = p.product_key

JOIN dw.dim_seller AS s
    ON f.seller_key = s.seller_key

LEFT JOIN dw.dim_date AS od
    ON f.order_date_key = od.date_key

LEFT JOIN dw.dim_date AS dd
    ON f.delivery_date_key = dd.date_key

LEFT JOIN dw.dim_date AS ed
    ON f.estimated_delivery_date_key = ed.date_key;


-- =========================================================
-- VERIFY OBT VIEW
-- =========================================================

SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'dw'
  AND table_name = 'vw_sales_obt';
