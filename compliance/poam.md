# Plan of Action & Milestones (POA&M) — Legacy Modernization Portfolio

**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only  
**Prepared For:** Federal Legacy Modernization Program Office  
**Review Cycle:** Monthly

---

## 1. Purpose

This Plan of Action and Milestones (POA&M) documents security findings identified during the modernization of 14 legacy systems (13 active, 1 skipped). Each finding includes a risk rating, remediation plan, responsible party, and target completion date per NIST SP 800-53 CA-5 requirements.

## 2. POA&M Summary

| Risk Level | Open Items | Closed Items | Total |
|-----------|-----------|-------------|-------|
| High | 18 | 0 | 18 |
| Medium | 25 | 0 | 25 |
| Low | 11 | 0 | 11 |
| **Total** | **54** | **0** | **54** |

---

## 3. Findings — Java Systems (5 Systems)

### 3.1 Apache OFBiz

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| OFBIZ-001 | Legacy global state patterns remain in codebase; shared mutable state may introduce race conditions and data leakage between user sessions | SI-2, SC-4 | Medium | Q3 2026 | Development Lead | 1. Identify all COMMON/global state patterns (Q2 2026) 2. Refactor to thread-safe patterns (Q3 2026) 3. Verify via load testing (Q3 2026) | Open |
| OFBIZ-002 | Monolithic architecture limits blast radius containment; single vulnerability could compromise entire ERP surface | SA-8, SC-39 | Medium | Q4 2026 | Solution Architect | 1. Document module boundaries (Q3 2026) 2. Implement JPMS modules (Q4 2026) 3. Validate isolation (Q4 2026) | Open |
| OFBIZ-003 | Custom ORM may not fully leverage parameterized queries | SI-10, SA-11 | Medium | Q3 2026 | Development Lead | 1. Audit all query builders (Q2 2026) 2. Replace string concat with parameterized queries (Q3 2026) 3. SAST scan verification (Q3 2026) | Open |
| OFBIZ-004 | Runtime regression testing incomplete; not all business flows validated post-migration | SA-11, CA-2 | Low | Q2 2026 | QA Lead | 1. Identify critical business flows (Q2 2026) 2. Execute regression test suite (Q2 2026) 3. Document results (Q2 2026) | Open |
| OFBIZ-005 | Third-party plugin compatibility with Jakarta namespace unverified | CM-4, SA-4 | Medium | Q3 2026 | Development Lead | 1. Inventory all plugins (Q2 2026) 2. Test each plugin with jakarta.* (Q3 2026) 3. Replace/update incompatible plugins (Q3 2026) | Open |

### 3.2 Alfresco Community

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| ALF-001 | Legacy content repository API may have undocumented endpoints allowing unauthorized document access | AC-3, AC-4 | Medium | Q3 2026 | Security Lead | 1. API endpoint discovery scan (Q2 2026) 2. Document all endpoints (Q3 2026) 3. Apply authorization to undocumented endpoints (Q3 2026) | Open |
| ALF-002 | Solr search index may cache sensitive document content in plaintext | SC-28, MP-4 | Medium | Q3 2026 | System Administrator | 1. Audit Solr index contents (Q2 2026) 2. Implement index encryption (Q3 2026) 3. Verify with penetration test (Q3 2026) | Open |
| ALF-003 | Custom workflow definitions not validated post-migration | SA-11, CM-4 | Low | Q2 2026 | Development Lead | 1. Inventory all custom workflows (Q2 2026) 2. Test each workflow (Q2 2026) 3. Document results (Q2 2026) | Open |
| ALF-004 | Third-party Alfresco modules may still reference javax.* causing runtime failures | CM-4, SI-2 | Medium | Q3 2026 | Development Lead | 1. Inventory third-party modules (Q2 2026) 2. Test compatibility (Q3 2026) 3. Update or replace modules (Q3 2026) | Open |

