-- ============================================================
-- Module 6: Query Optimization
-- File: 01_query_optimization.sql
-- Purpose: Practical SQL rewrite techniques, indexing patterns,
--          and performance hypotheses for PostgreSQL warehouses
-- ============================================================


-- ============================================================
-- TECHNIQUE 1: SARGABILITY & PREDICATE FORMULATION
-- ============================================================
-- Hypothesis:
-- Wrapping an indexed column in a function (e.g. EXTRACT, TO_CHAR,
-- DATE_TRUNC) prevents PostgreSQL from using a standard B-Tree index
-- range scan on that column (unless a specialized expression index exists).
--
-- Rewriting the filter as a SARGable (Search Argument Able) range predicate
-- allows the cost-based optimizer to consider an index scan. Note that the
-- planner may still choose a sequential scan if the table is small or if
-- the filter matches a large fraction of the total rows.

-- ------------------------------------------------------------
-- 1.1 Non-SARGable Query: Function call on indexed column
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM oltp.orders o
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
  AND EXTRACT(MONTH FROM o.order_purchase_timestamp) = 5
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp);

-- ------------------------------------------------------------
-- 1.2 SARGable Query: Typed half-open interval [start, end)
-- ------------------------------------------------------------
-- Explicit typed timestamps allow index bounds without type coercion.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM oltp.orders o
JOIN oltp.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp >= TIMESTAMP '2018-05-01 00:00:00'
  AND o.order_purchase_timestamp <  TIMESTAMP '2018-06-01 00:00:00'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp);


-- ============================================================
-- TECHNIQUE 2: ELIMINATING CORRELATED SUBQUERIES
-- ============================================================
-- Hypothesis:
-- Correlated subqueries in the SELECT clause execute repeatedly for
-- each outer row. Replacing them with set-based CTEs or window functions
-- allows PostgreSQL to process data in bulk sets rather than nested iterations.
--
-- Correctness Note:
-- To preserve exact metric equivalence, order count and item spending must
-- be computed in separate aggregations. A naive single join would drop orders
-- that have no matching order items, causing inconsistent metric counts.

-- ------------------------------------------------------------
-- 2.1 Correlated Subquery Pattern: Independent scalar lookups
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_id,
    c.customer_city,
    c.customer_state,
    (
        SELECT COUNT(DISTINCT o.order_id)
        FROM oltp.orders o
        WHERE o.customer_id = c.customer_id
    ) AS order_count,
    (
        SELECT ROUND(COALESCE(SUM(oi.price), 0)::numeric, 2)
        FROM oltp.orders o
        JOIN oltp.order_items oi ON o.order_id = oi.order_id
        WHERE o.customer_id = c.customer_id
    ) AS total_spend
FROM oltp.customers c
WHERE c.customer_state = 'SP'
LIMIT 500;

-- ------------------------------------------------------------
-- 2.2 Fully Equivalent Set-Based Rewrite: Pre-aggregated CTEs
-- ------------------------------------------------------------
-- Note: LIMIT 500 provides a representative execution sample for testing.
-- Removing LIMIT allows testing full-table scan and hash join characteristics.
EXPLAIN (ANALYZE, BUFFERS)
WITH customer_orders AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM oltp.orders o
    GROUP BY o.customer_id
),
customer_spend AS (
    SELECT
        o.customer_id,
        SUM(oi.price) AS total_spend
    FROM oltp.orders o
    JOIN oltp.order_items oi
        ON oi.order_id = o.order_id
    GROUP BY o.customer_id
)
SELECT
    c.customer_id,
    c.customer_city,
    c.customer_state,
    COALESCE(co.order_count, 0) AS order_count,
    ROUND(COALESCE(cs.total_spend, 0)::numeric, 2) AS total_spend
FROM oltp.customers c
LEFT JOIN customer_orders co
    ON co.customer_id = c.customer_id
LEFT JOIN customer_spend cs
    ON cs.customer_id = c.customer_id
WHERE c.customer_state = 'SP'
LIMIT 500;


-- ============================================================
-- TECHNIQUE 3: AGGREGATE PUSHDOWN (EARLY AGGREGATION)
-- ============================================================
-- Hypothesis:
-- In star schemas, grouping fact rows on surrogate keys before joining
-- descriptive dimensions can reduce the row volume flowing through the join
-- engine. However, early aggregation introduces an additional aggregation
-- step and subquery barrier that may or may not outperform PostgreSQL's
-- native Hash Join. Compare both plans on your dataset.

