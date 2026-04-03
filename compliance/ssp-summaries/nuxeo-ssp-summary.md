# SSP Summary: Nuxeo

**System Identifier:** nuxeo  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

Nuxeo is an open-source content services platform providing document management, digital asset management (DAM), and case management capabilities. In the federal context, Nuxeo supports mission-critical content workflows including case file management, FOIA request processing, and digital asset cataloging.

**Tier Classification:** Tier 1 — Enterprise Monolith (100K+ LOC)  
**Primary Function:** Content Services Platform and Digital Asset Management  
**User Base:** Internal agency staff (case workers, FOIA processors, content managers)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System stores case files, FOIA requests, and internal documents; unauthorized disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Document integrity required for legal and regulatory compliance; modification would undermine case management |
| **Availability** | Moderate | Case processing depends on system availability; extended outage would delay mission-critical workflows |

**Overall System Categorization:** **Moderate**

`SC nuxeo = {(confidentiality, moderate), (integrity, moderate), (availability, moderate)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | Java 8/11 | 1.8.x / 11.x | EOL / Maintenance |
| Framework | javax.* namespace, JAX-RS | javax.ws.rs | Deprecated |
| Content Repository | Nuxeo Core (VCS/DBS) | Legacy | Active |
| Search | Elasticsearch | Legacy version | Outdated |
| Database | PostgreSQL/MongoDB | Various | Active |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | Java 17 LTS | 17.x | September 2029 |
| Framework | Jakarta EE (jakarta.* namespace) | Jakarta EE 10 | Active |
| Content Repository | Nuxeo Core (updated) | Current | Active |
| Search | Elasticsearch | Current | Active |
| Database | PostgreSQL/MongoDB | Current | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- javax→jakarta migration resolves deprecated Java EE CVEs
- Java 17 addresses deserialization vulnerabilities critical for content management systems
- JAX-RS (javax.ws.rs→jakarta.ws.rs) update fixes REST API security issues

### 4.2 CM-8 System Component Inventory
- SBOM generation enabled via Maven BOM and CycloneDX
- All Nuxeo bundles and plugins inventoried with version tracking

### 4.3 AC-3 Access Enforcement
- Jakarta Security API for declarative access control on REST endpoints
- Document-level ACLs enforced through modernized security framework

### 4.4 AU-12 Audit Record Generation
- Nuxeo audit log enhanced with structured JSON output
- OpenTelemetry instrumentation for distributed request tracing

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| NUX-001 | Complex plugin architecture may have unmigrated javax.* references | Runtime failures in third-party Nuxeo packages | Medium | Open | Q3 2026 |
| NUX-002 | Elasticsearch index contains sensitive document metadata | Information disclosure if search cluster is compromised | Medium | Open | Q3 2026 |
| NUX-003 | Custom Nuxeo Automation chains not fully regression tested | Automated workflows may produce incorrect results post-migration | Medium | Open | Q2 2026 |
| NUX-004 | MongoDB document store encryption-at-rest not verified post-migration | Data-at-rest protection gap | High | Open | Q2 2026 |

---

## 6. Recommended Authorization Boundary

The nuxeo authorization boundary should include:

- **Application tier:** Nuxeo Server, REST API endpoints, Nuxeo Web UI
- **Search tier:** Elasticsearch cluster
- **Data tier:** PostgreSQL/MongoDB database, binary/blob storage (S3 or filesystem)
- **Processing tier:** Document rendition and conversion services
- **Integration tier:** CMIS, REST API, Nuxeo Automation endpoints

**Boundary Exclusions (Inherited Controls):**
- Underlying IaaS/PaaS infrastructure
- Physical data center controls
- Network perimeter firewalls

**Interconnections Requiring ISA:**
- Identity provider (SAML/OIDC)
- External content sources (inbound data feeds)
- Records management system (outbound retention)
- SIEM platform (outbound log shipping)
