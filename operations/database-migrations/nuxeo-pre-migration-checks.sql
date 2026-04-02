-- ============================================================
-- Nuxeo Platform Pre-Migration Validation Queries
-- Run against SOURCE database before migration
-- ============================================================

-- 1. Database overview
SELECT
    current_database() AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size,
    (SELECT count(*) FROM information_schema.tables
     WHERE table_schema = 'public') AS table_count;

-- 2. Document hierarchy counts
SELECT
    'total_documents' AS metric,
    count(*) AS value
FROM hierarchy
WHERE isproperty = false;

-- 3. Documents by primary type
SELECT primarytype, count(*) AS doc_count
FROM hierarchy
WHERE isproperty = false
GROUP BY primarytype
ORDER BY doc_count DESC
LIMIT 20;

-- 4. Version count
SELECT
    'total_versions' AS metric,
    count(*) AS value
FROM hierarchy
WHERE isversion = true;

-- 5. Critical table row counts
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

-- 6. Binary content statistics
SELECT
    count(*) AS total_content_refs,
    count(DISTINCT data) AS unique_binaries,
    pg_size_pretty(sum(length)) AS total_content_size
FROM content
WHERE data IS NOT NULL;

-- 7. ACL statistics
SELECT
    (SELECT count(*) FROM acls) AS total_acls,
    (SELECT count(*) FROM aclr) AS total_aclr,
    (SELECT count(DISTINCT id) FROM aclr) AS unique_acl_ids;

-- 8. Audit log size
SELECT
    count(*) AS total_entries,
    min(log_date) AS earliest_entry,
    max(log_date) AS latest_entry
FROM nxp_logs;

-- 9. Repository statistics
SELECT
    count(*) AS total_nodes,
    count(CASE WHEN isproperty = false THEN 1 END) AS documents,
    count(CASE WHEN isproperty = true THEN 1 END) AS properties,
    count(CASE WHEN isversion = true THEN 1 END) AS versions
FROM hierarchy;

-- 10. Directory (user/group) counts
SELECT 'users' AS directory, count(*) FROM users
UNION ALL SELECT 'groups', count(*) FROM groups;

-- 11. Top 20 largest tables
SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    n_live_tup AS row_count
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 20;

-- 12. Fulltext index status
SELECT
    count(*) AS total_fulltext_entries,
    count(CASE WHEN fulltext IS NOT NULL THEN 1 END) AS indexed_entries
FROM fulltext;

-- 13. Database encoding
SELECT datname, encoding, datcollate, datctype
FROM pg_database WHERE datname = current_database();

-- 14. Check for orphaned hierarchy entries
SELECT 'orphaned_hierarchy' AS check_name, count(*)
FROM hierarchy h
LEFT JOIN hierarchy p ON h.parentid = p.id
WHERE h.parentid IS NOT NULL AND p.id IS NULL AND h.isproperty = false;
