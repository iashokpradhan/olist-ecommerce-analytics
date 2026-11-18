-- ============================================================
-- Project: Olist E-commerce Analytics
-- Purpose: Verify imported record counts
-- Schema: oltp
-- Database: olist_analytics
-- ============================================================


SELECT
    'customers' AS table_name,
    COUNT(*) AS actual_rows,
    99441 AS expected_rows,
    COUNT(*) = 99441 AS count_matches
FROM oltp.customers

UNION ALL

SELECT
    'orders',
    COUNT(*),
    99441,
    COUNT(*) = 99441
FROM oltp.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*),
    112650,
    COUNT(*) = 112650
FROM oltp.order_items

UNION ALL

SELECT
    'products',
    COUNT(*),
    32951,
    COUNT(*) = 32951
FROM oltp.products

UNION ALL

SELECT
    'sellers',
    COUNT(*),
    3095,
    COUNT(*) = 3095
FROM oltp.sellers

UNION ALL

SELECT
    'order_payments',
    COUNT(*),
    103886,
    COUNT(*) = 103886
FROM oltp.order_payments

UNION ALL

SELECT
    'order_reviews',
    COUNT(*),
    99224,
    COUNT(*) = 99224
FROM oltp.order_reviews

UNION ALL

SELECT
    'geolocation',
    COUNT(*),
    1000163,
    COUNT(*) = 1000163
FROM oltp.geolocation

UNION ALL

SELECT
    'product_category_translation',
    COUNT(*),
    71,
    COUNT(*) = 71
FROM oltp.product_category_translation

ORDER BY table_name;