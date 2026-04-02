# CFWheels Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | CFWheels |
| **Type** | MVC Web Application Framework |
| **Language** | ColdFusion (CFML) |
| **Criticality** | Tier 2 |
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

### 1.2 Replacement System Validation

- [ ] All CFWheels application routes replicated
- [ ] Database schema migrated
- [ ] User accounts and authentication migrated
- [ ] File upload/download functionality working
- [ ] Custom business logic replicated
- [ ] URL structure preserved or redirects configured
- [ ] UAT completed
- [ ] Parallel operation period completed (minimum 14 days)

### 1.3 Dependency Verification

- [ ] API consumers migrated
- [ ] External integrations updated
- [ ] Scheduled tasks migrated
- [ ] Email templates transferred

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Application database | ~500K records | 7 years | Database dump |
| User accounts | ~5K records | 3 years | Encrypted archive |
| Uploaded files | ~10 GB | 3 years | File archive |
| Application source | ~15K LOC | Permanent (archive) | Git archive |
| Audit logs | ~5M records | 7 years | Immutable archive |
| Lucee/CF configuration | ~100 files | 3 years | File archive |

### 2.2 Archival Procedure

```bash
#!/bin/bash
ARCHIVE_DIR="/archive/cfwheels"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# Database archive (MySQL)
mysqldump -u cfwheels -p cfwheels_production > "$ARCHIVE_DIR/cfwheels_db_${TIMESTAMP}.sql"

# Application source and uploads
tar czf "$ARCHIVE_DIR/cfwheels_app_${TIMESTAMP}.tar.gz" /opt/lucee/web/cfwheels/
tar czf "$ARCHIVE_DIR/cfwheels_uploads_${TIMESTAMP}.tar.gz" /opt/lucee/web/cfwheels/uploads/

# Lucee configuration
tar czf "$ARCHIVE_DIR/cfwheels_lucee_config_${TIMESTAMP}.tar.gz" /opt/lucee/server/lucee-server/context/

# Checksums and encryption
cd "$ARCHIVE_DIR"
sha256sum *.sql *.tar.gz > manifest_${TIMESTAMP}.sha256
for f in *.sql *.tar.gz; do
    gpg --symmetric --cipher-algo AES256 --output "${f}.gpg" "$f" && rm "$f"
done
```

---

## 3. DNS/Routing Cutover

| Step | Action | Duration |
|------|--------|----------|
| 1 | Lower DNS TTL | 5 min |
| 2 | Configure URL redirects | 30 min |
| 3 | Remove CFWheels from load balancer | 5 min |
| 4 | Update DNS records | 5 min |
| 5 | Monitor for errors | 2 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Set application to maintenance mode
2. Stop Lucee/ColdFusion engine
   └─> systemctl stop lucee
   └─> (or) /opt/lucee/tomcat/bin/shutdown.sh
3. Final database backup
4. Stop MySQL (if dedicated)
   └─> systemctl stop mysql
5. Disable all services
6. Revoke network access
7. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] CFWheels application no longer accessible
- [ ] URL redirects working
- [ ] Replacement system serving all functionality
- [ ] No CFML engine processes running
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Application data | 7 years | Agency policy |
| User accounts | 3 years | Privacy Act |
| Audit logs | 7 years | FISMA |
| Source code | Permanent archive | Agency records policy |
| System documentation | 3 years | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore MySQL database from backup
2. Restart Lucee: systemctl start lucee
3. Deploy CFWheels application
4. Update DNS/routing
5. Verify application functionality
```

**Estimated rollback time**: 1-2 hours


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
