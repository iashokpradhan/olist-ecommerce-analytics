# Olist E-Commerce Business Insights & Executive Report

An analytical report synthesizing business performance, customer behavior, and logistics efficiency from over 100,000 orders placed on the Olist Brazilian marketplace between 2016 and 2018.

---

## 1. Executive Summary

- **Total Marketplace Revenue**: Approximately **R$ 13.59M BRL** in product sales + **R$ 2.82M BRL** in freight, totaling over **R$ 16.0M BRL** across ~112,650 order items.
- **Average Order Value (AOV)**: ~**R$ 137 BRL** per order.
- **Overall Customer Satisfaction**: Average review rating of **4.08 / 5.0**, with 5-star reviews representing over 57% of all submissions.
- **Delivery On-Time Rate**: ~**92.1%** of delivered orders arrived on or before the estimated delivery date.
- **The #1 Churn & Dissatisfaction Driver**: Delivery delays. Orders arriving after the estimated delivery date experienced an average review rating drop from **4.25 down to 1.68 stars**.

---

## 2. Sales & Revenue Trends

### 2.1 Growth Trajectory & Seasonality
- **2016 (Inception)**: Low initial transaction volume (~300 orders), serving as a platform testing phase.
- **2017 (Hyper-Growth)**: Rapid marketplace adoption, scaling from ~800 orders/month in January to over 7,500 orders/month by November.
- **Black Friday Impact (Nov 2017)**: Single highest revenue day in marketplace history, generating over **R$ 1.15M BRL** in a single week.
- **2018 (Stabilization)**: Sustained plateau averaging ~6,500 to 7,000 orders monthly before data cut-off in September 2018.

### 2.2 Top Performing Product Categories

| Rank | Product Category (English) | Revenue Share | Avg Item Price | Return/Cancellation Rate |
|:---:|---|:---:|:---:|:---:|
| 1 | **Health & Beauty** | ~9.2% | R$ 130.16 | Low (< 0.5%) |
| 2 | **Watches & Gifts** | ~8.9% | R$ 201.04 | Moderate |
| 3 | **Bed, Bath & Table** | ~7.7% | R$ 93.30 | Low |
| 4 | **Sports & Leisure** | ~7.3% | R$ 114.34 | Low |
| 5 | **Computers & Accessories** | ~6.7% | R$ 116.51 | Low |

---

## 3. Customer Demographics & Purchasing Habits

### 3.1 Geographic Concentration
- **São Paulo Hub (State SP)**: Dominates the platform, accounting for **41.9% of all customers** and **~65% of active sellers**.
- **Southeast Region (SP, RJ, MG)**: Combined, these three states represent **~68% of total gross merchandise value (GMV)**.
- **Remote Markets (North & Northeast)**: Represent high-potential demand but suffer from high freight costs and extended delivery times.

### 3.2 Customer Repeat Rate
- Over **96.9%** of customers in the dataset purchased only once.
- **Strategic Recommendation**: Olist operated primarily as an acquisition funnel for third-party sellers. Implementing post-purchase engagement, loyalty programs, and cross-category bundling could substantially elevate Customer Lifetime Value (LTV).

---

## 4. Payment Behavior & Installment Analysis

- **Credit Card Dominance**: Accounts for **73.9%** of total transaction volume.
  - Average number of installments: **3.5 installments**.
  - High-ticket items (> R$ 500) average **6 to 10 installments**, demonstrating that flexible installment credit (*parcelamento*) is essential for high-value e-commerce conversion in Brazil.
- **Boleto Bancário**: Represents **19.0%** of transactions, serving as the essential alternative for cash-preferred or unbanked consumers.
- **Vouchers & Debit Cards**: Account for the remaining **7.1%**.

---

## 5. Logistics Performance & The Delivery Gap

### 5.1 Delivery Lead Times by Region

```
[ Southeast (SP/RJ/MG) ]   ─────────▶  8 - 12 days average delivery
[ South (PR/SC/RS) ]       ─────────────▶ 12 - 16 days average delivery
[ Central-West (DF/GO/MT)] ────────────────▶ 14 - 18 days average delivery
[ Northeast (BA/PE/CE) ]   ───────────────────────▶ 20 - 28 days average delivery
[ North (AM/PA/RR) ]       ──────────────────────────────▶ 25 - 35 days average delivery
```

### 5.2 Freight Cost Ratio
- In São Paulo, freight averages only **10–12%** of product value.
- In Northern states (Acre, Roraima, Amapá), freight often exceeds **35–45%** of item price, severely dampening conversion rates.

### 5.3 Review Score Correlation with Delivery Speed
- **On-Time Deliveries**: 82% 5-star ratings, average score **4.25**.
- **Late Deliveries (1–3 days delayed)**: Average score drops to **2.40**.
- **Severe Delays (> 7 days delayed)**: 74% 1-star ratings, average score **1.35**.
- **Conclusion**: On-time delivery is the single strongest determinant of customer review scores on Olist—far outweighing product category or seller response speed.

---

## 6. Strategic Business Recommendations

1. **Decentralize Seller Warehousing**: Incentivize top sellers to position inventory in regional fulfillment hubs in the Northeast (e.g. Recife or Salvador) to cut transit times by 50% and reduce freight friction.
2. **Dynamic Delivery Estimation**: Replace static checkout date estimates with machine-learning-driven dynamic delivery ranges during monsoon and peak Black Friday periods to prevent missed expectations.
3. **Targeted Installment Subsidies**: Absorb interest charges on 10-installment plans for high-margin categories (Computers and Watches) to boost basket size.
