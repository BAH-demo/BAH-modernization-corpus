# NIST 800-53 Rev 5 Control Mapping — Legacy Modernization Portfolio

**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only  
**Prepared For:** Federal Legacy Modernization Program Office  
**Applicable Standard:** NIST SP 800-53 Revision 5, Security and Privacy Controls for Information Systems and Organizations

---

## 1. Purpose

This document maps the security controls from NIST SP 800-53 Revision 5 to the modernization activities performed across the 14-system legacy modernization portfolio. Each control family is evaluated for relevance to the modernization effort, with specific controls linked to the technical changes implemented.

## 2. Portfolio Overview

| # | System | Language | Modernization Actions | Status |
|---|--------|----------|----------------------|--------|
| 1 | apache-ofbiz | Java | javax→jakarta, Java 17, dependency updates | Active |
| 2 | alfresco-community | Java | javax→jakarta, Java 17, dependency updates | Active |
| 3 | nuxeo | Java | javax→jakarta, Java 17, dependency updates | Active |
| 4 | b2cweb | Java | javax→jakarta, Java 17, dependency updates | Active |
| 5 | monolith-enterprise | Java | javax→jakarta, Java 17, dependency updates | Active |
| 6 | odoo | Python | Python 3.12, imp→importlib, type hints | Active |
| 7 | django-oscar | Python | Python 3.12, imp→importlib, type hints | Active |
| 8 | mezzanine | Python | Python 3.12, imp→importlib, type hints | Active |
| 9 | umbraco-cms | C# | .NET 8, nullable references enabled | Active |
| 10 | dfe-net | C# | .NET 8, nullable references enabled | Active |
| 11 | cfwheels | ColdFusion | XSS/SQL injection fixes | Active |
| 12 | nastran-95 | Fortran | IMPLICIT NONE, GOTO/COMMON flagged | Active |
| 13 | apollo-11 | Assembly | Preservation/documentation | Active |
| 14 | cics-banking-sample | COBOL | Skipped (repo 403) | Skipped |

---

## 3. Control Family Mappings

### 3.1 AC — Access Control

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| AC-2 | Account Management | Moderate | Jakarta EE migration enables modern JAAS/Jakarta Security for centralized account management; .NET 8 Identity framework improves account lifecycle controls | Java (5), C# (2) |
| AC-3 | Access Enforcement | High | Updated frameworks enforce role-based access via modern middleware; nullable reference types in C# prevent null-bypass of authorization checks | Java (5), C# (2), Python (3) |
| AC-4 | Information Flow Enforcement | Moderate | Modern framework versions include improved request filtering and CORS handling; XSS fixes in cfwheels prevent unauthorized information flow | All active systems |
| AC-6 | Least Privilege | Moderate | Java 17 module system (JPMS) enables fine-grained access boundaries; .NET 8 minimal APIs reduce default surface area | Java (5), C# (2) |
| AC-7 | Unsuccessful Logon Attempts | Low | Modern authentication libraries (Jakarta Security, ASP.NET Core Identity) include lockout policies by default | Java (5), C# (2) |
| AC-14 | Permitted Actions Without Identification or Authentication | Moderate | Framework upgrades tighten default-deny posture; legacy permissive defaults replaced | Java (5), C# (2), Python (3) |
| AC-17 | Remote Access | Moderate | TLS 1.3 support in Java 17 and .NET 8 runtimes; deprecated cipher suites removed | Java (5), C# (2) |

**Summary:** The Java javax→jakarta migration directly enables modern Jakarta Security APIs that replace legacy JAAS patterns. .NET 8 brings ASP.NET Core Identity with modern access control primitives. Python 3.12 type hints improve static analysis of authorization logic.

---

### 3.2 AU — Audit and Accountability

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| AU-2 | Event Logging | High | Modern frameworks provide structured logging (SLF4J 2.x with Jakarta, Serilog with .NET 8, Python logging with type-safe configuration) | All active systems |
| AU-3 | Content of Audit Records | Moderate | Updated logging frameworks support structured JSON output with contextual fields (correlation IDs, user context) | Java (5), C# (2), Python (3) |
| AU-6 | Audit Record Review, Analysis, and Reporting | Moderate | Modern log formats enable integration with SIEM platforms (Splunk, ELK) for automated review | All active systems |
| AU-8 | Time Stamps | Low | Java 17 `java.time` API and .NET 8 `DateTimeOffset` provide consistent UTC timestamp generation | Java (5), C# (2) |
| AU-12 | Audit Record Generation | High | Modernized dependencies support OpenTelemetry instrumentation for comprehensive audit trail generation | Java (5), C# (2), Python (3) |

