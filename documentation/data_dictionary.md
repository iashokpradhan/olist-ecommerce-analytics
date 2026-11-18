# Olist Analytics Data Dictionary

This document provides a comprehensive technical reference for the physical schemas, tables, columns, data types, and grains across all layers of the Olist analytics platform.

---

## 1. OLTP Layer (`oltp` Schema)

The OLTP schema models the raw transactional entities normalized to Third Normal Form (3NF).

### 1.1 `oltp.customers`
- **Grain**: One row per unique customer order identity.
- **Description**: Stores customer identifiers and location details as recorded at purchase time.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `customer_id` | `VARCHAR(32)` | No | PK | Unique key per order-customer instance. |
| `customer_unique_id` | `VARCHAR(32)` | Yes | - | Persistent unique customer identifier across multiple orders. |
| `customer_zip_code_prefix` | `VARCHAR(5)` | Yes | - | First 5 digits of the Brazilian postal code (CEP). Stored as text to preserve leading zeros. |
| `customer_city` | `VARCHAR(100)` | Yes | - | City name of customer. |
| `customer_state` | `CHAR(2)` | Yes | - | Two-letter Brazilian state abbreviation (e.g., 'SP', 'RJ'). |

---

### 1.2 `oltp.sellers`
- **Grain**: One row per registered marketplace seller.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `seller_id` | `VARCHAR(32)` | No | PK | Unique identifier for each marketplace seller. |
| `seller_zip_code_prefix` | `VARCHAR(5)` | Yes | - | First 5 digits of the seller's Brazilian postal code (CEP). |
| `seller_city` | `VARCHAR(100)` | Yes | - | City name where seller operates. |
| `seller_state` | `CHAR(2)` | Yes | - | Two-letter Brazilian state abbreviation. |

---

### 1.3 `oltp.products`
- **Grain**: One row per product listed on the marketplace.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `product_id` | `VARCHAR(32)` | No | PK | Unique product identifier. |
| `product_category_name` | `VARCHAR(100)` | Yes | - | Portuguese category name. |
| `product_name_lenght` | `INTEGER` | Yes | - | Character count of product title (source spelling preserved). |
| `product_description_lenght` | `INTEGER` | Yes | - | Character count of product description. |
| `product_photos_qty` | `INTEGER` | Yes | - | Number of product photos published. |
| `product_weight_g` | `INTEGER` | Yes | - | Product weight in grams. |
| `product_length_cm` | `INTEGER` | Yes | - | Product package length in centimeters. |
| `product_height_cm` | `INTEGER` | Yes | - | Product package height in centimeters. |
| `product_width_cm` | `INTEGER` | Yes | - | Product package width in centimeters. |

---

### 1.4 `oltp.orders`
- **Grain**: One row per placed order.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `order_id` | `VARCHAR(32)` | No | PK | Unique order identifier. |
| `customer_id` | `VARCHAR(32)` | No | FK $\rightarrow$ `customers` | Foreign key linking to customer instance. |
| `order_status` | `VARCHAR(30)` | No | - | Status (e.g. `delivered`, `shipped`, `canceled`, `invoiced`). |
| `order_purchase_timestamp` | `TIMESTAMP` | No | - | Exact timestamp of order placement. |
| `order_approved_at` | `TIMESTAMP` | Yes | - | Timestamp when payment was authorized. |
| `order_delivered_carrier_date` | `TIMESTAMP` | Yes | - | Timestamp when order was handed to logistics carrier. |
| `order_delivered_customer_date` | `TIMESTAMP` | Yes | - | Actual customer delivery timestamp. |
| `order_estimated_delivery_date` | `TIMESTAMP` | Yes | - | Initial estimated arrival date provided at checkout. |

---

### 1.5 `oltp.order_items`
- **Grain**: One row per item within an order.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `order_id` | `VARCHAR(32)` | No | PK (composite) | Foreign key referencing order. |
| `order_item_id` | `INTEGER` | No | PK (composite) | Sequential line item number within the order (1, 2, 3...). |
| `product_id` | `VARCHAR(32)` | No | FK $\rightarrow$ `products` | Product purchased. |
| `seller_id` | `VARCHAR(32)` | No | FK $\rightarrow$ `sellers` | Seller fulfilling this item. |
| `shipping_limit_date` | `TIMESTAMP` | No | - | Seller shipping deadline to carrier. |
| `price` | `NUMERIC(10,2)` | No | $\ge 0$ | Selling item price in Brazilian Reais (BRL). |
| `freight_value` | `NUMERIC(10,2)` | No | $\ge 0$ | Shipping fee attributed to this line item. |

---

### 1.6 `oltp.order_payments`
- **Grain**: One row per payment transaction installment or method.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `order_id` | `VARCHAR(32)` | No | PK (composite) | Order identifier. |
| `payment_sequential` | `INTEGER` | No | PK (composite) | Payment sequence index per order. |
| `payment_type` | `VARCHAR(30)` | No | - | Payment instrument (e.g. `credit_card`, `boleto`, `voucher`, `debit_card`). |
| `payment_installments` | `INTEGER` | No | - | Number of installments selected. |
| `payment_value` | `NUMERIC(10,2)` | No | $\ge 0$ | Amount charged in Brazilian Reais (BRL). |

