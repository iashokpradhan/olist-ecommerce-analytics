-- ============================================================
-- Module 5: Numeric Validation
-- Purpose: Identify suspicious numeric values
-- ============================================================


-- 1. Negative prices or freight values

SELECT *
FROM oltp.order_items
WHERE price < 0
   OR freight_value < 0
ORDER BY order_id, order_item_id;


-- 2. Zero prices or freight values
-- These are flagged for review, not automatically treated as errors.

SELECT *
FROM oltp.order_items
WHERE price = 0
   OR freight_value = 0
ORDER BY order_id, order_item_id;


-- 3. Negative or zero payment values

SELECT *
FROM oltp.order_payments
WHERE payment_value <= 0
ORDER BY order_id, payment_sequential;


-- 4. Non-positive payment installments

-- Zero installments are known to occur in this dataset.
-- Preserve the source data and document the findings.

SELECT *
FROM oltp.order_payments
WHERE payment_installments <= 0
ORDER BY order_id, payment_sequential;


-- 5. Invalid review scores
-- Olist review scores are expected to range from 1 to 5.

SELECT *
FROM oltp.order_reviews
WHERE review_score NOT BETWEEN 1 AND 5
   OR review_score IS NULL
ORDER BY order_id;


-- 6. Negative product weight

SELECT *
FROM oltp.products
WHERE product_weight_g < 0
ORDER BY product_id;


-- 7. Non-positive product dimensions
-- NULL values are checked separately in Module 4.

SELECT *
FROM oltp.products
WHERE product_length_cm <= 0
   OR product_height_cm <= 0
   OR product_width_cm <= 0
ORDER BY product_id;


-- 8. Negative product photo counts or text lengths

SELECT *
FROM oltp.products
WHERE product_photos_qty < 0
   OR product_name_lenght < 0
   OR product_description_lenght < 0
ORDER BY product_id;


-- 9. Negative or zero product weight

SELECT *
FROM oltp.products
WHERE product_weight_g <= 0
ORDER BY product_id;