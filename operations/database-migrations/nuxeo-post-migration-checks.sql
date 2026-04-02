-- ============================================================
-- Nuxeo Platform Post-Migration Validation Queries
-- Run against TARGET database after migration
-- ============================================================

-- 1. Database size comparison
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Row count comparison
SELECT 'hierarchy' AS table_name, count(*) AS row_count FROM hierarchy
UNION ALL SELECT 'dublincore', count(*) FROM dublincore
UNION ALL SELECT 'common', count(*) FROM common
UNION ALL SELECT 'content', count(*) FROM content
UNION ALL SELECT 'acls', count(*) FROM acls
UNION ALL SELECT 'aclr', count(*) FROM aclr
UNION ALL SELECT 'fulltext', count(*) FROM fulltext
UNION ALL SELECT 'locks', count(*) FROM locks
UNION ALL SELECT 'ancestors', count(*) FROM ancestors
ORDER BY table_name;

-- 3. Document count verification
SELECT
    'total_documents' AS metric,
    count(*) AS value
FROM hierarchy
WHERE isproperty = false;

-- 4. Documents by type (compare with pre-migration)
SELECT primarytype, count(*) AS doc_count
FROM hierarchy
WHERE isproperty = false
GROUP BY primarytype
ORDER BY doc_count DESC
LIMIT 20;

-- 5. Binary content integrity
SELECT
    count(*) AS total_content_refs,
    count(DISTINCT data) AS unique_binaries,
    pg_size_pretty(sum(length)) AS total_content_size
FROM content
WHERE data IS NOT NULL;

-- 6. ACL integrity
SELECT
    (SELECT count(*) FROM acls) AS total_acls,
    (SELECT count(*) FROM aclr) AS total_aclr;

-- 7. Audit log preserved
SELECT
    count(*) AS total_entries,
    min(log_date) AS earliest_entry,
    max(log_date) AS latest_entry
FROM nxp_logs;

-- 8. User/group counts preserved
SELECT 'users' AS directory, count(*) FROM users
UNION ALL SELECT 'groups', count(*) FROM groups;

-- 9. Orphaned references check
SELECT 'orphaned_hierarchy' AS check_name, count(*)
FROM hierarchy h
LEFT JOIN hierarchy p ON h.parentid = p.id
WHERE h.parentid IS NOT NULL AND p.id IS NULL AND h.isproperty = false;

-- 10. Performance baseline
EXPLAIN ANALYZE
SELECT h.id, d.title
FROM hierarchy h
JOIN dublincore d ON d.id = h.id
WHERE h.primarytype = 'File' AND h.isproperty = false
LIMIT 100;

-- 11. Index verification
SELECT tablename, count(*) AS index_count
FROM pg_indexes
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 12. Migration artifact check
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%_tmp%' OR table_name LIKE '%_bak%')
ORDER BY table_name;

-- 13. Verify PostgreSQL version
SELECT version();
