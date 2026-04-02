-- ============================================================
-- Umbraco CMS Pre-Migration Validation Queries
-- Run against SOURCE database (SQL Server) before migration
-- ============================================================

-- 1. Database overview
SELECT
    DB_NAME() AS database_name,
    (SELECT CAST(SUM(size) * 8.0 / 1024 AS DECIMAL(10,2))
     FROM sys.database_files) AS size_mb,
    (SELECT count(*) FROM sys.tables) AS table_count;

-- 2. Umbraco version (from migration state)
SELECT TOP 1 [version]
FROM umbracoKeyValue
WHERE [key] = 'Umbraco.Core.Upgrader.State+Umbraco.Core'
ORDER BY [key];

-- 3. Content node counts
SELECT
    (SELECT count(*) FROM umbracoNode) AS total_nodes,
    (SELECT count(*) FROM umbracoNode WHERE nodeObjectType = 'C66BA18E-EAF3-4CFF-8A22-41B16D66A972') AS documents,
    (SELECT count(*) FROM umbracoNode WHERE nodeObjectType = 'B796F64C-1F99-4FFB-B886-4BF4BC011A9C') AS media,
    (SELECT count(*) FROM umbracoNode WHERE nodeObjectType = '39EB0F98-B348-42A1-8662-E7EB18487560') AS media_types;

-- 4. Content by document type
SELECT ct.alias AS content_type, count(c.nodeId) AS count
FROM umbracoContent c
JOIN cmsContentType ct ON c.contentTypeId = ct.nodeId
GROUP BY ct.alias
ORDER BY count DESC;

-- 5. Critical table row counts
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
UNION ALL SELECT 'cmsContentNu', count(*) FROM cmsContentNu
ORDER BY table_name;

-- 6. Published content status
SELECT
    (SELECT count(*) FROM umbracoDocument WHERE published = 1) AS published_docs,
    (SELECT count(*) FROM umbracoDocument WHERE published = 0) AS unpublished_docs;

-- 7. User/group inventory
SELECT u.id, u.userLogin, u.userName, u.userEmail, u.userDisabled
FROM umbracoUser u
ORDER BY u.id;

-- 8. Language configuration
SELECT id, languageISOCode, languageCultureName, isDefaultVariantLang
FROM umbracoLanguage
ORDER BY id;

-- 9. Property data type distribution
SELECT d.editorAlias, count(*) AS property_count
FROM cmsPropertyType pt
JOIN umbracoDataType d ON pt.dataTypeId = d.nodeId
GROUP BY d.editorAlias
ORDER BY property_count DESC;

-- 10. Top 20 largest tables
SELECT TOP 20
    t.name AS table_name,
    CAST(SUM(a.total_pages) * 8.0 / 1024 AS DECIMAL(10,2)) AS size_mb,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY size_mb DESC;

-- 11. Index inventory
SELECT
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL
ORDER BY t.name, i.name;

-- 12. Media file references count
SELECT count(*) AS media_file_count
FROM umbracoMediaVersion;

-- 13. Relation types
SELECT id, name, alias, parentObjectType, childObjectType
FROM umbracoRelationType;

-- 14. Check database compatibility level
SELECT name, compatibility_level
FROM sys.databases
WHERE name = DB_NAME();
