# Nuxeo Platform Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Nuxeo Platform |
| **Type** | Content Services Platform |
| **Language** | Java |
| **Criticality** | Tier 1 - Business Critical |
| **Target Decommission Date** | [TBD] |
| **Modernized Replacement** | [Replacement System Name] |

---

## 1. Pre-Decommission Checklist

### 1.1 Stakeholder Approval

- [ ] System Owner sign-off obtained
- [ ] Business Unit approval documented
- [ ] ISSO security review completed
- [ ] Authorizing Official (AO) approval
- [ ] Change Advisory Board (CAB) approval
- [ ] Records Management Officer approval

### 1.2 Replacement System Validation

- [ ] Modernized system fully operational
- [ ] All Nuxeo content migrated (documents, metadata, versions)
- [ ] Nuxeo Automation chains replicated in replacement
- [ ] Custom document types and schemas migrated
- [ ] ACLs and permission models transferred
- [ ] Nuxeo Drive sync clients migrated or replaced
- [ ] Rendition/preview pipelines operational in replacement
- [ ] User acceptance testing completed
- [ ] Parallel operation period completed (minimum 30 days)

### 1.3 Dependency Verification

- [ ] REST API consumers migrated
- [ ] Nuxeo Stream/Kafka consumers migrated
- [ ] External system integrations updated
- [ ] Bulk import processes redirected
- [ ] DAM workflows transferred

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Binary content (blob store) | ~1 TB | Per classification | Encrypted archive |
| Document metadata (PostgreSQL) | ~10M records | Same as content | Database dump |
| Elasticsearch index | ~50 GB | Not required | N/A (rebuildable) |
| Audit events | ~100M records | 7 years | Immutable archive |
| Workflow/task data | ~500K records | 7 years | Database dump |
| User/group directory | ~20K records | 3 years | Export/archive |
| Configuration (Nuxeo Studio) | N/A | 3 years | Git export |
| Redis cache | N/A | Not required | N/A |

### 2.2 Archival Procedure

```bash
#!/bin/bash
# nuxeo-archive.sh

ARCHIVE_DIR="/archive/nuxeo"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# Database archive
pg_dump -Fc -U nuxeo -d nuxeo_production > "$ARCHIVE_DIR/nuxeo_db_${TIMESTAMP}.dump"

# Binary store archive
tar czf "$ARCHIVE_DIR/nuxeo_binaries_${TIMESTAMP}.tar.gz" /var/lib/nuxeo/binaries/

# Configuration archive
tar czf "$ARCHIVE_DIR/nuxeo_config_${TIMESTAMP}.tar.gz" \
    /etc/nuxeo/nuxeo.conf \
    /opt/nuxeo/server/nxserver/config/ \
    /opt/nuxeo/server/templates/

# Nuxeo Studio project export
# (Export from Nuxeo Studio Designer before shutdown)

# Generate checksums and encrypt
cd "$ARCHIVE_DIR"
sha256sum *.tar.gz *.dump > manifest_${TIMESTAMP}.sha256
for f in *.tar.gz *.dump; do
    gpg --symmetric --cipher-algo AES256 --output "${f}.gpg" "$f" && rm "$f"
done
```

---

## 3. DNS/Routing Cutover

| Step | Action | Duration |
|------|--------|----------|
| 1 | Lower DNS TTL to 60s (48h before) | 5 min |
| 2 | Update reverse proxy for API endpoints | 15 min |
| 3 | Remove Nuxeo from load balancer | 5 min |
| 4 | Update DNS records | 5 min |
| 5 | Verify REST API redirect | 30 min |
| 6 | Monitor for errors | 4 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Stop Nuxeo Platform
   └─> nuxeoctl stop
   └─> systemctl stop nuxeo

2. Stop Elasticsearch (if dedicated)
   └─> systemctl stop elasticsearch

3. Stop Redis (if dedicated)
   └─> systemctl stop redis

4. Stop Kafka/Nuxeo Stream (if used)
   └─> systemctl stop kafka

5. Final database backup
   └─> pg_dump -Fc nuxeo_production > nuxeo_shutdown_final.dump

6. Stop PostgreSQL (if dedicated)
   └─> systemctl stop postgresql

7. Disable all services
   └─> systemctl disable nuxeo elasticsearch redis kafka

8. Revoke network access
9. Archive server filesystem
10. Power down
```

---

## 5. Post-Decommission Validation

- [ ] Nuxeo endpoints no longer accessible
- [ ] REST API returns redirect or 404
- [ ] Nuxeo Drive clients disconnected gracefully
- [ ] Replacement system handling all requests
- [ ] Content search functional on replacement
- [ ] Document previews/renditions working
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Government documents | Per NARA schedule | 44 U.S.C. Chapter 31 |
| PII-containing content | 7 years or per SORN | Privacy Act |
| Audit logs | 7 years | FISMA |
| Metadata records | Same as associated content | Agency policy |
| System configuration | 3 years post-decommission | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore PostgreSQL database
2. Restore binary store from archive
3. Restart: PostgreSQL → Redis → Elasticsearch → Kafka → Nuxeo
4. Trigger full Elasticsearch reindex: nuxeoctl reindex
5. Update DNS/routing
6. Verify content access and search
```

**Estimated rollback time**: 6-12 hours (binary store restore is the bottleneck)


## Decommission Timeline

| Phase | Duration | Activities | Exit Criteria |
|-------|----------|-----------|---------------|
| **Phase 1: Preparation** | Weeks 1-2 | Stakeholder notification, access audit, backup verification | All stakeholders acknowledged, backups validated |
| **Phase 2: Traffic Migration** | Weeks 3-4 | DNS cutover to modernized system, monitor error rates | Zero traffic to legacy system for 48 hours |
| **Phase 3: Read-Only Mode** | Weeks 5-6 | Disable write access, maintain read-only for audit trail | All data queries served by modernized system |
| **Phase 4: Shutdown** | Week 7 | Stop application services, revoke network access | All services stopped, no active connections |
| **Phase 5: Archive** | Week 8 | Final data export, archive to cold storage, documentation | Archive verified, retention policy applied |
| **Phase 6: Cleanup** | Weeks 9-10 | Remove infrastructure, decommission servers, close accounts | All resources released, cost savings confirmed |

### Key Milestones
- **T-30 days**: Stakeholder notification sent
- **T-14 days**: Final data backup completed and verified
- **T-7 days**: Read-only mode enabled
- **T-0**: Legacy system shutdown
- **T+7 days**: Post-shutdown verification complete
- **T+30 days**: Infrastructure cleanup complete
