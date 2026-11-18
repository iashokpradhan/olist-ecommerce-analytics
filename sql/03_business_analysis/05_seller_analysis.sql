-- ============================================================
-- File: 05_seller_analysis.sql
-- Purpose: Seller analysis
-- ============================================================


-- Query 1: Overall seller overview

SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_city) AS distinct_seller_cities,
    COUNT(DISTINCT seller_state) AS distinct_seller_states
FROM oltp.sellers;


-- Query 2: Top 20 sellers by product revenue

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS orders,
    COUNT(*) AS order_lines,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_value
FROM oltp.sellers s
JOIN oltp.order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY product_revenue DESC
LIMIT 20;


-- Query 3: Seller performance by state

SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS sellers,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM oltp.sellers s
JOIN oltp.order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY product_revenue DESC;


-- Query 4: Sellers with at least 100 order lines

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS order_lines,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS average_line_price
FROM oltp.sellers s
JOIN oltp.order_items oi
    ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING COUNT(*) >= 100
ORDER BY product_revenue DESC;


-- Query 5: Seller revenue concentration

WITH seller_revenue AS (
    SELECT
        seller_id,
        SUM(price) AS revenue
    FROM oltp.order_items
    GROUP BY seller_id
)
SELECT
    COUNT(*) AS active_sellers,
    ROUND(SUM(revenue), 2) AS total_product_revenue,
    ROUND(AVG(revenue), 2) AS average_seller_revenue,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue)::NUMERIC,
        2
    ) AS median_seller_revenue
FROM seller_revenue;


-- Query 6: Delivery outcomes for sellers

SELECT
    oi.seller_id,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.order_delivered_customer_date
              > o.order_estimated_delivery_date
    ) AS late_delivered_orders,
    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) FILTER (
            WHERE o.order_delivered_customer_date
                  > o.order_estimated_delivery_date
        )
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS late_delivery_percentage
FROM oltp.order_items oi
JOIN oltp.orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY oi.seller_id
ORDER BY late_delivery_percentage DESC NULLS LAST;