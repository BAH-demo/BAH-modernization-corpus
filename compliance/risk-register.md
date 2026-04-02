# Risk Register — Legacy Modernization Portfolio

**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only  
**Prepared For:** Federal Legacy Modernization Program Office  
**Review Cycle:** Monthly

---

## 1. Purpose

This Risk Register documents and tracks risks across the 14-system legacy modernization portfolio. Risks are categorized into four domains: Technical, Security, Operational, and Compliance. Each risk is assessed for likelihood and impact using a 5×5 risk matrix, with mitigation strategies and risk owners identified.

## 2. Risk Scoring Methodology

### 2.1 Likelihood Scale

| Score | Likelihood | Description |
|-------|-----------|-------------|
| 1 | Rare | < 5% probability; unlikely to occur |
| 2 | Unlikely | 5–25% probability; could occur but not expected |
| 3 | Possible | 25–50% probability; may occur |
| 4 | Likely | 50–75% probability; expected to occur |
| 5 | Almost Certain | > 75% probability; will almost certainly occur |

### 2.2 Impact Scale

| Score | Impact | Description |
|-------|--------|-------------|
| 1 | Negligible | Minimal impact on mission, budget, or schedule |
| 2 | Minor | Limited impact; workarounds available |
| 3 | Moderate | Significant impact on schedule, cost, or quality; requires management attention |
| 4 | Major | Severe impact on mission capability; significant cost/schedule overrun |
| 5 | Critical | Mission failure; safety/life impact; catastrophic financial or reputational loss |

### 2.3 Risk Score Matrix

**Risk Score = Likelihood × Impact**

| | Negligible (1) | Minor (2) | Moderate (3) | Major (4) | Critical (5) |
|---|---|---|---|---|---|
| **Almost Certain (5)** | 5 (M) | 10 (H) | 15 (H) | 20 (VH) | 25 (VH) |
| **Likely (4)** | 4 (L) | 8 (M) | 12 (H) | 16 (VH) | 20 (VH) |
| **Possible (3)** | 3 (L) | 6 (M) | 9 (M) | 12 (H) | 15 (H) |
| **Unlikely (2)** | 2 (L) | 4 (L) | 6 (M) | 8 (M) | 10 (H) |
| **Rare (1)** | 1 (L) | 2 (L) | 3 (L) | 4 (L) | 5 (M) |

**Risk Levels:** VH = Very High (16–25), H = High (10–15), M = Medium (5–9), L = Low (1–4)

---

## 3. Technical Risks

### T-001: Build Failures After Namespace Migration (Java Systems)

| Attribute | Value |
|-----------|-------|
| **Risk ID** | T-001 |
| **Category** | Technical |
| **Affected Systems** | apache-ofbiz, alfresco-community, nuxeo, b2cweb, monolith-enterprise |
| **Description** | javax→jakarta namespace migration may cause compile-time or runtime failures in systems with complex dependency trees, custom classloaders, or reflection-based component loading |
| **Likelihood** | 4 (Likely) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Use Eclipse Transformer or OpenRewrite recipes for automated migration 2. Maintain parallel javax/jakarta builds during transition 3. Comprehensive integration test suites 4. Staged rollout with canary deployments |
| **Risk Owner** | Development Lead |
| **Status** | Active |

### T-002: Runtime Incompatibilities in Java 17 Module System

| Attribute | Value |
|-----------|-------|
| **Risk ID** | T-002 |
| **Category** | Technical |
| **Affected Systems** | apache-ofbiz, alfresco-community, nuxeo, b2cweb, monolith-enterprise |
| **Description** | Java 17 strong encapsulation (JPMS) may break libraries that rely on deep reflection into JDK internals (e.g., sun.misc.Unsafe, internal XML parsers) |
| **Likelihood** | 4 (Likely) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Identify all --add-opens/--add-exports needed 2. Replace libraries using internal APIs 3. Test with `--illegal-access=deny` during CI 4. Document all required JVM flags |
| **Risk Owner** | Development Lead |
| **Status** | Active |

### T-003: Python 3.12 Breaking Changes in Legacy Odoo Modules

| Attribute | Value |
|-----------|-------|
| **Risk ID** | T-003 |
| **Category** | Technical |
| **Affected Systems** | odoo, django-oscar, mezzanine |
| **Description** | Python 3.12 removes several deprecated modules and changes behaviors (distutils removal, imp removal, str/bytes strictness); third-party packages may not be compatible |
| **Likelihood** | 3 (Possible) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **9 (Medium)** |
| **Mitigation Strategy** | 1. Run `python -W all` to surface deprecation warnings 2. Test all third-party packages against Python 3.12 3. Pin compatible package versions 4. Maintain Python 3.11 fallback environment |
| **Risk Owner** | Development Lead |
| **Status** | Active |

