-- =========================================================
-- File: 06_reconciliation_checks.sql
-- Purpose: Validate source-to-warehouse completeness
-- =========================================================


-- =========================================================
-- 1. SOURCE VS WAREHOUSE ROW COUNTS
-- =========================================================

SELECT
    'customers' AS entity,
    (SELECT COUNT(*) FROM oltp.customers) AS source_rows,
    (SELECT COUNT(*) FROM dw.dim_customer) AS warehouse_rows

UNION ALL

SELECT
    'products',
    (SELECT COUNT(*) FROM oltp.products),
    (SELECT COUNT(*) FROM dw.dim_product)

UNION ALL

SELECT
    'sellers',
    (SELECT COUNT(*) FROM oltp.sellers),
    (SELECT COUNT(*) FROM dw.dim_seller)

UNION ALL

SELECT
    'sales items',
    (SELECT COUNT(*) FROM oltp.order_items),
    (SELECT COUNT(*) FROM dw.fact_sales)

UNION ALL

SELECT
    'payment records',
    (SELECT COUNT(*) FROM oltp.order_payments),
    (SELECT COUNT(*) FROM dw.fact_payments)

UNION ALL

SELECT
    'review records',
    (SELECT COUNT(*) FROM oltp.order_reviews),
    (SELECT COUNT(*) FROM dw.fact_reviews)

ORDER BY entity;


-- =========================================================
-- 2. SALES REVENUE RECONCILIATION
-- =========================================================

WITH source_sales AS (
    SELECT
        COUNT(*) AS source_item_rows,
        SUM(price) AS source_product_revenue,
        SUM(freight_value) AS source_freight
    FROM oltp.order_items
),
warehouse_sales AS (
    SELECT
        COUNT(*) AS warehouse_item_rows,
        SUM(item_price) AS warehouse_product_revenue,
        SUM(freight_value) AS warehouse_freight
    FROM dw.fact_sales
)
SELECT
    s.source_item_rows,
    w.warehouse_item_rows,

    s.source_product_revenue,
    w.warehouse_product_revenue,

    s.source_freight,
    w.warehouse_freight,

    s.source_product_revenue
        - w.warehouse_product_revenue
        AS product_revenue_difference,

    s.source_freight
        - w.warehouse_freight
        AS freight_difference

FROM source_sales AS s
CROSS JOIN warehouse_sales AS w;


-- =========================================================
-- 3. MISSING SALES FACT ROWS
-- =========================================================

SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id
FROM oltp.order_items AS oi
LEFT JOIN dw.fact_sales AS f
    ON oi.order_id = f.order_id
   AND oi.order_item_id = f.order_item_id
WHERE f.sales_key IS NULL
ORDER BY oi.order_id, oi.order_item_id;


-- =========================================================
-- 4. DUPLICATE SALES GRAIN CHECK
-- Expected: zero rows
-- =========================================================

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS record_count
FROM dw.fact_sales
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;


-- =========================================================
-- 5. MISSING CUSTOMER DIMENSION MATCHES
-- =========================================================

SELECT COUNT(*) AS customers_missing_from_dimension
FROM oltp.customers AS c
LEFT JOIN dw.dim_customer AS d
    ON c.customer_id = d.customer_id
WHERE d.customer_key IS NULL;


-- =========================================================
-- 6. MISSING PRODUCT DIMENSION MATCHES
-- =========================================================

SELECT COUNT(*) AS products_missing_from_dimension
FROM oltp.products AS p
LEFT JOIN dw.dim_product AS d
    ON p.product_id = d.product_id
WHERE d.product_key IS NULL;


-- =========================================================
-- 7. MISSING SELLER DIMENSION MATCHES
-- =========================================================

SELECT COUNT(*) AS sellers_missing_from_dimension
FROM oltp.sellers AS s
LEFT JOIN dw.dim_seller AS d
    ON s.seller_id = d.seller_id
WHERE d.seller_key IS NULL;


-- =========================================================
-- 8. PAYMENT RECONCILIATION
-- =========================================================

WITH source_payments AS (
    SELECT
        COUNT(*) AS source_rows,
        SUM(payment_value) AS source_payment_value
    FROM oltp.order_payments
),
warehouse_payments AS (
    SELECT
        COUNT(*) AS warehouse_rows,
        SUM(payment_value) AS warehouse_payment_value
    FROM dw.fact_payments
)
SELECT
    s.source_rows,
    w.warehouse_rows,
    s.source_payment_value,
    w.warehouse_payment_value,
    s.source_payment_value
        - w.warehouse_payment_value
        AS payment_value_difference
FROM source_payments AS s
CROSS JOIN warehouse_payments AS w;


-- =========================================================
-- 9. REVIEW RECONCILIATION
-- =========================================================

WITH source_reviews AS (
    SELECT
        COUNT(*) AS source_rows,
        AVG(review_score::NUMERIC) AS source_average_score
    FROM oltp.order_reviews
),
warehouse_reviews AS (
    SELECT
        COUNT(*) AS warehouse_rows,
        AVG(review_score::NUMERIC) AS warehouse_average_score
    FROM dw.fact_reviews
)
SELECT
    s.source_rows,
    w.warehouse_rows,
    s.source_average_score,
    w.warehouse_average_score
FROM source_reviews AS s
CROSS JOIN warehouse_reviews AS w;


-- =========================================================
-- 10. WAREHOUSE VIEW VALIDATION
-- =========================================================

SELECT
    COUNT(*) AS obt_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    SUM(item_price) AS product_revenue,
    SUM(freight_value) AS freight_value
FROM dw.vw_sales_obt;