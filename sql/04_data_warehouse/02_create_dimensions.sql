-- =========================================================
-- File: 02_create_dimensions.sql
-- Purpose: Create warehouse dimension tables
-- =========================================================

-- =========================================================
-- 1. CUSTOMER DIMENSION
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.dim_customer (
    customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL UNIQUE,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dw.dim_customer IS
'Customer dimension containing descriptive customer attributes';


-- =========================================================
-- 2. PRODUCT DIMENSION
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.dim_product (
    product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL UNIQUE,
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(150),
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g NUMERIC(12, 2),
    product_length_cm NUMERIC(12, 2),
    product_height_cm NUMERIC(12, 2),
    product_width_cm NUMERIC(12, 2),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dw.dim_product IS
'Product dimension containing product and category attributes';


-- =========================================================
-- 3. SELLER DIMENSION
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.dim_seller (
    seller_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL UNIQUE,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dw.dim_seller IS
'Seller dimension containing descriptive seller attributes';


-- =========================================================
-- 4. DATE DIMENSION
-- =========================================================

CREATE TABLE IF NOT EXISTS dw.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(15) NOT NULL,
    week_of_year INTEGER NOT NULL,
    month_number INTEGER NOT NULL,
    month_name VARCHAR(15) NOT NULL,
    quarter_number INTEGER NOT NULL,
    year_number INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_dim_date_day
        CHECK (day_of_month BETWEEN 1 AND 31),

    CONSTRAINT chk_dim_date_month
        CHECK (month_number BETWEEN 1 AND 12),

    CONSTRAINT chk_dim_date_quarter
        CHECK (quarter_number BETWEEN 1 AND 4)
);

COMMENT ON TABLE dw.dim_date IS
'Calendar dimension for date-based business analysis';


-- =========================================================
-- VERIFY DIMENSION TABLES
-- =========================================================

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'dw'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
