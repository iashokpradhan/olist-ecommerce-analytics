# Architecture & Entity-Relationship Diagrams

This document illustrates the data architecture, entity-relationship diagrams (ERDs), and dimensional modeling structures implemented in the Olist E-Commerce Data Warehouse.

---

## 1. End-to-End Data Pipeline Architecture

```mermaid
flowchart TD
    subgraph S1["Raw Ingestion"]
        CSV["Kaggle Raw CSVs (9 Datasets)"]
    end

    subgraph S2["OLTP Layer (3NF Schema)"]
        O_CUST["oltp.customers"]
        O_ORD["oltp.orders"]
        O_ITEM["oltp.order_items"]
        O_PROD["oltp.products"]
        O_SELL["oltp.sellers"]
        O_PAY["oltp.order_payments"]
        O_REV["oltp.order_reviews"]
        O_GEO["oltp.geolocation"]
    end

    subgraph S3["Staging Layer (staging Schema)"]
        STG["staging.stg_* (ELT Buffering & Cleansing)"]
    end

    subgraph S4["Dimensional Warehouse (dw Schema)"]
        DIM_C["dw.dim_customer"]
        DIM_P["dw.dim_product"]
        DIM_S["dw.dim_seller"]
        DIM_D["dw.dim_date"]
        
        FACT_S["dw.fact_sales (Order-Item Grain)"]
        FACT_P["dw.fact_payments (Payment Grain)"]
        FACT_R["dw.fact_reviews (Review Grain)"]
    end

    subgraph S5["Presentation Layer (OBT)"]
        OBT["dw.vw_sales_obt (One Big Table View)"]
    end

    subgraph S6["Analytics & BI"]
        PBI["Power BI / Tableau Dashboards"]
        SQL_AN["Ad-Hoc SQL & Executive Reports"]
    end

    CSV --> O_CUST & O_ORD & O_ITEM & O_PROD & O_SELL & O_PAY & O_REV & O_GEO
    O_CUST & O_ORD & O_ITEM & O_PROD & O_SELL & O_PAY & O_REV --> STG
    
    STG --> DIM_C & DIM_P & DIM_S & DIM_D
    STG --> FACT_S & FACT_P & FACT_R

    DIM_C & DIM_P & DIM_S & DIM_D --> FACT_S
    DIM_D --> FACT_P & FACT_R

    FACT_S & DIM_C & DIM_P & DIM_S & DIM_D --> OBT
    OBT --> PBI & SQL_AN
```

---

## 2. OLTP Entity-Relationship Diagram (3NF Normalized)

