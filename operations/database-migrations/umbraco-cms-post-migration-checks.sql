-- ============================================================
-- Umbraco CMS Post-Migration Validation Queries
-- Run against TARGET database after migration
-- ============================================================

-- 1. Database overview comparison
SELECT
    DB_NAME() AS database_name,
    (SELECT CAST(SUM(size) * 8.0 / 1024 AS DECIMAL(10,2))
     FROM sys.database_files) AS size_mb,
    (SELECT count(*) FROM sys.tables) AS table_count;

-- 2. Umbraco version preserved
SELECT TOP 1 [version]
FROM umbracoKeyValue
WHERE [key] = 'Umbraco.Core.Upgrader.State+Umbraco.Core';

-- 3. Row count comparison
SELECT 'umbracoNode' AS table_name, count(*) AS row_count FROM umbracoNode
UNION ALL SELECT 'umbracoContent', count(*) FROM umbracoContent
UNION ALL SELECT 'umbracoContentVersion', count(*) FROM umbracoContentVersion
UNION ALL SELECT 'umbracoDocument', count(*) FROM umbracoDocument
UNION ALL SELECT 'umbracoPropertyData', count(*) FROM umbracoPropertyData
UNION ALL SELECT 'cmsPropertyType', count(*) FROM cmsPropertyType
UNION ALL SELECT 'umbracoMediaVersion', count(*) FROM umbracoMediaVersion
UNION ALL SELECT 'umbracoUser', count(*) FROM umbracoUser
UNION ALL SELECT 'umbracoRelation', count(*) FROM umbracoRelation
UNION ALL SELECT 'umbracoAudit', count(*) FROM umbracoAudit
UNION ALL SELECT 'umbracoLog', count(*) FROM umbracoLog
ORDER BY table_name;

-- 4. Content node type distribution (compare with pre-migration)
SELECT ct.alias AS content_type, count(c.nodeId) AS count
FROM umbracoContent c
JOIN cmsContentType ct ON c.contentTypeId = ct.nodeId
GROUP BY ct.alias
ORDER BY count DESC;

-- 5. Published content verification
SELECT
    (SELECT count(*) FROM umbracoDocument WHERE published = 1) AS published_docs,
    (SELECT count(*) FROM umbracoDocument WHERE published = 0) AS unpublished_docs;

-- 6. User accounts preserved
SELECT id, userLogin, userName, userDisabled
FROM umbracoUser
ORDER BY id;

-- 7. Language configuration preserved
SELECT id, languageISOCode, languageCultureName
FROM umbracoLanguage
ORDER BY id;

-- 8. Property data integrity
SELECT d.editorAlias, count(*) AS property_count
FROM cmsPropertyType pt
JOIN umbracoDataType d ON pt.dataTypeId = d.nodeId
GROUP BY d.editorAlias
ORDER BY property_count DESC;

-- 9. Index verification
SELECT
    t.name AS table_name,
    count(*) AS index_count
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL
GROUP BY t.name
ORDER BY t.name;

-- 10. NuCache status (should be empty if rebuild needed)
SELECT count(*) AS nucache_entries FROM cmsContentNu;

-- 11. Relation integrity
SELECT count(*) AS total_relations FROM umbracoRelation;

-- 12. Migration artifacts check
SELECT name
FROM sys.tables
WHERE name LIKE '%_tmp%' OR name LIKE '%_bak%' OR name LIKE '%_migration%';

-- 13. Verify compatibility level
SELECT name, compatibility_level
FROM sys.databases
WHERE name = DB_NAME();

-- 14. Verify admin user accessible
SELECT id, userLogin, userName, userDisabled
FROM umbracoUser
WHERE id = -1;  -- Built-in admin
