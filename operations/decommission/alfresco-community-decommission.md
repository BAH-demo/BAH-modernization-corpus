# Alfresco Community Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Alfresco Community |
| **Type** | Enterprise Content Management (ECM) |
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
- [ ] Records Management Officer approval (critical for ECM)

### 1.2 Replacement System Validation

- [ ] Modernized system fully operational and tested
- [ ] All Alfresco content migrated to replacement system
- [ ] Document metadata and permissions preserved
- [ ] Workflow definitions migrated
- [ ] Search functionality verified in replacement
- [ ] User acceptance testing (UAT) completed
- [ ] Security authorization (ATO) obtained for replacement
- [ ] Parallel operation period completed (minimum 30 days)

### 1.3 Content Migration Verification

- [ ] Total document count matches between systems
- [ ] Folder structure integrity verified
- [ ] Document versions preserved
- [ ] Metadata fields mapped and verified
- [ ] Permission/access controls replicated
- [ ] Content types and models migrated
- [ ] Audit trail preserved or archived

### 1.4 Dependency Verification

- [ ] All CMIS/REST API consumers migrated
- [ ] Share sites content migrated
- [ ] Workflow integrations transferred
- [ ] External system integrations updated
- [ ] Email integration (inbound/outbound) redirected

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention Requirement | Archive Method |
|--------------|--------|----------------------|----------------|
| Document content (content store) | ~500 GB | Per document classification | Encrypted archive |
| Document metadata | ~5M records | Same as content | Database dump |
| Document versions | ~15M records | Same as content | Database + content archive |
| User/group data | ~10K records | 3 years | Encrypted archive |
| Workflow data | ~100K instances | 7 years | Database dump |
| Audit logs | ~50M records | 7 years (NARA) | Immutable archive |
| Site configurations | ~500 sites | 3 years | Export/archive |
| Solr search index | ~20 GB | Not required (rebuildable) | N/A |

### 2.2 Content Store Archival

```bash
#!/bin/bash
# alfresco-content-archive.sh

CONTENT_STORE="/opt/alfresco/alf_data/contentstore"
ARCHIVE_DIR="/archive/alfresco"
TIMESTAMP=$(date +%Y%m%d)

# Archive content store
echo "Archiving Alfresco content store..."
tar czf "$ARCHIVE_DIR/contentstore_${TIMESTAMP}.tar.gz" "$CONTENT_STORE"

# Archive database
echo "Archiving Alfresco database..."
pg_dump -Fc -U alfresco -d alfresco_production > "$ARCHIVE_DIR/alfresco_db_${TIMESTAMP}.dump"

# Archive configuration
echo "Archiving configuration..."
tar czf "$ARCHIVE_DIR/alfresco_config_${TIMESTAMP}.tar.gz" \
    /opt/alfresco/tomcat/shared/classes/alfresco-global.properties \
    /opt/alfresco/tomcat/shared/classes/alfresco/ \
    /opt/alfresco/modules/

# Generate manifest
echo "Generating manifest..."
cd "$ARCHIVE_DIR"
sha256sum *.tar.gz *.dump > manifest_${TIMESTAMP}.sha256

# Encrypt archives
for f in *.tar.gz *.dump; do
    gpg --symmetric --cipher-algo AES256 --output "${f}.gpg" "$f"
    rm "$f"
done

echo "Archive complete: $ARCHIVE_DIR"
```

---

## 3. DNS/Routing Cutover

### 3.1 Cutover Steps

| Step | Action | Responsible | Duration |
|------|--------|-------------|----------|
| 1 | Lower DNS TTL to 60s (48 hours before) | Network Team | 5 min |
| 2 | Configure replacement system endpoints | Network Team | 15 min |
| 3 | Update load balancer for Alfresco Repository | Network Team | 10 min |
| 4 | Update load balancer for Alfresco Share | Network Team | 10 min |
| 5 | Remove Alfresco from load balancer pools | Network Team | 5 min |
| 6 | Update DNS records | Network Team | 5 min |
| 7 | Verify CMIS API endpoint redirect | Operations | 30 min |
| 8 | Monitor for errors | Operations | 4 hours |
| 9 | Restore DNS TTL | Network Team | 5 min |

---

## 4. Legacy System Shutdown Sequence

### 4.1 Multi-Component Shutdown Order

```
1. Disable external access
   └─> Remove from load balancer
   └─> Block ports 8080, 8443 at firewall

2. Stop Alfresco Share (UI layer)
   └─> systemctl stop alfresco-share

3. Stop Alfresco Repository (application layer)
   └─> /opt/alfresco/tomcat/bin/shutdown.sh
   └─> systemctl stop alfresco

4. Stop Solr 6 (search)
   └─> /opt/alfresco/solr6/solr/bin/solr stop
   └─> systemctl stop alfresco-solr

5. Stop ActiveMQ (messaging)
   └─> /opt/alfresco/activemq/bin/activemq stop
   └─> systemctl stop activemq

6. Take final database backup
   └─> pg_dump -Fc alfresco_production > alfresco_final.dump

7. Stop PostgreSQL (if dedicated)
   └─> systemctl stop postgresql

8. Disable all auto-start services
   └─> systemctl disable alfresco alfresco-share alfresco-solr activemq

9. Archive server filesystem
   └─> Backup /opt/alfresco/ completely
   └─> Backup /etc/ relevant configs

10. Revoke network access and power down
```

---

## 5. Post-Decommission Validation

- [ ] All Alfresco services no longer accessible
- [ ] CMIS endpoints return appropriate redirect or 404
- [ ] All DNS records updated
- [ ] No orphaned ActiveMQ queues
- [ ] Replacement system serving all content correctly
- [ ] Search functionality working on replacement
- [ ] Document download/preview working
- [ ] Workflow engine operational on replacement
- [ ] Monitoring alerts removed/updated

---

## 6. Data Retention Compliance

### 6.1 Federal Records Requirements

| Record Type | Retention Period | Authority | Disposition |
|-------------|-----------------|-----------|-------------|
| Government documents | Per NARA schedule | 44 U.S.C. Chapter 31 | Per records schedule |
| PII-containing documents | 7 years or per SORN | Privacy Act | Destroy per schedule |
| Audit/access logs | 7 years | FISMA | Destroy after retention |
| Email archives | Per agency policy | NARA GRS 6.1 | Per records schedule |
| System documentation | 3 years post-decommission | Agency policy | Destroy after retention |

### 6.2 Special Considerations for ECM

- Documents may have individual retention schedules based on classification
- Records Management Officer must approve destruction of any federal records
- NARA notification may be required for permanent records transfer
- Litigation hold documents must NOT be destroyed regardless of retention schedule

---

## 7. Rollback Procedures

### 7.1 Rollback Steps

```
1. Restore PostgreSQL database from final backup
2. Restore content store from archive
3. Restart components in order:
   PostgreSQL → ActiveMQ → Solr → Alfresco Repository → Alfresco Share
4. Rebuild Solr index (may take several hours for large content stores)
5. Update DNS/load balancer to route to Alfresco
6. Verify document access and search functionality
7. Notify stakeholders of rollback
```

### 7.2 Rollback Estimated Duration

| Phase | Duration |
|-------|----------|
| Database restore | 1-2 hours |
| Content store restore | 2-4 hours (depends on volume) |
| Service restart | 30 min |
| Solr reindex | 2-8 hours |
| Network cutover | 30 min |
| Validation | 2 hours |
| **Total** | **8-17 hours** |


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
