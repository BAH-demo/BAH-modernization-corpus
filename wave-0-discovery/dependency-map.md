# ATLAS Modernization Factory — Cross-System Dependency Map

**Document ID:** ATLAS-W0-DEP-001
**Classification:** CUI // Pre-Decisional
**Prepared:** April 2026
**Portfolio Scope:** FAA Legacy Systems — Representative Sample (14 of ~3,000)

---

## 1. Purpose

This document maps cross-system dependencies among the 14 legacy systems analyzed during Wave 0 Discovery. Dependency analysis drives wave sequencing: systems that share databases, API consumers, integration points, or infrastructure must be grouped into migration clusters and sequenced to prevent downstream breakage.

---

## 2. Dependency Analysis Methodology

Dependencies were identified through the following analysis vectors:

| Vector | Method |
|--------|--------|
| **Shared Data Models** | Examination of database schema patterns, ORM configurations, and data access layers |
| **API Dependencies** | Identification of REST/SOAP/RPC call patterns between systems |
| **Language/Runtime Coupling** | Systems sharing the same runtime, build toolchain, or deployment pipeline |
| **Domain Overlap** | Systems operating in the same business domain with potential data flow linkages |
| **Infrastructure Dependencies** | Shared application servers, middleware, message queues, or authentication systems |

---

## 3. Identified Dependency Clusters

### Cluster A — Java Enterprise Platform (5 systems)

| System | Relationship | Dependency Type |
|--------|-------------|-----------------|
| **Apache OFBiz** | Central ERP hub | Shared data model (entity engine); provides business services consumed by downstream systems |
| **Alfresco Community** | Document management | Content repository services; CMIS API surface shared with Nuxeo |
| **Nuxeo** | Document management | CMIS-compatible API; overlapping content model with Alfresco |
| **B2CWeb** | E-Commerce front-end | Depends on ERP-pattern business logic; tight coupling to Java servlet container |
| **Monolith Enterprise** | Generic enterprise app | Shares Java EE deployment patterns; potential shared JNDI/datasource configuration |

**Shared Infrastructure:**
- Java EE / Servlet container (Tomcat, WildFly, or equivalent)
- JDBC datasource configuration patterns
- Maven/Gradle build pipelines
- Potential shared LDAP/Active Directory authentication

**Migration Constraint:** Apache OFBiz is the highest-risk system in this cluster. Its entity engine data model is a dependency root — any system consuming OFBiz services or sharing its database schema cannot be safely migrated until OFBiz interfaces are stabilized or wrapped.

**Recommended Sequencing:** Wrap OFBiz APIs first (stabilize interfaces) → migrate smaller Java consumers (B2CWeb, Monolith Enterprise) → address Alfresco/Nuxeo document management pair.

---

### Cluster B — Python Web Applications (3 systems)

| System | Relationship | Dependency Type |
|--------|-------------|-----------------|
| **Odoo** | Central ERP/CRM | Multi-module business platform; ORM-driven data model; plugin architecture |
| **Django Oscar** | E-Commerce framework | Django ORM; potential shared authentication backend with Odoo if co-deployed |
| **Mezzanine** | CMS framework | Django-based; overlapping middleware and authentication patterns with Django Oscar |

**Shared Infrastructure:**
- Python runtime (2.x legacy or 3.x)
- Django framework and ORM layer
- PostgreSQL / MySQL database backends
- WSGI application servers (Gunicorn, uWSGI)
- Potential shared Celery task queues

**Migration Constraint:** Django Oscar and Mezzanine both depend on the Django framework and potentially share database backends. Odoo operates as an independent ERP but may share authentication infrastructure if co-deployed in a federal environment.

**Recommended Sequencing:** Migrate Django Oscar and Mezzanine together (shared Django stack) → address Odoo independently given its self-contained module architecture.

---

### Cluster C — .NET / C# Applications (2 systems)

| System | Relationship | Dependency Type |
|--------|-------------|-----------------|
| **Umbraco CMS** | Content management | .NET runtime; SQL Server backend; IIS deployment |
| **DFe.NET** | Fiscal invoicing | .NET runtime; XML/SOAP integration layer; potential shared certificate store |

**Shared Infrastructure:**
- .NET Framework / .NET Core runtime
- IIS or Kestrel web server
- SQL Server or equivalent RDBMS
- Windows Server deployment environment
- Potential shared PKI / certificate infrastructure (especially for DFe.NET fiscal signing)

**Migration Constraint:** Moderate coupling. Both systems share the .NET runtime and potentially Windows Server infrastructure, but operate in different business domains. Can be migrated in parallel if infrastructure dependencies are addressed.

**Recommended Sequencing:** Migrate together in a single wave to consolidate .NET infrastructure modernization effort.

---

### Cluster D — Federal Legacy / Mission-Critical (3 systems)

| System | Relationship | Dependency Type |
|--------|-------------|-----------------|
| **CICS Banking Sample** | Mainframe banking | CICS transaction server; VSAM/DB2 data stores; 3270 terminal interface |
| **NASTRAN-95** | Scientific computing | Fortran runtime; batch processing; specialized numerical libraries |
| **Apollo-11** | Historical mission code | Assembly; no active runtime dependencies; archival/reference system |

