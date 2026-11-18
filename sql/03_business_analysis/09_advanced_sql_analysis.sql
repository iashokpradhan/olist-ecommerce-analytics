-- ============================================================
-- File: 09_advanced_sql_analysis.sql
-- Purpose: Advanced SQL analysis
-- Topics: CTEs, window functions, ranking, running totals
-- ============================================================


-- Query 1: Top 3 product categories in each month

WITH monthly_category_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS sales_month,

        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'Unknown / Unclassified'
        ) AS category,

        SUM(oi.price) AS revenue

    FROM oltp.orders o

    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id

    JOIN oltp.products p
        ON oi.product_id = p.product_id

    LEFT JOIN oltp.product_category_translation t
        ON p.product_category_name = t.product_category_name

    WHERE o.order_purchase_timestamp IS NOT NULL

    GROUP BY 1, 2
),
ranked_categories AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY sales_month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category_sales
)
SELECT
    sales_month,
    category,
    ROUND(revenue, 2) AS revenue,
    category_rank
FROM ranked_categories
WHERE category_rank <= 3
ORDER BY sales_month, category_rank;


-- Query 2: Running monthly product revenue

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS sales_month,
        SUM(oi.price) AS revenue
    FROM oltp.orders o
    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS monthly_revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM monthly_sales
ORDER BY sales_month;


-- Query 3: Month-over-month revenue changes

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
            AS sales_month,
        SUM(oi.price) AS revenue
    FROM oltp.orders o
    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY 1
),
revenue_changes AS (
    SELECT
        sales_month,
        revenue,
        LAG(revenue) OVER (ORDER BY sales_month) AS previous_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_revenue, 2) AS previous_revenue,
    ROUND(revenue - previous_revenue, 2) AS revenue_change,
    ROUND(
        100.0 * (revenue - previous_revenue)
        / NULLIF(previous_revenue, 0),
        2
    ) AS revenue_growth_percentage
FROM revenue_changes
ORDER BY sales_month;


-- Query 4: Rank sellers by revenue

WITH seller_sales AS (
    SELECT
        seller_id,
        SUM(price) AS revenue
    FROM oltp.order_items
    GROUP BY seller_id
)
SELECT
    seller_id,
    ROUND(revenue, 2) AS revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    ROUND(
        100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0),
        2
    ) AS revenue_share_percentage
FROM seller_sales
ORDER BY revenue_rank
LIMIT 50;


-- Query 5: Customer RFM-style summary

-- Recency is measured against the latest purchase timestamp in
-- this dataset, not today's date. This is useful for comparing
-- customers within the source dataset's observation period.

WITH dataset_reference AS (
    SELECT MAX(order_purchase_timestamp) AS reference_timestamp
    FROM oltp.orders
),
customer_metrics AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary_value,
        MAX(o.order_purchase_timestamp) AS last_purchase_timestamp
    FROM oltp.customers c
    JOIN oltp.orders o
        ON c.customer_id = o.customer_id
    JOIN oltp.order_items oi
        ON o.order_id = oi.order_id
    WHERE c.customer_unique_id IS NOT NULL
    GROUP BY c.customer_unique_id
)
SELECT
    cm.customer_unique_id,
    cm.frequency,
    ROUND(cm.monetary_value, 2) AS monetary_value,
    cm.last_purchase_timestamp,
    ROUND(
        EXTRACT(
            EPOCH FROM (
                dr.reference_timestamp - cm.last_purchase_timestamp
            )
        ) / 86400.0,
        2
    ) AS recency_days
FROM customer_metrics cm
CROSS JOIN dataset_reference dr
ORDER BY cm.monetary_value DESC
LIMIT 100;


-- Query 6: Pareto-style seller revenue concentration

WITH seller_sales AS (
    SELECT
        seller_id,
        SUM(price) AS revenue
    FROM oltp.order_items
    GROUP BY seller_id
),
ranked_sellers AS (
    SELECT
        seller_id,
        revenue,
        SUM(revenue) OVER (
            ORDER BY revenue DESC, seller_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM seller_sales
)
SELECT
    seller_id,
    ROUND(revenue, 2) AS seller_revenue,
    ROUND(cumulative_revenue, 2) AS cumulative_revenue,
    ROUND(
        100.0 * cumulative_revenue / NULLIF(total_revenue, 0),
        2
    ) AS cumulative_revenue_percentage
FROM ranked_sellers
ORDER BY revenue DESC
LIMIT 100;