-- ------------------------------------------------------------
-- 3.1 Standard Star Join: Join dimensions first, then aggregate
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_state,
    p.product_category_name_english,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(f.item_price), 2) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_customer c ON f.customer_key = c.customer_key
JOIN dw.dim_product p  ON f.product_key  = p.product_key
GROUP BY c.customer_state, p.product_category_name_english
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------
-- 3.2 Early Aggregation: Group fact keys prior to dimension joins
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
WITH aggregated_facts AS (
    SELECT
        f.customer_key,
        f.product_key,
        COUNT(*) AS total_items_sold,
        SUM(f.item_price) AS raw_revenue
    FROM dw.fact_sales f
    GROUP BY f.customer_key, f.product_key
)
SELECT
    c.customer_state,
    p.product_category_name_english,
    SUM(af.total_items_sold) AS total_items_sold,
    ROUND(SUM(af.raw_revenue), 2) AS total_revenue
FROM aggregated_facts af
JOIN dw.dim_customer c ON af.customer_key = c.customer_key
JOIN dw.dim_product p  ON af.product_key  = p.product_key
GROUP BY c.customer_state, p.product_category_name_english
ORDER BY total_revenue DESC;


-- ============================================================
-- TECHNIQUE 4: SEMI-JOIN OPTIMIZATION (EXISTS VS DISTINCT)
-- ============================================================
-- Hypothesis:
-- Testing for the existence of related rows using an inner join with
-- DISTINCT generates intermediate join tuples and subsequently deduplicates
-- them via a Sort Unique or HashAggregate node.
--
-- A correlated EXISTS subquery allows PostgreSQL to plan a Semi-Join,
-- which stops scanning the inner relation as soon as the first match is found.

-- ------------------------------------------------------------
-- 4.1 Inner Join + DISTINCT (Forces generation & deduplication)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT
    c.customer_key,
    c.customer_city,
    c.customer_state
FROM dw.dim_customer c
JOIN dw.fact_sales f ON c.customer_key = f.customer_key
WHERE f.order_status = 'canceled';

-- ------------------------------------------------------------
-- 4.2 Correlated EXISTS (Enables Semi-Join / early exit)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_key,
    c.customer_city,
    c.customer_state
FROM dw.dim_customer c
WHERE EXISTS (
    SELECT 1
    FROM dw.fact_sales f
    WHERE f.customer_key = c.customer_key
      AND f.order_status = 'canceled'
);


-- ============================================================
-- TECHNIQUE 5: COVERING INDEXES & INDEX-ONLY SCANS
-- ============================================================
-- Hypothesis:
-- Standard B-Tree indexes require visiting heap pages to retrieve
-- payload columns (item_price, freight_value). An index using the
-- INCLUDE clause stores these payload attributes in leaf pages.
--
-- Important Operational Nuance:
-- An Index-Only Scan is NOT guaranteed solely by creating the index.
-- PostgreSQL requires the table's Visibility Map (VM) to mark pages
-- as all-visible to confirm that tuples are visible to the current MVCC
-- snapshot without heap fetches. Running VACUUM updates the Visibility Map.

-- Create covering index for date-filtered sales reporting
CREATE INDEX IF NOT EXISTS idx_fact_sales_covering_date_revenue
    ON dw.fact_sales (order_date_key)
    INCLUDE (item_price, freight_value);

-- Refresh planner statistics (ANALYZE is permitted inside transaction blocks)
ANALYZE dw.fact_sales;

-- NOTE: To update the Visibility Map (VM) and achieve 0 Heap Fetches,
-- PostgreSQL requires VACUUM. Because VACUUM cannot run inside a multi-statement
-- transaction block (SQL state 25001), execute it independently if desired:
-- VACUUM dw.fact_sales;

-- ------------------------------------------------------------
-- 5.1 Testing for Index-Only Scan
-- ------------------------------------------------------------
-- Check the plan output for:
--   "Index Only Scan using idx_fact_sales_covering_date_revenue"
--   "Heap Fetches: 0" (or low number if pages were modified recently)
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    order_date_key,
    COUNT(*) AS total_items,
    ROUND(SUM(item_price), 2) AS total_item_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight
FROM dw.fact_sales
WHERE order_date_key BETWEEN 20180101 AND 20180630
GROUP BY order_date_key
ORDER BY order_date_key;
