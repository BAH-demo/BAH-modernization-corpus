# System Security Plan (SSP) Template — Federal Legacy Modernization

**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only  
**Applicable Standards:** NIST SP 800-18 Rev 1, NIST SP 800-53 Rev 5, FIPS 199, FIPS 200  
**FedRAMP Baseline:** Moderate (adjust per system FIPS 199 categorization)

---

## Instructions

This template follows NIST SP 800-18 Rev 1 (Guide for Developing Security Plans for Federal Information Systems). Complete each section for the target system. Pre-filled values reflect the modernized technology stack; update as needed for your specific deployment.

---

## 1. System Identification

### 1.1 System Name and Identifier

| Field | Value |
|-------|-------|
| **System Name** | [Full system name] |
| **System Abbreviation** | [Abbreviation/acronym] |
| **System Unique Identifier** | [Agency FISMA ID, e.g., GSA-XXXXX-MAJ] |
| **System Version** | [Post-modernization version, e.g., 2.0-modernized] |

### 1.2 System Owner

| Field | Value |
|-------|-------|
| **System Owner Name** | [Name] |
| **System Owner Title** | [Title] |
| **System Owner Organization** | [Agency/Bureau/Office] |
| **System Owner Email** | [Email] |
| **System Owner Phone** | [Phone] |

### 1.3 Authorizing Official

| Field | Value |
|-------|-------|
| **AO Name** | [Name] |
| **AO Title** | [Title] |
| **AO Organization** | [Agency/Bureau/Office] |
| **AO Email** | [Email] |

### 1.4 Other Designated Contacts

| Role | Name | Organization | Email | Phone |
|------|------|-------------|-------|-------|
| Information System Security Officer (ISSO) | [Name] | [Org] | [Email] | [Phone] |
| Information System Security Manager (ISSM) | [Name] | [Org] | [Email] | [Phone] |
| Privacy Officer | [Name] | [Org] | [Email] | [Phone] |
| Configuration Manager | [Name] | [Org] | [Email] | [Phone] |

### 1.5 System Operational Status

- [ ] Operational
- [ ] Under Development
- [ ] Major Modification ← *Expected for modernized systems*
- [ ] Other: ___________

### 1.6 Assignment of Security Responsibility

| Field | Value |
|-------|-------|
| **ISSO Name** | [Name] |
| **ISSO Organization** | [Org] |
| **Date Assigned** | [Date] |

---

## 2. System Categorization (FIPS 199)

### 2.1 Information Types

Complete per NIST SP 800-60 Vol II. List all information types processed, stored, or transmitted.

| Information Type | NIST 800-60 Identifier | Confidentiality | Integrity | Availability |
|-----------------|----------------------|-----------------|-----------|--------------|
| [e.g., Administrative Information] | [D.x.x] | [Low/Moderate/High] | [Low/Moderate/High] | [Low/Moderate/High] |
| [e.g., Financial Information] | [D.x.x] | [Low/Moderate/High] | [Low/Moderate/High] | [Low/Moderate/High] |
| [e.g., Mission-Critical Data] | [D.x.x] | [Low/Moderate/High] | [Low/Moderate/High] | [Low/Moderate/High] |

### 2.2 Overall System Categorization

Per FIPS 199, the system categorization is the **high-water mark** across all information types:

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | [Low/Moderate/High] | [Rationale] |
| **Integrity** | [Low/Moderate/High] | [Rationale] |
| **Availability** | [Low/Moderate/High] | [Rationale] |

**Overall System Categorization:** **[Low / Moderate / High]**

**SC Template:**  
`SC {system name} = {(confidentiality, [impact]), (integrity, [impact]), (availability, [impact])}`

### 2.3 Categorization Reviewed By

| Name | Title | Date |
|------|-------|------|
| [Name] | [Title] | [Date] |

---

## 3. System Description and Purpose

### 3.1 System Function or Purpose

[Describe the system's mission, business functions, and purpose. Include the operational context and how it supports the agency's mission.]

### 3.2 System Environment

**Pre-Modernization Stack:**

