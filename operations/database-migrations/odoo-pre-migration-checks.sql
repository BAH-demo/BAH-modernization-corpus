-- ============================================================
-- Odoo Pre-Migration Validation Queries
-- Run against SOURCE database before migration
-- ============================================================

-- 1. Database overview
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Installed modules inventory
SELECT name, state, latest_version, shortdesc
FROM ir_module_module
WHERE state = 'installed'
ORDER BY name;

-- 3. Critical table row counts
SELECT 'res_partner' AS entity, count(*) AS row_count FROM res_partner
UNION ALL SELECT 'res_users', count(*) FROM res_users
UNION ALL SELECT 'res_company', count(*) FROM res_company
UNION ALL SELECT 'account_move', count(*) FROM account_move
UNION ALL SELECT 'account_move_line', count(*) FROM account_move_line
UNION ALL SELECT 'account_journal', count(*) FROM account_journal
UNION ALL SELECT 'sale_order', count(*) FROM sale_order
UNION ALL SELECT 'sale_order_line', count(*) FROM sale_order_line
UNION ALL SELECT 'purchase_order', count(*) FROM purchase_order
UNION ALL SELECT 'stock_move', count(*) FROM stock_move
UNION ALL SELECT 'stock_quant', count(*) FROM stock_quant
UNION ALL SELECT 'hr_employee', count(*) FROM hr_employee
UNION ALL SELECT 'product_template', count(*) FROM product_template
UNION ALL SELECT 'product_product', count(*) FROM product_product
UNION ALL SELECT 'ir_attachment', count(*) FROM ir_attachment
UNION ALL SELECT 'mail_message', count(*) FROM mail_message
ORDER BY entity;

-- 4. Accounting balance verification
SELECT
    'accounting_balance' AS check_name,
    company_id,
    sum(debit) AS total_debit,
    sum(credit) AS total_credit,
    sum(debit) - sum(credit) AS balance
FROM account_move_line
GROUP BY company_id;

-- 5. Multi-company data check
SELECT id, name FROM res_company ORDER BY id;

-- 6. Sequence values
SELECT name, number_next, implementation
FROM ir_sequence
ORDER BY name;

-- 7. Custom fields (studio/custom modules)
SELECT model, name, field_description, ttype, state
FROM ir_model_fields
WHERE state = 'manual'
ORDER BY model, name;

-- 8. Filestore attachment statistics
SELECT
    count(*) AS total_attachments,
    count(store_fname) AS filestore_refs,
    count(db_datas) AS db_stored,
    pg_size_pretty(sum(file_size)) AS total_size
FROM ir_attachment;

-- 9. Cron jobs inventory
SELECT name, model_id, state, interval_number, interval_type, nextcall
FROM ir_cron
WHERE active = true
ORDER BY nextcall;

-- 10. Check for pending activities/workflows
SELECT
    'pending_activities' AS check_name,
    count(*) AS count
FROM mail_activity
WHERE date_deadline < CURRENT_DATE;

-- 11. Translation records
SELECT lang, count(*) AS translation_count
FROM ir_translation
GROUP BY lang
ORDER BY count(*) DESC;

-- 12. Top 20 largest tables
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_live_tup AS row_count
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- 13. Check for data integrity issues
-- Orphaned partners (no user, no parent)
SELECT 'orphaned_partners' AS check_name, count(*)
FROM res_partner
WHERE parent_id IS NOT NULL
  AND parent_id NOT IN (SELECT id FROM res_partner);

-- 14. Database encoding
SELECT datname, encoding, datcollate, datctype
FROM pg_database WHERE datname = current_database();
