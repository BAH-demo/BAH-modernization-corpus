# B2CWeb Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | B2CWeb |
| **Type** | Web Application |
| **Language** | Java |
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

- [ ] Modernized system fully operational
- [ ] All B2CWeb pages/functionality replicated
- [ ] User sessions/accounts migrated
- [ ] Form submissions and data processing working
- [ ] SEO redirects configured (301) for all indexed URLs
- [ ] UAT completed and signed off
- [ ] Parallel operation period completed (minimum 14 days)

### 1.3 Dependency Verification

- [ ] All API consumers migrated
- [ ] External links/bookmarks will redirect
- [ ] Search engine crawlers notified (sitemap update)
- [ ] Analytics tracking transferred

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| User accounts | ~50K records | 3 years | Encrypted archive |
| Session data | Ephemeral | Not required | N/A |
| Form submissions | ~200K records | 7 years | Database dump |
| Static content | ~5 GB | 3 years | File archive |
| Audit logs | ~5M records | 7 years | Immutable archive |

### 2.2 Archival Procedure

```bash
# Database export
mysqldump -u b2cweb -p b2cweb_production > /archive/b2cweb/b2cweb_db_$(date +%Y%m%d).sql

# Application and static files
tar czf /archive/b2cweb/b2cweb_app_$(date +%Y%m%d).tar.gz /opt/tomcat/webapps/b2cweb/

# Configuration
tar czf /archive/b2cweb/b2cweb_config_$(date +%Y%m%d).tar.gz /opt/tomcat/conf/
```

---

## 3. DNS/Routing Cutover

| Step | Action | Duration |
|------|--------|----------|
| 1 | Lower DNS TTL | 5 min |
| 2 | Configure 301 redirects on reverse proxy | 30 min |
| 3 | Remove B2CWeb from load balancer | 5 min |
| 4 | Update DNS records | 5 min |
| 5 | Monitor redirects | 2 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Set application to maintenance mode
2. Stop Tomcat: systemctl stop tomcat
3. Final database backup
4. Disable services: systemctl disable tomcat
5. Revoke network access
6. Archive server filesystem
7. Power down
```

---

## 5. Post-Decommission Validation

- [ ] B2CWeb no longer accessible directly
- [ ] 301 redirects working for all key URLs
- [ ] Replacement system serving all traffic
- [ ] No broken links reported
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| User data (PII) | 3 years | Privacy Act |
| Form submissions | 7 years | Agency policy |
| Audit logs | 7 years | FISMA |
| System documentation | 3 years | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore database from backup
2. Restart Tomcat with B2CWeb WAR
3. Update load balancer/DNS
4. Verify functionality
```

**Estimated rollback time**: 1-2 hours