### 3.3 Nuxeo

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| NUX-001 | Complex plugin architecture may have unmigrated javax.* references | SI-2, CM-4 | Medium | Q3 2026 | Development Lead | 1. Scan all plugins for javax.* (Q2 2026) 2. Migrate remaining references (Q3 2026) 3. Integration test (Q3 2026) | Open |
| NUX-002 | Elasticsearch index contains sensitive document metadata | SC-28, AC-3 | Medium | Q3 2026 | Security Lead | 1. Audit ES index contents (Q2 2026) 2. Implement field-level security (Q3 2026) 3. Encrypt index at rest (Q3 2026) | Open |
| NUX-003 | Custom Nuxeo Automation chains not fully regression tested | SA-11, CM-4 | Medium | Q2 2026 | QA Lead | 1. Inventory automation chains (Q2 2026) 2. Execute test suite (Q2 2026) 3. Document results (Q2 2026) | Open |
| NUX-004 | MongoDB document store encryption-at-rest not verified post-migration | SC-28 | High | Q2 2026 | System Administrator | 1. Verify MongoDB encryption config (Q2 2026) 2. Enable if missing (Q2 2026) 3. Penetration test validation (Q2 2026) | Open |

### 3.4 B2CWeb

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| B2C-001 | Tight coupling between presentation and business logic limits security isolation | SA-8, SC-39 | High | Q4 2026 | Solution Architect | 1. Architectural assessment (Q3 2026) 2. Define decomposition plan (Q3 2026) 3. Implement separation (Q4 2026) | Open |
| B2C-002 | Server-rendered pages may have residual XSS vulnerabilities in citizen-facing portal | SI-10, SI-2 | High | Q2 2026 | Security Lead | 1. DAST scan of all pages (Q2 2026) 2. Fix identified XSS (Q2 2026) 3. Rescan verification (Q2 2026) | Open |
| B2C-003 | PII data handling not fully validated post-migration; citizen data may be exposed in logs or error messages | SI-11, SC-28 | High | Q2 2026 | Development Lead | 1. Audit log output for PII (Q2 2026) 2. Implement PII scrubbing (Q2 2026) 3. Verify with log review (Q2 2026) | Open |
| B2C-004 | Session management migration from javax.servlet to jakarta.servlet may introduce session handling bugs | AC-12, SC-23 | Medium | Q2 2026 | Development Lead | 1. Session handling regression tests (Q2 2026) 2. Fix identified issues (Q2 2026) 3. Penetration test (Q2 2026) | Open |
| B2C-005 | Legacy JSP includes may bypass new security filters | AC-3, SI-10 | Medium | Q3 2026 | Security Lead | 1. Audit all JSP includes (Q2 2026) 2. Apply security filters (Q3 2026) 3. SAST verification (Q3 2026) | Open |

### 3.5 Monolith Enterprise

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| MONO-001 | Single deployment unit creates single point of failure across all business domains | SA-8, CP-2 | High | Q4 2026 | Solution Architect | 1. Identify domain boundaries (Q3 2026) 2. JPMS modularization (Q4 2026) 3. Validate isolation (Q4 2026) | Open |
| MONO-002 | Tight coupling between modules limits independent security patching | CM-3, SI-2 | High | Q4 2026 | Development Lead | 1. Dependency analysis (Q3 2026) 2. Decouple shared libraries (Q4 2026) 3. Validate independent deployability (Q4 2026) | Open |
| MONO-003 | Shared database with cross-domain data lacks compartmentalization | AC-3, SC-4 | Medium | Q3 2026 | Database Administrator | 1. Schema audit (Q2 2026) 2. Implement row-level security (Q3 2026) 3. Validate data isolation (Q3 2026) | Open |
| MONO-004 | Complex dependency graph makes SBOM validation difficult | CM-8, SA-4 | Medium | Q3 2026 | DevSecOps Lead | 1. Generate comprehensive SBOM (Q2 2026) 2. Validate transitive deps (Q3 2026) 3. Automate SBOM checks in CI (Q3 2026) | Open |
| MONO-005 | Full regression test suite is time-consuming, delaying security patch deployment | SI-2, MA-6 | Medium | Q3 2026 | QA Lead | 1. Identify critical path tests (Q2 2026) 2. Implement fast smoke test suite (Q3 2026) 3. Parallel test execution (Q3 2026) | Open |

---