**Shared Infrastructure:**
- Mainframe environment (CICS Banking Sample)
- HPC / batch scheduling (NASTRAN-95)
- No shared runtime between these three systems

**Migration Constraint:** These systems share no direct runtime or data dependencies with each other or with Clusters A–C. However, they represent the highest-risk modernization targets due to language scarcity (COBOL, Fortran, Assembly), lack of automated test coverage, and mission-critical operational status.

> **CRITICAL FLAG:** COBOL and Assembly systems are designated API-Wrap or Retain ONLY. Transpilation is **NOT** recommended in Year 1. See `disposition-decisions.md` for rationale.

**Recommended Sequencing:** Address last (Wave 5). Wrap CICS Banking Sample and NASTRAN-95 behind modern API layers. Retain Apollo-11 as archival reference.

---

### Cluster E — Standalone / Low-Dependency (1 system)

| System | Relationship | Dependency Type |
|--------|-------------|-----------------|
| **CFWheels** | ColdFusion web framework | Adobe ColdFusion / Lucee runtime; standalone deployment |

**Shared Infrastructure:**
- ColdFusion runtime (Adobe or Lucee)
- Java-based application server (underlying ColdFusion)
- Potential shared JDBC datasources with Cluster A Java systems

**Migration Constraint:** CFWheels is the only ColdFusion system in the portfolio. The ColdFusion runtime is end-of-mainstream-support, making skilled developer availability a significant risk. No other system depends on CFWheels.

**Recommended Sequencing:** Retire in Wave 2. No downstream dependencies to clear.

---

## 4. Cross-Cluster Dependency Matrix

| | Cluster A (Java) | Cluster B (Python) | Cluster C (.NET) | Cluster D (Federal) | Cluster E (CF) |
|---|---|---|---|---|---|
| **Cluster A (Java)** | — | LOW: Potential shared auth (LDAP) | NONE | NONE | LOW: Shared Java underpinning |
| **Cluster B (Python)** | LOW | — | NONE | NONE | NONE |
| **Cluster C (.NET)** | NONE | NONE | — | NONE | NONE |
| **Cluster D (Federal)** | NONE | NONE | NONE | — | NONE |
| **Cluster E (CF)** | LOW | NONE | NONE | NONE | — |

**Legend:**
- **NONE** — No identified dependency; clusters can migrate independently
- **LOW** — Potential shared infrastructure (authentication, directory services); requires validation but unlikely to block migration
- **MEDIUM** — Shared data store or API dependency; must be addressed before parallel migration
- **HIGH** — Direct runtime dependency; must migrate together or stabilize interface first

---

## 5. Shared Infrastructure Components

The following infrastructure components are shared across multiple systems and must be addressed as part of wave planning:

| Component | Systems Affected | Risk if Not Addressed |
|-----------|-----------------|----------------------|
| **LDAP / Active Directory** | All Java, Python, .NET systems (potential) | Authentication failure during migration |
| **PostgreSQL / MySQL** | Odoo, Django Oscar, Mezzanine | Data integrity risk if schema changes not coordinated |
| **SQL Server** | Umbraco CMS, DFe.NET | Shared instance migration must be coordinated |
| **Java EE App Server** | Apache OFBiz, Alfresco, Nuxeo, B2CWeb, Monolith Enterprise | Deployment disruption during container migration |
| **CICS Transaction Server** | CICS Banking Sample | Mainframe dependency; requires API gateway before any migration |
| **PKI / Certificate Store** | DFe.NET (fiscal signing), potentially Umbraco (HTTPS) | Certificate rotation must be coordinated |
| **Batch Scheduling** | NASTRAN-95 | HPC job scheduler dependency |

---

## 6. Dependency-Driven Sequencing Implications

Based on the dependency analysis above, the following sequencing rules are derived:

1. **Rule 1 — Cluster Independence:** Clusters A, B, C, D, and E have no HIGH or MEDIUM cross-cluster dependencies. Waves can draw from multiple clusters simultaneously.

2. **Rule 2 — Intra-Cluster Ordering (Cluster A):** Within the Java Enterprise cluster, Apache OFBiz must have its API interfaces stabilized before B2CWeb or Monolith Enterprise can be safely migrated. Alfresco and Nuxeo should be addressed as a pair.

3. **Rule 3 — Intra-Cluster Ordering (Cluster B):** Django Oscar and Mezzanine should migrate together due to shared Django infrastructure. Odoo is independent.

4. **Rule 4 — Federal Systems Last:** Cluster D systems carry the highest risk and require specialized expertise (COBOL, Fortran, Assembly). They should be scheduled in the final wave with dedicated consent gates.

5. **Rule 5 — ColdFusion Retirement:** CFWheels has no downstream dependents. It can be retired in any wave without blocking other systems.

6. **Rule 6 — Infrastructure First:** Shared infrastructure components (LDAP, database instances, app servers) must be assessed and migration-ready before the systems they support enter execution.

---

## 7. Consent Gate Notice

> **CONSENT GATE — MANDATORY**
>
> No migration activity shall commence for any dependency cluster without explicit approval from the designated Authorizing Official. Dependency analysis findings in this document are subject to validation during detailed technical assessment. Changes to identified dependency relationships may alter wave sequencing.

---

*Prepared by ATLAS Modernization Factory — Wave 0 Discovery*
*All recommendations subject to federal program leadership review and approval*
