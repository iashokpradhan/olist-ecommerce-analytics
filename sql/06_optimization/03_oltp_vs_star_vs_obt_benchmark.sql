-- ============================================================
-- Module 6: Query Optimization
-- File: 03_oltp_vs_star_vs_obt_benchmark.sql
-- Purpose: Architectural benchmark comparing query performance,
--          execution plans, buffer reads, and trade-offs across:
--          1. OLTP Normalized (3NF)
--          2. Star Schema (Dimensional Data Warehouse)
--          3. OBT Logical View (Expanded Reporting Layer)
--          4. Materialized OBT (Physically Persisted Flat Table)
-- ============================================================


-- ============================================================
-- 1. TESTING PROTOCOL & BENCHMARKING METHODOLOGY
-- ============================================================
/*
  Before drawing performance conclusions, follow this testing sequence:

  Step 1: Schema & Column Verification
          Ensure all referenced tables, views, and columns exist.
  Step 2: Refresh Planner Statistics
          Run ANALYZE on source and warehouse schemas.
  Step 3: Execute Queries Individually
          Do not run the entire file at once. Highlight and run each
          query block with EXPLAIN (ANALYZE, BUFFERS).
  Step 4: Record Plan Metrics
          - Planning time vs Execution time (ms)
          - Scan types (Seq Scan, Index Scan, Index Only Scan)
          - Join types (Hash Join, Nested Loop, Merge Join)
          - Buffer metrics (shared hit, shared read, temp read/written)
  Step 5: Verify Correctness
          Confirm that all three architectural queries return identical
          row counts and metric totals for the same business question.
  Step 6: Repeat Measurements
          Run each query at least twice to observe cold cache (shared read)
          versus warm cache (shared hit) characteristics.
  Step 7: Formulate Evidence-Based Conclusions
          Document actual observed outcomes rather than assuming one
          architecture is universally faster.
*/

-- ------------------------------------------------------------
-- Pre-Flight Check: Verify columns available in dw.vw_sales_obt
-- ------------------------------------------------------------
SELECT 
    column_name, 
    data_type 
FROM information_schema.columns
WHERE table_schema = 'dw' 
  AND table_name = 'vw_sales_obt'
ORDER BY ordinal_position;


-- ============================================================
-- BENCHMARK 1: REVENUE & FREIGHT BY CATEGORY AND YEAR
-- Business Question: Total delivered revenue, freight, and item counts
--                   grouped by English product category and calendar year.
-- ============================================================

-- ------------------------------------------------------------
-- 1.A Normalized OLTP Architecture (4 Joins across 3NF tables)
-- ------------------------------------------------------------
-- Physical reality:
-- Must join orders -> order_items -> products -> product_category_translation.
-- Foreign keys are VARCHAR(32) UUID strings. Calendar year requires EXTRACT().
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COALESCE(t.product_category_name_english, 'uncategorized') AS category,
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INTEGER AS order_year,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM oltp.orders o
JOIN oltp.order_items oi 
    ON o.order_id = oi.order_id
JOIN oltp.products p 
    ON oi.product_id = p.product_id
LEFT JOIN oltp.product_category_translation t 
    ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 
    COALESCE(t.product_category_name_english, 'uncategorized'),
    EXTRACT(YEAR FROM o.order_purchase_timestamp)::INTEGER
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- 1.B Star Schema Architecture (2 Joins on Integer Surrogate Keys)
-- ------------------------------------------------------------
-- Physical reality:
-- Joins fact_sales -> dim_product -> dim_date.
-- Join conditions compare compact integer surrogate keys (BIGINT/INTEGER).
-- English category name and calendar year are pre-computed dimension attributes.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COALESCE(p.product_category_name_english, 'uncategorized') AS category,
    d.year_number AS order_year,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(f.item_price), 2) AS total_revenue,
    ROUND(SUM(f.freight_value), 2) AS total_freight,
    ROUND(AVG(f.item_price), 2) AS avg_item_price
FROM dw.fact_sales f
JOIN dw.dim_product p 
    ON f.product_key = p.product_key
JOIN dw.dim_date d 
    ON f.order_date_key = d.date_key
