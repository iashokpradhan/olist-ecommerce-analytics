-- =====================================================
-- OLIST PROJECT: OLTP PHYSICAL DATABASE
-- PostgreSQL 18
-- Schema: oltp
-- =====================================================

-- 1. CUSTOMERS
CREATE TABLE oltp.customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix VARCHAR(5),
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- 2. SELLERS
CREATE TABLE oltp.sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- 3. PRODUCTS
CREATE TABLE oltp.products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

-- 4. PRODUCT CATEGORY TRANSLATION
CREATE TABLE oltp.product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);

-- 5. ORDERS
CREATE TABLE oltp.orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    CONSTRAINT fk_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES oltp.customers(customer_id)
);

-- 6. ORDER ITEMS
CREATE TABLE oltp.order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date TIMESTAMP NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    freight_value NUMERIC(10,2) NOT NULL,

    CONSTRAINT pk_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_order_items_orders
        FOREIGN KEY (order_id)
        REFERENCES oltp.orders(order_id),

    CONSTRAINT fk_order_items_products
        FOREIGN KEY (product_id)
        REFERENCES oltp.products(product_id),

    CONSTRAINT fk_order_items_sellers
        FOREIGN KEY (seller_id)
        REFERENCES oltp.sellers(seller_id),

    CONSTRAINT chk_order_items_price
        CHECK (price >= 0),

    CONSTRAINT chk_order_items_freight
        CHECK (freight_value >= 0)
);

-- 7. ORDER PAYMENTS
CREATE TABLE oltp.order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30) NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value NUMERIC(10,2) NOT NULL,

    CONSTRAINT pk_order_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_order_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES oltp.orders(order_id),

    CONSTRAINT chk_payment_value
        CHECK (payment_value >= 0)
);

-- 8. ORDER REVIEWS
-- review_id is NOT unique in the source data.
-- Use a generated key to identify each review record.

CREATE TABLE oltp.order_reviews (
    review_record_id BIGINT
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32) NOT NULL,
    review_score INTEGER NOT NULL,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP NOT NULL,
    review_answer_timestamp TIMESTAMP NOT NULL,

    CONSTRAINT fk_order_reviews_orders
        FOREIGN KEY (order_id)
        REFERENCES oltp.orders(order_id),

    CONSTRAINT chk_review_score
        CHECK (review_score BETWEEN 1 AND 5)
);

-- 9. GEOLOCATION
-- ZIP prefixes repeat, so use a generated primary key.

CREATE TABLE oltp.geolocation (
    geolocation_id BIGINT
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    geolocation_zip_code_prefix VARCHAR(5) NOT NULL,
    geolocation_lat DOUBLE PRECISION NOT NULL,
    geolocation_lng DOUBLE PRECISION NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state CHAR(2) NOT NULL
);

-- =====================================================
-- INDEXES FOR COMMON JOINS AND LOOKUPS
-- =====================================================

CREATE INDEX idx_orders_customer_id
    ON oltp.orders(customer_id);

CREATE INDEX idx_order_items_product_id
    ON oltp.order_items(product_id);

CREATE INDEX idx_order_items_seller_id
    ON oltp.order_items(seller_id);

CREATE INDEX idx_order_payments_order_id
    ON oltp.order_payments(order_id);

CREATE INDEX idx_order_reviews_order_id
    ON oltp.order_reviews(order_id);

CREATE INDEX idx_geolocation_zip_code
    ON oltp.geolocation(geolocation_zip_code_prefix);