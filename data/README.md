# Dataset Documentation: Olist Brazilian E-Commerce

The dataset used in this project is the real-world Brazilian E-Commerce Public Dataset provided by **Olist Store**, available publicly on Kaggle.

- **Source URL**: [Kaggle - Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Timeframe**: Orders placed between October 2016 and October 2018.
- **Coverage**: Over 100,000 orders fulfilled across all 27 Brazilian federative units.

---

## Raw File Inventory

| File Name | Records | Description |
|---|---|---|
| `olist_customers_dataset.csv` | 99,441 | Customer ID, unique customer identity, and zip code prefix. |
| `olist_geolocation_dataset.csv` | 1,000,163 | Lat/long coordinates and cities associated with Brazilian postal codes. |
| `olist_orders_dataset.csv` | 99,441 | Order lifecycle timestamps (purchase, approval, carrier, delivery, estimated). |
| `olist_order_items_dataset.csv` | 112,650 | Item-level breakdown of orders, price, freight, product IDs, and seller IDs. |
| `olist_order_payments_dataset.csv`| 103,886 | Payment installments, payment methods (credit card, boleto, voucher), and amounts. |
| `olist_order_reviews_dataset.csv` | 99,224 | Customer review scores (1–5) and optional text comments. |
| `olist_products_dataset.csv` | 32,951 | Product catalog attributes, category names (Portuguese), weights, and dimensions. |
| `olist_sellers_dataset.csv` | 3,095 | Seller identities and geographic locations. |
| `product_category_name_translation.csv`| 71 | English translation mapping for Brazilian Portuguese category names. |

---

## Data Loading Order
To ingest this data into PostgreSQL, run the project SQL scripts in sequence:
1. `sql/01_database_setup/01_create_tables_&_indexes.sql`
2. Load CSV files into `oltp.*` tables via `\copy` or pgAdmin Import/Export tool.
3. `sql/01_database_setup/02_add_constraints.sql`
4. `sql/05_etl_pipeline/01_staging_tables.sql`
5. `sql/05_etl_pipeline/02_transform_data.sql`
6. `sql/04_data_warehouse/01_create_dw_schema.sql` through `05_dw_indexes.sql`
7. `sql/05_etl_pipeline/03_load_dimensions.sql`
8. `sql/05_etl_pipeline/04_load_facts.sql`
