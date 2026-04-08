# Database Disposition Framework

## Overview

This framework provides a structured methodology for determining the modernization disposition of legacy databases within federal and enterprise environments. Every database in the portfolio must be assessed against a standard set of criteria and assigned one of four dispositions: **Refactor**, **API-Wrap**, **Retire**, or **Retain**.

---

## Disposition Criteria Matrix

Each database is scored across five dimensions. Scores range from 1 (low) to 5 (high).

| Criterion | Weight | 1 (Low) | 3 (Medium) | 5 (High) |
|-----------|--------|---------|------------|----------|
| **Schema Complexity** | 25% | < 20 tables, no stored procedures | 20–100 tables, moderate SP use | 100+ tables, heavy SP/trigger/view dependencies |
| **Age / Technical Debt** | 20% | < 5 years, modern DBMS | 5–15 years, supported but aging | 15+ years, EOL platform or unsupported version |
| **Business Criticality** | 25% | Non-critical, limited users | Departmental, moderate user base | Mission-critical, agency-wide, 24/7 availability |
| **Downstream Dependencies** | 20% | Standalone, single consumer | 2–5 consumers, some ETL pipelines | 6+ consumers, cross-system joins, shared tables |
| **Documentation Quality** | 10% | Comprehensive, current ERD and data dictionary | Partial documentation, some tribal knowledge | No documentation, all tribal knowledge |

### Composite Score Interpretation

| Score Range | Recommended Starting Disposition |
|-------------|--------------------------------|
| 1.0 – 2.0 | **Retire** or **Retain** — Low complexity, limited value |
| 2.1 – 3.0 | **Retain** or **API-Wrap** — Moderate complexity, stable enough to defer |
| 3.1 – 4.0 | **API-Wrap** — High enough complexity/criticality to warrant isolation |
| 4.1 – 5.0 | **Refactor** or **API-Wrap** — High complexity and criticality demand active modernization |

> **Note:** Composite scores provide a starting recommendation. Final disposition requires human judgment, stakeholder input, and alignment with the parent application's disposition.

---

## Decision Tree: Refactor vs API-Wrap vs Retire vs Retain

```
START: Is the database actively used?
│
├── NO → Is data retention required (legal/regulatory)?
│         ├── YES → Archive data to approved cold storage → RETIRE
│         └── NO  → Decommission immediately → RETIRE
│
└── YES → Is the DBMS platform supported and compliant?
          │
          ├── YES → Are consumers stable and well-understood?
          │         │
          │         ├── YES → Is the cost of continued operation acceptable?
          │         │         ├── YES → RETAIN (re-evaluate annually)
          │         │         └── NO  → REFACTOR to cost-effective platform
          │         │
          │         └── NO  → Are there > 3 uncoordinated consumers?
          │                   ├── YES → API-WRAP to isolate consumers, then evaluate REFACTOR
          │                   └── NO  → REFACTOR with coordinated consumer migration
          │
          └── NO  → Is migration risk manageable (< 100 tables, good documentation)?
                    ├── YES → REFACTOR to supported platform
                    └── NO  → API-WRAP first to stabilize, then plan phased REFACTOR
```

---

## COBOL/DB2 Disposition Rules

COBOL/DB2 systems present unique disposition challenges due to the tight coupling between application logic and data access patterns. Apply these rules in order:

### Rule 1: Never Refactor DB2 Without Decoupling COBOL First
If COBOL programs contain embedded SQL (EXEC SQL blocks), the database cannot be migrated independently. Either:
- API-Wrap the DB2 instance and redirect COBOL programs to the API layer, OR
- Modernize the COBOL application and database together as a single unit

### Rule 2: Assess Batch Window Dependencies
If the DB2 database participates in nightly batch processing:
- Map all batch jobs that read from or write to the database
- Identify table-level locks and commit frequency
- Any migration must preserve batch window timing or provide equivalent throughput

### Rule 3: Evaluate VSAM/IMS Co-Dependencies
If the COBOL application also reads from VSAM files or IMS databases:
- Treat the entire data tier (DB2 + VSAM + IMS) as a single disposition unit
- Do not migrate DB2 independently if VSAM/IMS data feeds into DB2 tables