WHERE f.order_status = 'delivered'
GROUP BY 
    COALESCE(p.product_category_name_english, 'uncategorized'),
    d.year_number
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- 1.C One Big Table Architecture (Logical View: dw.vw_sales_obt)
-- ------------------------------------------------------------
-- Architectural Distinction:
-- dw.vw_sales_obt is a LOGICAL VIEW, not a pre-computed physical table.
-- Querying this view simplifies the SQL for business analysts and BI tools,
-- but PostgreSQL's query rewriter expands the view definition into the
-- underlying joins against fact_sales, dim_customer, dim_product, dim_seller,
-- and dim_date. Inspect the plan to observe how the optimizer prunes
-- unused tables (e.g. dim_customer, dim_seller).
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COALESCE(product_category_name_english, 'uncategorized') AS category,
    order_year,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(item_price), 2) AS total_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight,
    ROUND(AVG(item_price), 2) AS avg_item_price
FROM dw.vw_sales_obt
WHERE order_status = 'delivered'
GROUP BY 
    COALESCE(product_category_name_english, 'uncategorized'),
    order_year
ORDER BY total_revenue DESC;



-- ============================================================
-- BENCHMARK 2: INTERSTATE LOGISTICS & TRADE FLOW
-- Business Question: Trade flow between customer state and seller state
--                   for high-volume corridors (>= 50 shipments).
-- ============================================================

-- ------------------------------------------------------------
-- 2.A Normalized OLTP Architecture (4 Joins across 3NF tables)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_state,
    s.seller_state,
    COUNT(*) AS total_shipments,
    ROUND(SUM(oi.price), 2) AS total_merchandise_value,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_cost,
    ROUND(
        100.0 * SUM(oi.freight_value) 
        / NULLIF(SUM(oi.price + oi.freight_value), 0),
        2
    ) AS freight_cost_ratio_pct
FROM oltp.order_items oi
JOIN oltp.orders o 
    ON oi.order_id = o.order_id
JOIN oltp.customers c 
    ON o.customer_id = c.customer_id
JOIN oltp.sellers s 
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, s.seller_state
HAVING COUNT(*) >= 50
ORDER BY total_shipments DESC;


-- ------------------------------------------------------------
-- 2.B Star Schema Architecture (2 Joins on Surrogate Keys)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_state,
    s.seller_state,
    COUNT(*) AS total_shipments,
    ROUND(SUM(f.item_price), 2) AS total_merchandise_value,
    ROUND(SUM(f.freight_value), 2) AS total_freight_cost,
    ROUND(
        100.0 * SUM(f.freight_value) 
        / NULLIF(SUM(f.item_price + f.freight_value), 0),
        2
    ) AS freight_cost_ratio_pct
FROM dw.fact_sales f
JOIN dw.dim_customer c 
    ON f.customer_key = c.customer_key
JOIN dw.dim_seller s 
    ON f.seller_key = s.seller_key
WHERE f.order_status = 'delivered'
GROUP BY c.customer_state, s.seller_state
HAVING COUNT(*) >= 50
ORDER BY total_shipments DESC;


-- ------------------------------------------------------------
-- 2.C One Big Table Architecture (Logical View: dw.vw_sales_obt)
-- ------------------------------------------------------------
-- Uses pre-computed item_total_value defined in the view.
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_state,
    seller_state,
    COUNT(*) AS total_shipments,
    ROUND(SUM(item_price), 2) AS total_merchandise_value,
    ROUND(SUM(freight_value), 2) AS total_freight_cost,
    ROUND(
        100.0 * SUM(freight_value) 
        / NULLIF(SUM(item_total_value), 0),
        2
    ) AS freight_cost_ratio_pct
FROM dw.vw_sales_obt
WHERE order_status = 'delivered'
GROUP BY customer_state, seller_state
HAVING COUNT(*) >= 50
ORDER BY total_shipments DESC;



-- ============================================================
-- BENCHMARK 3: ON-TIME DELIVERY PERFORMANCE BY STATE
-- Business Question: Percentage of delivered orders arriving on or
--                   before estimated delivery date by customer state.
-- ============================================================

-- ------------------------------------------------------------
-- 3.A Normalized OLTP Architecture (On-the-fly CASE Logic)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(DISTINCT CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
        THEN o.order_id 
    END) AS on_time_orders,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
            THEN o.order_id 
        END) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS on_time_rate_pct
FROM oltp.orders o
JOIN oltp.customers c 
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY total_delivered_orders DESC;


-- ------------------------------------------------------------
-- 3.B Star Schema Architecture (Comparing Dimension Date Keys)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    c.customer_state,
    COUNT(DISTINCT f.order_id) AS total_delivered_orders,
    COUNT(DISTINCT CASE 
        WHEN f.delivery_date_key <= f.estimated_delivery_date_key 
        THEN f.order_id 
    END) AS on_time_orders,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN f.delivery_date_key <= f.estimated_delivery_date_key 
            THEN f.order_id 
        END) / NULLIF(COUNT(DISTINCT f.order_id), 0),
        2
    ) AS on_time_rate_pct