---

### 1.7 `oltp.order_reviews`
- **Grain**: One row per submitted customer review.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `review_record_id` | `BIGINT` | No | PK (Identity) | Generated synthetic PK (review_id repeats across orders). |
| `review_id` | `VARCHAR(32)` | No | - | Source review ID. |
| `order_id` | `VARCHAR(32)` | No | FK $\rightarrow$ `orders` | Order reviewed. |
| `review_score` | `INTEGER` | No | Check (1-5) | Customer satisfaction score between 1 and 5. |
| `review_comment_title` | `TEXT` | Yes | - | Customer feedback title. |
| `review_comment_message` | `TEXT` | Yes | - | Full review text commentary. |
| `review_creation_date` | `TIMESTAMP` | No | - | Date survey was sent to customer. |
| `review_answer_timestamp` | `TIMESTAMP` | No | - | Timestamp when customer submitted response. |

---

### 1.8 `oltp.geolocation`
- **Grain**: One row per zip code coordinate recording.

| Column | Type | Nullable | Constraint | Description |
|---|---|---|---|---|
| `geolocation_id` | `BIGINT` | No | PK (Identity) | Generated synthetic key. |
| `geolocation_zip_code_prefix`| `VARCHAR(5)`| No | Index | First 5 digits of CEP postal prefix. |
| `geolocation_lat` | `DOUBLE PRECISION`| No | - | Latitude coordinate. |
| `geolocation_lng` | `DOUBLE PRECISION`| No | - | Longitude coordinate. |
| `geolocation_city` | `VARCHAR(100)`| No | - | City name. |
| `geolocation_state` | `CHAR(2)` | No | - | State abbreviation. |

---

## 2. Dimensional Data Warehouse Layer (`dw` Schema)

The analytical data warehouse follows Kimball star-schema principles with synthetic surrogate keys and clean conformed dimensions.

### 2.1 `dw.dim_customer`
- **Grain**: One row per unique customer record.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `customer_key` | `BIGINT` | PK (Surrogate) | Auto-incrementing integer surrogate key. |
| `customer_id` | `VARCHAR(50)` | Natural Key (Unique) | Source customer transaction ID. |
| `customer_unique_id` | `VARCHAR(50)` | Natural Key | Persistent customer identifier. |
| `customer_zip_code_prefix`| `VARCHAR(5)` | Attribute | 5-digit postal code (preserves leading zeros). |
| `customer_city` | `VARCHAR(100)`| Attribute | Customer city name. |
| `customer_state` | `CHAR(2)` | Attribute | Two-letter state code. |
| `created_at` | `TIMESTAMP` | Metadata | DW record insertion timestamp. |

---

### 2.2 `dw.dim_product`
- **Grain**: One row per catalog product.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `product_key` | `BIGINT` | PK (Surrogate) | Synthetic integer surrogate key. |
| `product_id` | `VARCHAR(50)` | Natural Key (Unique) | Source product UUID. |
| `product_category_name` | `VARCHAR(100)`| Attribute | Original Portuguese category name. |
| `product_category_name_english`| `VARCHAR(150)`| Attribute | Translated English category name. |
| `product_name_length` | `INTEGER` | Attribute | Standardized column name (corrected spelling). |
| `product_description_length` | `INTEGER` | Attribute | Description length. |
| `product_photos_qty` | `INTEGER` | Attribute | Photo count. |
| `product_weight_g` | `NUMERIC(12,2)` | Attribute | Weight in grams. |
| `product_length_cm` | `NUMERIC(12,2)` | Attribute | Length in cm. |
| `product_height_cm` | `NUMERIC(12,2)` | Attribute | Height in cm. |
| `product_width_cm` | `NUMERIC(12,2)` | Attribute | Width in cm. |
| `created_at` | `TIMESTAMP` | Metadata | DW record insertion timestamp. |

---

### 2.3 `dw.dim_seller`
- **Grain**: One row per seller.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `seller_key` | `BIGINT` | PK (Surrogate) | Synthetic integer surrogate key. |
| `seller_id` | `VARCHAR(50)` | Natural Key (Unique) | Source seller UUID. |
| `seller_zip_code_prefix`| `VARCHAR(5)` | Attribute | 5-digit postal code. |
| `seller_city` | `VARCHAR(100)`| Attribute | Seller city. |
| `seller_state` | `CHAR(2)` | Attribute | Two-letter state code. |
| `created_at` | `TIMESTAMP` | Metadata | DW record insertion timestamp. |

---

