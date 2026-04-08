# Database Modernization — Executive Summary

## Why Databases Are Different from Code Modernization

Code modernization and database modernization are fundamentally different disciplines. While application code can be refactored, rewritten, or replaced with relative independence, databases carry **stateful, persistent data** that represents years — sometimes decades — of accumulated business records, audit trails, and institutional knowledge. A failed code deployment can be rolled back in minutes; a failed database migration can result in data loss, regulatory violations, or prolonged system outages.

Key differences include:

| Dimension | Code Modernization | Database Modernization |
|-----------|-------------------|----------------------|
| **State** | Stateless (rebuild from source) | Stateful (data must be preserved and migrated) |
| **Rollback** | Redeploy previous version | Complex — requires backup restoration, may lose transactions |
| **Dependencies** | Compile-time / runtime linkages | Shared consumers, ETL pipelines, reporting, cross-system joins |
| **Validation** | Unit tests, integration tests | Data integrity checks, referential consistency, row-count verification |
| **Downtime Risk** | Service-level (restart) | Data-level (corruption, loss) |
| **Regulatory** | Moderate | High — audit trails, data retention, encryption-at-rest mandates |

Database modernization demands a disposition-first approach: before writing a single migration script, every database must be assessed, categorized, and sequenced based on risk, complexity, and downstream impact.

---

## Disposition Strategies

Every legacy database falls into one of four disposition categories:

### Refactor
Migrate the schema and data to a modern DBMS (e.g., Oracle to PostgreSQL, DB2 to Aurora). Refactor stored procedures into application logic. Appropriate when the data model is sound but the platform is end-of-life or cost-prohibitive.

### API-Wrap
Leave the database in place but encapsulate access behind a modern API layer. Consumers interact with REST/gRPC endpoints instead of direct SQL connections. Appropriate when migration risk is too high or when the database serves many uncoordinated consumers.

### Retire
Decommission the database entirely. Archive data to cold storage (S3, Glacier, or agency-approved archive). Appropriate when the system is no longer actively used or when data retention requirements can be satisfied by archive alone.

### Retain
Keep the database as-is with no changes. Appropriate only when the database is stable, compliant, actively maintained, and the cost of change exceeds the cost of continued operation.

---

## COBOL/DB2 Specific Considerations for Federal Estates

Federal agencies — particularly within DoD, VA, SSA, and IRS — maintain large COBOL/DB2 estates that present unique modernization challenges:

- **Embedded SQL in COBOL programs**: DB2 queries are inline in COBOL source, making database and application boundaries indistinguishable
- **VSAM and IMS dependencies**: Many COBOL systems use pre-relational data stores that have no direct modern equivalent
- **Batch processing windows**: Nightly batch cycles are tightly coupled to DB2 table locks and commit strategies
- **EBCDIC encoding**: Character set conversion introduces subtle data corruption risks (packed decimal, COMP-3 fields)
- **Copybook-driven schemas**: Data structures are defined in COBOL copybooks, not SQL DDL — schema extraction requires specialized tooling

The recommended approach for COBOL/DB2 estates is typically **API-Wrap first, Refactor second**: expose DB2 data through a managed API layer to decouple consumers, then migrate the underlying data store once consumer dependencies are isolated.

---

## Common Federal DBMS Platforms and Modernization Paths

| Legacy Platform | Common In | Modernization Target | Notes |
|----------------|-----------|---------------------|-------|
| **Oracle 11g/12c** | DoD, DHS, VA | PostgreSQL (RDS/Aurora) | Most common federal migration path; FedRAMP-authorized targets available |
| **DB2 (z/OS)** | SSA, IRS, VA | PostgreSQL, Aurora | Requires COBOL decoupling; often API-Wrap first |
| **SQL Server (legacy)** | Civilian agencies | Azure SQL, PostgreSQL | Lift-and-shift to cloud SQL is often simplest |
| **Sybase ASE** | DoD legacy | PostgreSQL, MySQL | End-of-life; urgent migration typically required |
| **IMS/VSAM** | Mainframe agencies | DynamoDB, DocumentDB, PostgreSQL | Requires data model transformation, not just migration |
| **Informix** | Older civilian systems | PostgreSQL | Small install base; straightforward migration |
| **Microsoft Access** | Field offices, ad-hoc | PostgreSQL, cloud-native | Often undocumented; requires discovery phase |

---

## Integration with the ATLAS Engineering Invariants Framework

Database modernization integrates with the broader ATLAS Engineering Invariants framework at several key points:

1. **Discovery & Inventory**: Database assets are cataloged alongside application assets during the initial portfolio discovery phase. Schema complexity metrics feed into the overall system disposition scoring.

2. **Disposition Alignment**: Database disposition (Refactor/API-Wrap/Retire/Retain) must align with the parent application's disposition. A database cannot be retired if its consuming application is being retained.

3. **Wave Planning**: Database migrations are sequenced within the same wave structure used for application modernization. Databases with shared consumers must be coordinated across waves to prevent breaking changes.

4. **Consent Gates**: Production database changes require explicit consent gates — no database migration proceeds without sign-off from the data owner, the security team, and the operations team.

5. **Verification**: Post-migration verification follows the same invariant-based validation approach: data integrity checks, performance baselines, and security control verification are codified as testable invariants.

---

## Reference Data

This framework is informed by the [db-schema-corpus](https://github.com/mmartoccia/db-schema-corpus), which provides reference schemas from ERP systems (Odoo, ERPNext, Northwind), Oracle EBS/PeopleSoft HRMS packages, and federal government data models (NIST CORR). These schemas serve as representative examples of the complexity encountered in real federal database modernization engagements.
