-- ============================================================
-- Module 8: Data Quality Summary
-- Purpose: Consolidate selected validation results
-- ============================================================

WITH checks AS (

    -- 1. Expected row counts

    SELECT
        'Row count: customers' AS check_name,
        COUNT(*)::BIGINT AS observed_value,
        99441::BIGINT AS expected_value
    FROM oltp.customers

    UNION ALL

    SELECT
        'Row count: orders',
        COUNT(*)::BIGINT,
        99441::BIGINT
    FROM oltp.orders

    UNION ALL

    SELECT
        'Row count: order_items',
        COUNT(*)::BIGINT,
        112650::BIGINT
    FROM oltp.order_items

    UNION ALL

    SELECT
        'Row count: products',
        COUNT(*)::BIGINT,
        32951::BIGINT
    FROM oltp.products

    UNION ALL

    SELECT
        'Row count: sellers',
        COUNT(*)::BIGINT,
        3095::BIGINT
    FROM oltp.sellers

    UNION ALL

    SELECT
        'Row count: order_payments',
        COUNT(*)::BIGINT,
        103886::BIGINT
    FROM oltp.order_payments

    UNION ALL

    SELECT
        'Row count: order_reviews',
        COUNT(*)::BIGINT,
        99224::BIGINT
    FROM oltp.order_reviews

    UNION ALL

    SELECT
        'Row count: geolocation',
        COUNT(*)::BIGINT,
        1000163::BIGINT
    FROM oltp.geolocation

    UNION ALL

    SELECT
        'Row count: product_category_translation',
        COUNT(*)::BIGINT,
        71::BIGINT
    FROM oltp.product_category_translation


    -- 2. Primary-key checks

    UNION ALL

    SELECT
        'NULL customer IDs',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.customers
    WHERE customer_id IS NULL

    UNION ALL

    SELECT
        'NULL order IDs',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.orders
    WHERE order_id IS NULL

    UNION ALL

    SELECT
        'NULL product IDs',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.products
    WHERE product_id IS NULL

    UNION ALL

    SELECT
        'NULL seller IDs',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.sellers
    WHERE seller_id IS NULL


    -- 3. Foreign-key checks

    UNION ALL

    SELECT
        'Orders with missing customer records',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.orders AS o
    LEFT JOIN oltp.customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.customer_id IS NOT NULL
      AND c.customer_id IS NULL

    UNION ALL

    SELECT
        'Order items with missing order records',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_items AS oi
    LEFT JOIN oltp.orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_id IS NULL

    UNION ALL

    SELECT
        'Order items with missing product records',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_items AS oi
    LEFT JOIN oltp.products AS p
        ON oi.product_id = p.product_id
    WHERE oi.product_id IS NOT NULL
      AND p.product_id IS NULL

    UNION ALL

    SELECT
        'Order items with missing seller records',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_items AS oi
    LEFT JOIN oltp.sellers AS s
        ON oi.seller_id = s.seller_id
    WHERE oi.seller_id IS NOT NULL
      AND s.seller_id IS NULL

    UNION ALL

    SELECT
        'Payments with missing order records',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_payments AS p
    LEFT JOIN oltp.orders AS o
        ON p.order_id = o.order_id
    WHERE o.order_id IS NULL

    UNION ALL

    SELECT
        'Reviews with missing order records',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_reviews AS r
    LEFT JOIN oltp.orders AS o
        ON r.order_id = o.order_id
    WHERE r.order_id IS NULL


    -- 4. Numeric checks

    UNION ALL

    SELECT
        'Negative order-item prices or freight',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_items
    WHERE price < 0
       OR freight_value < 0

    UNION ALL

    SELECT
        'Invalid review scores',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM oltp.order_reviews
    WHERE review_score IS NULL
       OR review_score NOT BETWEEN 1 AND 5


    -- 5. Composite key checks

    UNION ALL

    SELECT
        'Duplicate order-item composite keys',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM (
        SELECT order_id, order_item_id
        FROM oltp.order_items
        GROUP BY order_id, order_item_id
        HAVING COUNT(*) > 1
    ) AS duplicates

    UNION ALL

    SELECT
        'Duplicate payment composite keys',
        COUNT(*)::BIGINT,
        0::BIGINT
    FROM (
        SELECT order_id, payment_sequential
        FROM oltp.order_payments
        GROUP BY order_id, payment_sequential
        HAVING COUNT(*) > 1
    ) AS duplicates
)

SELECT
    check_name,
    observed_value,
    expected_value,
    CASE
        WHEN observed_value = expected_value THEN 'PASS'
        ELSE 'INVESTIGATE'
    END AS status
FROM checks
ORDER BY check_name;