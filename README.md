# Olist E-Commerce Data Warehouse & Analytics Platform

An enterprise-grade, end-to-end data warehousing and business analytics platform built on **PostgreSQL**, modeling and analyzing over 100,000 Brazilian e-commerce orders from the Olist marketplace.

---

## 🏛️ Architecture Overview

The platform implements a multi-layer data architecture that transforms normalized transactional data into an optimized analytical star schema and wide reporting views:

```
[ Raw CSV Datasets ]
         │
         ▼
[ OLTP Schema: oltp ] ── (3NF Transactional Store)
         │
         ▼
[ Staging Schema: staging ] ── (ELT Buffer & Type Alignment)
         │
         ▼
[ DW Star Schema: dw ] ── (Conformed Dimensions & Grain-Specific Facts)
         │
         ▼
[ Wide Reporting: dw.vw_sales_obt ] ── (One Big Table for BI & Tableau/Power BI)
```

### Layer Responsibilities
1. **OLTP (`oltp`)**: Normalized source tables enforcing referential integrity, primary keys, check constraints, and B-Tree indexes on join keys.
2. **Staging (`staging`)**: Transient schema matching source schemas for zero-loss ingestion and batch verification before warehouse loading.
3. **Data Warehouse (`dw`)**: Dimensional model designed according to Kimball methodologies:
   - **Dimension Tables**: [`dw.dim_customer`](file:///sql/04_data_warehouse/02_create_dimensions.sql#L10-L19), [`dw.dim_product`](file:///sql/04_data_warehouse/02_create_dimensions.sql#L29-L43), [`dw.dim_seller`](file:///sql/04_data_warehouse/02_create_dimensions.sql#L53-L61), [`dw.dim_date`](file:///sql/04_data_warehouse/02_create_dimensions.sql#L71-L94).
   - **Fact Tables**: [`dw.fact_sales`](file:///sql/04_data_warehouse/03_create_facts.sql#L11-L69) (order-item grain), [`dw.fact_payments`](file:///sql/04_data_warehouse/03_create_facts.sql#L80-L108) (payment record grain), [`dw.fact_reviews`](file:///sql/04_data_warehouse/03_create_facts.sql#L119-L149) (review submission grain).
   - **OBT View**: [`dw.vw_sales_obt`](file:///sql/04_data_warehouse/04_create_obt.sql#L8-L82) (One Big Table pre-joining dimensions and facts for performant BI queries).

---

## 📂 Project Structure

```
olist-ecommerce-analytics/
├── data/
│   ├── README.md                  # Dataset origin, file schema & ingestion guide
│   └── raw/                       # Source CSV extracts & compressed archive
├── documentation/                 # Technical specifications & reports
│   ├── architecture_and_er_diagrams.md # Mermaid ERDs for OLTP & Star Schema
│   ├── business_insights_report.md     # Executive summary & commercial insights
│   └── data_dictionary.md         # Full column-level technical reference
├── power_bi/                      # Business Intelligence layer
│   └── README.md                  # DAX measure library & dashboard architecture
├── sql/
│   ├── 01_database_setup/         # OLTP table DDL, constraints, and validation
│   │   ├── 01_create_tables_&_indexes.sql
│   │   ├── 02_add_constraints.sql
│   │   └── 03_verify_row_counts.sql
│   ├── 02_data_quality/           # Data profiling, PK/FK validation & anomaly checks
│   │   ├── 01_row_count_validation.sql
│   │   ├── 02_primary_key_validation.sql
│   │   ├── 03_foreign_key_validation.sql
│   │   ├── 04_missing_values_validation.sql
│   │   ├── 05_numeric_validation.sql
│   │   ├── 06_date_validation.sql
│   │   ├── 07_duplicate_and_grain_validation.sql
│   │   └── 08_data_quality_summary.sql
│   ├── 03_business_analysis/      # Advanced SQL analytical queries (RFM, cohort, delivery)
│   ├── 04_data_warehouse/         # Star schema DDL, facts, indexes & views
│   │   ├── 01_create_dw_schema.sql
│   │   ├── 02_create_dimensions.sql
│   │   ├── 03_create_facts.sql
│   │   ├── 04_create_obt.sql
│   │   ├── 05_dw_indexes.sql
│   │   └── 06_remediate_dimension_types.sql
│   ├── 05_etl_pipeline/           # Staging layer and ELT data loading
│   │   ├── 01_staging_tables.sql
│   │   ├── 02_transform_data.sql
│   │   ├── 03_load_dimensions.sql
│   │   ├── 04_load_facts.sql
│   │   └── 06_reconciliation_checks.sql
│   └── 06_optimization/           # Query profiling, EXPLAIN analysis & benchmarks
│       ├── 01_query_optimization.sql
│       ├── 02_execution_plan_analysis.sql
│       └── 03_oltp_vs_star_vs_obt_benchmark.sql
├── .gitignore                     # Ignores large raw CSV/ZIP datasets
└── README.md
```

---

## 🛠️ Design Decisions & Engineering Post-Mortem

Building resilient data warehouses requires anticipating how the relational engine enforces types, locks dependencies, and manages transactions. During development, two realistic schema engineering challenges arose that highlight key data modeling principles:

### 1. Semantic Type Integrity: Identifiers vs Numeric Quantities

#### The Bug
Source postal prefixes (`customer_zip_code_prefix` and `seller_zip_code_prefix`) are defined as `VARCHAR(5)` in `oltp.customers` and `oltp.geolocation`. During warehouse dimension creation, these columns were initially specified as `INTEGER`. An `INSERT ... SELECT` into `dw.dim_customer` failed with:
```
ERROR: column "customer_zip_code_prefix" is of type integer but expression is of type character varying
HINT: You will need to rewrite or cast the expression.
```

#### Why a Simple Cast (`::INTEGER`) is a Dangerous Anti-Pattern
PostgreSQL strictly prohibits silent coercion from text to integer because string values may contain non-numeric characters. However, forcing an explicit cast (`c.customer_zip_code_prefix::INTEGER`) creates **silent data corruption**:
- In Brazil, postal codes (CEP) in São Paulo state begin with `0` (e.g. `01310-000` -> prefix `01310`).
- Converting `01310` to `INTEGER` truncates the leading zero, yielding `1310`.
- Downstream geospatial joins against `oltp.geolocation` on `zip_code_prefix` will silently fail for all São Paulo customers—the single largest consumer market in Brazil.
- **Rule of Thumb**: *If you do not perform arithmetic (addition, averaging) on a value, it is an identifier, not a quantity.* Postal codes, phone numbers, state codes, and SKUs must be stored as text (`VARCHAR`/`CHAR`).

---

### 2. PostgreSQL View Dependency Engine & Object Lifecycles

#### The Bug
When running an `ALTER TABLE` to align types (`customer_zip_code_prefix` to `VARCHAR(5)` and `customer_state` to `CHAR(2)`), PostgreSQL blocked the statement:
```
ERROR: cannot alter type of a column used by a view or rule
DETAIL: rule _RETURN on view dw.vw_sales_obt depends on column "customer_state"
```

#### Underlying Mechanism
PostgreSQL views are not dynamically interpreted SQL text strings; they compile into query trees and internal rewrite rules (`_RETURN`). The catalog records exact physical column references and their data types. If a column's type changes, the view's stored query tree becomes invalid. Consequently, Postgres blocks column alterations whenever an active view references that column.

#### Transactional Atomicity
PostgreSQL executes multi-action DDL statements within an implicit transaction. When the alteration of `customer_state` failed due to the view dependency, the entire `ALTER TABLE` statement rolled back. No partial changes were committed, preserving schema consistency.

#### Key Engineering Takeaways
1. **Layer Type Symmetry**: Maintain type consistency across Source, Staging, and Warehouse layers unless a deliberate, documented dimensional transformation is required.
2. **Dependency Order Execution**:
   $$\text{Tables} \longrightarrow \text{Constraints / Foreign Keys} \longrightarrow \text{Indexes} \longrightarrow \text{Views / Materialized Views}$$
   Always define downstream reporting views after all underlying physical dimension and fact schemas are finalized.
3. **Idempotent Views**: Include `DROP VIEW IF EXISTS ... CASCADE;` at the beginning of all view DDL scripts to enable deterministic tear-down and rebuilds.

---

### 3. Proactive Dependency Auditing with `pg_depend`

Before modifying schema definitions in production PostgreSQL environments, query the system catalogs (`pg_depend`, `pg_rewrite`, `pg_class`, `pg_attribute`) to discover all dependent views:

```sql
SELECT
    v.relname       AS dependent_view_name,
    n.nspname       AS view_schema,
    att.attname     AS referenced_column
FROM pg_depend d
JOIN pg_rewrite r   ON r.oid = d.objid
JOIN pg_class v     ON v.oid = r.ev_class
JOIN pg_namespace n ON n.oid = v.relnamespace
JOIN pg_attribute att 
    ON att.attrelid = d.refobjid 
   AND att.attnum   = d.refobjsubid
WHERE d.refobjid = 'dw.dim_customer'::regclass
  AND d.deptype  = 'n'
  AND v.relkind  = 'v';
```

---

## 🚀 Remediation Script

To safely patch an active database instance without data loss, execute [`sql/04_data_warehouse/06_remediate_dimension_types.sql`](file:///sql/04_data_warehouse/06_remediate_dimension_types.sql):

```sql
BEGIN;

-- 1. Drop dependent views
DROP VIEW IF EXISTS dw.vw_sales_obt CASCADE;

-- 2. Alter customer dimension (restoring 5-digit format with LPAD if needed)
ALTER TABLE dw.dim_customer
    ALTER COLUMN customer_zip_code_prefix TYPE VARCHAR(5)
        USING CASE 
            WHEN customer_zip_code_prefix IS NULL THEN NULL 
            ELSE LPAD(customer_zip_code_prefix::TEXT, 5, '0') 
        END,
    ALTER COLUMN customer_state TYPE CHAR(2);

-- 3. Alter seller dimension
ALTER TABLE dw.dim_seller
    ALTER COLUMN seller_zip_code_prefix TYPE VARCHAR(5)
        USING CASE 
            WHEN seller_zip_code_prefix IS NULL THEN NULL 
            ELSE LPAD(seller_zip_code_prefix::TEXT, 5, '0') 
        END,
    ALTER COLUMN seller_state TYPE CHAR(2);

-- 4. Recreate reporting view
\i sql/04_data_warehouse/04_create_obt.sql

COMMIT;
```
