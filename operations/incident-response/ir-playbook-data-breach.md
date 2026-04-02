# Data Breach Response Playbook

## Document Control

| Field | Value |
|-------|-------|
| **Document ID** | IR-PLAY-004 |
| **Version** | 1.0 |
| **Classification** | CUI (Controlled Unclassified Information) |
| **Framework** | NIST SP 800-61, OMB M-17-12, Privacy Act |
| **Applicable Systems** | All 13 Modernized Legacy Systems |
| **Review Cycle** | Annual or after data breach |

## Purpose

This playbook provides procedures for responding to data breaches involving personally identifiable information (PII), protected health information (PHI), payment card data, or other sensitive information within the modernized legacy systems portfolio.

---

## Phase 1: Preparation

### 1.1 Data Classification by System

| System | Data Types | Sensitivity | Regulatory |
|--------|-----------|-------------|------------|
| Apache OFBiz | PII, Financial, Business | High | FISMA, Privacy Act |
| Odoo | PII, Financial, HR, Business | High | FISMA, Privacy Act |
| Django Oscar | PII, Payment (PCI), Order data | High | PCI DSS, FISMA |
| DFe-NET | Fiscal documents, Tax ID, Business | High | Fiscal regulations |
| Alfresco | Documents (may contain PII) | Medium-High | FISMA, NARA |
| Nuxeo | Documents (may contain PII) | Medium-High | FISMA, NARA |
| B2CWeb | User accounts, session data | Medium | FISMA |
| Monolith Enterprise | Business data, user accounts | Medium | FISMA |
| Umbraco CMS | Content, admin accounts | Low-Medium | FISMA |
| Mezzanine | Content, admin accounts | Low | FISMA |
| CFWheels | Application data | Low-Medium | FISMA |
| NASTRAN-95 | Engineering models | Low | Export control (ITAR) |
| Apollo-11 | Public historic data | Low | NARA |

### 1.2 Data Breach Response Team

| Role | Responsibility |
|------|---------------|
| IR Manager | Coordinate response, manage timeline |
| Privacy Officer | Assess PII impact, notification requirements |
| Legal Counsel | Legal obligations, notification language |
| ISSO | Security assessment, system authorization impact |
| Communications | Public/stakeholder notifications |
| System Owner | System-specific data assessment |
| Database Administrator | Data analysis, scope determination |
| Human Resources | If employee data involved |

### 1.3 Preparation Checklist

- [ ] PII inventory documented for each system
- [ ] Data flow diagrams current for all 13 systems
- [ ] Breach notification templates prepared
- [ ] Privacy Impact Assessments (PIAs) current
- [ ] System of Records Notices (SORNs) current
- [ ] Legal notification requirements documented by jurisdiction
- [ ] Credit monitoring vendor on retainer
- [ ] External forensic firm on retainer
- [ ] US-CERT/CISA reporting procedures tested

---

## Phase 2: Detection and Analysis

### 2.1 Data Breach Indicators

| Indicator | Systems Most At Risk | Detection Method |
|-----------|---------------------|-----------------|
| Bulk data export/download | OFBiz, Odoo, Alfresco, Nuxeo | SIEM alert on volume |
| Unauthorized database queries | All DB-backed systems | Database audit logs |
| API data exfiltration | OFBiz, Nuxeo, Odoo, Oscar | API rate/volume anomaly |
| SQL injection success | All web-facing systems | WAF + DB audit logs |
| Unauthorized admin access | All systems | Auth logs, SIEM |
| Large outbound data transfer | All | Network flow analysis |
| Backup/dump file access | All | File access audit |
| Payment data access | Django Oscar | PCI audit logs |
| Fiscal document theft | DFe-NET | Certificate usage audit |

### 2.2 Breach Scope Assessment

