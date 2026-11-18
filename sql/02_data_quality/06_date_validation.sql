-- ============================================================
-- Module 6: Date Validation
-- Purpose: Identify suspicious timestamp sequences
-- ============================================================


-- 1. Approval before purchase

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at
FROM oltp.orders
WHERE order_approved_at < order_purchase_timestamp
ORDER BY order_purchase_timestamp;


-- 2. Carrier delivery before purchase

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date
FROM oltp.orders
WHERE order_delivered_carrier_date < order_purchase_timestamp
ORDER BY order_purchase_timestamp;


-- 3. Customer delivery before purchase

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM oltp.orders
WHERE order_delivered_customer_date < order_purchase_timestamp
ORDER BY order_purchase_timestamp;


-- 4. Carrier delivery before approval
-- Compare only when both timestamps are present.

SELECT
    order_id,
    order_status,
    order_approved_at,
    order_delivered_carrier_date
FROM oltp.orders
WHERE order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_carrier_date < order_approved_at
ORDER BY order_purchase_timestamp;


-- 5. Customer delivery before carrier delivery

SELECT
    order_id,
    order_status,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM oltp.orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date
ORDER BY order_purchase_timestamp;


-- 6. Actual delivery after estimated delivery

SELECT
    order_id,
    order_status,
    order_estimated_delivery_date,
    order_delivered_customer_date,
    order_delivered_customer_date
        - order_estimated_delivery_date AS delivery_delay
FROM oltp.orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date
ORDER BY delivery_delay DESC;


-- 7. Review answer timestamp before review creation timestamp

SELECT
    review_record_id,
    review_id,
    order_id,
    review_creation_date,
    review_answer_timestamp
FROM oltp.order_reviews
WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL
  AND review_answer_timestamp < review_creation_date
ORDER BY review_creation_date;