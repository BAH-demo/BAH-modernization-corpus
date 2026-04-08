# Federal and DoD-Specific Database Modernization Considerations

## Overview

Database modernization within federal and Department of Defense (DoD) environments operates under constraints that do not exist in the commercial sector. Security controls, authorization requirements, cross-domain restrictions, and audit mandates directly influence which databases can be migrated, when, and how. This document catalogs the key federal-specific considerations that must be addressed during database disposition and migration planning.

---

## NIST SP 800-53 Controls Affecting Database Disposition

NIST Special Publication 800-53 Rev. 5 defines the security controls that federal information systems must implement. The following control families have direct implications for database modernization:

### Access Control (AC)

| Control | Requirement | Migration Impact |
|---------|------------|-----------------|
| AC-2 (Account Management) | All database accounts must be managed, reviewed, and auditable | New DBMS must replicate or improve account management capabilities |
| AC-3 (Access Enforcement) | Role-based or attribute-based access control must be enforced | Schema migration must preserve RBAC/ABAC policies; PostgreSQL roles must map to Oracle grants |
| AC-6 (Least Privilege) | Database accounts must have minimum necessary permissions | Migration is an opportunity to right-size permissions — do not replicate over-provisioned legacy grants |
| AC-17 (Remote Access) | Remote database access must be controlled and encrypted | Cloud-hosted databases must use TLS, VPN, or Direct Connect — no plaintext connections |

### Audit and Accountability (AU)

| Control | Requirement | Migration Impact |
|---------|------------|-----------------|
| AU-2 (Event Logging) | Database must log access, modification, and administrative events | Target DBMS must support equivalent audit logging (pgAudit for PostgreSQL, CloudTrail for RDS) |
| AU-3 (Content of Audit Records) | Logs must include who, what, when, where, outcome | Trigger-based audit trails (common in legacy) must be replicated or replaced with native audit |
| AU-6 (Audit Review) | Audit logs must be reviewed regularly | Migration must include audit log pipeline to SIEM (Splunk, ELK, CloudWatch) |
| AU-9 (Protection of Audit Information) | Audit logs must be tamper-resistant | Separate audit storage from operational database; use write-once storage |
| AU-11 (Audit Record Retention) | Retain audit records per agency policy (typically 1–7 years) | Historical audit data must be migrated or archived — do not discard during migration |

### Configuration Management (CM)

| Control | Requirement | Migration Impact |
|---------|------------|-----------------|
| CM-2 (Baseline Configuration) | Database configuration must be documented and baselined | Target DBMS configuration must be documented before ATO |
| CM-6 (Configuration Settings) | Security-relevant settings must follow agency hardening guides (STIGs) | Target DBMS must have an approved STIG (PostgreSQL STIG, MySQL STIG exist) |
| CM-8 (Information System Component Inventory) | All database instances must be inventoried | New database instances must be registered in the agency's CMDB |

### System and Communications Protection (SC)

| Control | Requirement | Migration Impact |
|---------|------------|-----------------|
| SC-8 (Transmission Confidentiality) | Data in transit must be encrypted (TLS 1.2+) | All database connections must use TLS; legacy unencrypted connections must not be replicated |
| SC-28 (Protection of Information at Rest) | Data at rest must be encrypted | Target DBMS must support encryption at rest (RDS encryption, LUKS, TDE) |
| SC-13 (Cryptographic Protection) | FIPS 140-2/140-3 validated cryptography required | Encryption modules in the target DBMS must be FIPS-validated |

### System and Information Integrity (SI)

| Control | Requirement | Migration Impact |
|---------|------------|-----------------|
| SI-7 (Software, Firmware, and Information Integrity) | Database software must be integrity-verified | Use only approved DBMS versions from authorized repositories |
| SI-12 (Information Management and Retention) | Data retention policies must be enforced | Migration must preserve or update data retention mechanisms |

---

## FedRAMP Database Requirements