```bash
#!/bin/bash
# breach-scope-assessment.sh
# Run immediately upon suspected breach

SYSTEM=$1
DB_HOST=$2
DB_NAME=$3
DB_USER=$4
REPORT_FILE="/evidence/breach-scope-$(date +%Y%m%d_%H%M%S).txt"

echo "=== Breach Scope Assessment: $SYSTEM ===" > "$REPORT_FILE"
echo "Timestamp: $(date -u)" >> "$REPORT_FILE"

# Count affected records by data type
echo "" >> "$REPORT_FILE"
echo "=== Data Volume Assessment ===" >> "$REPORT_FILE"

case $SYSTEM in
    ofbiz)
        psql -U $DB_USER -h $DB_HOST -d $DB_NAME <<EOF >> "$REPORT_FILE"
SELECT 'Total Persons' as data_type, count(*) as record_count FROM person;
SELECT 'Persons with PII' as data_type, count(*) FROM person WHERE first_name IS NOT NULL;
SELECT 'Financial Records' as data_type, count(*) FROM payment;
SELECT 'User Accounts' as data_type, count(*) FROM user_login;
EOF
        ;;
    odoo)
        psql -U $DB_USER -h $DB_HOST -d $DB_NAME <<EOF >> "$REPORT_FILE"
SELECT 'Total Partners' as data_type, count(*) as record_count FROM res_partner;
SELECT 'Employees' as data_type, count(*) FROM hr_employee;
SELECT 'Invoices' as data_type, count(*) FROM account_move WHERE move_type IN ('out_invoice','in_invoice');
SELECT 'User Accounts' as data_type, count(*) FROM res_users;
EOF
        ;;
    oscar)
        psql -U $DB_USER -h $DB_HOST -d $DB_NAME <<EOF >> "$REPORT_FILE"
SELECT 'Total Users' as data_type, count(*) as record_count FROM auth_user;
SELECT 'Orders with PII' as data_type, count(*) FROM order_order;
SELECT 'Addresses' as data_type, count(*) FROM address_useraddress;
SELECT 'Payment Sources' as data_type, count(*) FROM payment_source;
EOF
        ;;
esac

echo "" >> "$REPORT_FILE"
echo "=== Recent Data Access Patterns ===" >> "$REPORT_FILE"

# Check for bulk access patterns in database logs
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -c "
SELECT usename, client_addr, count(*) as query_count,
       min(query_start) as first_query, max(query_start) as last_query
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY usename, client_addr
ORDER BY query_count DESC;" >> "$REPORT_FILE"

echo "Scope assessment saved to: $REPORT_FILE"
```

### 2.3 Breach Classification

| Category | Definition | Example |
|----------|-----------|---------|
| **Confirmed Breach** | PII/sensitive data verified as accessed by unauthorized party | Database dump found on dark web |
| **Suspected Breach** | Evidence suggests unauthorized access, scope unclear | Anomalous bulk query patterns |
| **PII Exposure** | PII inadvertently exposed but no confirmed access | Unencrypted backup on public S3 |
| **Near Miss** | Vulnerability discovered that could have led to breach | SQLi vulnerability found in audit |

### 2.4 Data Elements Impact Matrix

| Data Element | Impact if Breached | Notification Required |
|-------------|-------------------|----------------------|
| SSN | Critical | Yes - federal + state |
| Financial account numbers | Critical | Yes - PCI + federal |
| Tax ID / EIN | High | Yes - federal |
| Full name + DOB | High | Yes - federal |
| Email + password | High | Yes - affected users |
| Medical information | Critical | Yes - HIPAA + federal |
| Address + phone | Medium | Case-by-case |
| Business documents | Medium | Agency-dependent |

---

## Phase 3: Containment, Eradication, and Recovery

### 3.1 Immediate Containment

```
CRITICAL FIRST STEPS (within 1 hour):

1. STOP the active breach
   └─> Block attacker IP/account
   └─> Disable compromised credentials
   └─> Take affected system offline if necessary

2. PRESERVE evidence
   └─> Do NOT restart or rebuild yet
   └─> Capture memory, logs, network traffic
   └─> Document everything with timestamps

3. NOTIFY Privacy Officer and Legal
   └─> Verbal notification immediately
   └─> Written preliminary within 2 hours

4. ASSESS scope
   └─> Which data elements were accessed?
   └─> How many records affected?
   └─> How long was the exposure window?
```

### 3.2 Data-Specific Containment Actions

#### Payment Data (Django Oscar)

```
1. Isolate the payment processing component
2. Notify Payment Card Industry (PCI) Qualified Security Assessor (QSA)
3. Disable affected payment methods
4. Review all transactions in the breach window
5. Engage PCI forensic investigator (PFI)
```

#### Fiscal Documents (DFe-NET)

```
1. Revoke compromised digital certificates immediately
2. Notify fiscal authority (SEFAZ/Receita Federal)
3. Flag all documents signed during breach window
4. Issue new certificates and re-sign if necessary
5. Audit all fiscal document submissions
```

