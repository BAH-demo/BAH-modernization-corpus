# SSP Summary: Monolith Enterprise

**System Identifier:** monolith-enterprise  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

Monolith Enterprise is a large-scale Java enterprise application representing a canonical monolithic architecture pattern. The system encompasses multiple business domains within a single deployable unit, providing integrated enterprise services. In the federal context, it serves as a consolidated mission-support platform.

**Tier Classification:** Tier 1 — Enterprise Monolith (100K+ LOC)  
**Primary Function:** Consolidated Enterprise Service Platform  
**User Base:** Internal agency staff across multiple business units

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System processes cross-domain business data; unauthorized disclosure could cause serious adverse effect across multiple business units |
| **Integrity** | Moderate | Business process integrity required across integrated domains; unauthorized modification could cascade through tightly coupled modules |
| **Availability** | High | Single monolithic deployment means any outage impacts all business functions simultaneously; extended outage would cause severe mission impact |

**Overall System Categorization:** **High** (due to Availability high-water mark)

`SC monolith-enterprise = {(confidentiality, moderate), (integrity, moderate), (availability, high)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | Java 8 | 1.8.x | EOL |
| Framework | Java EE (javax.* namespace) | Full Java EE stack | Deprecated |
| Application Server | JBoss/WildFly or WebLogic | Legacy version | Outdated |
| Database | Oracle/PostgreSQL | Various | Active |
| Build | Maven/Ant | Legacy configuration | Active |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | Java 17 LTS | 17.x | September 2029 |
| Framework | Jakarta EE (jakarta.* namespace) | Jakarta EE 10 | Active |
| Application Server | WildFly/Payara (Jakarta EE compatible) | Current | Active |
| Database | PostgreSQL | Current | Active |
| Build | Maven | Current | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- Full javax→jakarta namespace migration across the entire monolith
- Java 17 upgrade resolves known JDK vulnerabilities
- Application server upgrade eliminates known container-level CVEs

### 4.2 CM-2 Baseline Configuration
- Complete dependency inventory captured in Maven BOM
- All dependency versions locked; SBOM generated
- Application server configuration baselined and version-controlled

### 4.3 AC-6 Least Privilege
- Java 17 Module System (JPMS) enables module-level access boundaries within the monolith
- Internal APIs can be encapsulated, reducing unintended cross-module access

### 4.4 SC-39 Process Isolation
- JPMS module boundaries provide logical isolation between business domains
- Preparation for future microservice decomposition with clear module interfaces

### 4.5 AU-2 Event Logging
- Centralized logging via SLF4J 2.x across all modules
- Structured JSON output with per-module log separation
- Correlation IDs for cross-module request tracing

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| MONO-001 | Single deployment unit creates single point of failure | Any vulnerability compromises all business domains; blast radius is entire enterprise | High | Open | Q4 2026 |
| MONO-002 | Tight coupling between modules limits independent patching | Security patches require full regression testing across all domains | High | Open | Q4 2026 |
| MONO-003 | Shared database with cross-domain data | Data isolation insufficient for compartmentalization requirements | Medium | Open | Q3 2026 |
| MONO-004 | Complex dependency graph makes SBOM validation difficult | Transitive dependency vulnerabilities may be missed | Medium | Open | Q3 2026 |
| MONO-005 | Full regression test suite for monolith is time-consuming | Delays security patch deployment beyond SLA windows | Medium | Open | Q3 2026 |

---

## 6. Recommended Authorization Boundary

The monolith-enterprise authorization boundary should include:

- **Application tier:** Full monolithic application deployment (all modules)
- **Application server tier:** WildFly/Payara container
- **Data tier:** PostgreSQL/Oracle database (all schemas)
- **Integration tier:** All inbound/outbound API endpoints, message queues
- **Supporting services:** Session management, caching layer, scheduled jobs

**Boundary Exclusions (Inherited Controls):**
- Underlying IaaS/PaaS infrastructure
- Physical data center controls
- Network perimeter firewalls

**Interconnections Requiring ISA:**
- Each integrated business domain's external systems
- Identity provider (SAML/OIDC)
- Enterprise service bus (if applicable)
- SIEM platform (outbound log shipping)
- Backup/DR systems

**Note:** Due to the monolithic architecture, the authorization boundary encompasses a larger surface area than a decomposed system. Future modernization phases should consider microservice decomposition to reduce authorization boundary scope per component.
