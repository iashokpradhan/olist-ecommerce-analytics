-- ============================================================
-- Project: Olist E-commerce Analytics
-- Phase 2: Data Quality Validation
-- Module 1: Row Count Validation
-- Database: olist_analytics
-- Schema: oltp
-- ============================================================

WITH actual_counts AS (
    SELECT 'customers' AS table_name, COUNT(*) AS actual_rows
    FROM oltp.customers

    UNION ALL
    SELECT 'orders', COUNT(*) FROM oltp.orders

    UNION ALL
    SELECT 'order_items', COUNT(*) FROM oltp.order_items

    UNION ALL
    SELECT 'products', COUNT(*) FROM oltp.products

    UNION ALL
    SELECT 'sellers', COUNT(*) FROM oltp.sellers

    UNION ALL
    SELECT 'order_payments', COUNT(*) FROM oltp.order_payments

    UNION ALL
    SELECT 'order_reviews', COUNT(*) FROM oltp.order_reviews

    UNION ALL
    SELECT 'geolocation', COUNT(*) FROM oltp.geolocation

    UNION ALL
    SELECT 'product_category_translation', COUNT(*)
    FROM oltp.product_category_translation
),
expected_counts AS (
    SELECT *
    FROM (
        VALUES
            ('customers', 99441::BIGINT),
            ('orders', 99441::BIGINT),
            ('order_items', 112650::BIGINT),
            ('products', 32951::BIGINT),
            ('sellers', 3095::BIGINT),
            ('order_payments', 103886::BIGINT),
            ('order_reviews', 99224::BIGINT),
            ('geolocation', 1000163::BIGINT),
            ('product_category_translation', 71::BIGINT)
    ) AS v(table_name, expected_rows)
)
SELECT
    a.table_name,
    a.actual_rows,
    e.expected_rows,
    a.actual_rows - e.expected_rows AS row_difference,
    CASE
        WHEN a.actual_rows = e.expected_rows THEN 'PASS'
        ELSE 'INVESTIGATE'
    END AS validation_status
FROM actual_counts AS a
JOIN expected_counts AS e USING (table_name)
ORDER BY a.table_name;