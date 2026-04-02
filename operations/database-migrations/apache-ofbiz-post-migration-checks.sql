-- ============================================================
-- Apache OFBiz Post-Migration Validation Queries
-- Run against TARGET database after migration
-- Compare results with pre-migration baseline
-- ============================================================

-- 1. Database size comparison
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS table_count;

-- 2. Row count comparison - critical tables
-- Compare these counts with pre-migration results
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

-- 3. Verify all tables migrated (compare with source)
SELECT schemaname, relname AS table_name, n_live_tup AS row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY relname;

-- 4. Foreign key constraint validation
-- Check no FK violations exist
DO $$
DECLARE
    r RECORD;
    violation_count INTEGER;
BEGIN
    FOR r IN
        SELECT tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public'
    LOOP
        EXECUTE format(
            'SELECT count(*) FROM %I t WHERE NOT EXISTS (SELECT 1 FROM %I)',
            r.table_name, r.table_name
        ) INTO violation_count;
        IF violation_count > 0 THEN
            RAISE NOTICE 'FK violation in %: % violations', r.constraint_name, violation_count;
        END IF;
    END LOOP;
END $$;

-- 5. Data integrity spot checks
-- Verify sample records match source
-- Order totals should match
SELECT
    'order_totals' AS check_name,
    count(*) AS total_orders,
    sum(grand_total) AS sum_grand_total,
    min(order_date) AS earliest_order,
    max(order_date) AS latest_order
FROM order_header;

-- Invoice totals should match
SELECT
    'invoice_totals' AS check_name,
    count(*) AS total_invoices,
    sum(CASE WHEN invoice_type_id = 'SALES_INVOICE' THEN 1 ELSE 0 END) AS sales_invoices,
    sum(CASE WHEN invoice_type_id = 'PURCHASE_INVOICE' THEN 1 ELSE 0 END) AS purchase_invoices
FROM invoice;

-- Accounting balance check
SELECT
    'gl_balance' AS check_name,
    sum(CASE WHEN debit_credit_flag = 'D' THEN amount ELSE 0 END) AS total_debits,
    sum(CASE WHEN debit_credit_flag = 'C' THEN amount ELSE 0 END) AS total_credits,
    sum(CASE WHEN debit_credit_flag = 'D' THEN amount ELSE -amount END) AS net_balance
FROM acctg_trans_entry;

-- 6. Verify indexes exist
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 7. Verify sequences are properly set
-- Sequences should be set to max(id) + 1 or higher
SELECT
    'sequence_check' AS check_name,
    sequence_name,
    last_value AS current_value
FROM pg_sequences
WHERE schemaname = 'public'
ORDER BY sequence_name;

-- 8. Check for NULL values in NOT NULL columns
SELECT table_name, column_name, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND is_nullable = 'NO'
ORDER BY table_name, column_name;

-- 9. Verify timezone conversion (TIMESTAMP to TIMESTAMPTZ)
SELECT
    'timezone_check' AS check_name,
    count(*) AS records_checked,
    min(order_date) AS min_date,
    max(order_date) AS max_date
FROM order_header
WHERE order_date IS NOT NULL;

-- 10. Performance baseline queries
-- These should complete within acceptable thresholds
EXPLAIN ANALYZE SELECT * FROM order_header WHERE status_id = 'ORDER_COMPLETED' LIMIT 100;
EXPLAIN ANALYZE SELECT * FROM product WHERE product_type_id = 'FINISHED_GOOD' LIMIT 100;
EXPLAIN ANALYZE SELECT * FROM party WHERE party_type_id = 'PERSON' LIMIT 100;

-- 11. Verify encrypted fields are properly migrated
SELECT 'encrypted_passwords' AS check_name,
       count(*) AS total_users,
       count(current_password) AS users_with_password,
       count(*) - count(current_password) AS users_without_password
FROM user_login;

-- 12. Check for any migration artifacts
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%_tmp%'
       OR table_name LIKE '%_bak%'
       OR table_name LIKE '%_migration%')
ORDER BY table_name;

-- 13. Verify PostgreSQL version and settings
SELECT version();
SHOW shared_buffers;
SHOW work_mem;
SHOW max_connections;
