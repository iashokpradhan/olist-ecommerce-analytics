-- ============================================================
-- File: 02_time_series_analysis.sql
-- Purpose: Time-series analysis
-- ============================================================


-- Query 1: Monthly sales and order volume

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
        AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS customer_records,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(
        SUM(oi.price)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM oltp.orders o
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- Query 2: Month-over-month revenue growth

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS order_month,
        SUM(oi.price) AS product_revenue
    FROM oltp.orders o
    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1
),
comparison AS (
    SELECT
        order_month,
        product_revenue,
        LAG(product_revenue) OVER (ORDER BY order_month)
            AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    order_month,
    ROUND(product_revenue, 2) AS product_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 * (product_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS revenue_growth_percentage
FROM comparison
ORDER BY order_month;


-- Query 3: Month-over-month order growth

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp)::DATE
            AS order_month,
        COUNT(*) AS total_orders
    FROM oltp.orders
    WHERE order_purchase_timestamp IS NOT NULL
    GROUP BY 1
),
comparison AS (
    SELECT
        order_month,
        total_orders,
        LAG(total_orders) OVER (ORDER BY order_month)
            AS previous_month_orders
    FROM monthly_orders
)
SELECT
    order_month,
    total_orders,
    previous_month_orders,
    ROUND(
        100.0 * (total_orders - previous_month_orders)
        / NULLIF(previous_month_orders, 0),
        2
    ) AS order_growth_percentage
FROM comparison
ORDER BY order_month;


-- Query 4: Orders by day of week

SELECT
    EXTRACT(ISODOW FROM order_purchase_timestamp)::INT
        AS weekday_number,
    TO_CHAR(order_purchase_timestamp, 'FMDay') AS weekday_name,
    COUNT(*) AS total_orders
FROM oltp.orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY 1, 2
ORDER BY 1;


-- Query 5: Orders by hour of day

SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp)::INT
        AS purchase_hour,
    COUNT(*) AS total_orders
FROM oltp.orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- Query 6: Monthly delivered-order revenue

SELECT
    DATE_TRUNC('month', o.order_delivered_customer_date)::DATE
        AS delivery_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM oltp.orders o
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 1;