-- ============================================================
-- Module 3: Foreign Key Validation
-- Purpose: Identify orphan records
-- ============================================================

-- 1. Orders referencing missing customers

SELECT
    'orders -> customers' AS relationship,
    COUNT(*) AS orphan_rows
FROM oltp.orders AS o
LEFT JOIN oltp.customers AS c
    ON o.customer_id = c.customer_id
WHERE o.customer_id IS NOT NULL
  AND c.customer_id IS NULL;


-- 2. Order items referencing missing orders

SELECT
    'order_items -> orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM oltp.order_items AS oi
LEFT JOIN oltp.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 3. Order items referencing missing products

SELECT
    'order_items -> products' AS relationship,
    COUNT(*) AS orphan_rows
FROM oltp.order_items AS oi
LEFT JOIN oltp.products AS p
    ON oi.product_id = p.product_id
WHERE oi.product_id IS NOT NULL
  AND p.product_id IS NULL;


-- 4. Order items referencing missing sellers

SELECT
    'order_items -> sellers' AS relationship,
    COUNT(*) AS orphan_rows
FROM oltp.order_items AS oi
LEFT JOIN oltp.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE oi.seller_id IS NOT NULL
  AND s.seller_id IS NULL;


-- 5. Payments referencing missing orders

SELECT
    'order_payments -> orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM oltp.order_payments AS op
LEFT JOIN oltp.orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 6. Reviews referencing missing orders

SELECT
    'order_reviews -> orders' AS relationship,
    COUNT(*) AS orphan_rows
FROM oltp.order_reviews AS r
LEFT JOIN oltp.orders AS o
    ON r.order_id = o.order_id
WHERE r.order_id IS NULL;