## 4. Findings — Python Systems (3 Systems)

### 4.1 Odoo

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| ODOO-001 | Large plugin/module ecosystem may contain unmigrated code using deprecated Python patterns | SI-2, CM-4 | Medium | Q3 2026 | Development Lead | 1. Scan all modules for deprecated patterns (Q2 2026) 2. Update third-party modules (Q3 2026) 3. Regression test (Q3 2026) | Open |
| ODOO-002 | Dynamic module loading (even with importlib) introduces code execution risk | SI-3, SA-8 | Medium | Q3 2026 | Security Lead | 1. Audit module loading paths (Q2 2026) 2. Implement module allowlisting (Q3 2026) 3. Runtime monitoring (Q3 2026) | Open |
| ODOO-003 | ORM-generated SQL may not be fully parameterized in custom modules | SI-10 | Medium | Q3 2026 | Development Lead | 1. SAST scan of custom modules (Q2 2026) 2. Fix identified SQL injection paths (Q3 2026) 3. Rescan verification (Q3 2026) | Open |
| ODOO-004 | Type hints added but not enforced at runtime; type safety is advisory only | SA-11 | Low | Q4 2026 | Development Lead | 1. Configure mypy strict mode (Q3 2026) 2. Integrate mypy into CI (Q3 2026) 3. Achieve zero-error mypy run (Q4 2026) | Open |

### 4.2 Django Oscar

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| OSC-001 | Architectural debt in checkout workflow; complex flow may have unvalidated state transitions | SI-10, SA-8 | Medium | Q3 2026 | Development Lead | 1. Map checkout state machine (Q2 2026) 2. Add state validation (Q3 2026) 3. Security test checkout flow (Q3 2026) | Open |
| OSC-002 | Payment processing integration not validated post-migration | SI-2, SA-11 | High | Q2 2026 | Payment Lead | 1. Payment gateway connectivity test (Q2 2026) 2. End-to-end transaction test (Q2 2026) 3. PCI compliance validation (Q2 2026) | Open |
| OSC-003 | Custom Oscar dashboard views may have XSS vulnerabilities enabling admin privilege escalation | SI-10, AC-6 | Medium | Q3 2026 | Security Lead | 1. DAST scan of admin views (Q2 2026) 2. Fix identified XSS (Q3 2026) 3. Rescan verification (Q3 2026) | Open |
| OSC-004 | Type hints incomplete in custom business logic; static analysis coverage gaps | SA-11 | Low | Q4 2026 | Development Lead | 1. Add type hints to critical paths (Q3 2026) 2. Integrate mypy into CI (Q3 2026) 3. Achieve coverage threshold (Q4 2026) | Open |

### 4.3 Mezzanine

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| MEZ-001 | Rich text editor may allow stored XSS via crafted HTML serving malicious scripts to public visitors | SI-10, SI-2 | High | Q2 2026 | Security Lead | 1. Audit rich text sanitization (Q2 2026) 2. Implement server-side HTML sanitization (Q2 2026) 3. DAST verification (Q2 2026) | Open |
| MEZ-002 | File upload functionality may allow unrestricted file types containing malicious content | SI-3, SI-10 | Medium | Q3 2026 | Development Lead | 1. Implement file type allowlisting (Q2 2026) 2. Add virus scanning (Q3 2026) 3. Test upload restrictions (Q3 2026) | Open |
| MEZ-003 | Mezzanine admin panel session-based authentication; session hijacking risk | AC-12, SC-23 | Medium | Q2 2026 | Security Lead | 1. Enforce HTTPS-only sessions (Q2 2026) 2. Implement session timeout (Q2 2026) 3. Add MFA for admin (Q2 2026) | Open |
| MEZ-004 | Legacy theme templates may not escape output consistently; template injection risk | SI-10 | Medium | Q3 2026 | Development Lead | 1. Audit all templates for unescaped output (Q2 2026) 2. Fix identified issues (Q3 2026) 3. Implement CSP headers (Q3 2026) | Open |

---

## 5. Findings — C# Systems (2 Systems)