When migrating federal databases to cloud-hosted DBMS (RDS, Aurora, Cloud SQL), FedRAMP authorization requirements apply:

### FedRAMP Authorization Levels

| Impact Level | Data Types | Database Requirements |
|-------------|-----------|----------------------|
| **Low** | Publicly available data | Standard cloud database with encryption, access control, audit logging |
| **Moderate** | Controlled Unclassified Information (CUI), PII | FIPS 140-2 encryption, MFA for admin access, continuous monitoring |
| **High** | Law enforcement sensitive, critical infrastructure, export-controlled | Dedicated infrastructure (GovCloud), enhanced logging, strict network segmentation |

### FedRAMP Database Checklist

- [ ] Target CSP has FedRAMP authorization at the required impact level
- [ ] Database service is included in the CSP's FedRAMP authorization boundary
- [ ] Encryption at rest uses FIPS 140-2 validated modules
- [ ] Encryption in transit uses TLS 1.2+ with FIPS-approved cipher suites
- [ ] Database admin access requires MFA
- [ ] Audit logs are exported to agency-controlled SIEM
- [ ] Backup and disaster recovery meet agency RPO/RTO requirements
- [ ] Data residency requirements are met (data stays in approved regions)
- [ ] Vulnerability scanning covers the database layer
- [ ] Incident response procedures include database-specific scenarios

### Common FedRAMP-Authorized Database Services

| CSP | Database Services | FedRAMP Level |
|-----|------------------|---------------|
| AWS GovCloud | RDS (PostgreSQL, MySQL, Oracle, SQL Server), Aurora, DynamoDB, DocumentDB | High |
| Azure Government | Azure SQL, Cosmos DB, Database for PostgreSQL, Database for MySQL | High |
| Google Cloud (IL2/IL4) | Cloud SQL, Cloud Spanner, Firestore | Moderate/High (IL4 for select services) |
| Oracle Cloud (Gov) | Autonomous Database, MySQL HeatWave | Moderate/High |

---

## Cross-Domain Solutions and Data Segmentation

### When Cross-Domain Applies

Cross-domain database considerations arise when:
- Data from different classification levels must be queried together
- A modernized database must serve consumers on different networks (e.g., NIPRNet and SIPRNet)
- Data aggregation from multiple classification levels creates a higher-classification composite

### Data Segmentation Requirements

| Requirement | Implementation |
|------------|----------------|
| **Network separation** | Databases on different classification levels must reside on separate, air-gapped or guard-protected networks |
| **Data labeling** | Row-level or column-level classification labels where supported (Oracle Label Security, PostgreSQL RLS + classification columns) |
| **Cross-domain transfers** | Any data movement between classification levels must pass through an approved cross-domain solution (CDS) |
| **Query restrictions** | Application layer must enforce classification-aware query filtering — database-level controls alone are insufficient |
| **Spill prevention** | Migration processes must prevent data from a higher classification from being written to a lower-classification database |

### Database Modernization Implications

- **Do not combine data from different classification levels** into a single database instance unless the target environment is authorized at the highest classification level
- **Row-level security (RLS)** in PostgreSQL can enforce data segmentation within a single database, but only when paired with application-level classification enforcement
- **Separate migration pipelines** are required for each classification level — a single ETL pipeline must not touch databases at different levels
- **Cross-domain data synchronization** (if required) must use an approved CDS with content filtering

---

## ATO/CCRI Implications for Database Migration

### Authority to Operate (ATO)

Every federal information system — including databases — must have an ATO before operating in a production environment. Database migration creates ATO implications:

| Scenario | ATO Impact |
|----------|-----------|
| **Same DBMS, same version, same environment** | Typically covered under existing ATO (change request only) |
| **Same DBMS, new version** | May require ATO amendment; assess control changes |
| **Different DBMS (e.g., Oracle → PostgreSQL)** | Requires new ATO or significant ATO amendment; full security assessment |
| **On-prem → Cloud migration** | New ATO required for the cloud environment; inherits CSP FedRAMP controls |
| **Database decommission** | ATO update to remove the system from the authorization boundary |

