-- ============================================================
-- Django Oscar Pre-Migration Validation Queries
-- Run against SOURCE database before migration
-- ============================================================

-- 1. Database overview
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Django migration state
SELECT app, name, applied
FROM django_migrations
ORDER BY app, name;

-- 3. Critical table row counts
SELECT 'auth_user' AS entity, count(*) AS row_count FROM auth_user
UNION ALL SELECT 'catalogue_product', count(*) FROM catalogue_product
UNION ALL SELECT 'catalogue_productcategory', count(*) FROM catalogue_productcategory
UNION ALL SELECT 'catalogue_category', count(*) FROM catalogue_category
UNION ALL SELECT 'catalogue_productimage', count(*) FROM catalogue_productimage
UNION ALL SELECT 'order_order', count(*) FROM order_order
UNION ALL SELECT 'order_line', count(*) FROM order_line
UNION ALL SELECT 'basket_basket', count(*) FROM basket_basket
UNION ALL SELECT 'basket_line', count(*) FROM basket_line
UNION ALL SELECT 'partner_partner', count(*) FROM partner_partner
UNION ALL SELECT 'partner_stockrecord', count(*) FROM partner_stockrecord
UNION ALL SELECT 'payment_source', count(*) FROM payment_source
UNION ALL SELECT 'payment_transaction', count(*) FROM payment_transaction
UNION ALL SELECT 'voucher_voucher', count(*) FROM voucher_voucher
UNION ALL SELECT 'reviews_productreview', count(*) FROM reviews_productreview
UNION ALL SELECT 'wishlists_wishlist', count(*) FROM wishlists_wishlist
ORDER BY entity;

-- 4. Order statistics
SELECT
    'order_stats' AS check_name,
    count(*) AS total_orders,
    count(DISTINCT user_id) AS unique_customers,
    sum(total_incl_tax) AS total_revenue,
    min(date_placed) AS first_order,
    max(date_placed) AS last_order
FROM order_order;

-- 5. Order status distribution
SELECT status, count(*) AS count
FROM order_order
GROUP BY status
ORDER BY count DESC;

-- 6. Product catalog statistics
SELECT
    'catalog_stats' AS check_name,
    count(*) AS total_products,
    count(CASE WHEN is_discountable THEN 1 END) AS discountable,
    count(DISTINCT product_class_id) AS product_classes
FROM catalogue_product;

-- 7. Payment data summary (PCI-sensitive)
SELECT
    'payment_summary' AS check_name,
    count(*) AS total_transactions,
    count(DISTINCT source_id) AS unique_sources
FROM payment_transaction;

-- 8. User statistics
SELECT
    count(*) AS total_users,
    count(CASE WHEN is_active THEN 1 END) AS active_users,
    count(CASE WHEN is_staff THEN 1 END) AS staff_users,
    count(CASE WHEN is_superuser THEN 1 END) AS superusers
FROM auth_user;

-- 9. Session data (can be discarded)
SELECT
    'session_data' AS check_name,
    count(*) AS total_sessions,
    count(CASE WHEN expire_date > NOW() THEN 1 END) AS active_sessions
FROM django_session;

-- 10. Celery task results (can be purged)
SELECT count(*) AS pending_tasks
FROM django_celery_results_taskresult
WHERE status = 'PENDING';

-- 11. Top 20 largest tables
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_live_tup AS row_count
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- 12. Foreign key inventory
SELECT count(*) AS fk_constraint_count
FROM information_schema.table_constraints
WHERE constraint_type = 'FOREIGN KEY' AND table_schema = 'public';

-- 13. Database encoding
SELECT datname, encoding, datcollate, datctype
FROM pg_database WHERE datname = current_database();