**Summary:** Moving to current runtime versions enables structured, machine-parseable audit logging compatible with federal SIEM requirements (e.g., Splunk GovCloud, ELK-based solutions).

---

### 3.3 CA — Assessment, Authorization, and Monitoring

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| CA-2 | Control Assessments | High | Modernization activities themselves constitute a control assessment; findings documented in POA&M | All 14 systems |
| CA-5 | Plan of Action and Milestones | High | POA&M generated from modernization findings (see `compliance/poam.md`) | All 14 systems |
| CA-6 | Authorization | High | System changes require ATO re-authorization; SSP updates needed per system | All active systems |
| CA-7 | Continuous Monitoring | High | Updated dependencies enable automated vulnerability scanning (Dependabot, Snyk, OWASP Dependency-Check) | Java (5), C# (2), Python (3) |
| CA-8 | Penetration Testing | Moderate | Modernized codebases are compatible with current DAST/SAST tools (SonarQube, Fortify, Checkmarx) | All active systems |

**Summary:** The modernization effort directly supports CA-7 by bringing systems onto dependency management platforms with automated CVE monitoring. Every system change triggers CA-6 re-authorization requirements.

---

### 3.4 CM — Configuration Management

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| CM-2 | Baseline Configuration | High | Post-modernization baseline established with updated runtime versions, dependency manifests, and build configurations | All active systems |
| CM-3 | Configuration Change Control | High | All changes tracked via Git with full commit history; modernization patches preserved for audit | All active systems |
| CM-4 | Impact Analyses | High | Pre/post modernization metrics collected (LOC changed, files modified, dependency delta) | All active systems |
| CM-5 | Access Restrictions for Change | Moderate | Git branch protection and PR-based workflows enforce change control | All active systems |
| CM-6 | Configuration Settings | High | Hardened default configurations in updated frameworks (e.g., secure cookie defaults in Jakarta Servlet 6.0, HTTPS-only defaults in .NET 8) | Java (5), C# (2), Python (3) |
| CM-7 | Least Functionality | Moderate | Deprecated APIs removed; unused legacy modules identified for decommission | Java (5), Python (3) |
| CM-8 | System Component Inventory | High | SBOM generation enabled via modern build tools (Maven BOM, NuGet, pip-audit) | Java (5), C# (2), Python (3) |
| CM-11 | User-Installed Software | Low | Container-based deployment models restrict unauthorized software installation | Java (5), C# (2), Python (3) |

**Summary:** CM is the most directly impacted control family. Every modernization change is a configuration change requiring CM-3 documentation. CM-8 is enhanced by modern SBOM tooling.

---

### 3.5 IA — Identification and Authentication

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| IA-2 | Identification and Authentication (Organizational Users) | Moderate | Jakarta Security and ASP.NET Core Identity support SAML 2.0/OIDC for PIV/CAC integration | Java (5), C# (2) |
| IA-5 | Authenticator Management | Moderate | Modern password hashing (bcrypt/Argon2) available in updated framework crypto libraries | Java (5), C# (2), Python (3) |
| IA-7 | Cryptographic Module Authentication | High | Java 17 includes updated JCE providers; .NET 8 uses OS-level FIPS 140-2 validated modules | Java (5), C# (2) |
| IA-8 | Identification and Authentication (Non-Organizational Users) | Low | Modern OAuth 2.0/OIDC libraries enable federated identity for external users | Java (5), C# (2), Python (3) |

**Summary:** Migrating to Java 17 and .NET 8 ensures access to FIPS 140-2/140-3 validated cryptographic modules required for federal authentication.

---

