-- ============================================================
-- File: 04_customer_analysis.sql
-- Purpose: Customer analysis
-- ============================================================


-- Query 1: Customer overview

SELECT
    COUNT(*) AS customer_records,
    COUNT(DISTINCT customer_unique_id) AS unique_customer_identities,
    COUNT(DISTINCT customer_city) AS distinct_cities,
    COUNT(DISTINCT customer_state) AS distinct_states
FROM oltp.customers;


-- Query 2: Customers by state

SELECT
    c.customer_state,
    COUNT(*) AS customer_records,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customer_identities
FROM oltp.customers c
GROUP BY c.customer_state
ORDER BY customer_records DESC;


-- Query 3: Top customer cities

SELECT
    customer_state,
    customer_city,
    COUNT(*) AS customer_records
FROM oltp.customers
GROUP BY customer_state, customer_city
ORDER BY customer_records DESC
LIMIT 20;


-- Query 4: Repeat purchasing by unique customer identity

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM oltp.customers c
    JOIN oltp.orders o
        ON c.customer_id = o.customer_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS unique_customers_with_orders,
    COUNT(*) FILTER (WHERE order_count = 1) AS one_order_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_count > 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;


-- Query 5: Top 20 customers by product revenue

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_value
FROM oltp.customers c
JOIN oltp.orders o
    ON c.customer_id = o.customer_id
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY product_revenue DESC
LIMIT 20;


-- Query 6: Customer order-value segments

WITH order_values AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        SUM(oi.price) AS product_value
    FROM oltp.customers c
    JOIN oltp.orders o
        ON c.customer_id = o.customer_id
    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, c.customer_unique_id
)
SELECT
    CASE
        WHEN product_value < 100 THEN 'Under 100'
        WHEN product_value < 250 THEN '100 to under 250'
        WHEN product_value < 500 THEN '250 to under 500'
        ELSE '500 and above'
    END AS order_value_segment,
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(AVG(product_value), 2) AS average_product_value
FROM order_values
GROUP BY 1
ORDER BY MIN(product_value);