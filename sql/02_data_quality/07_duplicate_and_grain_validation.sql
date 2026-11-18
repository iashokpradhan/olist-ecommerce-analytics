-- ============================================================
-- Module 7: Duplicate and Grain Validation
-- Purpose: Identify duplicate identifiers and understand
--          the level of detail in each table
-- ============================================================


-- 1. Duplicate review_id values
-- review_id is a source identifier; investigate duplicates
-- rather than assuming they are invalid.

SELECT
    review_id,
    COUNT(*) AS record_count,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM oltp.order_reviews
WHERE review_id IS NOT NULL
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC, review_id;


-- 2. Orders containing multiple order items
-- Multiple items per order are expected.

SELECT
    order_id,
    COUNT(*) AS item_count
FROM oltp.order_items
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY item_count DESC, order_id
LIMIT 50;


-- 3. Orders containing multiple payment records
-- Multiple payment records per order are expected.

SELECT
    order_id,
    COUNT(*) AS payment_record_count
FROM oltp.order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_record_count DESC, order_id
LIMIT 50;


-- 4. Customers sharing the same customer_unique_id
-- This may reflect multiple customer records for one identity.

SELECT
    customer_unique_id,
    COUNT(*) AS customer_records
FROM oltp.customers
WHERE customer_unique_id IS NOT NULL
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY customer_records DESC
LIMIT 50;


-- 5. Repeated geolocation ZIP prefixes
-- These are expected because one ZIP prefix may have
-- multiple geographic observations.

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS location_records,
    COUNT(DISTINCT geolocation_city) AS distinct_cities,
    COUNT(DISTINCT geolocation_state) AS distinct_states
FROM oltp.geolocation
WHERE geolocation_zip_code_prefix IS NOT NULL
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1
ORDER BY location_records DESC
LIMIT 50;


-- 6. Products without a matching English category translation

SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM oltp.products AS p
LEFT JOIN oltp.product_category_translation AS t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;


-- 7. Review records per order
-- An order can have multiple review records.

SELECT
    order_id,
    COUNT(*) AS review_record_count,
    COUNT(DISTINCT review_id) AS distinct_review_ids
FROM oltp.order_reviews
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_record_count DESC, order_id
LIMIT 50;


-- 8. Confirm order-item table grain
-- Expected grain: one row per order_id + order_item_id.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS distinct_order_items,
    COUNT(*) - COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_key_difference
FROM oltp.order_items;


-- 9. Confirm payment table grain
-- Expected grain: one row per order_id + payment_sequential.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential))
        AS distinct_payment_records,
    COUNT(*) - COUNT(DISTINCT (order_id, payment_sequential))
        AS duplicate_key_difference
FROM oltp.order_payments;