### Rule 4: EBCDIC Data Conversion
If the DB2 instance stores EBCDIC-encoded data, packed decimal fields, or COMP-3 values:
- Add a mandatory data conversion validation phase to any Refactor plan
- Test conversion with representative production data samples before committing to migration

### Rule 5: Copybook-to-DDL Mapping
If schema definitions exist only in COBOL copybooks (not SQL DDL):
- Extract schema using specialized tooling (e.g., Micro Focus, AWS Mainframe Modernization)
- Validate extracted DDL against actual DB2 catalog before proceeding

### Disposition Summary for COBOL/DB2

| Condition | Disposition |
|-----------|------------|
| DB2 standalone, no embedded SQL in COBOL | REFACTOR to PostgreSQL/Aurora |
| DB2 with embedded SQL, < 3 consumers | API-WRAP, then phased REFACTOR |
| DB2 with embedded SQL, 3+ consumers | API-WRAP (long-term) |
| DB2 + VSAM + IMS co-dependent | API-WRAP entire data tier |
| DB2 no longer accessed, data retention required | RETIRE (archive) |
| DB2 no longer accessed, no retention requirement | RETIRE (decommission) |

---

## Dependency-Aware Disposition: Sequencing Shared Databases

When multiple applications share a database — or when databases share consumers through ETL, DB links, or cross-database queries — disposition decisions cannot be made in isolation.

### Step 1: Build the Dependency Graph
Map all database-to-consumer relationships:
- Direct SQL connections (application → database)
- ETL pipelines (database A → ETL → database B)
- Database links (cross-database joins)
- Reporting and analytics consumers
- Batch job dependencies

### Step 2: Identify Disposition Conflicts
A disposition conflict occurs when:
- Database A is marked RETIRE but Database B (which depends on A) is marked RETAIN
- Database A is marked REFACTOR but its consumers cannot be migrated in the same wave
- Two databases share consumers but have different disposition timelines

### Step 3: Resolve Conflicts Using Sequencing Rules

| Conflict | Resolution |
|----------|-----------|
| Upstream RETIRE, downstream RETAIN | Upstream must API-WRAP (not RETIRE) until downstream migrates |
| Shared consumers across databases | Coordinate into the same migration wave |
| ETL dependency between databases | Migrate source database first, then ETL, then target |
| Cross-database joins via DB links | API-WRAP both databases, replace DB link with API call |

### Step 4: Document the Disposition Dependency Map
Create a visual dependency map showing:
- Each database and its disposition
- Consumer relationships (arrows)
- Migration wave assignment
- Conflict resolution notes

---

## Consent Gate Requirements for Production Database Changes

No production database change — migration, schema alteration, or decommission — proceeds without passing through the consent gate process.

### Required Approvals

| Approver | Scope | Criteria |
|----------|-------|----------|
| **Data Owner** | Business | Confirms data will be preserved, accessible, and accurate post-change |
| **Security (ISSM/ISSO)** | Security | Confirms the change maintains or improves the security posture (NIST 800-53 controls) |
| **Operations** | Infrastructure | Confirms operational readiness: backup strategy, rollback plan, monitoring |
| **Change Advisory Board (CAB)** | Governance | Confirms alignment with agency change management policy |

### Consent Gate Checklist

- [ ] Pre-migration backup completed and verified
- [ ] Rollback plan documented and tested
- [ ] Data integrity validation script prepared
- [ ] Performance baseline captured (pre-migration)
- [ ] Security controls verified for target environment
- [ ] Consumer notification completed (all downstream systems aware)
- [ ] Maintenance window scheduled and communicated
- [ ] Post-migration validation plan reviewed
- [ ] Incident response plan updated for migration-related failures
- [ ] ATO/CCRI impact assessment completed (if applicable)

### Gate Outcomes

| Outcome | Action |
|---------|--------|
| **APPROVED** | Proceed with migration in the scheduled maintenance window |
| **CONDITIONAL** | Proceed after addressing specified conditions (re-review required) |
| **DEFERRED** | Postpone to a future wave; document reason and re-evaluation date |
| **REJECTED** | Do not proceed; return to disposition assessment with CAB feedback |
