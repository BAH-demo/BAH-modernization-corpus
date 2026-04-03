-- ============================================================
-- Django Oscar Post-Migration Validation Queries
-- Run against TARGET database after migration
-- ============================================================

-- 1. Database size comparison
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Django migration state (must match source)
SELECT app, count(*) AS migration_count
FROM django_migrations
GROUP BY app
ORDER BY app;

-- 3. Row count comparison
SELECT 'auth_user' AS entity, count(*) AS row_count FROM auth_user
UNION ALL SELECT 'catalogue_product', count(*) FROM catalogue_product
UNION ALL SELECT 'catalogue_category', count(*) FROM catalogue_category
UNION ALL SELECT 'order_order', count(*) FROM order_order
UNION ALL SELECT 'order_line', count(*) FROM order_line
UNION ALL SELECT 'basket_basket', count(*) FROM basket_basket
UNION ALL SELECT 'partner_partner', count(*) FROM partner_partner
UNION ALL SELECT 'partner_stockrecord', count(*) FROM partner_stockrecord
UNION ALL SELECT 'payment_source', count(*) FROM payment_source
UNION ALL SELECT 'payment_transaction', count(*) FROM payment_transaction
UNION ALL SELECT 'voucher_voucher', count(*) FROM voucher_voucher
UNION ALL SELECT 'reviews_productreview', count(*) FROM reviews_productreview
ORDER BY entity;

-- 4. Order totals verification (MUST match pre-migration)
SELECT
    count(*) AS total_orders,
    sum(total_incl_tax) AS total_revenue,
    min(date_placed) AS first_order,
    max(date_placed) AS last_order
FROM order_order;

-- 5. Order status distribution (compare)
SELECT status, count(*) AS count
FROM order_order
GROUP BY status
ORDER BY count DESC;

-- 6. Product catalog integrity
SELECT
    count(*) AS total_products,
    count(DISTINCT product_class_id) AS product_classes
FROM catalogue_product;

-- 7. User counts preserved
SELECT
    count(*) AS total_users,
    count(CASE WHEN is_active THEN 1 END) AS active_users,
    count(CASE WHEN is_staff THEN 1 END) AS staff_users
FROM auth_user;

-- 8. Payment data integrity
SELECT
    count(*) AS total_transactions,
    count(DISTINCT source_id) AS unique_sources
FROM payment_transaction;

-- 9. Index verification
SELECT tablename, count(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 10. FK constraint count (match pre-migration)
SELECT count(*) AS fk_constraint_count
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY' AND table_schema = 'public';

-- 11. Performance baseline
EXPLAIN ANALYZE SELECT * FROM order_order WHERE date_placed > '2024-01-01' LIMIT 100;
EXPLAIN ANALYZE SELECT * FROM catalogue_product WHERE is_discountable = true LIMIT 100;

-- 12. Migration artifacts check
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%_tmp%' OR table_name LIKE '%_bak%')
ORDER BY table_name;

-- 13. Admin user accessible
SELECT id, username, is_active, is_superuser
FROM auth_user
WHERE is_superuser = true;

-- 14. Verify PostgreSQL version
SELECT version();
