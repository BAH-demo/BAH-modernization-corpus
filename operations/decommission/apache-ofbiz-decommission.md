# Apache OFBiz Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Apache OFBiz |
| **Type** | ERP System |
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
- [ ] Union/workforce notification (if applicable)

### 1.2 Replacement System Validation

- [ ] Modernized system fully operational and tested
- [ ] All OFBiz business functions replicated in new system
- [ ] User acceptance testing (UAT) completed and signed off
- [ ] Performance benchmarks met or exceeded
- [ ] Security authorization (ATO) obtained for replacement
- [ ] Data migration to replacement system completed and verified
- [ ] Parallel operation period completed (minimum 30 days)

### 1.3 Dependency Verification

- [ ] All upstream systems reconfigured to use replacement
- [ ] All downstream consumers migrated off OFBiz APIs
- [ ] Batch jobs and scheduled tasks moved to replacement
- [ ] Reporting and analytics redirected
- [ ] Integration points documented and transferred
- [ ] Third-party vendor notifications sent

### 1.4 Documentation

- [ ] Final system state documented
- [ ] Configuration exported and archived
- [ ] Admin credentials documented and secured
- [ ] Network diagrams updated
- [ ] CMDB/asset inventory updated

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention Requirement | Archive Method |
|--------------|--------|----------------------|----------------|
| Customer/Partner records (PII) | ~500K records | 7 years (federal) | Encrypted archive |
| Financial transactions | ~2M records | 7 years (fiscal) | Encrypted archive |
| Order history | ~1M records | 7 years | Encrypted archive |
| Product catalog | ~50K records | 3 years | Database dump |
| User accounts | ~5K records | 3 years | Encrypted archive |
| Audit logs | ~10M records | 7 years (NARA) | Immutable archive |
| Configuration data | ~1K files | 3 years | Git archive |
| Uploaded documents | ~50 GB | 7 years | Encrypted file archive |

### 2.2 Data Migration Steps

```
1. FREEZE data changes
   └─> Set OFBiz to read-only mode
   └─> Disable all write APIs
   └─> Stop scheduled imports/exports

2. EXPORT final data snapshot
   └─> pg_dump -Fc -U ofbiz -d ofbiz_production > ofbiz_final_$(date +%Y%m%d).dump
   └─> Export all uploaded files/documents
   └─> Export configuration files

3. VERIFY data completeness
   └─> Row counts match between source and archive
   └─> Checksum verification on file exports
   └─> Spot-check critical records (10% sample)

4. ARCHIVE to long-term storage
   └─> Encrypt archives (AES-256, FIPS 140-2 compliant)
   └─> Store in designated federal records storage
   └─> Create archive manifest with checksums
   └─> Store encryption keys in HSM/key management system
```

### 2.3 Archive Verification Script

```bash
#!/bin/bash
# ofbiz-archive-verify.sh

ARCHIVE_DIR="/archive/ofbiz"
MANIFEST="$ARCHIVE_DIR/manifest.sha256"

echo "=== OFBiz Archive Verification ==="

# Verify all archive files exist
while IFS= read -r line; do
    HASH=$(echo "$line" | awk '{print $1}')
    FILE=$(echo "$line" | awk '{print $2}')
    if [ -f "$ARCHIVE_DIR/$FILE" ]; then
        ACTUAL_HASH=$(sha256sum "$ARCHIVE_DIR/$FILE" | awk '{print $1}')
        if [ "$HASH" = "$ACTUAL_HASH" ]; then
            echo "OK: $FILE"
        else
            echo "FAIL: $FILE (checksum mismatch)"
        fi
    else
        echo "MISSING: $FILE"
    fi
done < "$MANIFEST"
```

---

## 3. DNS/Routing Cutover

### 3.1 Cutover Steps

| Step | Action | Responsible | Duration |
|------|--------|-------------|----------|
| 1 | Update DNS TTL to 60s (48 hours before cutover) | Network Team | 5 min |
| 2 | Configure replacement system on new DNS entry | Network Team | 15 min |
| 3 | Update load balancer to route to replacement | Network Team | 10 min |
| 4 | Remove OFBiz from load balancer pool | Network Team | 5 min |
| 5 | Update DNS A/CNAME records to point to replacement | Network Team | 5 min |
| 6 | Verify DNS propagation | Network Team | 30 min |
| 7 | Monitor for errors from misdirected traffic | Operations | 4 hours |
| 8 | Restore normal DNS TTL | Network Team | 5 min |

### 3.2 URL Redirect Configuration

```nginx
# Nginx redirect from old OFBiz URLs to replacement system
server {
    listen 443 ssl;
    server_name ofbiz.example.gov ofbiz-legacy.example.gov;

    # Permanent redirect to replacement system
    return 301 https://erp.example.gov$request_uri;

    # Log redirected requests for monitoring
    access_log /var/log/nginx/ofbiz-redirect.log;
}
```

