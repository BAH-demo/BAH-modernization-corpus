# Database Migration Wave Planning

## Overview

Database migrations in large federal and enterprise environments cannot be executed all at once. They must be sequenced into **waves** — groups of databases migrated together within a defined time window. Wave planning accounts for dependencies between databases, consumer readiness, operational risk tolerance, and change management capacity.

This document describes how to apply wave sequencing to database modernization, map dependencies, validate migrations, and plan rollbacks.

---

## How to Apply Wave Sequencing to Database Modernization

### Wave Structure

A typical migration program consists of 4–6 waves, each lasting 4–8 weeks:

```
Wave 0: Foundation (4 weeks)
├── Establish target environment (cloud accounts, networking, security)
├── Deploy database infrastructure (RDS instances, parameter groups, security groups)
├── Configure monitoring, alerting, and backup
└── Validate connectivity from consumer applications

Wave 1: Low-Risk Pilot (4–6 weeks)
├── 1–3 non-critical databases
├── Databases with single consumers and good documentation
├── Full migration rehearsal: extract, transform, load, validate
└── Lessons learned feed into Wave 2 planning

Wave 2: Core Migrations (6–8 weeks)
├── 5–10 databases of moderate complexity
├── Includes first shared-consumer databases
├── Parallel migrations where dependencies allow
└── Consumer cutover coordinated with application teams

Wave 3: Complex/High-Risk Migrations (6–8 weeks)
├── Databases with 3+ consumers, cross-database dependencies
├── COBOL/DB2 systems (API-wrapped databases)
├── Databases requiring data transformation (not just migration)
└── Extended validation windows

Wave 4: Final Migrations + Decommission (4–6 weeks)
├── Remaining databases
├── Decommission source databases after validation period
├── Archive data for retired databases
└── Close out migration program
```

### Wave Assignment Criteria

| Criterion | Wave 1 (Pilot) | Wave 2 (Core) | Wave 3 (Complex) | Wave 4 (Final) |
|-----------|----------------|---------------|-------------------|-----------------|
| **Consumers** | 1 consumer | 2–3 consumers | 3+ consumers | Any remaining |
| **Schema complexity** | < 30 tables | 30–100 tables | 100+ tables | Any remaining |
| **Dependencies** | Standalone | Limited | Cross-database | Any remaining |
| **Business criticality** | Low | Medium | High | Varies |
| **Documentation** | Good | Moderate | Any | Any |
| **Data volume** | < 10 GB | 10–100 GB | 100+ GB | Any |

### Wave Sequencing Rules

1. **Downstream before upstream**: If Database A feeds Database B via ETL, migrate A first
2. **Shared consumers together**: If two databases share the same consumer application, migrate them in the same wave
3. **API-wrapped databases last**: Databases that have been API-wrapped can be migrated later since consumers are already decoupled
4. **Critical systems in Wave 3**: Never put mission-critical databases in the pilot wave
5. **Leave buffer**: Each wave should have 1–2 weeks of buffer for unexpected issues

---

## Database Dependency Mapping

### Types of Dependencies

| Dependency Type | Description | Discovery Method |
|----------------|-------------|-----------------|
| **Direct consumer** | Application connects directly via JDBC/ODBC/connection string | Application configuration review, connection pool analysis |
| **Shared tables** | Multiple applications read/write the same tables | Database audit logs, query analysis |
| **Database links** | Cross-database queries via Oracle DB links, SQL Server linked servers | `DBA_DB_LINKS` view, `sys.servers` catalog |
| **ETL pipelines** | Scheduled data movement between databases | ETL tool configuration (Informatica, Talend, SSIS, Airflow) |
| **Reporting/BI** | Reporting tools query the database directly | BI tool connection configuration (Tableau, Power BI, MicroStrategy) |
| **Batch jobs** | Scheduled jobs that read from or write to the database | Job scheduler review (Control-M, Autosys, cron) |
| **Replication** | Active-passive or active-active replication | Database replication configuration |
| **Backup/DR** | Disaster recovery dependencies | Backup tool configuration, DR runbooks |

### Building the Dependency Map

#### Step 1: Inventory All Databases
```
For each database instance:
  - DBMS type and version
  - Host, port, instance name
  - Size (GB)
  - Table count
  - Owner / responsible team
  - Current disposition (Refactor/API-Wrap/Retire/Retain)
```

#### Step 2: Discover Consumers
```
For each database:
  - Query active sessions / connection pools
  - Review application configuration files
  - Check ETL tool source/target configurations
  - Review reporting tool data source definitions
  - Audit firewall rules for inbound database connections
```

