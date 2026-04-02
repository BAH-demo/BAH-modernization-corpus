# Mezzanine Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Mezzanine |
| **Type** | Content Management System |
| **Language** | Python |
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

- [ ] All content pages migrated to replacement CMS
- [ ] Blog posts and comments migrated
- [ ] Media files (images, documents) migrated
- [ ] URL structure preserved or redirects configured
- [ ] Cartridge e-commerce data migrated (if used)
- [ ] Custom templates replicated
- [ ] Form handlers migrated
- [ ] UAT completed by content team
- [ ] SEO rankings preserved (redirects in place)
- [ ] Parallel operation period completed (minimum 14 days)

### 1.3 Dependency Verification

- [ ] RSS feeds redirected
- [ ] Newsletter integrations updated
- [ ] Social media sharing URLs redirected
- [ ] External links (inbound) will be redirected
- [ ] API consumers (if any) migrated

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Page content | ~5K pages | 3 years | Database dump |
| Blog posts | ~2K posts | 3 years | Database dump |
| Media files | ~10 GB | 3 years | File archive |
| User accounts | ~1K records | 3 years | Encrypted archive |
| Comments | ~10K records | 3 years | Database dump |
| E-commerce data (Cartridge) | ~5K records | 7 years (if financial) | Database dump |
| Audit logs | ~2M records | 7 years | Immutable archive |

### 2.2 Archival Procedure

```bash
#!/bin/bash
ARCHIVE_DIR="/archive/mezzanine"
TIMESTAMP=$(date +%Y%m%d)
mkdir -p "$ARCHIVE_DIR"

pg_dump -Fc -U mezzanine -d mezzanine_production > "$ARCHIVE_DIR/mezzanine_db_${TIMESTAMP}.dump"
tar czf "$ARCHIVE_DIR/mezzanine_media_${TIMESTAMP}.tar.gz" /opt/mezzanine/media/
tar czf "$ARCHIVE_DIR/mezzanine_config_${TIMESTAMP}.tar.gz" /opt/mezzanine/settings/

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
| 2 | Configure 301 redirects for all content URLs | 1 hour |
| 3 | Remove Mezzanine from load balancer | 5 min |
| 4 | Update DNS records | 5 min |
| 5 | Verify SEO redirects with crawler | 2 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Set CMS to read-only/maintenance mode
2. Stop Gunicorn: systemctl stop mezzanine-gunicorn
3. Final database backup
4. Stop PostgreSQL (if dedicated)
5. Stop Redis (if dedicated)
6. Disable all services
7. Revoke network access
8. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] Mezzanine admin and frontend no longer accessible
- [ ] 301 redirects working for all content URLs
- [ ] Replacement CMS serving all content
- [ ] No 404 errors for previously indexed pages
- [ ] RSS feeds working on replacement
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Public content | 3 years | Agency policy |
| User accounts | 3 years | Privacy Act |
| E-commerce records | 7 years (if financial) | Agency policy |
| Audit logs | 7 years | FISMA |
| System documentation | 3 years | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore database from backup
2. Restore media files
3. Start Gunicorn: systemctl start mezzanine-gunicorn
4. Update DNS/routing
5. Verify content pages rendering
```

**Estimated rollback time**: 1-2 hours
