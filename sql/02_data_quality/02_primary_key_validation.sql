-- ============================================================
-- Module 2: Primary Key Validation
-- Purpose: Check key columns for NULLs and duplicates
-- ============================================================

-- 1. Customers: customer_id

SELECT
    'customers.customer_id' AS key_column,
    COUNT(*) AS invalid_rows
FROM oltp.customers
WHERE customer_id IS NULL

UNION ALL

SELECT
    'customers.customer_id - duplicate groups',
    COUNT(*)
FROM (
    SELECT customer_id
    FROM oltp.customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- 2. Orders: order_id

SELECT
    'orders.order_id' AS key_column,
    COUNT(*) AS invalid_rows
FROM oltp.orders
WHERE order_id IS NULL

UNION ALL

SELECT
    'orders.order_id - duplicate groups',
    COUNT(*)
FROM (
    SELECT order_id
    FROM oltp.orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- 3. Products: product_id

SELECT
    'products.product_id',
    COUNT(*)
FROM oltp.products
WHERE product_id IS NULL

UNION ALL

SELECT
    'products.product_id - duplicate groups',
    COUNT(*)
FROM (
    SELECT product_id
    FROM oltp.products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- 4. Sellers: seller_id

SELECT
    'sellers.seller_id',
    COUNT(*)
FROM oltp.sellers
WHERE seller_id IS NULL

UNION ALL

SELECT
    'sellers.seller_id - duplicate groups',
    COUNT(*)
FROM (
    SELECT seller_id
    FROM oltp.sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- 5. Order items: composite key

SELECT
    'order_items - NULL composite key values' AS key_column,
    COUNT(*) AS invalid_rows
FROM oltp.order_items
WHERE order_id IS NULL
   OR order_item_id IS NULL

UNION ALL

SELECT
    'order_items - duplicate composite key groups',
    COUNT(*)
FROM (
    SELECT order_id, order_item_id
    FROM oltp.order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- 6. Order payments: composite key

SELECT
    'order_payments - NULL composite key values',
    COUNT(*)
FROM oltp.order_payments
WHERE order_id IS NULL
   OR payment_sequential IS NULL

UNION ALL

SELECT
    'order_payments - duplicate composite key groups',
    COUNT(*)
FROM (
    SELECT order_id, payment_sequential
    FROM oltp.order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS duplicates;


-- 7. Product category translation

SELECT
    'product_category_translation.product_category_name - NULL',
    COUNT(*)
FROM oltp.product_category_translation
WHERE product_category_name IS NULL

UNION ALL

SELECT
    'product_category_translation.product_category_name - duplicates',
    COUNT(*)
FROM (
    SELECT product_category_name
    FROM oltp.product_category_translation
    GROUP BY product_category_name
    HAVING COUNT(*) > 1
) AS duplicates;


-- 8. Order reviews: generated record identifier

SELECT
    'order_reviews.review_record_id - NULL' AS key_column,
    COUNT(*) AS invalid_rows
FROM oltp.order_reviews
WHERE review_record_id IS NULL

UNION ALL

SELECT
    'order_reviews.review_record_id - duplicate groups',
    COUNT(*)
FROM (
    SELECT review_record_id
    FROM oltp.order_reviews
    GROUP BY review_record_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- 9. Geolocation: generated record identifier

SELECT
    'geolocation.geolocation_id - NULL',
    COUNT(*)
FROM oltp.geolocation
WHERE geolocation_id IS NULL

UNION ALL

SELECT
    'geolocation.geolocation_id - duplicate groups',
    COUNT(*)
FROM (
    SELECT geolocation_id
    FROM oltp.geolocation
    GROUP BY geolocation_id
    HAVING COUNT(*) > 1
) AS duplicates;