#### Step 3: Map Cross-Database Dependencies
```
For each database pair (A, B):
  - Does A have a DB link to B? (or vice versa)
  - Does an ETL pipeline move data from A to B?
  - Do any applications query both A and B in the same transaction?
  - Do batch jobs write to A and read from B (or vice versa)?
```

#### Step 4: Visualize and Validate
Produce a dependency graph showing:
- Nodes = databases (colored by disposition)
- Edges = dependency relationships (labeled by type)
- Clusters = databases that must migrate together
- Wave assignments = groups of clusters

### Example Dependency Notation

```
[HR_DB] --ETL--> [PAYROLL_DB] --DB_LINK--> [FINANCE_DB]
    |                  |
    |              [REPORTING_DB] (read-only consumer)
    |
[BENEFITS_DB] (shared consumer: BenefitsApp reads HR_DB and BENEFITS_DB)
```

**Implication**: HR_DB and BENEFITS_DB must migrate in the same wave (shared consumer). PAYROLL_DB must migrate before or with FINANCE_DB (DB link dependency). REPORTING_DB can migrate independently.

---

## Pre-Migration Validation Checklist

Complete this checklist before executing any production database migration:

### Environment Readiness
- [ ] Target DBMS instance provisioned and accessible
- [ ] Network connectivity verified (source → target, consumers → target)
- [ ] TLS certificates installed and validated
- [ ] Database user accounts created with appropriate permissions
- [ ] Monitoring and alerting configured for target instance
- [ ] Backup strategy configured and tested for target instance

### Schema Validation
- [ ] Schema migration scripts tested in non-production environment
- [ ] All tables, indexes, constraints, and sequences created successfully
- [ ] Stored procedures / functions converted and tested (if applicable)
- [ ] Triggers converted or replaced with application logic (if applicable)
- [ ] Views recreated and validated
- [ ] Character set and collation settings match requirements

### Data Migration Readiness
- [ ] Data volume estimated and storage provisioned
- [ ] ETL / migration tool configured and tested with sample data
- [ ] Data type mappings validated (especially: dates, numerics, LOBs, encoding)
- [ ] Row count baseline captured for all tables in source database
- [ ] Checksum / hash baseline captured for critical tables
- [ ] Large table migration strategy defined (partitioned load, parallel streams)

### Consumer Readiness
- [ ] All consumer applications identified and notified
- [ ] Connection strings / DSNs updated in consumer configurations (staged, not active)
- [ ] Consumer application tested against target database in non-production
- [ ] Rollback procedure documented for consumer cutover
- [ ] Consumer team on-call during migration window

### Operational Readiness
- [ ] Migration runbook reviewed and approved
- [ ] Maintenance window scheduled and communicated
- [ ] Rollback plan documented and tested
- [ ] Consent gate approvals obtained (data owner, security, operations, CAB)
- [ ] On-call roster confirmed for migration window
- [ ] Communication plan ready (status updates, escalation contacts)

---

## Post-Migration Validation

### Data Integrity Checks

| Check | Method | Pass Criteria |
|-------|--------|--------------|
| **Row count** | `SELECT COUNT(*) FROM <table>` on both source and target | Exact match for all tables |
| **Checksum** | Hash comparison of critical columns | SHA-256 match for sampled rows |
| **Referential integrity** | Foreign key constraint validation | Zero orphaned records |
| **Null analysis** | Compare NULL counts per column | Match within tolerance (< 0.01% variance) |
| **Range validation** | MIN/MAX of numeric and date columns | Match source ranges |
| **Sample comparison** | Random sample of 1,000 rows per table, full column comparison | 100% match |
| **Encoding verification** | Check for garbled characters in text columns | Zero encoding errors |

### Automated Validation Script Pattern

```sql
-- Row count comparison template
WITH source_counts AS (
    SELECT 'employees' AS table_name, COUNT(*) AS row_count FROM source_db.employees
    UNION ALL
    SELECT 'departments', COUNT(*) FROM source_db.departments
    UNION ALL
    SELECT 'transactions', COUNT(*) FROM source_db.transactions
),
target_counts AS (
    SELECT 'employees' AS table_name, COUNT(*) AS row_count FROM target_db.employees
    UNION ALL
    SELECT 'departments', COUNT(*) FROM target_db.departments
    UNION ALL
    SELECT 'transactions', COUNT(*) FROM target_db.transactions
)
SELECT
    s.table_name,
    s.row_count AS source_rows,
    t.row_count AS target_rows,
    CASE WHEN s.row_count = t.row_count THEN 'PASS' ELSE 'FAIL' END AS status
FROM source_counts s
JOIN target_counts t ON s.table_name = t.table_name;
```