### 2.4 `dw.dim_date`
- **Grain**: One row per calendar day.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `date_key` | `INTEGER` | PK (Smart Key) | Date key formatted as `YYYYMMDD` (e.g. `20180515`). |
| `full_date` | `DATE` | Unique | Calendar date (`YYYY-MM-DD`). |
| `day_of_month` | `INTEGER` | Attribute | Day number (1-31). |
| `day_of_week` | `INTEGER` | Attribute | ISO day of week (1=Monday, 7=Sunday). |
| `day_name` | `VARCHAR(15)` | Attribute | Full weekday name ('Monday', 'Tuesday'). |
| `week_of_year` | `INTEGER` | Attribute | ISO calendar week number (1-53). |
| `month_number` | `INTEGER` | Attribute | Month number (1-12). |
| `month_name` | `VARCHAR(15)` | Attribute | Month name ('January', 'February'). |
| `quarter_number` | `INTEGER` | Attribute | Fiscal/calendar quarter (1-4). |
| `year_number` | `INTEGER` | Attribute | Calendar year (e.g. 2016, 2017, 2018). |
| `is_weekend` | `BOOLEAN` | Attribute | True if Saturday or Sunday. |

---

### 2.5 `dw.fact_sales`
- **Grain**: One row per ordered item.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `sales_key` | `BIGINT` | PK (Surrogate) | Fact record identity key. |
| `order_id` | `VARCHAR(50)` | Degenerate Dimension | Order identifier for order-level aggregations. |
| `order_item_id` | `INTEGER` | Degenerate Dimension | Line item sequential index. |
| `customer_key` | `BIGINT` | FK $\rightarrow$ `dim_customer` | Customer dimension foreign key. |
| `product_key` | `BIGINT` | FK $\rightarrow$ `dim_product` | Product dimension foreign key. |
| `seller_key` | `BIGINT` | FK $\rightarrow$ `dim_seller` | Seller dimension foreign key. |
| `order_date_key` | `INTEGER` | FK $\rightarrow$ `dim_date` | Purchase date smart key (`YYYYMMDD`). |
| `approval_date_key` | `INTEGER` | FK $\rightarrow$ `dim_date` | Payment approval date smart key. |
| `delivery_date_key` | `INTEGER` | FK $\rightarrow$ `dim_date` | Actual delivery date smart key. |
| `estimated_delivery_date_key`| `INTEGER` | FK $\rightarrow$ `dim_date`| Estimated delivery date smart key. |
| `order_status` | `VARCHAR(30)` | Attribute | Status flag at time of load. |
| `item_price` | `NUMERIC(12,2)` | Measure | Item selling price (BRL). |
| `freight_value` | `NUMERIC(12,2)` | Measure | Freight cost for this item (BRL). |

---

### 2.6 `dw.fact_payments`
- **Grain**: One row per payment transaction record.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `payment_key` | `BIGINT` | PK (Surrogate) | Payment record identity key. |
| `order_id` | `VARCHAR(50)` | Degenerate Dimension | Order identifier. |
| `payment_sequential` | `INTEGER` | Degenerate Dimension | Installment sequence number. |
| `payment_date_key` | `INTEGER` | FK $\rightarrow$ `dim_date` | Order date smart key. |
| `payment_type` | `VARCHAR(50)` | Attribute | Payment method ('credit_card', 'boleto', etc.). |
| `payment_installments` | `INTEGER` | Measure | Number of installments. |
| `payment_value` | `NUMERIC(12,2)` | Measure | Total payment amount (BRL). |

---

### 2.7 `dw.fact_reviews`
- **Grain**: One row per customer review submission.

| Column | Type | Key Type | Description |
|---|---|---|---|
| `review_key` | `BIGINT` | PK (Surrogate) | Review identity key. |
| `review_id` | `VARCHAR(50)` | Degenerate Dimension | Review source ID. |
| `order_id` | `VARCHAR(50)` | Degenerate Dimension | Order identifier. |
| `review_date_key` | `INTEGER` | FK $\rightarrow$ `dim_date` | Review submission date smart key. |
| `review_score` | `INTEGER` | Measure | Star rating (1 to 5). |
| `review_comment_title` | `TEXT` | Attribute | Feedback headline. |
| `review_comment_message`| `TEXT` | Attribute | Feedback body commentary. |
| `review_creation_date` | `TIMESTAMP` | Attribute | Date survey was sent. |
| `review_answer_timestamp`| `TIMESTAMP` | Attribute | Date response was submitted. |

---

## 3. Wide Reporting Layer (`dw.vw_sales_obt`)

A logical presentation view denormalizing the Star Schema into **One Big Table (OBT)** for BI tools and ad-hoc SQL querying.

- **Underlying Tables Joined**: `dw.fact_sales` $\Join$ `dw.dim_customer` $\Join$ `dw.dim_product` $\Join$ `dw.dim_seller` $\Join$ `dw.dim_date` (role-playing aliases `od`, `dd`, `ed`).
- **Pre-computed Business Measures**:
  - `item_total_value = item_price + freight_value`
  - `delivery_status`:
    - `'On Time or Early'` when `delivery_date <= estimated_delivery_date`
    - `'Late'` when `delivery_date > estimated_delivery_date`
    - `NULL` when delivery dates are pending or missing.
