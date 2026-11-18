-- ============================================================
-- Module 4: Missing Values Validation
-- Purpose: Profile NULL values in important columns
-- ============================================================


-- 1. Customers

SELECT
    'customers' AS table_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS missing_unique_id,
    COUNT(*) FILTER (WHERE customer_city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS missing_state
FROM oltp.customers;


-- 2. Orders

SELECT
    'orders' AS table_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS missing_status,
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
    ) AS missing_purchase_timestamp,
    COUNT(*) FILTER (
        WHERE order_approved_at IS NULL
    ) AS missing_approval_timestamp,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NULL
    ) AS missing_carrier_timestamp,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_timestamp,
    COUNT(*) FILTER (
        WHERE order_estimated_delivery_date IS NULL
    ) AS missing_estimated_delivery_date
FROM oltp.orders;


-- 3. Order items

SELECT
    'order_items' AS table_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS missing_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS missing_freight
FROM oltp.order_items;


-- 4. Products

SELECT
    'products' AS table_name,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_id,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_category,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weight,
    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
    ) AS missing_length,
    COUNT(*) FILTER (
        WHERE product_height_cm IS NULL
    ) AS missing_height,
    COUNT(*) FILTER (
        WHERE product_width_cm IS NULL
    ) AS missing_width
FROM oltp.products;


-- 5. Sellers

SELECT
    'sellers' AS table_name,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id,
    COUNT(*) FILTER (WHERE seller_city IS NULL) AS missing_city,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS missing_state
FROM oltp.sellers;


-- 6. Order payments

SELECT
    'order_payments' AS table_name,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (
        WHERE payment_sequential IS NULL
    ) AS missing_payment_sequence,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS missing_payment_type,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS missing_payment_value,
    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
    ) AS missing_installments
FROM oltp.order_payments;


-- 7. Order reviews

SELECT
    'order_reviews' AS table_name,
    COUNT(*) FILTER (WHERE review_record_id IS NULL) AS missing_record_id,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS missing_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS missing_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS missing_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS missing_message,
    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
    ) AS missing_creation_date,
    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
    ) AS missing_answer_timestamp
FROM oltp.order_reviews;


-- 8. Geolocation

SELECT
    'geolocation' AS table_name,
    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
    ) AS missing_zip_prefix,
    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
    ) AS missing_latitude,
    COUNT(*) FILTER (
        WHERE geolocation_lng IS NULL
    ) AS missing_longitude,
    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
    ) AS missing_city,
    COUNT(*) FILTER (
        WHERE geolocation_state IS NULL
    ) AS missing_state
FROM oltp.geolocation;


-- 9. Product category translation

SELECT
    'product_category_translation' AS table_name,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_original_category,
    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
    ) AS missing_english_category
FROM oltp.product_category_translation;