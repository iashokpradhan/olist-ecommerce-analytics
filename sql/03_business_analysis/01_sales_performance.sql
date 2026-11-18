-- ============================================================
-- Module 3: Business Analysis
-- File: 01_sales_performance.sql
-- ============================================================


-- Query 1: Overall sales KPIs

SELECT
    COUNT(DISTINCT oi.order_id) AS orders_with_items,
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT o.customer_id) AS customer_records_with_sales,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2)
        AS product_plus_freight,
    ROUND(
        SUM(oi.price)
        / NULLIF(COUNT(DISTINCT oi.order_id), 0),
        2
    ) AS average_order_value
FROM oltp.order_items oi
JOIN oltp.orders o
    ON oi.order_id = o.order_id;


-- Query 2: Order count by status

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(*)
        / NULLIF((SELECT COUNT(*) FROM oltp.orders), 0),
        2
    ) AS percentage_of_all_orders
FROM oltp.orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- Query 3: Product revenue by order status

SELECT
    o.order_status,
    COUNT(DISTINCT oi.order_id) AS orders_with_items,
    COUNT(*) AS order_items,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_value
FROM oltp.orders o
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY product_revenue DESC NULLS LAST;


-- Query 4: Delivered-order sales

SELECT
    COUNT(DISTINCT oi.order_id) AS delivered_orders,
    COUNT(*) AS delivered_order_items,
    ROUND(SUM(oi.price), 2) AS delivered_product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS delivered_freight_value,
    ROUND(
        SUM(oi.price)
        / NULLIF(COUNT(DISTINCT oi.order_id), 0),
        2
    ) AS average_delivered_order_value
FROM oltp.orders o
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- Query 5: Top 20 orders by product value

SELECT
    oi.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    COUNT(*) AS item_count,
    ROUND(SUM(oi.price), 2) AS product_value,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(SUM(oi.price + oi.freight_value), 2)
        AS product_plus_freight
FROM oltp.order_items oi
JOIN oltp.orders o
    ON oi.order_id = o.order_id
GROUP BY
    oi.order_id,
    o.order_status,
    o.order_purchase_timestamp
ORDER BY product_value DESC
LIMIT 20;


-- Query 6: Share of product revenue by order status

WITH status_sales AS (
    SELECT
        o.order_status,
        SUM(oi.price) AS product_revenue
    FROM oltp.orders o
    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_status
)
SELECT
    order_status,
    ROUND(product_revenue, 2) AS product_revenue,
    ROUND(
        100.0 * product_revenue
        / NULLIF(SUM(product_revenue) OVER (), 0),
        2
    ) AS revenue_percentage
FROM status_sales
ORDER BY product_revenue DESC;