### T-004: .NET Framework to .NET 8 API Incompatibilities

| Attribute | Value |
|-----------|-------|
| **Risk ID** | T-004 |
| **Category** | Technical |
| **Affected Systems** | umbraco-cms, dfe-net |
| **Description** | .NET Framework APIs not available in .NET 8 (e.g., System.Web, WCF client, AppDomains); nullable reference types may introduce thousands of compiler warnings in legacy code |
| **Likelihood** | 4 (Likely) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Use .NET Upgrade Assistant for automated migration 2. Replace System.Web with ASP.NET Core equivalents 3. Enable NRT incrementally (per-project) 4. Suppress non-critical NRT warnings initially |
| **Risk Owner** | Development Lead |
| **Status** | Active |

### T-005: Fortran Modernization May Alter Numerical Results

| Attribute | Value |
|-----------|-------|
| **Risk ID** | T-005 |
| **Category** | Technical |
| **Affected Systems** | nastran-95 |
| **Description** | Adding IMPLICIT NONE and refactoring GOTO/COMMON patterns may subtly change computation results due to variable type changes or control flow reordering |
| **Likelihood** | 3 (Possible) |
| **Impact** | 5 (Critical) — Incorrect structural analysis could lead to safety failures |
| **Risk Score** | **15 (High)** |
| **Mitigation Strategy** | 1. Establish reference test cases with known-good results before changes 2. Compare results to machine precision after each change 3. Change only one pattern at a time 4. Preserve original code as baseline |
| **Risk Owner** | Engineering Lead |
| **Status** | Active |

### T-006: ColdFusion Framework Compatibility After Security Fixes

| Attribute | Value |
|-----------|-------|
| **Risk ID** | T-006 |
| **Category** | Technical |
| **Affected Systems** | cfwheels |
| **Description** | XSS/SQL injection fixes (parameterized queries, output encoding) may break existing functionality that relied on unencoded output or dynamic SQL construction |
| **Likelihood** | 3 (Possible) |
| **Impact** | 2 (Minor) |
| **Risk Score** | **6 (Medium)** |
| **Mitigation Strategy** | 1. Comprehensive regression testing of all forms and reports 2. Staged rollout 3. User acceptance testing before production deployment 4. Rollback plan |
| **Risk Owner** | Development Lead |
| **Status** | Active |

---

## 4. Security Risks

### S-001: New Dependency Vulnerabilities Introduced During Migration

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-001 |
| **Category** | Security |
| **Affected Systems** | All actively modernized systems (13) |
| **Description** | Updated dependencies may introduce new CVEs not present in legacy versions; transitive dependency tree changes may pull in vulnerable libraries |
| **Likelihood** | 4 (Likely) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. SBOM generation at build time 2. Automated CVE scanning in CI/CD (Dependabot, Snyk, OWASP DC) 3. Dependency pinning with lock files 4. Regular dependency audit cycle |
| **Risk Owner** | DevSecOps Lead |
| **Status** | Active |

### S-002: Namespace Migration Gaps Leaving javax.* References

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-002 |
| **Category** | Security |
| **Affected Systems** | apache-ofbiz, alfresco-community, nuxeo, b2cweb, monolith-enterprise |
| **Description** | Incomplete javax→jakarta migration may leave some code paths using deprecated javax.* classes that don't receive security patches; mixed namespace usage may cause unpredictable behavior |
| **Likelihood** | 3 (Possible) |
| **Impact** | 4 (Major) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Automated grep/scan for residual javax.* references 2. Compile-time verification with jakarta-only classpath 3. Runtime monitoring for ClassNotFoundException 4. CI gate blocking javax.* imports |
| **Risk Owner** | Security Lead |
| **Status** | Active |

### S-003: XSS/SQL Injection Fixes Incomplete in ColdFusion

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-003 |
| **Category** | Security |
| **Affected Systems** | cfwheels |
| **Description** | Manual XSS/SQL injection remediation may not cover all code paths; admin interfaces, error pages, and edge cases may retain vulnerabilities |
| **Likelihood** | 3 (Possible) |
| **Impact** | 4 (Major) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Full DAST scan (OWASP ZAP) of all endpoints 2. SAST review of all CFML files 3. WAF deployment as compensating control 4. Penetration test before production deployment |
| **Risk Owner** | Security Lead |
| **Status** | Active |