---

## 4. Legacy System Shutdown Sequence

### 4.1 Shutdown Procedure

```
T-7 days:  Final user notification
T-1 day:   Disable new user registrations
T-0:       Begin shutdown

1. Stop all scheduled jobs and cron tasks
   └─> systemctl stop ofbiz-scheduler

2. Set application to maintenance mode
   └─> Enable maintenance page on load balancer

3. Stop OFBiz application server
   └─> /opt/ofbiz/bin/ofbiz --shutdown
   └─> systemctl stop ofbiz

4. Take final database backup
   └─> pg_dump -Fc -U ofbiz -d ofbiz_production > ofbiz_shutdown_final.dump

5. Stop PostgreSQL (if dedicated instance)
   └─> systemctl stop postgresql

6. Disable all services from auto-start
   └─> systemctl disable ofbiz
   └─> systemctl disable ofbiz-scheduler

7. Revoke network access
   └─> Remove firewall rules for OFBiz ports (8443, 8080)
   └─> Remove from security groups

8. Power down servers (if physical/dedicated)
   └─> Or terminate VM instances

9. Archive server configuration
   └─> Backup /opt/ofbiz/
   └─> Backup /etc/ (relevant configs)
   └─> Backup SSL certificates
```

---

## 5. Post-Decommission Validation

### 5.1 Validation Checklist

- [ ] OFBiz application is no longer accessible
- [ ] All DNS records updated or removed
- [ ] No services listening on OFBiz ports
- [ ] Replacement system handling all traffic correctly
- [ ] No error reports from users regarding missing functionality
- [ ] Monitoring alerts for OFBiz removed or acknowledged
- [ ] CMDB updated to reflect decommissioned status
- [ ] Asset inventory updated (hardware returned/repurposed)
- [ ] Licenses released or terminated
- [ ] Vulnerability scan confirms no exposed legacy services

### 5.2 Validation Period

| Timeframe | Activity |
|-----------|----------|
| Day 1-7 | Intensive monitoring of replacement system |
| Day 8-14 | Verify no lingering OFBiz connections |
| Day 15-30 | Confirm all integrations working on replacement |
| Day 30+ | Close decommission ticket |

---

## 6. Data Retention Compliance

### 6.1 Federal Records Requirements

| Record Type | Retention Period | Authority | Disposition |
|-------------|-----------------|-----------|-------------|
| Financial records | 7 years | 31 U.S.C. § 3512 | Destroy after retention |
| PII records | 7 years or per SORN | Privacy Act | Destroy per NARA schedule |
| Audit logs | 7 years | FISMA | Destroy after retention |
| System documentation | 3 years after decommission | Agency policy | Destroy after retention |
| Security records | 6 years after ATO expiration | NIST 800-53 | Destroy after retention |
| Contracts/procurement | 6 years | FAR 4.705 | Destroy after retention |

### 6.2 Archive Location and Access

| Archive | Location | Access Control |
|---------|----------|---------------|
| Database dump | Federal Records Storage (S3 GovCloud) | ISSO + System Owner |
| File archives | Federal Records Storage (S3 GovCloud) | ISSO + System Owner |
| Configuration | Git archive repository | Operations Team |
| Documentation | SharePoint/Confluence archive | All stakeholders |

---

## 7. Rollback Procedures

### 7.1 Rollback Decision Criteria

Rollback should be initiated if:
- Replacement system experiences critical failure within first 30 days
- Data integrity issues discovered in migrated data
- Business-critical functionality missing from replacement
- Security vulnerability in replacement requires extended downtime

### 7.2 Rollback Steps

```
1. ASSESS the situation
   └─> Confirm rollback is necessary
   └─> Obtain emergency CAB approval

2. RESTORE database
   └─> pg_restore -U ofbiz -d ofbiz_production ofbiz_shutdown_final.dump

3. RESTART OFBiz
   └─> systemctl enable ofbiz
   └─> systemctl start ofbiz
   └─> Verify health: curl https://ofbiz:8443/webtools/control/main

4. UPDATE routing
   └─> Add OFBiz back to load balancer
   └─> Update DNS records
   └─> Verify traffic flowing

5. NOTIFY stakeholders
   └─> Communications to users
   └─> Update incident record
   └─> Schedule PIR for decommission failure

6. RE-PLAN decommission
   └─> Address the issues that caused rollback
   └─> Update decommission plan
   └─> Schedule new decommission window
```

### 7.3 Rollback Timeline

| Phase | Action | Max Duration |
|-------|--------|-------------|
| Decision | Assess and approve rollback | 1 hour |
| Database Restore | Restore from shutdown backup | 2 hours |
| Application Restart | Start OFBiz and verify | 30 min |
| Network Cutover | DNS/LB update | 30 min |
| Validation | Verify full functionality | 2 hours |
| **Total** | | **6 hours** |
