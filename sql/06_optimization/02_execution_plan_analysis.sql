-- ============================================================
-- Module 6: Query Optimization
-- File: 02_execution_plan_analysis.sql
-- Purpose: In-depth execution plan diagnostics, operator analysis,
--          buffer profiling, and memory tuning with EXPLAIN
-- ============================================================


-- ============================================================
-- 1. EXPLAIN OUTPUT REFERENCE GUIDE
-- ============================================================
/*
  EXPLAIN (ANALYZE, BUFFERS, VERBOSE, TIMING, COSTS)

  Understanding Key Metrics:
  - cost=A..B:
      A = Startup cost (cost units estimated before returning the first row).
      B = Total cost (estimated total units to complete the node).
      These are relative arbitrary units based on seq_page_cost and cpu costs.
  - actual time=X..Y:
      X = Actual milliseconds elapsed until the first row was produced.
      Y = Actual milliseconds elapsed until the node finished producing rows.
  - rows=N (estimated) vs rows=M (actual):
      Comparing estimated vs actual rows identifies estimation errors,
      which often point to stale statistics or complex correlated filters.
  - loops=L:
      Number of times this plan node was executed (e.g. in Nested Loops).
      Total actual time for that node = Y * L.
  - Buffers:
      shared hit:        Pages read from PostgreSQL's shared buffer pool (RAM).
      shared read:       Pages read from the operating system cache or disk.
      shared dirtied:    Pages modified by the query in shared memory.
      temp read/written: Pages spilled to temporary disk files because work_mem
                         was insufficient for sorting or hash table construction.
*/


-- ============================================================
-- 2. SCAN OPERATORS IN POSTGRESQL
-- ============================================================
-- PostgreSQL's choice of scan operator is not determined by a simple
-- percentage rule. The Cost-Based Optimizer (CBO) balances several factors:
--   1. Estimated row count and table size.
--   2. Physical layout & correlation (pg_stats.correlation with disk order).
--   3. Relative cost of random I/O vs sequential I/O (random_page_cost vs seq_page_cost).
--   4. Memory cache availability (shared_buffers and effective_cache_size).

-- ------------------------------------------------------------
-- 2.1 Sequential Scan (Seq Scan)
-- ------------------------------------------------------------
-- When a query reads a large portion of a table, reading pages sequentially
-- from start to finish is often faster than performing thousands of random
-- B-Tree traversals and pointer dereferences.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    sales_key, 
    order_id, 
    item_price 
FROM dw.fact_sales
WHERE order_status = 'delivered';


-- ------------------------------------------------------------
-- 2.2 Index Scan
-- ------------------------------------------------------------
-- When a filter matches very few rows, traversing the B-Tree index to locate
-- the specific page pointers (TIDs) and fetching only those heap pages
-- minimizes both I/O and CPU time.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    sales_key, 
    order_id, 
    item_price 
FROM dw.fact_sales
WHERE order_id = '00010242788daf3c2f8e5da67e8e37f1';


-- ------------------------------------------------------------
-- 2.3 Bitmap Index Scan + Bitmap Heap Scan
-- ------------------------------------------------------------
-- When selectivity is intermediate or when multiple indexes are combined:
--   - Bitmap Index Scan: Builds a memory bitmap of target physical heap pages.
--   - Bitmap Heap Scan: Reads heap pages in physical sequential order,
--     reducing random disk head movement.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    sales_key, 
    order_id, 
    customer_key, 
    item_price 
FROM dw.fact_sales
WHERE order_status = 'canceled';


-- ------------------------------------------------------------
-- 2.4 Index-Only Scan
-- ------------------------------------------------------------
-- Satisfies the query entirely from index leaf pages without accessing the heap,
-- provided all requested columns are in the index and the table's Visibility
-- Map indicates that referenced pages contain only tuples visible to all transactions.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    order_date_key, 
    COUNT(*) 
FROM dw.fact_sales
WHERE order_date_key BETWEEN 20180101 AND 20180331
GROUP BY order_date_key;


-- ============================================================
-- 3. JOIN OPERATORS IN POSTGRESQL
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Nested Loop
-- ------------------------------------------------------------
-- For each row found in the outer relation, the engine probes the inner relation.
-- Typically chosen when the outer relation returns very few rows and the inner
-- relation has an efficient index on the join key.
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    c.customer_id, 
    c.customer_city, 
    f.order_id, 
    f.item_price
FROM dw.dim_customer c
JOIN dw.fact_sales f ON c.customer_key = f.customer_key
WHERE c.customer_id = '06b8999e2fba1a1fbc88172c00ba8bc7';