### 5.1 Umbraco CMS

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| UMB-001 | Custom backoffice extensions may not handle nullable references correctly | SI-11, SI-2 | Medium | Q3 2026 | Development Lead | 1. Enable NRT warnings in all projects (Q2 2026) 2. Fix all nullable warnings (Q3 2026) 3. Test backoffice extensions (Q3 2026) | Open |
| UMB-002 | .NET 8 LTS end-of-support November 2026; must plan .NET 10 migration | MA-6, SA-15 | Medium | Q3 2026 | Solution Architect | 1. Assess .NET 10 compatibility (Q3 2026) 2. Create migration plan (Q3 2026) 3. Execute migration before Nov 2026 (Q3 2026) | Open |
| UMB-003 | Legacy Umbraco data types may expose raw HTML to editors; stored XSS risk | SI-10 | Medium | Q3 2026 | Security Lead | 1. Audit data types for raw HTML (Q2 2026) 2. Implement sanitization (Q3 2026) 3. DAST verification (Q3 2026) | Open |
| UMB-004 | SQL Server connection string may be in plaintext configuration | IA-5, SC-28 | Low | Q4 2026 | System Administrator | 1. Implement Azure Key Vault or DPAPI (Q3 2026) 2. Remove plaintext strings (Q4 2026) 3. Verify (Q4 2026) | Open |

### 5.2 DfE .NET

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| DFE-001 | .NET 8 LTS support ends November 2026; migration to .NET 10 required | MA-6, SA-15 | Medium | Q3 2026 | Solution Architect | 1. Assess .NET 10 compatibility (Q3 2026) 2. Create migration plan (Q3 2026) 3. Execute before Nov 2026 (Q3 2026) | Open |
| DFE-002 | Legacy EF 6 migrations may not translate cleanly to EF Core | SI-2, SA-11 | Medium | Q2 2026 | Development Lead | 1. Audit data migrations (Q2 2026) 2. Test all migration paths (Q2 2026) 3. Fix data access issues (Q2 2026) | Open |
| DFE-003 | Citizen PII handling not fully validated for FERPA compliance post-migration | SI-11, SC-28 | High | Q2 2026 | Privacy Officer | 1. PII data flow mapping (Q2 2026) 2. Audit logging for PII exposure (Q2 2026) 3. Implement PII scrubbing (Q2 2026) | Open |
| DFE-004 | Custom middleware from .NET Framework pipeline may not be fully ported | AC-3, SI-10 | Medium | Q3 2026 | Development Lead | 1. Inventory legacy middleware (Q2 2026) 2. Port or replace middleware (Q3 2026) 3. Security test pipeline (Q3 2026) | Open |
| DFE-005 | Nullable reference types may cause warnings in untouched legacy code | SA-11 | Low | Q4 2026 | Development Lead | 1. Enable NRT in all projects (Q3 2026) 2. Triage warnings (Q3 2026) 3. Fix critical paths (Q4 2026) | Open |

---

## 6. Findings — ColdFusion (1 System)

### 6.1 CFWheels

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| CFW-001 | ColdFusion runtime has limited security update cadence; zero-day exposure risk | SI-2, SI-5 | High | Q2 2026 | System Administrator | 1. Verify latest CF patches applied (Q2 2026) 2. Configure WAF rules for known CF vulns (Q2 2026) 3. Establish patch monitoring (Q2 2026) | Open |
| CFW-002 | ColdFusion lacks modern security middleware; security is application-level only | AC-3, SA-8 | High | Q3 2026 | Security Lead | 1. Implement WAF as compensating control (Q2 2026) 2. Add application-level security filters (Q3 2026) 3. Network segmentation (Q3 2026) | Open |
| CFW-003 | XSS/SQL injection fixes may not cover all code paths; untested views may retain vulnerabilities | SI-10, SI-2 | Medium | Q3 2026 | Security Lead | 1. Full DAST scan of all endpoints (Q2 2026) 2. Fix remaining vulnerabilities (Q3 2026) 3. Rescan and penetration test (Q3 2026) | Open |
| CFW-004 | ColdFusion developer talent pool is shrinking; difficulty finding qualified security reviewers | PS-3, MA-5 | Medium | Ongoing | Program Manager | 1. Document institutional knowledge (Q2 2026) 2. Cross-train existing staff (Q3 2026) 3. Evaluate replatforming (Q4 2026) | Open |
| CFW-005 | No FIPS 140-2 validated crypto module for ColdFusion runtime | SC-13, IA-7 | High | Q2 2026 | Security Lead | 1. Assess crypto usage in application (Q2 2026) 2. Implement Java-level FIPS provider (Q2 2026) 3. Validate FIPS compliance (Q2 2026) | Open |
| CFW-006 | ColdFusion platform should be considered for retirement; recommend replatforming to Java or .NET | PL-2, SA-3 | Medium | FY2027 | Solution Architect | 1. Cost-benefit analysis (Q4 2026) 2. Target platform selection (Q1 2027) 3. Migration plan (Q2 2027) | Open |

