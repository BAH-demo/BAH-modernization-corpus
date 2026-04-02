-- ============================================================
-- Odoo Post-Migration Validation Queries
-- Run against TARGET database after migration
-- Compare with pre-migration baseline
-- ============================================================

-- 1. Database size comparison
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Module state verification (all should still be 'installed')
SELECT name, state, latest_version
FROM ir_module_module
WHERE state = 'installed'
ORDER BY name;

-- 3. Row count comparison (match with pre-migration)
SELECT 'res_partner' AS entity, count(*) AS row_count FROM res_partner
UNION ALL SELECT 'res_users', count(*) FROM res_users
UNION ALL SELECT 'account_move', count(*) FROM account_move
UNION ALL SELECT 'account_move_line', count(*) FROM account_move_line
UNION ALL SELECT 'sale_order', count(*) FROM sale_order
UNION ALL SELECT 'sale_order_line', count(*) FROM sale_order_line
UNION ALL SELECT 'purchase_order', count(*) FROM purchase_order
UNION ALL SELECT 'stock_move', count(*) FROM stock_move
UNION ALL SELECT 'stock_quant', count(*) FROM stock_quant
UNION ALL SELECT 'hr_employee', count(*) FROM hr_employee
UNION ALL SELECT 'product_template', count(*) FROM product_template
UNION ALL SELECT 'product_product', count(*) FROM product_product
UNION ALL SELECT 'ir_attachment', count(*) FROM ir_attachment
ORDER BY entity;

-- 4. Accounting balance verification (MUST match pre-migration)
SELECT
    'accounting_balance' AS check_name,
    company_id,
    sum(debit) AS total_debit,
    sum(credit) AS total_credit,
    sum(debit) - sum(credit) AS balance
FROM account_move_line
GROUP BY company_id;

-- 5. Verify sequences are properly set
SELECT name, number_next
FROM ir_sequence
ORDER BY name;

-- 6. Custom fields preserved
SELECT model, name, field_description, ttype, state
FROM ir_model_fields
WHERE state = 'manual'
ORDER BY model, name;

-- 7. Filestore integrity
SELECT
    count(*) AS total_attachments,
    count(store_fname) AS filestore_refs,
    pg_size_pretty(sum(file_size)) AS total_size
FROM ir_attachment;

-- 8. Cron jobs still active
SELECT name, state, interval_number, interval_type, nextcall
FROM ir_cron
WHERE active = true
ORDER BY name;

-- 9. Verify admin user accessible
SELECT id, login, active, company_id
FROM res_users
WHERE id = 2;  -- Admin user is typically id=2 in Odoo

-- 10. Performance baseline
EXPLAIN ANALYZE
SELECT * FROM account_move_line
WHERE account_id IN (SELECT id FROM account_account WHERE code LIKE '1%')
LIMIT 100;

-- 11. Check for migration artifacts
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%_tmp%' OR table_name LIKE '%_bak%')
ORDER BY table_name;

-- 12. Verify PostgreSQL version
SELECT version();