-- ------------------------------------------------------------
-- 3.2 Hash Join
-- ------------------------------------------------------------
-- The engine builds an in-memory hash table from the smaller relation, then
-- scans the larger relation and probes the hash table.
-- Typically chosen for joining medium-to-large un-indexed or unsorted sets.
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    s.seller_state, 
    COUNT(*) AS total_sales,
    ROUND(SUM(f.item_price), 2) AS total_revenue
FROM dw.fact_sales f
JOIN dw.dim_seller s ON f.seller_key = s.seller_key
GROUP BY s.seller_state;


-- ------------------------------------------------------------
-- 3.3 Merge Join
-- ------------------------------------------------------------
-- Both input relations must be sorted on the join key (either via an index
-- or an explicit sort node). The engine walks both sorted inputs in lockstep.
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    f.order_date_key, 
    d.day_name, 
    SUM(f.item_price) AS daily_revenue
FROM dw.fact_sales f
JOIN dw.dim_date d ON f.order_date_key = d.date_key
WHERE f.order_date_key BETWEEN 20180101 AND 20180228
GROUP BY f.order_date_key, d.day_name
ORDER BY f.order_date_key;


-- ============================================================
-- 4. MEMORY TUNING & DISK SPILLS (work_mem)
-- ============================================================
-- Operations like ORDER BY, DISTINCT, and Hash Joins allocate memory
-- up to work_mem per operation (not per connection).
-- When an operation exceeds work_mem, PostgreSQL spills data to disk files.
--
-- Testing Note:
-- SET LOCAL requires an explicit transaction block (BEGIN ... ROLLBACK)
-- to be effective in client environments like pgAdmin with autocommit.
-- The values 64kB and 64MB below are diagnostic test settings to observe
-- plan differences, not production server sizing recommendations.

-- ------------------------------------------------------------
-- 4.1 Simulating Constrained Memory (External Merge Sort / Disk Spill)
-- ------------------------------------------------------------
BEGIN;

SET LOCAL work_mem = '64kB';

-- Inspect output for: "Sort Method: external merge  Disk: ...kB"
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    customer_key, 
    product_key, 
    item_price, 
    freight_value
FROM dw.fact_sales
ORDER BY item_price DESC, customer_key, product_key;

ROLLBACK;


-- ------------------------------------------------------------
-- 4.2 Allocating Sufficient In-Memory Allocation
-- ------------------------------------------------------------
BEGIN;

SET LOCAL work_mem = '64MB';

-- Inspect output for: "Sort Method: quicksort  Memory: ...kB"
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    customer_key, 
    product_key, 
    item_price, 
    freight_value
FROM dw.fact_sales
ORDER BY item_price DESC, customer_key, product_key;

ROLLBACK;


-- ============================================================
-- 5. CARDINALITY ESTIMATION & PLANNER STATISTICS
-- ============================================================
-- PostgreSQL relies on the pg_statistic catalog (viewable via pg_stats)
-- to estimate row counts. When data distributions change, running ANALYZE
-- updates these statistics.

-- ------------------------------------------------------------
-- 5.1 Inspecting Column Statistics
-- ------------------------------------------------------------
SELECT 
    schemaname, 
    tablename, 
    attname, 
    null_frac, 
    n_distinct, 
    most_common_vals, 
    most_common_freqs, 
    correlation
FROM pg_stats
WHERE schemaname = 'dw' 
  AND tablename = 'fact_sales'
ORDER BY attname;

-- ------------------------------------------------------------
-- 5.2 Updating Table Statistics
-- ------------------------------------------------------------
ANALYZE dw.fact_sales;
ANALYZE dw.dim_customer;
ANALYZE dw.dim_product;
ANALYZE dw.dim_seller;
ANALYZE dw.dim_date;

-- ------------------------------------------------------------
-- 5.3 Modifying Statistics Target for Complex Columns
-- ------------------------------------------------------------
-- By default, PostgreSQL samples up to 100 histogram buckets.
-- If a column with high cardinality or skewed data has significant
-- estimation errors (e.g. estimated rows differ by orders of magnitude from actual),
-- increasing the statistics target to 500 provides finer-grained histograms.
--
-- CAUTION: This is a persistent DDL change to the database catalog.
-- Higher targets increase ANALYZE run time and statistics memory usage.

-- Step 1: Identify estimation accuracy prior to adjustment
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) 
FROM dw.fact_sales 
WHERE order_status = 'shipped';

-- Step 2: (Optional) Alter target and re-analyze if estimation error is verified
/*
ALTER TABLE dw.fact_sales 
    ALTER COLUMN order_status SET STATISTICS 500;

ANALYZE dw.fact_sales (order_status);

-- Step 3: Verify whether the estimated row count improved
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*) 
FROM dw.fact_sales 
WHERE order_status = 'shipped';
*/
