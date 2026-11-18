-- ============================================================
-- File: 03_product_analysis.sql
-- Purpose: Product and category analysis
-- ============================================================


-- Query 1: Product category performance

SELECT
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown / Unclassified'
    ) AS product_category,
    COUNT(*) AS units_or_order_lines,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(DISTINCT oi.product_id) AS distinct_products,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(AVG(oi.price), 2) AS average_line_price
FROM oltp.order_items oi
JOIN oltp.products p
    ON oi.product_id = p.product_id
LEFT JOIN oltp.product_category_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY product_revenue DESC;


-- Query 2: Top 20 products by revenue

SELECT
    oi.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown / Unclassified'
    ) AS product_category,
    COUNT(*) AS order_lines,
    COUNT(DISTINCT oi.order_id) AS orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS average_line_price
FROM oltp.order_items oi
JOIN oltp.products p
    ON oi.product_id = p.product_id
LEFT JOIN oltp.product_category_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY oi.product_id, p.product_category_name,
         t.product_category_name_english
ORDER BY product_revenue DESC
LIMIT 20;


-- Query 3: Lowest-revenue products with at least 10 order lines

SELECT
    oi.product_id,
    COUNT(*) AS order_lines,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM oltp.order_items oi
GROUP BY oi.product_id
HAVING COUNT(*) >= 10
ORDER BY product_revenue ASC
LIMIT 20;


-- Query 4: Price bands

WITH product_lines AS (
    SELECT
        order_id,
        price,
        CASE
            WHEN price < 50 THEN 'Under 50'
            WHEN price < 100 THEN '50 to under 100'
            WHEN price < 250 THEN '100 to under 250'
            WHEN price < 500 THEN '250 to under 500'
            ELSE '500 and above'
        END AS price_band
    FROM oltp.order_items
)
SELECT
    price_band,
    COUNT(*) AS order_lines,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(price), 2) AS product_revenue,
    ROUND(AVG(price), 2) AS average_line_price
FROM product_lines
GROUP BY price_band
ORDER BY MIN(price);


-- Query 5: Product dimensions and missing attributes

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
    ) AS missing_categories,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS missing_weights,
    COUNT(*) FILTER (
        WHERE product_length_cm IS NULL
           OR product_height_cm IS NULL
           OR product_width_cm IS NULL
    ) AS products_with_missing_dimensions,
    ROUND(AVG(product_weight_g), 2) AS average_weight_g
FROM oltp.products;


-- Query 6: Category contribution to total revenue

WITH category_revenue AS (
    SELECT
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown / Unclassified'
        ) AS product_category,
        SUM(oi.price) AS revenue
    FROM oltp.order_items oi
    JOIN oltp.products p
        ON oi.product_id = p.product_id
    LEFT JOIN oltp.product_category_translation t
        ON p.product_category_name = t.product_category_name
    GROUP BY 1
)
SELECT
    product_category,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0),
        2
    ) AS revenue_share_percentage
FROM category_revenue
ORDER BY revenue DESC;