---

## 7. Findings — Fortran (1 System)

### 7.1 NASTRAN-95

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| NAS-001 | GOTO statements remain in codebase (flagged but not removed); complex control flow hinders security review | SA-8, SI-7 | Medium | Q4 2026 | Development Lead | 1. Prioritize GOTO removal by risk (Q3 2026) 2. Refactor high-risk GOTOs (Q4 2026) 3. Verify computation integrity (Q4 2026) | Open |
| NAS-002 | COMMON blocks remain (flagged but not removed); shared mutable state could leak data between analysis runs | SC-4, AC-3 | Medium | Q4 2026 | Development Lead | 1. Identify mutable COMMON blocks (Q3 2026) 2. Refactor to module variables (Q4 2026) 3. Multi-user isolation test (Q4 2026) | Open |
| NAS-003 | No modern input validation framework for Fortran; input files parsed without bounds checking | SI-10 | High | Q3 2026 | Development Lead | 1. Audit input parsing routines (Q2 2026) 2. Add bounds checking (Q3 2026) 3. Fuzz testing of input parser (Q3 2026) | Open |
| NAS-004 | Legacy Fortran has no memory safety guarantees; buffer overflows possible in array operations | SI-16 | High | Q3 2026 | Development Lead | 1. Compile with bounds-checking flags (Q2 2026) 2. Address identified overflows (Q3 2026) 3. Runtime testing (Q3 2026) | Open |
| NAS-005 | No automated test suite for regression verification of computation results | SA-11, SI-7 | Medium | Q3 2026 | QA Lead | 1. Identify reference test cases (Q2 2026) 2. Automate comparison tests (Q3 2026) 3. Validate numerical accuracy (Q3 2026) | Open |
| NAS-006 | Limited Fortran security tooling; SAST tools have minimal Fortran support | RA-5, SA-11 | Medium | Ongoing | DevSecOps Lead | 1. Evaluate Fortran SAST tools (Q2 2026) 2. Manual code review for critical sections (Q3 2026) 3. Document findings (Q3 2026) | Open |

---

## 8. Findings — Assembly (1 System)

### 8.1 Apollo-11

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| APL-001 | Non-operational system; limited traditional security relevance | PL-2 | Low | N/A | Program Manager | 1. Document risk acceptance (Q2 2026) 2. AO sign-off (Q2 2026) | Open |
| APL-002 | If used as input to analysis tools, crafted Assembly could exploit parser vulnerabilities | SI-3, SA-11 | Low | Q4 2026 | DevSecOps Lead | 1. Identify tools consuming AGC source (Q3 2026) 2. Validate parser security (Q4 2026) 3. Document tool-chain risk (Q4 2026) | Open |
| APL-003 | Historical accuracy dependent on upstream repository integrity | SI-7 | Low | Ongoing | System Administrator | 1. Create authoritative local mirror (Q2 2026) 2. Implement integrity checksums (Q2 2026) 3. Periodic verification (Ongoing) | Open |

---

## 9. Findings — COBOL (1 System)

