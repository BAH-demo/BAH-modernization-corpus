# Alfresco Community Database Migration Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Alfresco Community |
| **Source Database** | PostgreSQL 12.x |
| **Target Database** | PostgreSQL 14.x+ (modernized) |
| **Estimated Records** | ~15M+ across 200+ tables |
| **Estimated Duration** | 6-10 hours (database) + content store |

---

## 1. Migration Strategy

### 1.1 Approach: Multi-Component Migration

Alfresco has three data stores that must be migrated together:
1. **PostgreSQL database** - metadata, node properties, associations
2. **Content store** - binary files on filesystem
3. **Solr index** - can be rebuilt post-migration

```
Phase 1: Schema analysis and content store inventory (Week 1)
Phase 2: Content store sync (Week 2 - can run while live)
Phase 3: Database schema migration (Week 3)
Phase 4: Database data migration (Week 3-4)
Phase 5: Final content sync + cutover (Weekend window)
Phase 6: Solr reindex and validation (Week 5)
```

### 1.2 Key Challenges

| Challenge | Mitigation |
|-----------|-----------|
| Content store + DB must be consistent | Freeze writes during final sync |
| Node reference integrity | Migrate alf_node before associations |
| Content URL references | Preserve content store structure |
| Large binary content store | Rsync incremental during Phase 2 |
| Solr index rebuild time | Plan for 2-8 hours post-migration |
| ACL/permission entries | Migrate alf_access_control_* tables together |

### 1.3 Core Table Groups

| Table Group | Key Tables | Est. Records |
|-------------|-----------|--------------|
| Node store | alf_node, alf_node_properties, alf_child_assoc | ~5M |
| Content | alf_content_data, alf_content_url | ~2M |
| Permissions | alf_access_control_list, alf_access_control_entry, alf_authority | ~3M |
| Transactions | alf_transaction, alf_node_aspects | ~2M |
| Audit | alf_prop_*, alf_audit_* | ~3M |
| System | alf_applied_patch, alf_namespace, alf_qname | ~50K |

---

## 2. Pre-Migration Steps

1. Run pre-migration checks (see `alfresco-community-pre-migration-checks.sql`)
2. Full database backup
3. Content store inventory: count files, total size
4. Document applied patches (alf_applied_patch)
5. Record content store structure
6. Verify Alfresco version compatibility
7. Test in staging with representative data subset

---

## 3. Migration Execution

### 3.1 Database Migration

```bash
#!/bin/bash
# Alfresco database migration

# Full dump (recommended for consistency)
pg_dump -Fc -U alfresco -d alfresco_production -f alfresco_full.dump

# Restore to target
createdb -U alfresco alfresco_target
pg_restore -U alfresco -d alfresco_target --no-owner alfresco_full.dump

# Apply modernization patches
psql -U alfresco -d alfresco_target -f alfresco_modernization.sql
```

### 3.2 Content Store Migration

```bash
#!/bin/bash
# Incremental content store sync (run multiple times before cutover)
rsync -av --progress \
    /opt/alfresco/alf_data/contentstore/ \
    /opt/alfresco-new/alf_data/contentstore/

# Deleted content store (optional - for trash recovery)
rsync -av --progress \
    /opt/alfresco/alf_data/contentstore.deleted/ \
    /opt/alfresco-new/alf_data/contentstore.deleted/

# Final sync during cutover window (with --delete for consistency)
rsync -av --delete --progress \
    /opt/alfresco/alf_data/contentstore/ \
    /opt/alfresco-new/alf_data/contentstore/
```

### 3.3 Post-Restore Index Rebuild

```bash
# After database and content store are migrated:
# 1. Start Alfresco against new database
# 2. Trigger full Solr reindex
curl -X POST "http://localhost:8983/solr/admin/cores?action=purge&core=alfresco"
curl -X POST "http://localhost:8983/solr/admin/cores?action=purge&core=archive"
# Reindex will happen automatically on next tracking cycle
```

---

## 4. Post-Migration Validation

1. Run post-migration checks (see `alfresco-community-post-migration-checks.sql`)
2. Verify node counts match
3. Verify content is accessible (download sample documents)
4. Verify search returns results (after reindex)
5. Verify permission model intact
6. Test admin console access
7. Verify Share sites accessible

---

## 5. Rollback Plan

```
1. Stop Alfresco on target
2. Revert alfresco-global.properties to point to source DB
3. Revert dir.contentstore to source content store
4. Restart Alfresco against original data
```
