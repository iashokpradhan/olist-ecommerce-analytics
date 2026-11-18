-- =========================================================
-- File: 02_transform_data.sql
-- Purpose: Extract and prepare source data in staging
-- =========================================================

BEGIN;

TRUNCATE TABLE
    staging.stg_order_items,
    staging.stg_order_payments,
    staging.stg_order_reviews,
    staging.stg_orders,
    staging.stg_products,
    staging.stg_sellers,
    staging.stg_customers,
    staging.stg_product_category_translation;

INSERT INTO staging.stg_customers
SELECT *
FROM oltp.customers;

INSERT INTO staging.stg_orders
SELECT *
FROM oltp.orders;

INSERT INTO staging.stg_order_items
SELECT *
FROM oltp.order_items;

INSERT INTO staging.stg_products
SELECT *
FROM oltp.products;

INSERT INTO staging.stg_sellers
SELECT *
FROM oltp.sellers;

INSERT INTO staging.stg_order_payments
SELECT *
FROM oltp.order_payments;

INSERT INTO staging.stg_order_reviews
SELECT *
FROM oltp.order_reviews;

INSERT INTO staging.stg_product_category_translation
SELECT *
FROM oltp.product_category_translation;

COMMIT;


-- =========================================================
-- VALIDATE STAGING ROW COUNTS
-- =========================================================

SELECT 'customers' AS table_name,
       (SELECT COUNT(*) FROM oltp.customers) AS source_rows,
       (SELECT COUNT(*) FROM staging.stg_customers) AS staging_rows

UNION ALL

SELECT 'orders',
       (SELECT COUNT(*) FROM oltp.orders),
       (SELECT COUNT(*) FROM staging.stg_orders)

UNION ALL

SELECT 'order_items',
       (SELECT COUNT(*) FROM oltp.order_items),
       (SELECT COUNT(*) FROM staging.stg_order_items)

UNION ALL

SELECT 'products',
       (SELECT COUNT(*) FROM oltp.products),
       (SELECT COUNT(*) FROM staging.stg_products)

UNION ALL

SELECT 'sellers',
       (SELECT COUNT(*) FROM oltp.sellers),
       (SELECT COUNT(*) FROM staging.stg_sellers)

UNION ALL

SELECT 'order_payments',
       (SELECT COUNT(*) FROM oltp.order_payments),
       (SELECT COUNT(*) FROM staging.stg_order_payments)

UNION ALL

SELECT 'order_reviews',
       (SELECT COUNT(*) FROM oltp.order_reviews),
       (SELECT COUNT(*) FROM staging.stg_order_reviews)

UNION ALL

SELECT 'product_category_translation',
       (SELECT COUNT(*) FROM oltp.product_category_translation),
       (SELECT COUNT(*) FROM staging.stg_product_category_translation)

ORDER BY table_name;