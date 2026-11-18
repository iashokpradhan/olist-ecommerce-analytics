-- =========================================================
-- File: 05_dw_indexes.sql
-- Purpose: Add selected indexes to warehouse tables
-- =========================================================

-- =========================================================
-- SALES FACT INDEXES
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_fact_sales_customer
    ON dw.fact_sales (customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_sales_product
    ON dw.fact_sales (product_key);

CREATE INDEX IF NOT EXISTS idx_fact_sales_seller
    ON dw.fact_sales (seller_key);

CREATE INDEX IF NOT EXISTS idx_fact_sales_order_date
    ON dw.fact_sales (order_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_sales_status
    ON dw.fact_sales (order_status);


-- =========================================================
-- PAYMENT FACT INDEXES
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_fact_payments_payment_type
    ON dw.fact_payments (payment_type);


-- =========================================================
-- REVIEW FACT INDEXES
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_fact_reviews_score
    ON dw.fact_reviews (review_score);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_order
    ON dw.fact_reviews (order_id);


-- =========================================================
-- DIMENSION INDEXES
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_dim_customer_state
    ON dw.dim_customer (customer_state);

CREATE INDEX IF NOT EXISTS idx_dim_product_category
    ON dw.dim_product (product_category_name_english);

CREATE INDEX IF NOT EXISTS idx_dim_seller_state
    ON dw.dim_seller (seller_state);


-- =========================================================
-- VERIFY INDEXES
-- =========================================================

SELECT
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'dw'
ORDER BY
    tablename,
    indexname;