### S-004: Fortran Memory Safety Vulnerabilities

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-004 |
| **Category** | Security |
| **Affected Systems** | nastran-95 |
| **Description** | Legacy Fortran lacks memory safety features; buffer overflows in array operations, uninitialized variables, and format string vulnerabilities possible |
| **Likelihood** | 3 (Possible) |
| **Impact** | 4 (Major) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Compile with `-fbounds-check -finit-local-zero` flags 2. Run with AddressSanitizer during testing 3. Isolate in sandboxed execution environment 4. Input validation wrapper |
| **Risk Owner** | Development Lead |
| **Status** | Active |

### S-005: COBOL System Remains Unassessed (403 Access Failure)

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-005 |
| **Category** | Security |
| **Affected Systems** | cics-banking-sample |
| **Description** | Highest-categorized system (High/High/High) in the portfolio could not be assessed due to repository access failure; all vulnerabilities remain unknown and unaddressed |
| **Likelihood** | 5 (Almost Certain) — Vulnerabilities exist in any unassessed legacy system |
| **Impact** | 5 (Critical) — Financial transaction system with PII |
| **Risk Score** | **25 (Very High)** |
| **Mitigation Strategy** | 1. **Immediate:** Restore repository access 2. Compensating controls: network segmentation, enhanced monitoring, WAF for CICS Web Services 3. Manual mainframe security audit 4. Evaluate IBM zSecure for automated assessment |
| **Risk Owner** | Program Manager |
| **Status** | Active — **Requires immediate attention** |