### 3.6 IR — Incident Response

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| IR-4 | Incident Handling | Moderate | Modern observability stacks (OpenTelemetry) enable faster incident detection and root cause analysis | Java (5), C# (2), Python (3) |
| IR-5 | Incident Monitoring | Moderate | Updated logging and metrics libraries support integration with SOC monitoring tools | All active systems |
| IR-6 | Incident Reporting | Low | Structured log output facilitates automated incident ticket generation | Java (5), C# (2), Python (3) |

**Summary:** Modernized systems are instrumentation-ready for incident response toolchains. Legacy systems (Fortran, Assembly) require wrapper-level monitoring.

---

### 3.7 MA — Maintenance

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| MA-2 | Controlled Maintenance | Moderate | Modern CI/CD pipelines enable controlled, repeatable maintenance windows | All active systems |
| MA-5 | Maintenance Personnel | Low | Modernized tech stacks have larger talent pools, reducing key-person dependency risk | All active systems |
| MA-6 | Timely Maintenance | High | Active LTS runtime versions (Java 17 LTS, .NET 8 LTS, Python 3.12) ensure timely security patches from vendors | Java (5), C# (2), Python (3) |

**Summary:** Moving to LTS versions directly addresses MA-6 by ensuring vendor-supported patch timelines through at least 2028-2030.

---

### 3.8 MP — Media Protection

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| MP-4 | Media Storage | Low | Modern deployment artifacts (container images, signed packages) support secure media storage | Java (5), C# (2), Python (3) |
| MP-5 | Media Transport | Low | Code signing and artifact checksums enabled by modern build tooling | All active systems |

**Summary:** Minimal direct impact from modernization. Controls primarily addressed at infrastructure level.

---

### 3.9 PE — Physical and Environmental Protection

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| PE-1 through PE-20 | Physical/Environmental Controls | None | Physical controls are outside the scope of code modernization; addressed at data center/cloud provider level | N/A |

**Summary:** No direct modernization impact. PE controls are inherited from the hosting environment (FedRAMP-authorized cloud or agency data center).

---

### 3.10 PL — Planning

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| PL-2 | System Security and Privacy Plans | High | SSP updates required for all modernized systems (see `compliance/ssp-template.md` and `compliance/ssp-summaries/`) | All 14 systems |
| PL-4 | Rules of Behavior | Low | No direct impact from code modernization | N/A |
| PL-8 | Security and Privacy Architectures | High | Security architecture updated to reflect modernized technology stack (see `compliance/security-architecture.md`) | All active systems |

**Summary:** PL-2 is directly impacted — every SSP must be updated to reflect the new technology baseline.

---

### 3.11 PM — Program Management

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| PM-1 | Information Security Program Plan | Moderate | Modernization program aligns with agency-wide security program goals | All 14 systems |
| PM-4 | Plan of Action and Milestones Process | High | POA&M process established with modernization findings (see `compliance/poam.md`) | All 14 systems |
| PM-9 | Risk Management Strategy | High | Risk register established with modernization-specific risks (see `compliance/risk-register.md`) | All 14 systems |
| PM-11 | Mission and Business Process Definition | Moderate | System rationalization identifies mission-critical vs. decommission candidates | All 14 systems |
| PM-28 | Risk Framing | Moderate | Risk taxonomy defined for modernization portfolio | All 14 systems |

**Summary:** The modernization effort is a program-level activity with direct PM family implications.

---

### 3.12 PS — Personnel Security

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| PS-1 through PS-9 | Personnel Security Controls | Low | Personnel controls are outside the scope of code modernization; modernized stacks may reduce need for specialized legacy skills | N/A |

**Summary:** Indirect benefit: modern technology stacks reduce reliance on scarce legacy-language specialists (COBOL, Fortran, Assembly), improving personnel security posture.

---

### 3.13 RA — Risk Assessment

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| RA-2 | Security Categorization | High | FIPS 199 categorization documented for each system in SSP summaries | All 14 systems |
| RA-3 | Risk Assessment | High | Risk register created from modernization analysis (see `compliance/risk-register.md`) | All 14 systems |
| RA-5 | Vulnerability Monitoring and Scanning | High | Modern dependency management enables automated CVE scanning; known vulnerabilities in legacy javax/Python 2 patterns eliminated | Java (5), C# (2), Python (3) |
| RA-7 | Risk Response | High | Remediation actions defined in POA&M for identified risks | All 14 systems |

