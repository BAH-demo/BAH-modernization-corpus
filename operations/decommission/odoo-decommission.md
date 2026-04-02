# Odoo Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Odoo |
| **Type** | ERP System |
| **Language** | Python |
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
- [ ] Finance/Accounting department approval (ERP-critical)

### 1.2 Replacement System Validation

- [ ] All Odoo modules replicated in replacement system
- [ ] Accounting/financial data migrated and reconciled
- [ ] HR/employee records migrated
- [ ] CRM/contact data migrated
- [ ] Inventory/warehouse data migrated
- [ ] Custom module functionality replicated
- [ ] Report templates migrated
- [ ] Scheduled actions (cron jobs) migrated
- [ ] Email templates and automation transferred
- [ ] UAT completed by all business units
- [ ] Parallel operation period completed (minimum 30 days)
- [ ] Month-end/quarter-end close tested on replacement

### 1.3 Dependency Verification

- [ ] XML-RPC/JSON-RPC API consumers migrated
- [ ] External integrations (payment, shipping, etc.) updated
- [ ] Reporting/BI tools redirected
- [ ] POS terminals reconfigured (if applicable)
- [ ] E-commerce frontend redirected (if applicable)

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Partner/contact records (PII) | ~200K records | 7 years | Encrypted archive |
| Accounting entries | ~5M records | 7 years (fiscal) | Database dump |
| HR/employee records | ~5K records | 7 years | Encrypted archive |
| Inventory records | ~100K records | 7 years | Database dump |
| Sales orders | ~500K records | 7 years | Database dump |
| Purchase orders | ~200K records | 7 years | Database dump |
| Filestore (attachments) | ~100 GB | 7 years | Encrypted archive |
| Audit logs | ~20M records | 7 years | Immutable archive |
| Custom module data | Variable | 7 years | Database dump |

### 2.2 Archival Procedure

```bash
#!/bin/bash
# odoo-archive.sh

ARCHIVE_DIR="/archive/odoo"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# Database archive
pg_dump -Fc -U odoo -d odoo_production > "$ARCHIVE_DIR/odoo_db_${TIMESTAMP}.dump"

# Filestore archive
tar czf "$ARCHIVE_DIR/odoo_filestore_${TIMESTAMP}.tar.gz" /opt/odoo/.local/share/Odoo/filestore/

# Configuration archive
tar czf "$ARCHIVE_DIR/odoo_config_${TIMESTAMP}.tar.gz" \
    /etc/odoo/odoo.conf \
    /opt/odoo/custom-addons/

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
| 1 | Lower DNS TTL | 5 min |
| 2 | Update reverse proxy configuration | 15 min |
| 3 | Remove Odoo from load balancer | 5 min |
| 4 | Redirect XML-RPC/JSON-RPC endpoints | 15 min |
| 5 | Update DNS records | 5 min |
| 6 | Monitor for errors | 4 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Disable cron/scheduled actions in Odoo
   └─> Update ir.cron records: active = False

2. Set Odoo to maintenance mode
   └─> Enable maintenance page on reverse proxy

3. Wait for any running long-poll/cron to complete

4. Stop Odoo workers
   └─> systemctl stop odoo

5. Final database backup
   └─> pg_dump -Fc odoo_production > odoo_shutdown_final.dump

6. Stop PostgreSQL (if dedicated)
   └─> systemctl stop postgresql

7. Stop Redis (if used for sessions)
   └─> systemctl stop redis

8. Disable all services
   └─> systemctl disable odoo

9. Revoke network access
10. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] Odoo web interface no longer accessible
- [ ] XML-RPC/JSON-RPC endpoints returning redirect or 404
- [ ] Replacement system handling all ERP functions
- [ ] Financial reports generating correctly on replacement
- [ ] No orphaned cron jobs running
- [ ] POS terminals connected to replacement (if applicable)
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Financial/accounting records | 7 years | 31 U.S.C. § 3512 |
| Employee records (PII) | 7 years after separation | 5 U.S.C. § 552a |
| Tax records | 7 years | IRS requirements |
| Procurement records | 6 years | FAR 4.705 |
| Audit logs | 7 years | FISMA |
| System documentation | 3 years post-decommission | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore PostgreSQL database from final backup
2. Restore filestore from archive
3. Start Odoo: systemctl start odoo
4. Re-enable cron jobs in database
5. Update DNS/routing
6. Verify all modules operational
7. Run accounting reconciliation check
```

**Estimated rollback time**: 2-4 hours