FROM dw.fact_sales f
JOIN dw.dim_customer c 
    ON f.customer_key = c.customer_key
WHERE f.order_status = 'delivered'
  AND f.delivery_date_key IS NOT NULL
  AND f.estimated_delivery_date_key IS NOT NULL
GROUP BY c.customer_state
ORDER BY total_delivered_orders DESC;


-- ------------------------------------------------------------
-- 3.C One Big Table Architecture (Using pre-computed delivery_status)
-- ------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    customer_state,
    COUNT(DISTINCT order_id) AS total_delivered_orders,
    COUNT(DISTINCT CASE 
        WHEN delivery_status = 'On Time or Early' 
        THEN order_id 
    END) AS on_time_orders,
    ROUND(
        100.0 * COUNT(DISTINCT CASE 
            WHEN delivery_status = 'On Time or Early' 
            THEN order_id 
        END) / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS on_time_rate_pct
FROM dw.vw_sales_obt
WHERE order_status = 'delivered'
  AND delivery_status IS NOT NULL
GROUP BY customer_state
ORDER BY total_delivered_orders DESC;



-- ============================================================
-- 4. ADVANCED: TESTING A PHYSICAL MATERIALIZED OBT
-- ============================================================
-- To test true "zero-join" execution time without view expansion,
-- create a physical materialized view. Compare query latency against
-- the Star Schema and record the storage footprint trade-off.

/*
-- Create the materialized view (physically stores flattened rows on disk)
CREATE MATERIALIZED VIEW IF NOT EXISTS dw.mv_sales_obt AS
SELECT * FROM dw.vw_sales_obt;

-- Create an index to support category/year queries
CREATE INDEX IF NOT EXISTS idx_mv_sales_obt_cat_year
    ON dw.mv_sales_obt (product_category_name_english, order_year);

ANALYZE dw.mv_sales_obt;

-- Benchmark: Zero-join physical table scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    COALESCE(product_category_name_english, 'uncategorized') AS category,
    order_year,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_items_sold,
    ROUND(SUM(item_price), 2) AS total_revenue,
    ROUND(SUM(freight_value), 2) AS total_freight
FROM dw.mv_sales_obt
WHERE order_status = 'delivered'
GROUP BY 
    COALESCE(product_category_name_english, 'uncategorized'),
    order_year
ORDER BY total_revenue DESC;
*/



-- ============================================================
-- 5. ARCHITECTURAL COMPARISON & SUMMARY DECISION MATRIX
-- ============================================================
/*
=============================================================================================================
ARCHITECTURAL MODEL | WHAT IT REPRESENTS             | JOIN CHARACTERISTICS     | TRADE-OFFS & USE CASES
=============================================================================================================
OLTP (3NF)          | Normalized transactional store | 4-6 joins on VARCHAR     | Maximum write efficiency,
                    | for ACID integrity.            | primary/foreign keys.    | zero data redundancy,
                    |                                | High CPU per query.      | poor analytical speed.
--------------------+--------------------------------+--------------------------+----------------------------
Star Schema (DW)    | Dimensional model with         | 1-3 star joins on compact| Balanced read speed,
                    | conformed dimensions & facts.  | BIGINT surrogate keys.   | flexible ad-hoc querying,
                    |                                | Fast Hash/Merge joins.   | minimal disk duplication.
--------------------+--------------------------------+--------------------------+----------------------------
OBT Logical View    | Presentation view abstracting  | View is expanded at      | Standardized business logic,
(dw.vw_sales_obt)   | star schema for BI analysts.   | runtime; optimizer joins | simple BI SQL, but query
                    |                                | only required tables.    | still incurs join costs.
--------------------+--------------------------------+--------------------------+----------------------------
Materialized OBT    | Physically persisted, pre-     | True zero runtime joins. | Fastest read latency,
(dw.mv_sales_obt)   | calculated wide flat table.    | Direct sequential or     | but highest disk usage and
                    |                                | index scan on flat rows. | requires periodic REFRESH.
=============================================================================================================

PORTFOLIO TAKEAWAY:
- A star schema represents the industry standard foundation for relational data warehouses,
  providing flexible slicing and dicing across conformed dimensions with integer keys.
- Logical OBT views eliminate repeated SQL boilerplate for BI tools and end users.
- Materialized OBTs should be reserved for high-traffic dashboards where sub-second latency
  outweighs data duplication and refresh pipeline overhead.
*/