**Summary:** RA-5 is one of the highest-impact controls. The javax→jakarta migration alone eliminates dozens of known CVEs in deprecated Java EE libraries.

---

### 3.14 SA — System and Services Acquisition

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| SA-3 | System Development Life Cycle | High | Modernization follows defined SDLC with version control, code review, and automated testing | All active systems |
| SA-4 | Acquisition Process | Moderate | Open-source component analysis (SBOM) supports supply chain risk management | Java (5), C# (2), Python (3) |
| SA-8 | Security and Privacy Engineering Principles | High | Modernization applies secure-by-default principles (input validation, parameterized queries, nullable safety) | All active systems |
| SA-10 | Developer Configuration Management | High | Git-based version control with branch protection and signed commits | All active systems |
| SA-11 | Developer Testing and Evaluation | Moderate | Updated test frameworks compatible with modern CI/CD for automated security testing | Java (5), C# (2), Python (3) |
| SA-15 | Development Process, Standards, and Tools | High | Migration to current LTS toolchains with vendor security support | All active systems |

**Summary:** SA-8 is directly addressed by the cfwheels XSS/SQL injection fixes and by nullable reference types in C#.

---

### 3.15 SC — System and Communications Protection

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| SC-8 | Transmission Confidentiality and Integrity | High | Java 17 and .NET 8 support TLS 1.3; deprecated TLS 1.0/1.1 removed from default configurations | Java (5), C# (2) |
| SC-12 | Cryptographic Key Establishment and Management | Moderate | Updated crypto libraries support modern key exchange algorithms (X25519, P-384) | Java (5), C# (2) |
| SC-13 | Cryptographic Protection | High | FIPS 140-2/140-3 validated cryptographic modules available in current runtimes | Java (5), C# (2) |
| SC-28 | Protection of Information at Rest | Moderate | Modern frameworks provide transparent data encryption APIs | Java (5), C# (2), Python (3) |
| SC-39 | Process Isolation | Moderate | Java 17 module system (JPMS) and .NET 8 assembly trimming improve process isolation | Java (5), C# (2) |

**Summary:** SC-8 and SC-13 are significantly improved by runtime upgrades that enforce modern cryptographic standards.

---

### 3.16 SI — System and Information Integrity

| Control | Title | Relevance | Modernization Impact | Applicable Systems |
|---------|-------|-----------|---------------------|--------------------|
| SI-2 | Flaw Remediation | **Critical** | javax→jakarta migration resolves known CVEs; Python 3.12 fixes deprecated `imp` module vulnerabilities; .NET 8 patches known .NET Framework flaws; cfwheels XSS/SQL injection fixes directly remediate OWASP Top 10 | All active systems |
| SI-3 | Malicious Code Protection | Moderate | Modern dependency scanning (Dependabot, Snyk) detects malicious packages in supply chain | Java (5), C# (2), Python (3) |
| SI-4 | System Monitoring | Moderate | OpenTelemetry-compatible runtimes enable real-time integrity monitoring | Java (5), C# (2), Python (3) |
| SI-5 | Security Alerts, Advisories, and Directives | High | Active LTS versions receive vendor security advisories; EOL runtimes do not | All active systems |
| SI-7 | Software, Firmware, and Information Integrity | High | Modern build tools support reproducible builds, artifact signing, and SBOM generation | Java (5), C# (2), Python (3) |
| SI-10 | Information Input Validation | **Critical** | cfwheels XSS/SQL injection fixes directly implement input validation; Jakarta Bean Validation replaces legacy patterns; Python type hints enable static input validation | cfwheels, Java (5), Python (3) |
| SI-11 | Error Handling | Moderate | Nullable reference types in C# prevent null reference exceptions; Python type hints catch type errors at compile time | C# (2), Python (3) |
| SI-16 | Memory Protection | Moderate | Java 17 and .NET 8 include improved memory safety features (bounds checking, GC improvements) | Java (5), C# (2) |

**Summary:** SI-2 (Flaw Remediation) and SI-10 (Input Validation) are the **most directly impacted controls** across the entire portfolio. The modernization effort is fundamentally a flaw remediation activity.

---

## 4. Control Family Impact Summary