### ATO Assessment Activities for Database Migration

1. **Security Control Assessment**: Verify all NIST 800-53 controls are implemented in the target environment
2. **Penetration Testing**: Test the new database for SQL injection, privilege escalation, and configuration weaknesses
3. **Vulnerability Scanning**: Run ACAS/Nessus scans against the new database instance
4. **STIG Compliance**: Verify the target DBMS meets the applicable DISA STIG
5. **Plan of Action and Milestones (POA&M)**: Document any controls not yet fully implemented with remediation timelines

### Command Cyber Readiness Inspection (CCRI)

For DoD systems, CCRI adds additional requirements:

- **STIG compliance scores** must meet or exceed thresholds (typically CAT I = 0, CAT II < threshold)
- **Database STIGs** must be applied and verified: PostgreSQL STIG, MySQL STIG, Oracle STIG, SQL Server STIG
- **Credential management**: No default accounts, no shared credentials, password complexity enforced
- **Patch currency**: Database software must be within agency-defined patch currency windows (typically 30 days for critical, 90 days for high)
- **Network architecture**: Database must be on an approved network segment with appropriate firewall rules

---

## Audit Trail and Forensic Requirements for Database Changes

### Audit Requirements During Migration

Every step of the database migration process must be auditable:

| Phase | What Must Be Logged | Retention |
|-------|--------------------|-----------|
| **Pre-migration** | Baseline schema snapshot, row counts, checksum/hash of critical tables | Permanent (part of migration record) |
| **Migration execution** | Start/stop times, scripts executed, errors encountered, data volumes transferred | 3+ years per agency policy |
| **Validation** | Row count comparison, referential integrity checks, sample data verification results | 3+ years |
| **Post-migration** | Access grants applied, security controls verified, first production queries | Ongoing (standard audit) |
| **Rollback (if needed)** | Rollback trigger, rollback execution, data state after rollback | 3+ years |

### Forensic Chain of Custody

For databases containing law enforcement data, PII, or national security information:

- **Hash verification**: Generate cryptographic hashes (SHA-256) of critical tables before and after migration to prove data integrity
- **Migration scripts**: All migration scripts must be version-controlled and signed
- **Access logs**: Complete access logs for the migration window, including who accessed what data
- **Separation of duties**: The person who writes the migration script should not be the person who executes it in production
- **Witness requirement**: For high-impact migrations, a second authorized individual must observe and verify the migration execution

### Recommended Audit Implementation

```sql
-- PostgreSQL audit table for migration tracking
CREATE TABLE migration_audit_log (
    audit_id        SERIAL PRIMARY KEY,
    migration_name  VARCHAR(200) NOT NULL,
    phase           VARCHAR(50) NOT NULL,  -- pre_migration, execution, validation, post_migration
    action          TEXT NOT NULL,
    actor           VARCHAR(100) NOT NULL,
    timestamp       TIMESTAMPTZ DEFAULT NOW(),
    details         JSONB,
    checksum        VARCHAR(64)  -- SHA-256 of affected data where applicable
);

-- Immutable: revoke DELETE and UPDATE on audit table
REVOKE DELETE, UPDATE ON migration_audit_log FROM PUBLIC;
GRANT INSERT, SELECT ON migration_audit_log TO migration_role;
```

### Data Preservation Requirements

| Data Type | Requirement | Implementation |
|-----------|------------|----------------|
| **Active records** | Must be migrated with full fidelity | Byte-level verification post-migration |
| **Historical records** | Must be preserved per retention schedule | Migrate to target or archive to approved storage |
| **Deleted records** | May need to be recoverable (legal hold) | Check for active litigation holds before migration |
| **Audit logs** | Must be preserved independently | Export to separate audit store before decommissioning source |
| **Backup tapes** | May contain evidence | Do not destroy backup media without records management approval |