### Performance Validation

| Metric | Method | Pass Criteria |
|--------|--------|--------------|
| **Query response time** | Run top-20 queries from production workload | Within 120% of source baseline |
| **Throughput** | Measure transactions/second under simulated load | Within 90% of source baseline |
| **Index effectiveness** | Compare EXPLAIN plans for critical queries | No full table scans on indexed columns |
| **Connection pool** | Verify connection pool sizing under peak load | No connection exhaustion |
| **Replication lag** | If using read replicas, measure replication delay | < 1 second under normal load |

### Security Validation

| Check | Method | Pass Criteria |
|-------|--------|--------------|
| **Access control** | Test each role against expected permissions | No over-provisioned access |
| **Encryption at rest** | Verify via DBMS configuration or cloud console | Enabled with FIPS-validated module |
| **Encryption in transit** | Verify TLS from consumer connections | TLS 1.2+ with approved cipher suites |
| **Audit logging** | Generate test events and verify log capture | All event types captured |
| **STIG compliance** | Run STIG checklist against target instance | CAT I = 0, CAT II within threshold |
| **Vulnerability scan** | Run ACAS/Nessus against target instance | No critical or high findings |

---

## Rollback Considerations for Database Migrations

### Rollback Strategy Selection

| Strategy | When to Use | Recovery Time | Data Loss Risk |
|----------|------------|---------------|---------------|
| **Hot standby** | Source database kept running in parallel during validation period | Minutes | None (source is authoritative) |
| **Backup restore** | Source database backed up before migration, restored if needed | Hours | Transactions during migration window |
| **Reverse ETL** | Data written to target during validation period is synced back to source | Hours–Days | Complex, risk of conflicts |
| **Blue-green cutover** | DNS/connection string switch between source and target | Minutes | Minimal (controlled cutover) |

### Recommended Approach: Parallel Operation with Cutover

```
Phase 1: Migration (maintenance window)
├── Take final source backup
├── Execute migration (ETL from source → target)
├── Validate data integrity
└── Keep source database running (read-only)

Phase 2: Validation (1–5 business days)
├── Route read traffic to target, write traffic to target
├── Monitor for errors, performance, data issues
├── Source remains available for rollback
└── Daily integrity checks

Phase 3: Cutover Decision
├── PASS → Decommission source (after retention period)
└── FAIL → Revert consumer connections to source
           Investigate and re-plan
```

### Rollback Triggers

Immediately initiate rollback if any of the following occur during or after migration:

| Trigger | Severity | Action |
|---------|----------|--------|
| Data loss detected (row counts don't match) | Critical | Immediate rollback |
| Referential integrity failures | Critical | Immediate rollback |
| Application errors exceed baseline by > 500% | High | Rollback within 1 hour |
| Query performance degraded > 200% of baseline | High | Investigate; rollback within 4 hours if unresolvable |
| Security control failure (audit logging not working) | High | Rollback within 4 hours |
| Consumer unable to connect | Medium | Troubleshoot first; rollback if not resolved within 2 hours |
| Encoding/character set issues in data | Medium | Assess scope; rollback if > 1% of records affected |

### Rollback Checklist

- [ ] Revert consumer connection strings to source database
- [ ] Verify source database is accepting writes
- [ ] Verify all consumer applications are functional against source
- [ ] Document what went wrong and root cause
- [ ] Preserve target database state for analysis (do not delete immediately)
- [ ] Schedule post-mortem within 48 hours
- [ ] Update wave plan based on findings
- [ ] Re-test in non-production before rescheduling migration

---

## Wave Planning Template

| Wave | Databases | Disposition | Dependencies | Target Date | Status |
|------|-----------|------------|-------------|-------------|--------|
| 0 | (Infrastructure setup) | N/A | None | Week 1–4 | |
| 1 | DB_A, DB_B | Refactor | Standalone | Week 5–10 | |
| 2 | DB_C, DB_D, DB_E | Refactor | DB_C → DB_D (ETL) | Week 11–18 | |
| 3 | DB_F, DB_G | API-Wrap + Refactor | Shared consumers | Week 19–26 | |
| 4 | DB_H (retire), DB_I | Retire, Retain | None | Week 27–32 | |

### Tracking Metrics

| Metric | Target |
|--------|--------|
| Databases migrated per wave | 1–10 (depends on complexity) |
| Migration success rate | > 95% first attempt |
| Rollbacks per wave | < 1 |
| Average downtime per migration | < 4 hours |
| Post-migration defects | < 2 per database |
| Wave schedule adherence | Within 1 week of plan |
