-- ============================================================
-- Alfresco Community Post-Migration Validation Queries
-- Run against TARGET database after migration
-- ============================================================

-- 1. Database size comparison
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Row count comparison (match pre-migration)
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

-- 3. Node counts by store (compare with pre-migration)
SELECT
    s.protocol, s.identifier,
    count(n.id) AS node_count
FROM alf_store s
LEFT JOIN alf_node n ON n.store_id = s.id
GROUP BY s.protocol, s.identifier
ORDER BY node_count DESC;

-- 4. Content store integrity
SELECT
    count(*) AS total_content_urls,
    count(DISTINCT content_url) AS unique_urls,
    pg_size_pretty(sum(content_size)) AS total_content_size
FROM alf_content_url;

-- 5. Applied patches preserved
SELECT count(*) AS patch_count,
       max(applied_on_date) AS latest_patch
FROM alf_applied_patch;

-- 6. ACL integrity
SELECT
    (SELECT count(*) FROM alf_access_control_list) AS total_acls,
    (SELECT count(*) FROM alf_access_control_entry) AS total_aces,
    (SELECT count(*) FROM alf_authority) AS total_authorities;

-- 7. Transaction continuity
SELECT
    min(id) AS min_txn_id,
    max(id) AS max_txn_id,
    count(*) AS total_transactions
FROM alf_transaction;

-- 8. Verify indexes exist
SELECT tablename, count(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 9. Check for orphaned references
SELECT 'orphaned_child_assocs' AS check_name, count(*)
FROM alf_child_assoc ca
LEFT JOIN alf_node n ON ca.child_node_id = n.id
WHERE n.id IS NULL;

SELECT 'orphaned_content_refs' AS check_name, count(*)
FROM alf_content_data cd
LEFT JOIN alf_content_url cu ON cd.content_url_id = cu.id
WHERE cu.id IS NULL;

-- 10. Performance baseline
EXPLAIN ANALYZE
SELECT n.id, np.string_value
FROM alf_node n
JOIN alf_node_properties np ON np.node_id = n.id
WHERE n.type_qname_id = (SELECT id FROM alf_qname WHERE local_name = 'content')
LIMIT 100;

-- 11. Verify PostgreSQL version
SELECT version();
