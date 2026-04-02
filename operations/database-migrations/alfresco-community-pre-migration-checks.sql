-- ============================================================
-- Alfresco Community Pre-Migration Validation Queries
-- Run against SOURCE database before migration
-- ============================================================

-- 1. Database overview
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Alfresco version / applied patches
SELECT id, description, fix_from_schema, fix_to_schema, applied_to_schema,
       applied_on_date, applied_to_server, was_executed, succeeded
FROM alf_applied_patch
ORDER BY applied_on_date DESC
LIMIT 20;

-- 3. Node counts by store
SELECT
    s.protocol, s.identifier,
    count(n.id) AS node_count
FROM alf_store s
LEFT JOIN alf_node n ON n.store_id = s.id
GROUP BY s.protocol, s.identifier
ORDER BY node_count DESC;

-- 4. Node counts by type
SELECT
    q.local_name AS node_type,
    count(*) AS node_count
FROM alf_node n
JOIN alf_qname q ON n.type_qname_id = q.id
GROUP BY q.local_name
ORDER BY node_count DESC
LIMIT 20;

-- 5. Content store references
SELECT
    count(*) AS total_content_urls,
    count(DISTINCT content_url) AS unique_urls,
    pg_size_pretty(sum(content_size)) AS total_content_size
FROM alf_content_url;

-- 6. Critical table row counts
SELECT 'alf_node' AS table_name, count(*) AS row_count FROM alf_node
UNION ALL SELECT 'alf_node_properties', count(*) FROM alf_node_properties
UNION ALL SELECT 'alf_child_assoc', count(*) FROM alf_child_assoc
UNION ALL SELECT 'alf_node_assoc', count(*) FROM alf_node_assoc
UNION ALL SELECT 'alf_content_data', count(*) FROM alf_content_data
UNION ALL SELECT 'alf_content_url', count(*) FROM alf_content_url
UNION ALL SELECT 'alf_access_control_list', count(*) FROM alf_access_control_list
UNION ALL SELECT 'alf_access_control_entry', count(*) FROM alf_access_control_entry
UNION ALL SELECT 'alf_authority', count(*) FROM alf_authority
UNION ALL SELECT 'alf_transaction', count(*) FROM alf_transaction
UNION ALL SELECT 'alf_audit_entry', count(*) FROM alf_audit_entry
ORDER BY table_name;

-- 7. Permission / ACL statistics
SELECT
    'acl_stats' AS check_name,
    (SELECT count(*) FROM alf_access_control_list) AS total_acls,
    (SELECT count(*) FROM alf_access_control_entry) AS total_aces,
    (SELECT count(*) FROM alf_authority) AS total_authorities;

-- 8. Transaction log range
SELECT
    min(id) AS min_txn_id,
    max(id) AS max_txn_id,
    count(*) AS total_transactions,
    min(commit_time_ms) AS earliest_commit,
    max(commit_time_ms) AS latest_commit
FROM alf_transaction;

-- 9. Property value types distribution
SELECT
    actual_type, count(*) AS count
FROM alf_node_properties
GROUP BY actual_type
ORDER BY count DESC;

-- 10. Top 20 largest tables
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_live_tup AS row_count
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- 11. Index inventory
SELECT tablename, indexname, pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexname::regclass) DESC
LIMIT 30;

-- 12. Check for orphaned nodes
SELECT 'orphaned_child_assocs' AS check_name, count(*)
FROM alf_child_assoc ca
LEFT JOIN alf_node n ON ca.child_node_id = n.id
WHERE n.id IS NULL;

-- 13. Database encoding
SELECT datname, encoding, datcollate, datctype
FROM pg_database WHERE datname = current_database();
