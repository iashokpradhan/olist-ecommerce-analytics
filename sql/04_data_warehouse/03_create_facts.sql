-- =========================================================
-- File: 03_create_facts.sql
-- Purpose: Create warehouse fact tables
-- =========================================================

-- =========================================================
-- 1. SALES FACT
-- Grain: One row per order item
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.fact_sales (
    sales_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_id VARCHAR(50) NOT NULL,
    order_item_id INTEGER NOT NULL,

    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    seller_key BIGINT NOT NULL,

    order_date_key INTEGER,
    approval_date_key INTEGER,
    delivery_date_key INTEGER,
    estimated_delivery_date_key INTEGER,

    order_status VARCHAR(30),

    item_price NUMERIC(12, 2) NOT NULL,
    freight_value NUMERIC(12, 2) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_fact_sales_order_item
        UNIQUE (order_id, order_item_id),

    CONSTRAINT fk_fact_sales_customer
        FOREIGN KEY (customer_key)
        REFERENCES dw.dim_customer(customer_key),

    CONSTRAINT fk_fact_sales_product
        FOREIGN KEY (product_key)
        REFERENCES dw.dim_product(product_key),

    CONSTRAINT fk_fact_sales_seller
        FOREIGN KEY (seller_key)
        REFERENCES dw.dim_seller(seller_key),

    CONSTRAINT fk_fact_sales_order_date
        FOREIGN KEY (order_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT fk_fact_sales_approval_date
        FOREIGN KEY (approval_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT fk_fact_sales_delivery_date
        FOREIGN KEY (delivery_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT fk_fact_sales_estimated_date
        FOREIGN KEY (estimated_delivery_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT chk_fact_sales_item_price
        CHECK (item_price >= 0),

    CONSTRAINT chk_fact_sales_freight
        CHECK (freight_value >= 0)
);

COMMENT ON TABLE dw.fact_sales IS
'Sales fact at order-item grain; product price and freight are stored separately';


-- =========================================================
-- 2. PAYMENT FACT
-- Grain: One row per source payment record
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.fact_payments (
    payment_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_id VARCHAR(50) NOT NULL,
    payment_sequential INTEGER NOT NULL,

    payment_date_key INTEGER,
    payment_type VARCHAR(50),
    payment_installments INTEGER,
    payment_value NUMERIC(12, 2) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_fact_payments_source_record
        UNIQUE (order_id, payment_sequential),

    CONSTRAINT fk_fact_payments_date
        FOREIGN KEY (payment_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT chk_fact_payments_value
        CHECK (payment_value >= 0)
);

COMMENT ON TABLE dw.fact_payments IS
'Payment fact at payment-record grain';


-- =========================================================
-- 3. REVIEW FACT
-- Grain: One row per source review record
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.fact_reviews (
    review_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    review_record_id BIGINT NOT NULL UNIQUE,
    review_id VARCHAR(100),
    order_id VARCHAR(50) NOT NULL,

    review_date_key INTEGER,
    review_answer_date_key INTEGER,

    review_score INTEGER,
    has_comment BOOLEAN,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_fact_reviews_review_date
        FOREIGN KEY (review_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT fk_fact_reviews_answer_date
        FOREIGN KEY (review_answer_date_key)
        REFERENCES dw.dim_date(date_key),

    CONSTRAINT chk_fact_reviews_score
        CHECK (
            review_score IS NULL
            OR review_score BETWEEN 1 AND 5
        )
);

COMMENT ON TABLE dw.fact_reviews IS
'Review fact at source review-record grain';


-- =========================================================
-- VERIFY FACT TABLES
-- =========================================================

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'dw'
  AND table_type = 'BASE TABLE'
  AND table_name LIKE 'fact_%'
ORDER BY table_name;