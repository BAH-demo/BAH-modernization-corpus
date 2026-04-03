# Umbraco CMS Database Migration Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Umbraco CMS |
| **Source Database** | SQL Server 2019 |
| **Target Database** | SQL Server 2022 or PostgreSQL 14.x+ |
| **Estimated Records** | ~2M+ across 80+ tables |
| **Estimated Duration** | 4-6 hours (full migration) |

---

## 1. Migration Strategy

### 1.1 Approach: SQL Server to SQL Server (or Cross-Platform)

Two migration paths available:
- **Path A**: SQL Server 2019 → SQL Server 2022 (simpler, native backup/restore)
- **Path B**: SQL Server → PostgreSQL (requires schema conversion)

```
Phase 1: Schema analysis and Umbraco version verification (Week 1)
Phase 2: Media file sync (Week 2)
Phase 3: Database migration (Week 2-3)
Phase 4: NuCache rebuild (Week 3)
Phase 5: Validation and cutover (Weekend)
```

### 1.2 Key Challenges

| Challenge | Mitigation |
|-----------|-----------|
| Umbraco-managed schema | Use Umbraco migrations, not raw DDL |
| NuCache (denormalized cache) | Rebuild after migration |
| Property data (complex JSON/XML) | Preserve exactly as-is |
| Media files on disk | Sync separately |
| Examine indexes (Lucene) | Rebuild after migration |
| Cross-platform types (if PostgreSQL) | Map SQL Server types carefully |

### 1.3 Core Table Groups

| Table Group | Key Tables | Est. Records |
|-------------|-----------|--------------|
| Content | umbracoNode, umbracoContent, umbracoContentVersion | ~500K |
| Document | umbracoDocument, umbracoDocumentCultureVariation | ~100K |
| Property | umbracoPropertyData, cmsPropertyType, cmsPropertyTypeGroup | ~1M |
| Media | umbracoMediaVersion, cmsContentType2ContentType | ~50K |
| User | umbracoUser, umbracoUserGroup, umbracoUser2UserGroup | ~5K |
| Relations | umbracoRelation, umbracoRelationType | ~50K |
| Audit | umbracoAudit, umbracoLog | ~200K |
| Cache | cmsContentNu (NuCache) | ~100K |
| Dictionary | cmsDictionary, cmsLanguageText | ~10K |

### 1.4 Data Type Mapping (SQL Server → PostgreSQL, if applicable)

| SQL Server Type | PostgreSQL Type |
|----------------|-----------------|
| UNIQUEIDENTIFIER | UUID |
| NVARCHAR(n) | VARCHAR(n) |
| NTEXT | TEXT |
| DATETIME | TIMESTAMPTZ |
| BIT | BOOLEAN |
| IMAGE | BYTEA |
| INT IDENTITY | SERIAL |
| NVARCHAR(MAX) | TEXT |

---

## 2. Pre-Migration Steps

1. Run pre-migration checks (see `umbraco-cms-pre-migration-checks.sql`)
2. Full database backup (SQL Server `.bak`)
3. Document Umbraco version and installed packages
4. Record content tree structure
5. Inventory media files
6. Test in staging environment

---

## 3. Migration Execution

### 3.1 Path A: SQL Server to SQL Server

```sql
-- Backup source
BACKUP DATABASE UmbracoDB
TO DISK = '/backup/umbraco_pre_migration.bak'
WITH FORMAT, COMPRESSION;

-- Restore to target instance
RESTORE DATABASE UmbracoDB
FROM DISK = '/backup/umbraco_pre_migration.bak'
WITH MOVE 'UmbracoDB' TO '/data/UmbracoDB.mdf',
     MOVE 'UmbracoDB_log' TO '/data/UmbracoDB_log.ldf',
     RECOVERY;

-- Update compatibility level if upgrading
ALTER DATABASE UmbracoDB SET COMPATIBILITY_LEVEL = 160;  -- SQL Server 2022
```

### 3.2 Path B: SQL Server to PostgreSQL

```bash
#!/bin/bash
# Use pgloader for cross-platform migration
pgloader mssql://sa:password@source/UmbracoDB \
         pgsql://umbraco:password@target/umbraco_target

# Or use custom ETL scripts for more control
# Export from SQL Server
bcp "SELECT * FROM umbracoNode" queryout /tmp/nodes.csv -c -t'|' -S source -U sa
# Import to PostgreSQL
psql -U umbraco -d umbraco_target -c "\COPY umbraco_node FROM '/tmp/nodes.csv' DELIMITER '|'"
```

### 3.3 Media File Migration

```bash
rsync -av --progress /opt/umbraco/wwwroot/media/ /opt/umbraco-new/wwwroot/media/
```

### 3.4 Post-Migration NuCache Rebuild

```bash
# Delete NuCache data to force rebuild
# Umbraco will rebuild NuCache on next startup
rm -f /opt/umbraco/umbraco/Data/NuCache.*

# Or via SQL (truncate NuCache table)
# SQL Server:
# TRUNCATE TABLE cmsContentNu
# PostgreSQL:
# TRUNCATE TABLE cms_content_nu
```

---

## 4. Post-Migration Validation

1. Run post-migration checks (see `umbraco-cms-post-migration-checks.sql`)
2. Start Umbraco and verify startup logs
3. Login to back office
4. Verify content tree navigation
5. Preview content pages
6. Test media library
7. Verify member/user access
8. Test form submissions
9. Run Examine index rebuild from back office

---

## 5. Rollback Plan

### SQL Server to SQL Server
```
1. Restore from pre-migration .bak file
2. Update connection string
3. Restart Umbraco
```

### SQL Server to PostgreSQL
```
1. Revert connection string to SQL Server
2. Restart Umbraco
3. Verify NuCache regeneration
```
