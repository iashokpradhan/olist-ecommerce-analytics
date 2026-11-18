-- ============================================================
-- File: 06_payment_analysis.sql
-- Purpose: Payment analysis
-- ============================================================


-- Query 1: Overall payment KPIs

SELECT
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders_with_payments,
    ROUND(SUM(payment_value), 2) AS total_recorded_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_record_value,
    ROUND(AVG(payment_installments), 2) AS average_installments
FROM oltp.order_payments;


-- Query 2: Payment method distribution

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders_using_method,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(
        100.0 * SUM(payment_value)
        / NULLIF(
            (SELECT SUM(payment_value) FROM oltp.order_payments),
            0
        ),
        2
    ) AS share_of_payment_value_percentage
FROM oltp.order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- Query 3: Installment distribution

SELECT
    payment_installments,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM oltp.order_payments
GROUP BY payment_installments
ORDER BY payment_installments;


-- Query 4: Payment records by sequential number

SELECT
    payment_sequential,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM oltp.order_payments
GROUP BY payment_sequential
ORDER BY payment_sequential;


-- Query 5: Orders with multiple payment records

SELECT
    order_id,
    COUNT(*) AS payment_record_count,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM oltp.order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY total_payment_value DESC
LIMIT 50;


-- Query 6: Compare item totals and payment totals at order level

-- This comparison aggregates each table separately before joining,
-- preventing row multiplication between items and payment records.

WITH item_totals AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS item_and_freight_total
    FROM oltp.order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_total
    FROM oltp.order_payments
    GROUP BY order_id
)
SELECT
    COALESCE(i.order_id, p.order_id) AS order_id,
    ROUND(i.item_and_freight_total, 2) AS item_and_freight_total,
    ROUND(p.payment_total, 2) AS payment_total,
    ROUND(
        p.payment_total - i.item_and_freight_total,
        2
    ) AS payment_minus_item_total
FROM item_totals i
FULL OUTER JOIN payment_totals p
    ON i.order_id = p.order_id
WHERE i.order_id IS NULL
   OR p.order_id IS NULL
   OR ABS(
        COALESCE(p.payment_total, 0)
        - COALESCE(i.item_and_freight_total, 0)
      ) > 0.01
ORDER BY ABS(
    COALESCE(p.payment_total, 0)
    - COALESCE(i.item_and_freight_total, 0)
) DESC
LIMIT 100;