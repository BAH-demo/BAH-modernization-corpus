# SSP Summary: Apache OFBiz

**System Identifier:** apache-ofbiz  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

Apache OFBiz (Open For Business) is an open-source enterprise resource planning (ERP) system providing comprehensive business automation capabilities including accounting, inventory management, manufacturing, order management, CRM, and e-commerce. In the federal context, OFBiz supports back-office financial and supply chain operations.

**Tier Classification:** Tier 1 — Enterprise Monolith (100K+ LOC)  
**Primary Function:** Enterprise Resource Planning and Business Process Automation  
**User Base:** Internal agency staff (finance, procurement, logistics)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System processes financial records, procurement data, and personnel information; unauthorized disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Financial transaction integrity is critical; unauthorized modification could result in incorrect financial reporting |
| **Availability** | Moderate | System supports daily business operations; extended outage would significantly impact mission functions |

**Overall System Categorization:** **Moderate**

`SC apache-ofbiz = {(confidentiality, moderate), (integrity, moderate), (availability, moderate)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | Java 8 | 1.8.x | EOL (March 2022 for public updates) |
| Framework | javax.servlet, Java EE | javax.* namespace | Deprecated/EOL |
| Build Tool | Gradle | Legacy version | Outdated |
| Application Server | Embedded Tomcat | 8.x/9.x | Legacy |
| Database | Derby/PostgreSQL | Various | Active |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | Java 17 LTS | 17.x | September 2029 |
| Framework | Jakarta EE (jakarta.* namespace) | Jakarta EE 10 | Active |
| Build Tool | Gradle | Current | Active |
| Application Server | Embedded Tomcat 10.1+ | 10.1.x | Active |
| Database | PostgreSQL | Current | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- **javax→jakarta namespace migration:** Eliminates CVEs associated with deprecated Java EE libraries (e.g., CVE-2021-28170 in javax.el, CVE-2020-1938 in legacy AJP connectors)
- **Java 17 upgrade:** Addresses JDK-level vulnerabilities present in Java 8 (CVE-2022-21449 — ECDSA signature bypass, CVE-2022-21476 — XML parsing)
- **Dependency updates:** Transitive dependencies updated to patched versions

### 4.2 CM-2 Baseline Configuration
- Runtime pinned to Java 17 LTS
- All dependencies version-locked in build manifests
- SBOM generation enabled via CycloneDX Gradle plugin

### 4.3 SC-8 Transmission Confidentiality
- Java 17 supports TLS 1.3 natively
- Deprecated TLS 1.0/1.1 cipher suites removed from default configuration
- FIPS 140-2 validated crypto providers available (SunJCE, Bouncy Castle FIPS)

### 4.4 SC-13 Cryptographic Protection
- Java 17 JCE includes FIPS-capable providers
- SHA-256/SHA-384 hashing available for password storage
- Key management via Java KeyStore (JKS) or PKCS#12

### 4.5 AC-3 Access Enforcement
- Jakarta Security API enables declarative RBAC (`@RolesAllowed`, `@DenyAll`, `@PermitAll`)
- Modern servlet filter chain for request-level authorization

### 4.6 AU-2 Event Logging
- SLF4J 2.x with Logback for structured JSON logging
- MDC (Mapped Diagnostic Context) for correlation IDs
- OpenTelemetry-compatible instrumentation

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| OFBIZ-001 | Legacy global state patterns remain in codebase | Shared mutable state may introduce race conditions and data leakage between user sessions | Medium | Open | Q3 2026 |
| OFBIZ-002 | Large monolithic architecture limits blast radius containment | Single vulnerability could compromise entire ERP surface | Medium | Open | Q4 2026 |
| OFBIZ-003 | Custom ORM may not fully leverage parameterized queries | Potential for SQL injection in complex query builders | Medium | Open | Q3 2026 |
| OFBIZ-004 | Runtime regression testing incomplete | Not all business flows validated post-migration | Low | Open | Q2 2026 |
| OFBIZ-005 | Third-party plugin compatibility with Jakarta namespace unverified | Plugins using javax.* may fail at runtime | Medium | Open | Q3 2026 |

---

## 6. Recommended Authorization Boundary

The apache-ofbiz authorization boundary should include:

- **Application tier:** OFBiz application server (Tomcat embedded), all deployed OFBiz components and plugins
- **Data tier:** PostgreSQL database server storing financial, inventory, and user data
- **Web tier:** Reverse proxy/load balancer handling TLS termination
- **Integration tier:** API endpoints for external system connections (procurement, HR, financial reporting)
- **Supporting services:** LDAP/AD integration for authentication, SMTP for notifications, file storage for document management

**Boundary Exclusions (Inherited Controls):**
- Underlying IaaS/PaaS infrastructure (if FedRAMP-authorized)
- Physical data center controls
- Network perimeter firewalls (managed by NOC)

**Interconnections Requiring ISA:**
- Financial reporting systems (outbound data feed)
- Procurement gateway (bidirectional API)
- Identity provider (SAML/OIDC — inbound authentication)
- SIEM platform (outbound log shipping)