### S-006: Supply Chain Risk from Open-Source Dependencies

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-006 |
| **Category** | Security |
| **Affected Systems** | All systems using open-source packages (Java, Python, C#) |
| **Description** | Open-source supply chain attacks (typosquatting, dependency confusion, compromised maintainer accounts) could introduce malicious code via updated packages |
| **Likelihood** | 2 (Unlikely) |
| **Impact** | 5 (Critical) |
| **Risk Score** | **10 (High)** |
| **Mitigation Strategy** | 1. SBOM generation and verification 2. Artifact repository with provenance checks (e.g., Sigstore/cosign) 3. Dependency pinning with hash verification 4. Private artifact mirror (Artifactory/Nexus) to control ingress |
| **Risk Owner** | DevSecOps Lead |
| **Status** | Active |

### S-007: ColdFusion Platform Lacks FIPS 140-2 Validated Cryptography

| Attribute | Value |
|-----------|-------|
| **Risk ID** | S-007 |
| **Category** | Security |
| **Affected Systems** | cfwheels |
| **Description** | Adobe ColdFusion and Lucee CFML runtimes do not ship with FIPS 140-2 validated cryptographic modules; federal systems require FIPS-validated crypto for data protection |
| **Likelihood** | 5 (Almost Certain) — ColdFusion definitively lacks FIPS validation |
| **Impact** | 3 (Moderate) — Compliance gap; may not impact data security if underlying JVM provides FIPS |
| **Risk Score** | **15 (High)** |
| **Mitigation Strategy** | 1. Configure underlying JVM with FIPS-validated provider (Bouncy Castle FIPS) 2. Route all crypto operations through Java APIs, not CFML built-ins 3. Document compensating control for assessors 4. Long-term: replatform off ColdFusion |
| **Risk Owner** | Security Lead |
| **Status** | Active |

---

## 5. Operational Risks

### O-001: Service Disruption During Production Cutover

| Attribute | Value |
|-----------|-------|
| **Risk ID** | O-001 |
| **Category** | Operational |
| **Affected Systems** | All actively modernized systems (13) |
| **Description** | Deploying modernized code to production may cause service disruptions due to runtime incompatibilities, configuration drift, or database migration failures |
| **Likelihood** | 3 (Possible) |
| **Impact** | 4 (Major) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Blue/green deployment strategy 2. Database migration dry-runs in staging 3. Automated rollback procedures 4. Maintenance window scheduling with stakeholder coordination 5. Canary releases where possible |
| **Risk Owner** | Operations Lead |
| **Status** | Active |

### O-002: Loss of Institutional Knowledge for Legacy Languages

| Attribute | Value |
|-----------|-------|
| **Risk ID** | O-002 |
| **Category** | Operational |
| **Affected Systems** | nastran-95 (Fortran), apollo-11 (Assembly), cics-banking-sample (COBOL), cfwheels (ColdFusion) |
| **Description** | Subject matter experts for legacy languages are retiring or leaving; insufficient documentation may prevent future maintenance or incident response |
| **Likelihood** | 4 (Likely) |
| **Impact** | 4 (Major) |
| **Risk Score** | **16 (Very High)** |
| **Mitigation Strategy** | 1. Knowledge capture sessions with current SMEs 2. Comprehensive code documentation 3. Cross-training programs 4. Evaluate automated migration tools (COBOL-to-Java, etc.) 5. Contract with specialized legacy support firms |
| **Risk Owner** | Program Manager |
| **Status** | Active |

### O-003: CI/CD Pipeline Incompatibility with Legacy Build Systems

| Attribute | Value |
|-----------|-------|
| **Risk ID** | O-003 |
| **Category** | Operational |
| **Affected Systems** | nastran-95 (Fortran/Make), cfwheels (ColdFusion), cics-banking-sample (JCL/mainframe) |
| **Description** | Legacy build systems (Make, Ant, JCL) may not integrate cleanly with modern CI/CD platforms (GitHub Actions, GitLab CI, Jenkins) |
| **Likelihood** | 3 (Possible) |
| **Impact** | 2 (Minor) |
| **Risk Score** | **6 (Medium)** |
| **Mitigation Strategy** | 1. Containerized build environments for legacy compilers 2. Custom CI/CD scripts wrapping legacy build tools 3. Separate pipelines for legacy systems 4. Gradual migration to modern build tools where feasible |
| **Risk Owner** | DevSecOps Lead |
| **Status** | Active |

### O-004: Monitoring Gaps for Non-Web Legacy Systems

| Attribute | Value |
|-----------|-------|
| **Risk ID** | O-004 |
| **Category** | Operational |
| **Affected Systems** | nastran-95 (batch processing), apollo-11 (archive), cics-banking-sample (mainframe) |
| **Description** | Legacy systems that are not web-based may not support standard monitoring approaches (APM, OpenTelemetry); operational visibility may be limited |
| **Likelihood** | 4 (Likely) |
| **Impact** | 2 (Minor) |
| **Risk Score** | **8 (Medium)** |
| **Mitigation Strategy** | 1. OS-level monitoring (CPU, memory, disk, process health) 2. Log file monitoring via Filebeat/Fluentd 3. Custom health check scripts 4. Mainframe SMF record forwarding to SIEM |
| **Risk Owner** | Operations Lead |
| **Status** | Active |

### O-005: Simultaneous Migration of Multiple Systems Strains Resources

| Attribute | Value |
|-----------|-------|
| **Risk ID** | O-005 |
| **Category** | Operational |
| **Affected Systems** | All 14 systems |
| **Description** | Modernizing 14 systems concurrently may exceed available engineering, security, and operations capacity; quality may suffer from resource contention |
| **Likelihood** | 3 (Possible) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **9 (Medium)** |
| **Mitigation Strategy** | 1. Phased rollout prioritized by risk and business impact 2. Dedicated teams per technology stack 3. Shared services (CI/CD, security scanning) to reduce per-system overhead 4. Clear prioritization framework |
| **Risk Owner** | Program Manager |
| **Status** | Active |

---

## 6. Compliance Risks

### C-001: ATO Re-Authorization Required for All Modernized Systems

| Attribute | Value |
|-----------|-------|
| **Risk ID** | C-001 |
| **Category** | Compliance |
| **Affected Systems** | All 13 actively modernized systems |
| **Description** | Significant technology changes (runtime version, framework, namespace) constitute a major modification triggering ATO re-authorization per NIST SP 800-37; operating without updated ATO is a compliance violation |
| **Likelihood** | 5 (Almost Certain) — Re-authorization is mandatory, not discretionary |
| **Impact** | 4 (Major) — Systems cannot operate in production without valid ATO |
| **Risk Score** | **20 (Very High)** |
| **Mitigation Strategy** | 1. SSP updates concurrent with modernization (this package) 2. Engage AO and ISSO early in the process 3. Leverage continuous monitoring data to expedite re-authorization 4. Use Ongoing Authorization approach where possible (NIST SP 800-37 Rev 2) |
| **Risk Owner** | ISSO |
| **Status** | Active |

### C-002: FedRAMP Continuous Monitoring Disruption

| Attribute | Value |
|-----------|-------|
| **Risk ID** | C-002 |
| **Category** | Compliance |
| **Affected Systems** | Systems hosted in FedRAMP environments |
| **Description** | Technology stack changes may disrupt existing continuous monitoring configurations (vulnerability scanning profiles, SAST rules, configuration baselines) requiring recalibration |
| **Likelihood** | 3 (Possible) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **9 (Medium)** |
| **Mitigation Strategy** | 1. Update vulnerability scanning profiles for new tech stacks 2. Reconfigure SAST rules for jakarta.*/Python 3.12/.NET 8 3. Update SCAP/OVAL content for new baselines 4. Validate ConMon reports post-migration |
| **Risk Owner** | DevSecOps Lead |
| **Status** | Active |

### C-003: FIPS 199 Recategorization May Be Required

| Attribute | Value |
|-----------|-------|
| **Risk ID** | C-003 |
| **Category** | Compliance |
| **Affected Systems** | All 14 systems |
| **Description** | Modernization may change data processing patterns (new integrations, expanded user base, cloud migration) that alter the FIPS 199 categorization, requiring additional controls |
| **Likelihood** | 2 (Unlikely) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **6 (Medium)** |
| **Mitigation Strategy** | 1. Review FIPS 199 categorization as part of SSP update 2. Document any changes in data processing 3. If categorization changes, update control baseline accordingly 4. AO review of categorization |
| **Risk Owner** | ISSO |
| **Status** | Active |

### C-004: NIST 800-53 Rev 5 Control Gaps in Legacy Systems

| Attribute | Value |
|-----------|-------|
| **Risk ID** | C-004 |
| **Category** | Compliance |
| **Affected Systems** | nastran-95, apollo-11, cics-banking-sample, cfwheels |
| **Description** | Legacy technology platforms (Fortran, Assembly, COBOL, ColdFusion) may not be able to implement certain NIST 800-53 Rev 5 controls (e.g., FIPS crypto, structured logging, modern authentication) |
| **Likelihood** | 4 (Likely) |
| **Impact** | 3 (Moderate) |
| **Risk Score** | **12 (High)** |
| **Mitigation Strategy** | 1. Document compensating controls for each gap 2. Implement wrapper/infrastructure-level controls where application-level is not feasible 3. Accept residual risk with AO approval 4. Prioritize these systems for technology migration |
| **Risk Owner** | ISSO |
| **Status** | Active |

### C-005: Privacy Impact Assessment (PIA) Updates Required

| Attribute | Value |
|-----------|-------|
| **Risk ID** | C-005 |
| **Category** | Compliance |
| **Affected Systems** | b2cweb, dfe-net, django-oscar, odoo, cics-banking-sample |
| **Description** | Systems processing PII require updated Privacy Impact Assessments when technology changes affect data handling, storage, or transmission patterns |
| **Likelihood** | 4 (Likely) — PIA update is mandatory for PII systems with major modifications |
| **Impact** | 2 (Minor) — Administrative requirement; does not block deployment if initiated |
| **Risk Score** | **8 (Medium)** |
| **Mitigation Strategy** | 1. Initiate PIA update with Privacy Officer 2. Document data flow changes from modernization 3. Verify PII handling in new framework (logging, caching, error messages) 4. Complete before ATO re-authorization |
| **Risk Owner** | Privacy Officer |
| **Status** | Active |

---

## 7. Risk Summary Dashboard

### By Risk Level

| Risk Level | Count | Percentage |
|-----------|-------|------------|
| Very High (16–25) | 3 | 14% |
| High (10–15) | 11 | 50% |
| Medium (5–9) | 7 | 32% |
| Low (1–4) | 1 | 5% |
| **Total** | **22** | **100%** |

### By Category

| Category | Count | Avg Risk Score |
|---------|-------|---------------|
| Technical | 6 | 11.0 |
| Security | 7 | 14.0 |
| Operational | 5 | 10.2 |
| Compliance | 5 | 11.0 |

### Top 5 Risks by Score

| Rank | Risk ID | Description | Score | Level |
|------|---------|-------------|-------|-------|
| 1 | S-005 | COBOL system unassessed (403 access failure) | 25 | Very High |
| 2 | C-001 | ATO re-authorization required for all systems | 20 | Very High |
| 3 | O-002 | Loss of institutional knowledge for legacy languages | 16 | Very High |
| 4 | T-005 | Fortran modernization may alter numerical results | 15 | High |
| 5 | S-007 | ColdFusion lacks FIPS 140-2 validated crypto | 15 | High |

---

## 8. Risk Acceptance Criteria

Risks scored **Low (1–4)** may be accepted by the System Owner.  
Risks scored **Medium (5–9)** may be accepted by the ISSO with System Owner concurrence.  
Risks scored **High (10–15)** require acceptance by the Authorizing Official.  
Risks scored **Very High (16–25)** require acceptance by the Agency CIO/CISO and must have active mitigation plans.

---

## 9. Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Program Manager | _________________ | _________________ | ________ |
| ISSO | _________________ | _________________ | ________ |
| ISSM | _________________ | _________________ | ________ |
| Authorizing Official | _________________ | _________________ | ________ |
