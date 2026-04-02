-- ============================================================
-- Apache OFBiz Pre-Migration Validation Queries
-- Run against SOURCE database before migration
-- ============================================================

-- 1. Database size and table count
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS table_count;

-- 2. Row counts for all tables (summary)
SELECT schemaname, relname AS table_name, n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- 3. Critical table row counts (exact)
SELECT 'party' AS entity, count(*) AS row_count FROM party
UNION ALL SELECT 'person', count(*) FROM person
UNION ALL SELECT 'party_group', count(*) FROM party_group
UNION ALL SELECT 'user_login', count(*) FROM user_login
UNION ALL SELECT 'product', count(*) FROM product
UNION ALL SELECT 'product_category', count(*) FROM product_category
UNION ALL SELECT 'order_header', count(*) FROM order_header
UNION ALL SELECT 'order_item', count(*) FROM order_item
UNION ALL SELECT 'invoice', count(*) FROM invoice
UNION ALL SELECT 'payment', count(*) FROM payment
UNION ALL SELECT 'gl_account', count(*) FROM gl_account
UNION ALL SELECT 'acctg_trans', count(*) FROM acctg_trans
UNION ALL SELECT 'acctg_trans_entry', count(*) FROM acctg_trans_entry
UNION ALL SELECT 'inventory_item', count(*) FROM inventory_item
UNION ALL SELECT 'content', count(*) FROM content
UNION ALL SELECT 'data_resource', count(*) FROM data_resource
ORDER BY entity;

-- 4. Check for NULL primary keys (data integrity)
SELECT 'party' AS table_name, count(*) AS null_pk_count
FROM party WHERE party_id IS NULL
UNION ALL
SELECT 'product', count(*) FROM product WHERE product_id IS NULL
UNION ALL
SELECT 'order_header', count(*) FROM order_header WHERE order_id IS NULL
UNION ALL
SELECT 'invoice', count(*) FROM invoice WHERE invoice_id IS NULL;

-- 5. Check for orphaned foreign key references
-- Orders referencing non-existent parties
SELECT 'orphaned_order_parties' AS check_name, count(*) AS count
FROM order_header oh
LEFT JOIN party p ON oh.created_by_user_login = p.party_id
WHERE oh.created_by_user_login IS NOT NULL AND p.party_id IS NULL;

-- Order items referencing non-existent products
SELECT 'orphaned_order_products' AS check_name, count(*) AS count
FROM order_item oi
LEFT JOIN product p ON oi.product_id = p.product_id
WHERE oi.product_id IS NOT NULL AND p.product_id IS NULL;

-- 6. Check for data type issues
-- Timestamps that might cause timezone conversion issues
SELECT 'future_timestamps' AS check_name, count(*) AS count
FROM order_header WHERE order_date > NOW() + INTERVAL '1 day';

SELECT 'very_old_timestamps' AS check_name, count(*) AS count
FROM order_header WHERE order_date < '1990-01-01';

-- 7. Check for large text/blob fields
SELECT table_name, column_name, data_type,
       character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (data_type = 'text' OR data_type = 'bytea'
       OR character_maximum_length > 1000)
ORDER BY table_name, column_name;

-- 8. Index inventory
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 9. Sequence values (for ID generation)
SELECT sequence_name, last_value
FROM information_schema.sequences s
JOIN pg_sequences ps ON s.sequence_name = ps.sequencename
WHERE s.sequence_schema = 'public'
ORDER BY sequence_name;

-- 10. Check for encrypted/sensitive data columns
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (column_name LIKE '%password%'
       OR column_name LIKE '%secret%'
       OR column_name LIKE '%token%'
       OR column_name LIKE '%encrypt%'
       OR column_name LIKE '%ssn%'
       OR column_name LIKE '%credit%')
ORDER BY table_name, column_name;

-- 11. Database encoding and collation
SELECT datname, encoding, datcollate, datctype
FROM pg_database
WHERE datname = current_database();

-- 12. Active connections and locks
SELECT count(*) AS active_connections FROM pg_stat_activity
WHERE datname = current_database() AND state = 'active';

-- 13. Table size summary (top 20)
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS data_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- 14. Foreign key constraints inventory
SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- 15. Check replication status (if applicable)
SELECT * FROM pg_stat_replication;
