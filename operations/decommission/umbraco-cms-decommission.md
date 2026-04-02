# Umbraco CMS Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Umbraco CMS |
| **Type** | Content Management System |
| **Language** | C# (.NET) |
| **Criticality** | Tier 2 |
| **Target Decommission Date** | [TBD] |
| **Modernized Replacement** | [Replacement System Name] |

---

## 1. Pre-Decommission Checklist

### 1.1 Stakeholder Approval

- [ ] System Owner sign-off obtained
- [ ] Business Unit (content team) approval
- [ ] ISSO security review completed
- [ ] Authorizing Official (AO) approval
- [ ] Change Advisory Board (CAB) approval

### 1.2 Replacement System Validation

- [ ] All content nodes migrated to replacement CMS
- [ ] Media library migrated
- [ ] Document types and templates replicated
- [ ] URL structure preserved or redirects configured
- [ ] Back office users migrated
- [ ] Custom property editors replicated
- [ ] Macro functionality migrated
- [ ] Member/user portal migrated (if applicable)
- [ ] UAT completed
- [ ] Parallel operation period completed (minimum 14 days)

### 1.3 Dependency Verification

- [ ] Content Delivery API consumers migrated
- [ ] External integrations updated
- [ ] Umbraco Forms data migrated
- [ ] Custom packages/plugins functionality replicated

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Content nodes | ~10K nodes | 3 years | Database backup |
| Media library | ~20 GB | 3 years | File archive |
| Member data | ~5K records | 3 years | Encrypted archive |
| Form submissions | ~50K records | 7 years | Database backup |
| Audit trail | ~5M records | 7 years | Immutable archive |
| NuCache data | N/A | Not required | N/A |

### 2.2 Archival Procedure

```bash
#!/bin/bash
ARCHIVE_DIR="/archive/umbraco"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# SQL Server database backup
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
    -Q "BACKUP DATABASE UmbracoDB TO DISK = '$ARCHIVE_DIR/umbraco_db_${TIMESTAMP}.bak'"

# Media files
tar czf "$ARCHIVE_DIR/umbraco_media_${TIMESTAMP}.tar.gz" /opt/umbraco/wwwroot/media/

# Configuration
tar czf "$ARCHIVE_DIR/umbraco_config_${TIMESTAMP}.tar.gz" \
    /opt/umbraco/appsettings.json \
    /opt/umbraco/umbraco/config/

# Checksums and encryption
cd "$ARCHIVE_DIR"
sha256sum *.bak *.tar.gz > manifest_${TIMESTAMP}.sha256
for f in *.bak *.tar.gz; do
    gpg --symmetric --cipher-algo AES256 --output "${f}.gpg" "$f" && rm "$f"
done
```

---

## 3. DNS/Routing Cutover

| Step | Action | Duration |
|------|--------|----------|
| 1 | Lower DNS TTL | 5 min |
| 2 | Configure 301 redirects for content URLs | 1 hour |
| 3 | Remove Umbraco from load balancer | 5 min |
| 4 | Update DNS records | 5 min |
| 5 | Verify redirects and SEO preservation | 2 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Set Umbraco to maintenance mode
2. Stop Kestrel/dotnet process
   └─> systemctl stop umbraco
3. Final database backup (SQL Server)
4. Stop SQL Server (if dedicated)
   └─> systemctl stop mssql-server
5. Disable all services
6. Clear NuCache data
7. Revoke network access
8. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] Umbraco back office no longer accessible
- [ ] Frontend content pages redirecting properly
- [ ] Replacement CMS serving all content
- [ ] Content Delivery API returning from replacement
- [ ] No 404 errors for migrated URLs
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Public content | 3 years | Agency policy |
| Member data (PII) | 3 years | Privacy Act |
| Form submissions | 7 years | Agency policy |
| Audit logs | 7 years | FISMA |
| System documentation | 3 years | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore SQL Server database from backup
2. Restore media files
3. Start Umbraco: systemctl start umbraco
4. Clear and rebuild NuCache
5. Update DNS/routing
6. Verify back office and frontend
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