### 9.1 CICS Banking Sample

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| CICS-001 | **System not modernized — repository inaccessible (HTTP 403)**; all vulnerabilities remain unaddressed | SI-2, CA-2 | **High** | Q2 2026 | Program Manager | 1. Resolve repository access (Q2 2026) 2. Perform security assessment (Q2 2026) 3. Execute modernization (Q3 2026) | Open |
| CICS-002 | COBOL/CICS talent shortage; shrinking developer pool increases maintenance and key-person risk | PS-3, MA-5 | High | Ongoing | Program Manager | 1. Knowledge documentation (Q2 2026) 2. Cross-training program (Q3 2026) 3. Evaluate automated migration tools (Q4 2026) | Open |
| CICS-003 | Mainframe security tooling not integrated with modern DevSecOps | RA-5, SA-11 | Medium | Q3 2026 | DevSecOps Lead | 1. Evaluate COBOL SAST tools (Q2 2026) 2. Pilot selected tool (Q3 2026) 3. Integrate into CI pipeline (Q3 2026) | Open |
| CICS-004 | COBOL programs may lack input validation; CICS BMS maps may accept unvalidated input | SI-10 | High | Q2 2026 | Security Lead | 1. Audit CICS BMS map definitions (Q2 2026) 2. Add input validation (Q2 2026) 3. Test with boundary values (Q2 2026) | Open |
| CICS-005 | RACF/ACF2 security configuration not audited; access control drift possible | AC-2, AC-3 | Medium | Q3 2026 | System Administrator | 1. Export RACF profiles (Q2 2026) 2. Compare to baseline (Q3 2026) 3. Remediate drift (Q3 2026) | Open |
| CICS-006 | Repository access must be restored before any assessment or remediation | CA-2, CM-3 | **High** | Q2 2026 | Program Manager | 1. Contact repository owner (Immediate) 2. Obtain access credentials (Q2 2026) 3. Clone and baseline (Q2 2026) | Open |

---

## 10. Cross-Cutting Findings (Portfolio-Wide)

| POA&M ID | Finding | Control | Risk | Scheduled Completion | Responsible Party | Milestones | Status |
|----------|---------|---------|------|---------------------|-------------------|------------|--------|
| XCUT-001 | ATO re-authorization required for all 13 actively modernized systems | CA-6 | High | Q3 2026 | ISSO | 1. SSP updates (Q2 2026) 2. Control assessment (Q3 2026) 3. AO authorization decision (Q3 2026) | Open |
| XCUT-002 | SBOM generation not standardized across all technology stacks | CM-8, SA-4 | Medium | Q3 2026 | DevSecOps Lead | 1. Define SBOM format (CycloneDX/SPDX) (Q2 2026) 2. Implement per-system SBOM generation (Q3 2026) 3. Automate in CI/CD (Q3 2026) | Open |
| XCUT-003 | Continuous monitoring tooling not deployed for legacy systems (Fortran, Assembly, COBOL) | CA-7 | Medium | Q3 2026 | DevSecOps Lead | 1. Evaluate monitoring options (Q2 2026) 2. Implement wrapper-level monitoring (Q3 2026) 3. Integrate with SIEM (Q3 2026) | Open |
| XCUT-004 | .NET 8 LTS end-of-support November 2026 affects 2 C# systems | MA-6, SI-5 | Medium | Q3 2026 | Solution Architect | 1. .NET 10 compatibility assessment (Q2 2026) 2. Migration plan (Q3 2026) 3. Execute migration (Q3 2026) | Open |

---

## 11. POA&M Review Schedule

| Review Date | Reviewer | Scope | Deliverable |
|------------|---------|-------|-------------|
| May 2026 | ISSO + System Owners | All open items | Monthly status update |
| June 2026 | ISSO + System Owners | All open items | Monthly status update |
| July 2026 | ISSO + AO | Q2 milestone items | Quarterly review report |
| August 2026 | ISSO + System Owners | All open items | Monthly status update |
| September 2026 | ISSO + System Owners | All open items | Monthly status update |
| October 2026 | ISSO + AO | Q3 milestone items | Quarterly review report |

---

## 12. Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Program Manager | _________________ | _________________ | ________ |
| ISSO | _________________ | _________________ | ________ |
| ISSM | _________________ | _________________ | ________ |
| Authorizing Official | _________________ | _________________ | ________ |
