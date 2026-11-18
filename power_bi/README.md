# Power BI Dashboard & Business Intelligence Layer

This directory contains the reporting specifications, DAX measure definitions, and visual data model designs for the Olist E-Commerce Analytics platform.

---

## 1. Connecting Power BI to the Data Warehouse

### Connection Options:
1. **Option A: Star Schema Direct Import (Recommended)**
   - Connect via PostgreSQL connector to the `dw` schema.
   - Load: `dim_customer`, `dim_product`, `dim_seller`, `dim_date`, `fact_sales`, `fact_payments`, `fact_reviews`.
   - Maintain 1-to-many single-direction relationships from dimensions to facts.
2. **Option B: One Big Table (OBT) View**
   - Connect to `dw.vw_sales_obt`.
   - Flat single-table import for fast, low-complexity dashboard authoring.

---

## 2. Core DAX Measure Library

### Sales & Financials
```dax
Total Revenue = SUM(fact_sales[item_price])

Total Freight = SUM(fact_sales[freight_value])

Gross Merchandise Value = [Total Revenue] + [Total Freight]

Total Orders = DISTINCTCOUNT(fact_sales[order_id])

Average Order Value (AOV) = DIVIDE([Total Revenue], [Total Orders], 0)

Freight Ratio % = DIVIDE([Total Freight], [Gross Merchandise Value], 0)
```

### Logistics & Fulfillment
```dax
Total Delivered Orders = 
CALCULATE(
    [Total Orders],
    fact_sales[order_status] = "delivered"
)

On Time Orders = 
CALCULATE(
    [Total Delivered Orders],
    fact_sales[delivery_date_key] <= fact_sales[estimated_delivery_date_key],
    NOT(ISBLANK(fact_sales[delivery_date_key]))
)

On Time Delivery Rate % = 
DIVIDE([On Time Orders], [Total Delivered Orders], 0)

Average Delivery Duration Days = 
AVERAGEX(
    FILTER(fact_sales, NOT(ISBLANK(fact_sales[delivery_date_key]))),
    DATEDIFF(
        RELATED(dim_date[full_date]), 
        -- where dim_date is linked via order_date_key
        LOOKUPVALUE(dim_date[full_date], dim_date[date_key], fact_sales[delivery_date_key]),
        DAY
    )
)
```

### Customer Satisfaction
```dax
Average Review Score = AVERAGE(fact_reviews[review_score])

5 Star Review Count = 
CALCULATE(
    COUNT(fact_reviews[review_key]),
    fact_reviews[review_score] = 5
)

5 Star Review % = 
DIVIDE([5 Star Review Count], COUNT(fact_reviews[review_key]), 0)
```

---

## 3. Planned Dashboard Pages

1. **Executive Overview**: KPI metric cards (Revenue, Orders, AOV, Review Score), Monthly Sales Trend line chart, Top 10 Product Categories by Revenue bar chart.
2. **Logistics & Delivery Operations**: Delivery On-Time Rate gauge, State-by-State Freight Cost map, Average Delivery Time bar chart by destination region.
3. **Customer & Payment Insights**: Payment Type breakdown donut chart, Installment distribution histogram, Customer vs. Seller geographic concentration matrix.
