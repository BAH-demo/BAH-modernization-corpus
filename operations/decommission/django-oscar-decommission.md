# Django Oscar Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Django Oscar |
| **Type** | E-commerce Platform |
| **Language** | Python |
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
- [ ] PCI DSS compliance team approval (payment data)

### 1.2 Replacement System Validation

- [ ] Product catalog migrated to replacement
- [ ] Customer accounts and order history migrated
- [ ] Payment processing operational on replacement
- [ ] Shipping/fulfillment integrations working
- [ ] Promotional/voucher system migrated
- [ ] Search functionality operational
- [ ] Email notifications configured
- [ ] Celery background tasks migrated
- [ ] UAT completed
- [ ] PCI DSS compliance validated on replacement
- [ ] Parallel operation period completed (minimum 14 days)

### 1.3 Dependency Verification

- [ ] REST API consumers migrated
- [ ] Payment gateway reconfigured
- [ ] Shipping provider integrations updated
- [ ] Analytics/tracking redirected
- [ ] SEO redirects configured for product URLs

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Customer accounts (PII) | ~100K records | 7 years | Encrypted archive |
| Order history | ~500K records | 7 years | Database dump |
| Product catalog | ~20K records | 3 years | Database dump |
| Payment records | ~300K records | 7 years (PCI) | Encrypted archive |
| Shipping records | ~400K records | 7 years | Database dump |
| Media/product images | ~20 GB | 3 years | File archive |
| Celery task results | ~5M records | 1 year | Database dump |
| Audit logs | ~10M records | 7 years | Immutable archive |

### 2.2 PCI DSS Data Handling

```
IMPORTANT: Payment card data handling requirements:
1. Verify all PAN data is properly tokenized/encrypted
2. Do NOT archive raw card numbers
3. Archive only tokenized payment references
4. Engage PCI QSA for decommission compliance review
5. Securely destroy any stored card data per PCI DSS 3.1
6. Document destruction with witness signatures
```

### 2.3 Archival Procedure

```bash
#!/bin/bash
# oscar-archive.sh

ARCHIVE_DIR="/archive/django-oscar"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

# Database archive
pg_dump -Fc -U oscar -d oscar_production > "$ARCHIVE_DIR/oscar_db_${TIMESTAMP}.dump"

# Media files archive
tar czf "$ARCHIVE_DIR/oscar_media_${TIMESTAMP}.tar.gz" /opt/oscar/media/

# Configuration
tar czf "$ARCHIVE_DIR/oscar_config_${TIMESTAMP}.tar.gz" \
    /opt/oscar/settings/ /opt/oscar/requirements/

# Encrypt
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
| 2 | Configure 301 redirects for product URLs | 1 hour |
| 3 | Update payment gateway endpoint | 30 min |
| 4 | Remove Oscar from load balancer | 5 min |
| 5 | Update DNS records | 5 min |
| 6 | Monitor for failed transactions | 4 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Disable new order processing
2. Wait for pending Celery tasks to complete
3. Stop Celery workers: systemctl stop oscar-celery oscar-celery-beat
4. Stop Gunicorn: systemctl stop oscar-gunicorn
5. Final database backup
6. Stop PostgreSQL (if dedicated)
7. Stop Redis (if dedicated)
8. Disable all services
9. Revoke network access
10. Secure destruction of any PCI-scoped data
11. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] Oscar web storefront no longer accessible
- [ ] 301 redirects working for all product/category URLs
- [ ] Replacement system processing orders
- [ ] Payment processing working on replacement
- [ ] No pending Celery tasks orphaned
- [ ] PCI DSS decommission checklist completed
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Customer PII | 7 years | Privacy Act |
| Payment records | 7 years | PCI DSS + fiscal |
| Order records | 7 years | Agency policy |
| Product catalog | 3 years | Agency policy |
| Audit logs | 7 years | FISMA |
| PCI audit trail | 1 year after decommission | PCI DSS 10.7 |

---

## 7. Rollback Procedures

```
1. Restore database from backup
2. Restore media files
3. Start Redis, then Gunicorn, then Celery workers
4. Update payment gateway endpoint back to Oscar
5. Update DNS/routing
6. Verify order processing end-to-end
```

**Estimated rollback time**: 2-3 hours


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