| Control Family | Impact Level | Primary Driver |
|---------------|-------------|----------------|
| AC — Access Control | Moderate | Framework-level auth improvements |
| AU — Audit and Accountability | Moderate | Structured logging enablement |
| CA — Assessment, Authorization, and Monitoring | High | ATO re-authorization, continuous monitoring |
| CM — Configuration Management | **Critical** | Baseline changes, SBOM generation |
| IA — Identification and Authentication | Moderate | FIPS crypto module availability |
| IR — Incident Response | Moderate | Observability improvements |
| MA — Maintenance | High | LTS vendor support timelines |
| MP — Media Protection | Low | Artifact signing |
| PE — Physical and Environmental | None | Outside scope |
| PL — Planning | High | SSP updates required |
| PM — Program Management | High | POA&M, risk management |
| PS — Personnel Security | Low | Talent pool expansion |
| RA — Risk Assessment | High | Vulnerability scanning, FIPS categorization |
| SA — System/Services Acquisition | High | SDLC, supply chain, secure engineering |
| SC — System/Comm Protection | High | TLS 1.3, FIPS crypto |
| SI — System/Info Integrity | **Critical** | Flaw remediation, input validation |

---

## 5. FedRAMP Alignment

For systems hosted in FedRAMP-authorized cloud environments, the following controls are **inherited** from the Cloud Service Provider (CSP):

- **PE family** — Physical and Environmental Protection (fully inherited)
- **MP-2, MP-4, MP-5** — Media Protection (partially inherited)
- **SC-8** — Transmission Confidentiality (partially inherited via CSP TLS termination)

The modernization effort addresses **application-level** controls that are the responsibility of the agency (customer responsibility under the shared responsibility model).

---

## 6. Infrastructure Modernization Technology Mapping

The following modernized infrastructure technologies are deployed as part of this program and have direct control implications:

| Technology | Purpose | Key Controls Impacted |
|-----------|---------|----------------------|
| **Docker** (multi-stage builds) | Application containerization for all 11 deployable systems | CM-2 (baseline), CM-7 (least functionality), SC-39 (process isolation) |
| **Kubernetes** (EKS) | Container orchestration with namespace isolation, RBAC, NetworkPolicy | AC-3 (access enforcement), AC-4 (information flow), SC-7 (boundary protection) |
| **Terraform** | Infrastructure-as-Code for AWS EKS, VPC, RDS, S3, IAM | CM-2 (baseline), CM-3 (change control), SA-10 (developer config mgmt) |
| **Helm** (umbrella chart) | Declarative deployment management for fleet-wide consistency | CM-2 (baseline), CM-6 (configuration settings) |
| **Prometheus / Grafana / AlertManager** | Observability stack for metrics, dashboards, and alerting | AU-6 (audit review), IR-5 (incident monitoring), SI-4 (system monitoring) |
| **Semgrep / Trivy / Bandit** | SAST/SCA scanning integrated into CI/CD pipelines | RA-5 (vulnerability scanning), SA-11 (developer testing), SI-2 (flaw remediation) |
| **Dependabot** | Automated dependency update management | SI-2 (flaw remediation), SI-5 (security alerts), CM-3 (change control) |
| **GitHub Actions** | CI/CD pipeline automation with build, test, scan stages | SA-3 (SDLC), SA-10 (developer config mgmt), SA-11 (developer testing) |
| **.NET 8** (net8.0) | Runtime modernization for C# systems (Umbraco, DFe.NET) | SC-13 (crypto protection), IA-7 (crypto module auth), SI-16 (memory protection) |
| **importlib** (Python 3.12) | Replacement for deprecated `imp` module in Python systems | SI-2 (flaw remediation), CM-7 (least functionality) |

---

## 7. References

- NIST SP 800-53 Rev 5: https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- NIST SP 800-53A Rev 5: Assessment Procedures
- FedRAMP Control Baselines: https://www.fedramp.gov/documents/
- CISA BOD 22-01: Known Exploited Vulnerabilities Catalog
- CISA BOD 23-01: Improving Asset Visibility and Vulnerability Detection
- Docker Security Best Practices: https://docs.docker.com/develop/security-best-practices/
- Kubernetes Security: https://kubernetes.io/docs/concepts/security/
- Terraform Security: https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices
