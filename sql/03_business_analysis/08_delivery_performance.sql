-- ============================================================
-- File: 08_delivery_performance.sql
-- Purpose: Delivery performance analysis
-- ============================================================


-- Query 1: Overall delivery KPIs

SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
    ) AS delivered_orders_with_both_dates,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400.0
        ) FILTER (
            WHERE order_status = 'delivered'
              AND order_delivered_customer_date IS NOT NULL
              AND order_purchase_timestamp IS NOT NULL
        ),
        2
    ) AS average_purchase_to_delivery_days,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_delivered_orders

FROM oltp.orders;


-- Query 2: Late delivery percentage

SELECT
    COUNT(*) AS delivered_orders_with_both_dates,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_delivered_customer_date
                  > order_estimated_delivery_date
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage

FROM oltp.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- Query 3: Delivery performance by month of purchase

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::DATE AS purchase_month,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_purchase_timestamp
                )
            ) / 86400.0
        ),
        2
    ) AS average_delivery_days,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date
              > order_estimated_delivery_date
    ) AS late_orders

FROM oltp.orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- Query 4: Delivery performance by customer state

SELECT
    c.customer_state,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400.0
        ),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_delivered_customer_date
                  > o.order_estimated_delivery_date
        )
        / NULLIF(COUNT(*) FILTER (
            WHERE o.order_estimated_delivery_date IS NOT NULL
        ), 0),
        2
    ) AS late_delivery_percentage

FROM oltp.orders o
JOIN oltp.customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_delivery_percentage DESC NULLS LAST;


-- Query 5: Longest delivery times

SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,

    ROUND(
        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_purchase_timestamp
            )
        ) / 86400.0,
        2
    ) AS purchase_to_delivery_days,

    ROUND(
        EXTRACT(
            EPOCH FROM (
                order_delivered_customer_date
                - order_estimated_delivery_date
            )
        ) / 86400.0,
        2
    ) AS days_late

FROM oltp.orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
ORDER BY purchase_to_delivery_days DESC
LIMIT 50;


-- Query 6: Shipping time from carrier handoff to customer

SELECT
    COUNT(*) AS orders_with_shipping_dates,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    order_delivered_customer_date
                    - order_delivered_carrier_date
                )
            ) / 86400.0
        ),
        2
    ) AS average_carrier_to_customer_days

FROM oltp.orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;