The transactional layer enforces relational integrity through primary and foreign keys:

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    ORDERS ||--|{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : "included in"
    SELLERS ||--o{ ORDER_ITEMS : fulfills
    ORDERS ||--o{ ORDER_PAYMENTS : "paid via"
    ORDERS ||--o{ ORDER_REVIEW : receives
    PRODUCT_CATEGORY_TRANSLATION ||--o{ PRODUCTS : translates

    CUSTOMERS {
        varchar customer_id PK
        varchar customer_unique_id
        varchar customer_zip_code_prefix
        varchar customer_city
        char customer_state
    }

    ORDERS {
        varchar order_id PK
        varchar customer_id FK
        varchar order_status
        timestamp order_purchase_timestamp
        timestamp order_approved_at
        timestamp order_delivered_carrier_date
        timestamp order_delivered_customer_date
        timestamp order_estimated_delivery_date
    }

    ORDER_ITEMS {
        varchar order_id PK, FK
        integer order_item_id PK
        varchar product_id FK
        varchar seller_id FK
        timestamp shipping_limit_date
        numeric price
        numeric freight_value
    }

    PRODUCTS {
        varchar product_id PK
        varchar product_category_name FK
        integer product_weight_g
        integer product_length_cm
        integer product_height_cm
        integer product_width_cm
    }

    SELLERS {
        varchar seller_id PK
        varchar seller_zip_code_prefix
        varchar seller_city
        char seller_state
    }

    ORDER_PAYMENTS {
        varchar order_id PK, FK
        integer payment_sequential PK
        varchar payment_type
        integer payment_installments
        numeric payment_value
    }

    ORDER_REVIEW {
        bigint review_record_id PK
        varchar review_id
        varchar order_id FK
        integer review_score
        timestamp review_creation_date
        timestamp review_answer_timestamp
    }

    PRODUCT_CATEGORY_TRANSLATION {
        varchar product_category_name PK
        varchar product_category_name_english
    }
```

---

## 3. Dimensional Data Warehouse Model (Kimball Star Schema)

The analytical data warehouse optimizes queries using synthetic integer surrogate keys and role-playing date dimensions:

```mermaid
erDiagram
    DIM_CUSTOMER ||--o{ FACT_SALES : "buys"
    DIM_PRODUCT ||--o{ FACT_SALES : "purchased"
    DIM_SELLER ||--o{ FACT_SALES : "fulfills"
    DIM_DATE ||--o{ FACT_SALES : "ordered on (role-playing)"
    DIM_DATE ||--o{ FACT_SALES : "approved on (role-playing)"
    DIM_DATE ||--o{ FACT_SALES : "delivered on (role-playing)"
    DIM_DATE ||--o{ FACT_SALES : "estimated on (role-playing)"
    DIM_DATE ||--o{ FACT_PAYMENTS : "paid on"
    DIM_DATE ||--o{ FACT_REVIEWS : "reviewed on"

    FACT_SALES {
        bigint sales_key PK
        varchar order_id "Degenerate Dim"
        integer order_item_id "Degenerate Dim"
        bigint customer_key FK
        bigint product_key FK
        bigint seller_key FK
        integer order_date_key FK
        integer approval_date_key FK
        integer delivery_date_key FK
        integer estimated_delivery_date_key FK
        varchar order_status
        numeric item_price
        numeric freight_value
    }

    DIM_CUSTOMER {
        bigint customer_key PK
        varchar customer_id "Natural Key"
        varchar customer_unique_id
        varchar customer_zip_code_prefix
        varchar customer_city
        char customer_state
    }

    DIM_PRODUCT {
        bigint product_key PK
        varchar product_id "Natural Key"
        varchar product_category_name
        varchar product_category_name_english
        numeric product_weight_g
        numeric product_length_cm
        numeric product_height_cm
        numeric product_width_cm
    }

    DIM_SELLER {
        bigint seller_key PK
        varchar seller_id "Natural Key"
        varchar seller_zip_code_prefix
        varchar seller_city
        char seller_state
    }

    DIM_DATE {
        integer date_key PK
        date full_date
        integer day_of_month
        integer day_of_week
        varchar day_name
        integer week_of_year
        integer month_number
        varchar month_name
        integer quarter_number
        integer year_number
        boolean is_weekend
    }

    FACT_PAYMENTS {
        bigint payment_key PK
        varchar order_id "Degenerate Dim"
        integer payment_sequential "Degenerate Dim"
        integer payment_date_key FK
        varchar payment_type
        integer payment_installments
        numeric payment_value
    }

    FACT_REVIEWS {
        bigint review_key PK
        varchar review_id "Degenerate Dim"
        varchar order_id "Degenerate Dim"
        integer review_date_key FK
        integer review_score
        text review_comment_title
        text review_comment_message
    }
```

---

## 4. Key Modeling Techniques

1. **Surrogate Keys**: `BIGINT GENERATED ALWAYS AS IDENTITY` on all dimension tables isolate the analytical layer from changes in source UUID formats and allow $O(1)$ integer comparisons during joins.
2. **Role-Playing Dimensions**: `dw.dim_date` is joined multiple times to `dw.fact_sales` across different date keys (`order_date_key`, `delivery_date_key`, `estimated_delivery_date_key`), avoiding the creation of duplicate date tables.
3. **Degenerate Dimensions**: `order_id` and `order_item_id` are maintained directly in the fact tables without an extra order dimension table, providing natural groupings for order-level metric calculations.
4. **Zero-Loss Postal Code Integrity**: All zip prefix columns are typed as `VARCHAR(5)` to prevent leading zero truncation (e.g. São Paulo prefixes `01000`–`09999`).