| Component | Technology | Version | EOL Status |
|-----------|-----------|---------|------------|
| Runtime | [e.g., Java 8 / Python 2.7 / .NET Framework 4.x] | [Version] | [EOL/Active] |
| Framework | [e.g., javax.servlet / Django 2.x] | [Version] | [EOL/Active] |
| Database | [e.g., PostgreSQL / SQL Server / MySQL] | [Version] | [EOL/Active] |
| Web Server | [e.g., Tomcat / IIS / Nginx] | [Version] | [EOL/Active] |
| OS | [e.g., RHEL 7 / Windows Server 2016] | [Version] | [EOL/Active] |

**Post-Modernization Stack:**

| Component | Technology | Version | Support End Date |
|-----------|-----------|---------|-----------------|
| Runtime | [e.g., Java 17 LTS / Python 3.12 / .NET 8 LTS] | [Version] | [Date] |
| Framework | [e.g., Jakarta EE 10 / Django 5.x] | [Version] | [Date] |
| Database | [e.g., PostgreSQL 16 / SQL Server 2022] | [Version] | [Date] |
| Web Server | [e.g., Tomcat 10.1 / Kestrel] | [Version] | [Date] |
| OS | [e.g., RHEL 9 / Windows Server 2022] | [Version] | [Date] |

### 3.3 User Roles and Access