#### Document Repositories (Alfresco, Nuxeo)

```
1. Disable bulk download capabilities
2. Revoke external sharing links
3. Audit all document access in breach window
4. Assess document classification (PII content analysis)
5. Determine if documents contained embedded PII
```

### 3.3 Evidence Collection for Legal

```bash
#!/bin/bash
# legal-evidence-collection.sh
# Collect evidence for legal/regulatory proceedings

EVIDENCE_DIR="/evidence/legal-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EVIDENCE_DIR"

# Chain of custody header
cat > "$EVIDENCE_DIR/chain_of_custody.txt" <<EOF
Evidence Collection Record
Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Collected by: $(whoami) on $(hostname)
Incident ID: [INSERT INCIDENT ID]
Purpose: Data breach evidence preservation
EOF

# Database query logs
tar czf "$EVIDENCE_DIR/db_query_logs.tar.gz" /var/log/postgresql/

# Application access logs
for system in ofbiz alfresco nuxeo odoo oscar umbraco dfe-net; do
    tar czf "$EVIDENCE_DIR/${system}_access_logs.tar.gz" \
      /var/log/${system}/ /opt/${system}/logs/ 2>/dev/null
done

# Network flow data
tar czf "$EVIDENCE_DIR/network_flows.tar.gz" /var/log/netflow/ 2>/dev/null

# SIEM export
# [Export relevant SIEM events for the breach timeframe]

# Generate checksums
cd "$EVIDENCE_DIR"
sha256sum *.tar.gz >> chain_of_custody.txt

echo "Evidence collected: $EVIDENCE_DIR"
echo "IMPORTANT: Secure this directory and restrict access"
```

### 3.4 Recovery

```
1. Patch the vulnerability that enabled the breach
2. Rotate ALL credentials for affected system(s)
3. Rebuild system from known-good state if compromised
4. Re-encrypt any data that may have been exposed
5. Restore service with enhanced monitoring
6. Verify no data was modified/corrupted
```

---

## Phase 4: Post-Incident Activity

### 4.1 Federal Breach Notification Requirements

| Notification | Recipient | Timeline | Authority |
|-------------|-----------|----------|-----------|
| US-CERT Initial Report | CISA | 1 hour of discovery | BOD 22-01, FISMA |
| Agency SAOP/CPO | Senior Agency Official for Privacy | 1 hour | OMB M-17-12 |
| Congressional Notification | Relevant committees | If >100K records | FISMA |
| Individual Notification | Affected individuals | Without unreasonable delay | Privacy Act, OMB M-17-12 |
| Credit Monitoring | Affected individuals | With notification | OMB M-17-12 |
| Media Statement | Public | If significant | Agency policy |
| Inspector General | OIG | As warranted | Agency policy |

### 4.2 Individual Notification Template

```
Subject: Notice of Data Breach - [Agency Name]

Dear [Individual Name],

We are writing to inform you of a data security incident that may have 
affected your personal information.

What Happened:
[Brief factual description of the breach]

What Information Was Involved:
[Specific data elements: name, SSN, etc.]

What We Are Doing:
[Steps taken to address the breach]

What You Can Do:
[Protective steps the individual can take]

Credit Monitoring:
[Details of free credit monitoring being offered]

For More Information:
Contact: [Phone number, email, website]
Reference: [Incident number]

[Agency Head or Designee Signature]
```

### 4.3 Breach Impact Report

Document the following for the final breach report:

- Total records affected (by data type)
- Duration of exposure (first access to containment)
- Root cause analysis
- Remediation actions taken
- Notifications issued (to whom, when)
- Credit monitoring enrollment statistics
- Cost of breach response
- Regulatory penalties (if any)
- System authorization impact (ATO review)

### 4.4 Long-Term Corrective Actions

| Action | Timeline | Owner |
|--------|----------|-------|
| Patch root cause vulnerability | Immediate | System Owner |
| Review encryption of PII at rest | 30 days | ISSO |
| Implement data loss prevention (DLP) | 60 days | Security Team |
| Review access controls for PII | 30 days | System Owners |
| Update Privacy Impact Assessments | 60 days | Privacy Officer |
| Enhance monitoring for data exfiltration | 30 days | SOC |
| Conduct breach simulation exercise | 90 days | IR Manager |
| Review and update SORN if needed | 90 days | Privacy Officer |
| System re-authorization (if needed) | Per agency policy | AO |
