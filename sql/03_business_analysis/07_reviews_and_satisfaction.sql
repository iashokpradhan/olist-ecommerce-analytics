-- ============================================================
-- File: 07_reviews_and_satisfaction.sql
-- Purpose: Review and customer satisfaction analysis
-- ============================================================


-- Query 1: Overall review KPIs

SELECT
    COUNT(*) AS review_records,
    COUNT(DISTINCT order_id) AS orders_with_reviews,
    ROUND(AVG(review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE review_score = 5) AS five_star_reviews,
    COUNT(*) FILTER (WHERE review_score = 1) AS one_star_reviews,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE review_score >= 4)
        / NULLIF(COUNT(review_score), 0),
        2
    ) AS percentage_scores_4_or_5
FROM oltp.order_reviews;


-- Query 2: Review score distribution

SELECT
    review_score,
    COUNT(*) AS review_records,
    ROUND(
        100.0 * COUNT(*)
        / NULLIF((SELECT COUNT(*) FROM oltp.order_reviews), 0),
        2
    ) AS percentage_of_reviews
FROM oltp.order_reviews
GROUP BY review_score
ORDER BY review_score;


-- Query 3: Monthly review trend

SELECT
    DATE_TRUNC('month', review_creation_date)::DATE AS review_month,
    COUNT(*) AS review_records,
    ROUND(AVG(review_score), 2) AS average_review_score
FROM oltp.order_reviews
WHERE review_creation_date IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- Query 4: Review scores by order status

SELECT
    o.order_status,
    COUNT(r.review_record_id) AS review_records,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM oltp.orders o
JOIN oltp.order_reviews r
    ON o.order_id = r.order_id
GROUP BY o.order_status
ORDER BY average_review_score DESC NULLS LAST;


-- Query 5: Review scores by customer state

SELECT
    c.customer_state,
    COUNT(r.review_record_id) AS review_records,
    ROUND(AVG(r.review_score), 2) AS average_review_score,
    COUNT(*) FILTER (WHERE r.review_score <= 2) AS low_score_reviews
FROM oltp.customers c
JOIN oltp.orders o
    ON c.customer_id = o.customer_id
JOIN oltp.order_reviews r
    ON o.order_id = r.order_id
GROUP BY c.customer_state
ORDER BY average_review_score ASC NULLS LAST;


-- Query 6: Review comment availability

SELECT
    COUNT(*) AS total_review_records,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(review_comment_title), '') IS NOT NULL
    ) AS reviews_with_titles,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(review_comment_message), '') IS NOT NULL
    ) AS reviews_with_messages,
    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(review_comment_title), '') IS NULL
          AND NULLIF(TRIM(review_comment_message), '') IS NULL
    ) AS reviews_without_text
FROM oltp.order_reviews;