| User Role | Privileges | Number of Users | Internal/External | Authentication Method |
|-----------|-----------|----------------|-------------------|----------------------|
| System Administrator | Full system access | [#] | Internal | PIV/CAC + MFA |
| Application Administrator | Application configuration | [#] | Internal | PIV/CAC + MFA |
| End User | Read/write application data | [#] | [Int/Ext] | [Method] |
| Auditor | Read-only access | [#] | Internal | PIV/CAC + MFA |
| Service Account | Automated processes | [#] | Internal | Certificate-based |

---

## 4. System Boundary

### 4.1 Authorization Boundary Description

[Describe what is inside the authorization boundary for this system. Include all components, interfaces, and data flows that are under the system owner's control and subject to this authorization.]

### 4.2 Boundary Diagram

[Insert or reference a network/system boundary diagram showing:]
- All system components within the boundary
- External connections crossing the boundary
- Data flow directions
- Security zones and trust levels

### 4.3 Components Within the Boundary

| Component ID | Component Name | Type | Purpose | Location |
|-------------|---------------|------|---------|----------|
| [ID] | Application Server | Software | Hosts application logic | [Cloud region/data center] |
| [ID] | Database Server | Software | Persistent data storage | [Cloud region/data center] |
| [ID] | Web Server/Load Balancer | Software | Request routing, TLS termination | [Cloud region/data center] |
| [ID] | Message Queue | Software | Asynchronous processing | [Cloud region/data center] |
| [ID] | Cache Layer | Software | Session/data caching | [Cloud region/data center] |

### 4.4 Components Outside the Boundary (External Services)

| Service | Provider | Interconnection Type | Data Exchanged | Authorization Status |
|---------|----------|---------------------|----------------|---------------------|
| [e.g., Email Service] | [Provider] | API/SMTP | [Data types] | [FedRAMP Auth status] |
| [e.g., Identity Provider] | [Provider] | SAML/OIDC | Authentication tokens | [FedRAMP Auth status] |

---

## 5. System Interconnections

| Interconnected System | System Owner | Agreement Type | Agreement Date | Data Direction | Data Sensitivity |
|----------------------|-------------|---------------|---------------|---------------|-----------------|
| [System name] | [Owner] | ISA/MOU/SLA | [Date] | Inbound/Outbound/Both | [FIPS 199 level] |

### 5.1 Interconnection Security Agreements (ISA)

For each interconnection, document:
- Connection method (VPN, TLS API, Direct Connect)
- Ports and protocols
- Authentication mechanism
- Encryption requirements
- Monitoring requirements

---

## 6. Security Control Implementation

### 6.1 Control Implementation Approach

For each applicable NIST 800-53 Rev 5 control, document the implementation status:

| Status | Definition |
|--------|-----------|
| **Implemented** | Control is fully implemented and operational |
| **Partially Implemented** | Control is partially implemented; gaps documented in POA&M |
| **Planned** | Control is planned for future implementation |
| **Inherited** | Control is inherited from hosting environment (CSP/data center) |
| **Not Applicable** | Control is not applicable to this system (justify) |
| **Alternative** | Alternative implementation with equivalent protection |

### 6.2 Access Control (AC)

#### AC-2: Account Management

**Implementation Status:** [Implemented / Partially Implemented / Planned]

**Control Implementation Description:**

*Pre-Modernization:* [Describe legacy account management approach]

*Post-Modernization:*
- **Java systems:** Jakarta Security API provides declarative role-based account management via `@RolesAllowed`, `@DeclareRoles` annotations. Account provisioning integrated with [enterprise directory service].
- **Python systems:** Django authentication framework with custom user model. Account lifecycle managed via admin interface and management commands.
- **C# systems:** ASP.NET Core Identity with Entity Framework Core backing store. Account policies enforced via `IdentityOptions` configuration.
- **ColdFusion systems:** Application-level session management with server-side validation.

*Compensating Controls:* [If any]

#### AC-3: Access Enforcement

**Implementation Status:** [Implemented / Partially Implemented / Planned]

**Control Implementation Description:**

*Post-Modernization:*
- Role-based access control (RBAC) enforced at application middleware layer
- API endpoints protected by authentication/authorization middleware
- Database-level row security where supported
- Nullable reference types (C#) prevent null-bypass of authorization objects

#### [Continue for all applicable AC controls...]

### 6.3 Audit and Accountability (AU)

#### AU-2: Event Logging

**Implementation Status:** [Implemented / Partially Implemented / Planned]

**Control Implementation Description:**

*Post-Modernization:*
- **Java systems:** SLF4J 2.x with Logback; structured JSON logging with MDC context (user ID, session ID, transaction ID)
- **Python systems:** Python `logging` module with structured formatters; Django audit middleware
- **C# systems:** Serilog with structured logging sinks; ASP.NET Core request logging middleware
- Events logged: authentication success/failure, authorization decisions, data access, configuration changes, privilege escalation

#### [Continue for all applicable AU controls...]

### 6.4 Configuration Management (CM)

#### CM-2: Baseline Configuration

**Implementation Status:** Implemented

**Control Implementation Description:**

*Post-Modernization:*
- Baseline configurations maintained as Infrastructure-as-Code (IaC) in version-controlled repositories
- Runtime versions pinned: Java 17.x.x, Python 3.12.x, .NET 8.x.x
- Dependency versions locked via: Maven BOM (Java), requirements.txt/poetry.lock (Python), NuGet packages.lock.json (C#)
- SBOM generated at build time using CycloneDX/SPDX format

#### CM-6: Configuration Settings

**Implementation Status:** Implemented

**Control Implementation Description:**

*Post-Modernization:*
- Jakarta Servlet 6.0 secure defaults: `HttpOnly`, `Secure`, `SameSite` cookie attributes
- .NET 8 HTTPS-only default; HSTS enabled
- Python Django `SECURE_*` settings enabled (SECURE_SSL_REDIRECT, SECURE_HSTS_SECONDS)
- TLS 1.2 minimum enforced; TLS 1.0/1.1 disabled
- Default error pages configured to prevent information disclosure

### 6.5 System and Information Integrity (SI)

#### SI-2: Flaw Remediation

**Implementation Status:** Implemented

**Control Implementation Description:**

*Post-Modernization — Flaws Remediated:*
- **Java (5 systems):** javax→jakarta namespace migration resolves CVEs in deprecated Java EE libraries; Java 17 addresses JDK-level vulnerabilities present in Java 8/11
- **Python (3 systems):** `imp` module (deprecated, removed in 3.12) replaced with `importlib`; Python 3.12 includes security fixes for HTTP header injection, XML parsing vulnerabilities
- **C# (2 systems):** .NET 8 migration addresses .NET Framework vulnerabilities; nullable reference types eliminate null reference exception attack vectors
- **ColdFusion (cfwheels):** XSS vulnerabilities remediated via output encoding; SQL injection fixed via parameterized queries
- **Fortran (nastran-95):** `IMPLICIT NONE` prevents type confusion vulnerabilities; `GOTO`/`COMMON` usage flagged for future remediation

*Ongoing Flaw Remediation:*
- Automated dependency scanning via [Dependabot/Snyk/OWASP Dependency-Check]
- Security patch SLA: Critical — 48 hours; High — 7 days; Medium — 30 days; Low — 90 days

#### SI-10: Information Input Validation

**Implementation Status:** [Implemented / Partially Implemented]

**Control Implementation Description:**

*Post-Modernization:*
- **cfwheels:** XSS fixes implement output encoding (`encodeForHTML`, `encodeForJavaScript`); SQL injection fixes implement parameterized queries replacing string concatenation
- **Java systems:** Jakarta Bean Validation (`@NotNull`, `@Size`, `@Pattern`) replaces manual validation
- **Python systems:** Type hints enable mypy/pyright static analysis of input handling; Django form validation
- **C# systems:** Nullable reference types ensure non-null input validation; data annotation attributes enforce constraints

### 6.6 [Continue for remaining control families...]

*[Repeat Section 6.x structure for: IA, IR, MA, MP, PE, PL, RA, SA, SC]*

---

## 7. Continuous Monitoring Strategy

### 7.1 Monitoring Approach

| Monitoring Activity | Frequency | Tool/Method | Responsible Party |
|--------------------|-----------|------------|-------------------|
| Vulnerability Scanning | Weekly (automated) | [e.g., Tenable Nessus, Qualys] | ISSO |
| Dependency Scanning | Per commit (CI/CD) | [e.g., Dependabot, Snyk, OWASP DC] | DevSecOps Team |
| SAST | Per commit (CI/CD) | [e.g., SonarQube, Fortify, Checkmarx] | DevSecOps Team |
| DAST | Monthly | [e.g., OWASP ZAP, Burp Suite] | Security Team |
| Penetration Testing | Annual | Third-party assessor | CISO Office |
| Configuration Compliance | Daily (automated) | [e.g., SCAP, OpenSCAP, Chef InSpec] | System Admin |
| Log Review | Continuous (automated) / Weekly (manual) | SIEM platform | SOC |
| POA&M Review | Monthly | Manual review | ISSO + System Owner |
| Control Assessment | Annual | Third-party assessor | AO / CISO Office |

### 7.2 Automated Monitoring

*Post-Modernization Enablement:*
- Modern runtimes support OpenTelemetry for distributed tracing and metrics
- Container health checks and readiness probes for availability monitoring
- Automated SBOM generation triggers on each build
- CVE alerts configured for all declared dependencies

### 7.3 Reporting

| Report | Frequency | Audience | Format |
|--------|-----------|----------|--------|
| Vulnerability Status | Weekly | ISSO, System Owner | Dashboard + Email |
| POA&M Status | Monthly | AO, ISSO, ISSM | Spreadsheet |
| Continuous Monitoring Summary | Quarterly | AO, CISO | Narrative Report |
| Annual Assessment | Annual | AO | Full Assessment Report |

---

## 8. Minimum Assurance Requirements

### 8.1 FIPS 200 Minimum Security Requirements

Per FIPS 200 and the system's categorization level, the minimum baseline of NIST 800-53 controls must be implemented:

| Categorization | Baseline | Total Controls (Approximate) |
|---------------|----------|------------------------------|
| Low | Low Baseline | ~156 |
| Moderate | Moderate Baseline | ~325 |
| High | High Baseline | ~421 |

### 8.2 FedRAMP Requirements (If Cloud-Hosted)

| FedRAMP Level | Applicable If | Additional Requirements |
|--------------|--------------|------------------------|
| Li-SaaS | Low-impact SaaS | FedRAMP Tailored baseline |
| Low | Low-impact systems | FedRAMP Low baseline |
| Moderate | Moderate-impact systems | FedRAMP Moderate baseline |
| High | High-impact systems | FedRAMP High baseline |

---

## 9. Plan of Action and Milestones (POA&M) Reference

All identified weaknesses, deficiencies, and findings are tracked in the system POA&M document.

**POA&M Location:** `compliance/poam.md`  
**POA&M Last Updated:** [Date]  
**Open Items:** [Count]  
**Overdue Items:** [Count]

---

## 10. SSP Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| System Owner | _________________ | _________________ | ________ |
| ISSO | _________________ | _________________ | ________ |
| ISSM | _________________ | _________________ | ________ |
| Authorizing Official | _________________ | _________________ | ________ |

---

## Appendices

### Appendix A: Acronyms

| Acronym | Definition |
|---------|-----------|
| AO | Authorizing Official |
| ATO | Authority to Operate |
| BOD | Binding Operational Directive |
| CAC | Common Access Card |
| CISO | Chief Information Security Officer |
| CUI | Controlled Unclassified Information |
| CVE | Common Vulnerabilities and Exposures |
| DAST | Dynamic Application Security Testing |
| FIPS | Federal Information Processing Standards |
| FISMA | Federal Information Security Modernization Act |
| FedRAMP | Federal Risk and Authorization Management Program |
| IaC | Infrastructure as Code |
| ISA | Interconnection Security Agreement |
| ISSO | Information System Security Officer |
| ISSM | Information System Security Manager |
| LTS | Long-Term Support |
| MFA | Multi-Factor Authentication |
| MOU | Memorandum of Understanding |
| NIST | National Institute of Standards and Technology |
| OWASP | Open Web Application Security Project |
| PIV | Personal Identity Verification |
| POA&M | Plan of Action and Milestones |
| RBAC | Role-Based Access Control |
| SAST | Static Application Security Testing |
| SBOM | Software Bill of Materials |
| SCAP | Security Content Automation Protocol |
| SIEM | Security Information and Event Management |
| SLA | Service Level Agreement |
| SOC | Security Operations Center |
| SSP | System Security Plan |
| TLS | Transport Layer Security |

### Appendix B: Referenced Documents

| Document | Version | Date |
|----------|---------|------|
| NIST SP 800-18 Rev 1 | Rev 1 | February 2006 |
| NIST SP 800-37 Rev 2 | Rev 2 | December 2018 |
| NIST SP 800-53 Rev 5 | Rev 5 | September 2020 |
| NIST SP 800-53A Rev 5 | Rev 5 | January 2022 |
| NIST SP 800-60 Vol I Rev 1 | Rev 1 | August 2008 |
| NIST SP 800-60 Vol II Rev 1 | Rev 1 | August 2008 |
| FIPS 199 | Initial | February 2004 |
| FIPS 200 | Initial | March 2006 |
| FedRAMP SSP Template | Current | [Check fedramp.gov] |

### Appendix C: System Topology Diagram

[Insert detailed network topology diagram here]

### Appendix D: Data Flow Diagram

[Insert data flow diagram showing how data enters, moves through, and exits the system]

### Appendix E: Port/Protocol Matrix

| Source | Destination | Port | Protocol | Direction | Purpose | Encrypted |
|--------|------------|------|----------|-----------|---------|-----------|
| User Browser | Load Balancer | 443 | HTTPS/TLS 1.2+ | Inbound | Web application access | Yes |
| Load Balancer | App Server | 8443 | HTTPS | Internal | Application traffic | Yes |
| App Server | Database | 5432/1433 | PostgreSQL/TDS | Internal | Data persistence | Yes (TLS) |
| App Server | Cache | 6379 | Redis TLS | Internal | Session/data caching | Yes |
| App Server | SIEM | 514/6514 | Syslog/TLS | Outbound | Security event logging | Yes |

### Appendix F: Modernization Change Summary

| System | Language | Key Changes | Files Modified | Risk Level |
|--------|----------|------------|----------------|------------|
| apache-ofbiz | Java | javax→jakarta, Java 17 | [Count] | Medium |
| alfresco-community | Java | javax→jakarta, Java 17 | [Count] | Medium |
| nuxeo | Java | javax→jakarta, Java 17 | [Count] | Medium |
| b2cweb | Java | javax→jakarta, Java 17 | [Count] | Medium |
| monolith-enterprise | Java | javax→jakarta, Java 17 | [Count] | Medium |
| odoo | Python | Python 3.12, imp→importlib, type hints | [Count] | Low |
| django-oscar | Python | Python 3.12, imp→importlib, type hints | [Count] | Low |
| mezzanine | Python | Python 3.12, imp→importlib, type hints | [Count] | Low |
| umbraco-cms | C# | .NET 8, nullable refs | [Count] | Medium |
| dfe-net | C# | .NET 8, nullable refs | [Count] | Medium |
| cfwheels | ColdFusion | XSS/SQL injection fixes | [Count] | High |
| nastran-95 | Fortran | IMPLICIT NONE, GOTO/COMMON flagged | [Count] | Low |
| apollo-11 | Assembly | Preservation/documentation | [Count] | Low |
| cics-banking-sample | COBOL | Skipped (repo 403) | 0 | N/A |
