# DFe-NET Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | DFe-NET |
| **Type** | Fiscal Document Processing |
| **Language** | C# (.NET) |
| **Criticality** | Tier 2 (Regulatory Critical) |
| **Target Decommission Date** | [TBD] |
| **Modernized Replacement** | [Replacement System Name] |

---

## 1. Pre-Decommission Checklist

### 1.1 Stakeholder Approval

- [ ] System Owner sign-off obtained
- [ ] Finance/Accounting department approval
- [ ] Legal/Compliance team approval
- [ ] ISSO security review completed
- [ ] Authorizing Official (AO) approval
- [ ] Change Advisory Board (CAB) approval
- [ ] Fiscal authority notification (SEFAZ if applicable)

### 1.2 Replacement System Validation

- [ ] All fiscal document types supported by replacement
- [ ] Digital certificate signing operational on replacement
- [ ] SEFAZ communication tested and validated
- [ ] XML schema validation passing
- [ ] Document status tracking migrated
- [ ] Batch processing operational
- [ ] Rejection/correction workflows working
- [ ] All regulatory reporting functional
- [ ] UAT completed with finance team
- [ ] Fiscal authority acceptance confirmed
- [ ] Parallel operation period completed (minimum 60 days - regulatory)

### 1.3 Special Regulatory Considerations

- [ ] All pending fiscal documents processed and acknowledged
- [ ] No documents in "pending authorization" state
- [ ] All correction/cancellation requests completed
- [ ] Fiscal period alignment verified (do not decommission mid-period)
- [ ] Regulatory archive requirements met for all historical documents

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Fiscal documents (XML) | ~2M documents | 5-10 years (regulatory) | Encrypted archive |
| Digital signatures | ~2M signatures | Same as documents | Encrypted archive |
| Certificate history | ~100 records | 10 years | Encrypted archive |
| SEFAZ communication logs | ~5M records | 5 years | Immutable archive |
| Business partner data | ~50K records | 7 years | Encrypted archive |
| Audit trail | ~10M records | 7 years | Immutable archive |
| Batch processing history | ~100K records | 5 years | Database backup |

### 2.2 Regulatory Archive Requirements

```
CRITICAL: Fiscal document retention is MANDATORY by law.
- All signed XML documents must be preserved in original format
- Digital signatures must remain verifiable
- Certificates used for signing must be archived
- SEFAZ authorization codes must be preserved
- Archive must be tamper-evident (hash chains recommended)
```

### 2.3 Archival Procedure

```bash
#!/bin/bash
ARCHIVE_DIR="/archive/dfe-net"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# SQL Server database backup
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
    -Q "BACKUP DATABASE DfeNetDB TO DISK = '$ARCHIVE_DIR/dfenet_db_${TIMESTAMP}.bak'"

# XML fiscal documents archive
tar czf "$ARCHIVE_DIR/dfenet_documents_${TIMESTAMP}.tar.gz" /data/dfe-net/documents/

# Certificates archive (CRITICAL - maintain chain of trust)
tar czf "$ARCHIVE_DIR/dfenet_certificates_${TIMESTAMP}.tar.gz" /etc/dfe-net/certificates/

# SEFAZ communication logs
tar czf "$ARCHIVE_DIR/dfenet_sefaz_logs_${TIMESTAMP}.tar.gz" /var/log/dfe-net/sefaz/

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
| 2 | Update SEFAZ callback URLs to replacement | 30 min |
| 3 | Redirect API endpoints | 15 min |
| 4 | Remove DFe-NET from load balancer | 5 min |
| 5 | Update DNS records | 5 min |
| 6 | Verify fiscal document processing end-to-end | 2 hours |
| 7 | Monitor for processing errors | 24 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. CRITICAL: Verify NO pending documents awaiting authorization
2. CRITICAL: Verify NO pending correction/cancellation requests
3. Complete any in-progress batch processing
4. Stop document processing workers
   └─> systemctl stop dfe-net-worker
5. Stop API service
   └─> systemctl stop dfe-net
6. Final database backup
7. Export all certificates and revocation lists
8. Stop SQL Server (if dedicated)
9. Disable all services
10. Revoke SEFAZ credentials for old system
11. Revoke network access
12. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] DFe-NET endpoints no longer accessible
- [ ] Replacement system processing fiscal documents
- [ ] SEFAZ communication operational on replacement
- [ ] Digital signing working on replacement
- [ ] No pending documents in limbo
- [ ] Old certificates properly revoked
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Fiscal documents (signed XML) | 5-10 years | Fiscal regulations |
| Digital certificates | 10 years after expiration | Certificate policy |
| SEFAZ authorization records | 5 years | Fiscal regulations |
| Business partner data | 7 years | Agency policy |
| Audit logs | 7 years | FISMA |
| Tax-related records | 7 years | IRS/fiscal authority |

---

## 7. Rollback Procedures

```
1. Restore SQL Server database
2. Restore XML document archive
3. Reinstall/restore certificates
4. Start DFe-NET services
5. Re-register SEFAZ callback URLs
6. Update DNS/routing
7. Verify certificate signing operational
8. Process any queued documents
```

**Estimated rollback time**: 3-4 hours (certificate restoration is critical path)

**IMPORTANT**: Rollback must be tested before decommission window to ensure certificate trust chain is restorable.


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
