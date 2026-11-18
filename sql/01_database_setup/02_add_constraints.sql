-- ============================================================
-- Project: Olist E-commerce Analytics
-- Purpose: Verify primary keys, foreign keys, and constraints
-- Schema: oltp
-- Database: olist_analytics
-- ============================================================


-- 1. Verify primary keys

SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints AS tc
WHERE tc.table_schema = 'oltp'
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name;


-- 2. Verify foreign keys

SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.constraint_schema = kcu.constraint_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
   AND tc.constraint_schema = ccu.constraint_schema
WHERE tc.table_schema = 'oltp'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, tc.constraint_name;


-- 3. Verify UNIQUE and CHECK constraints

SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints AS tc
WHERE tc.table_schema = 'oltp'
  AND tc.constraint_type IN ('UNIQUE', 'CHECK')
ORDER BY tc.table_name, tc.constraint_type;


-- 4. Verify NOT NULL columns

SELECT
    table_schema,
    table_name,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_schema = 'oltp'
  AND is_nullable = 'NO'
ORDER BY table_name, ordinal_position;