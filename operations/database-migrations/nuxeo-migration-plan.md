# Nuxeo Platform Database Migration Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Nuxeo Platform |
| **Source Database** | PostgreSQL 12.x |
| **Target Database** | PostgreSQL 14.x+ (modernized) |
| **Estimated Records** | ~10M+ across 100+ tables |
| **Estimated Duration** | 6-10 hours (database) + binary store |

---

## 1. Migration Strategy

### 1.1 Approach: VCS Storage Migration

Nuxeo uses a Visible Content Store (VCS) model where the database schema is auto-generated from document type definitions. Migration must preserve VCS metadata and binary references.

```
Phase 1: Schema and document type analysis (Week 1)
Phase 2: Binary store sync (Week 2 - incremental)
Phase 3: Database migration (Week 3)
Phase 4: Elasticsearch reindex (Week 4)
Phase 5: Validation and cutover (Weekend)
```

### 1.2 Key Challenges

| Challenge | Mitigation |
|-----------|-----------|
| VCS-generated schema | Dump full schema, don't regenerate |
| Binary store (BlobProvider) | Sync separately, preserve content hashes |
| Elasticsearch dependency | Reindex after migration |
| Document versioning (complex hierarchy) | Migrate hierarchy table with integrity |
| Full-text extraction data | Re-extract or migrate content column |
| Nuxeo Stream / Kafka offsets | Reset or migrate offsets |

### 1.3 Core Table Groups

| Table Group | Key Tables | Est. Records |
|-------------|-----------|--------------|
| Hierarchy | hierarchy, ancestors | ~5M |
| Document data | dublincore, common, uid | ~5M |
| Binary refs | content | ~2M |
| ACLs | acls, aclr, aclr_user | ~3M |
| Audit | nxp_logs, audit_log | ~5M |
| Directories | directories, users, groups | ~20K |
| Fulltext | fulltext | ~2M |
| Locks | locks | ~1K |

---

## 2. Pre-Migration Steps

1. Run pre-migration checks (see `nuxeo-pre-migration-checks.sql`)
2. Full database backup
3. Binary store inventory
4. Document Nuxeo Connect packages installed
5. Record Elasticsearch index settings
6. Test in staging

---

## 3. Migration Execution

### 3.1 Database Migration

```bash
#!/bin/bash
# Full dump/restore approach for Nuxeo VCS database
pg_dump -Fc -U nuxeo -d nuxeo_production -f nuxeo_full.dump
createdb -U nuxeo nuxeo_target
pg_restore -U nuxeo -d nuxeo_target --no-owner nuxeo_full.dump
```

### 3.2 Binary Store Migration

```bash
#!/bin/bash
# Nuxeo binary store uses content-addressable storage
# Files are stored by their digest hash
rsync -av --progress \
    /var/lib/nuxeo/binaries/data/ \
    /var/lib/nuxeo-new/binaries/data/

# Verify binary integrity
find /var/lib/nuxeo-new/binaries/data/ -type f | while read f; do
    expected_hash=$(basename "$f")
    actual_hash=$(sha256sum "$f" | awk '{print $1}')
    if [ "$expected_hash" != "$actual_hash" ]; then
        echo "MISMATCH: $f"
    fi
done
```

### 3.3 Elasticsearch Reindex

```bash
# After migration, trigger full reindex
curl -X POST "http://localhost:8080/nuxeo/site/automation/Elasticsearch.Index" \
    -H "Content-Type: application/json" \
    -u Administrator:password \
    -d '{"params": {"query": "SELECT ecm:uuid FROM Document"}}'
```

---

## 4. Post-Migration Validation

1. Run post-migration checks (see `nuxeo-post-migration-checks.sql`)
2. Verify document counts match
3. Test document download (binary retrieval)
4. Verify search (Elasticsearch)
5. Test permission model
6. Verify workflow execution
7. Check audit trail integrity

---

## 5. Rollback Plan

```
1. Stop Nuxeo on target
2. Revert nuxeo.conf database connection
3. Revert binary store path
4. Restart Nuxeo
5. Trigger Elasticsearch reindex against original
```
