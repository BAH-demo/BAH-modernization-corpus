# Authority to Operate (ATO) Submission Cover Letter

**CONTROLLED UNCLASSIFIED INFORMATION (CUI)**

---

**Date:** April 2026
**From:** Program Manager, Legacy Systems Modernization Program
**To:** Authorizing Official (AO)
**Through:** Information System Security Officer (ISSO)
**Subject:** Request for Authority to Operate — Federal Legacy Systems Modernization Program (14 Systems)

---

## 1. Purpose

This letter formally requests Authority to Operate (ATO) for the modernized federal legacy systems portfolio comprising 14 information systems totaling 8.7 million lines of code across 55,000+ files. The modernization effort has completed all seven planned phases and produced comprehensive security documentation in accordance with NIST SP 800-53 Rev. 5, NIST SP 800-37 Rev. 2, and applicable Federal Information Security Modernization Act (FISMA) requirements.

## 2. System Identification

### 2.1 Systems Under Review

| # | System Name | Technology Stack | Lines of Code | FIPS 199 Impact |
|---|-------------|-----------------|---------------|-----------------|
| 1 | Apache OFBiz | Java/Gradle → Jakarta EE | 2,831,744 | Moderate |
| 2 | Odoo | Python/JavaScript | 1,712,019 | Moderate |
| 3 | Alfresco Community | Java/Maven → Jakarta EE | 1,146,489 | Moderate |
| 4 | Umbraco CMS | C#/.NET 8 | 760,917 | Low |
| 5 | CFWheels | ColdFusion/CFML | 354,155 | Moderate |
| 6 | Nuxeo | Java/Maven → Jakarta EE | 317,824 | Moderate |
| 7 | Django Oscar | Python/Django | 254,810 | Moderate |
| 8 | B2CWeb | Java → Jakarta EE | 229,439 | Low |
| 9 | Mezzanine | Python/Django | 68,541 | Low |
| 10 | DFe.NET | C#/.NET 8 | 56,728 | Low |
| 11 | Monolith Enterprise | Java/Maven → Jakarta EE | 45,237 | Moderate |
| 12 | NASTRAN-95 | Fortran 77 | 107,485 | High |
| 13 | Apollo-11 Guidance | AGC Assembly | 81,520 | Low (Historical) |
| 14 | CICS Banking Sample | COBOL/JCL | — | High |

### 2.2 Target Environment

- **Cloud Provider:** AWS GovCloud (US)
- **Container Orchestration:** Amazon EKS (Kubernetes 1.28+)
- **Database:** Amazon RDS (PostgreSQL 15, MySQL 8.0)
- **Object Storage:** Amazon S3 (SSE-KMS encrypted)
- **Network:** Private VPC with NAT gateways, no direct internet exposure
- **Encryption:** AWS KMS for all data at rest; TLS 1.3 for data in transit

## 3. Security Documentation Package

The following artifacts are included with this submission:

### 3.1 Core ATO Documents

| Document | Location | Status |
|----------|----------|--------|
| System Security Plan (SSP) | `compliance/system-security-plan.md` | Complete |
| NIST 800-53 Control Mapping | `compliance/nist-800-53-control-mapping.md` | Complete |
| Plan of Action & Milestones (POA&M) | `compliance/poam.md` | Complete |
| Risk Register | `compliance/risk-register.md` | Complete |
| Risk Assessment Report | `compliance/risk-assessment-report.md` | Complete |

### 3.2 Technical Security Evidence

| Evidence | Location | Status |
|----------|----------|--------|
| SAST Scan Results (Semgrep) | `sast-results/` | Complete |
| Software Bill of Materials (SBOMs) | `compliance/sbom/` | 5 of 14 generated; remainder documented |
| Terraform IaC (validated) | `terraform/` | Validated — 0 warnings |
| Kubernetes Security Manifests | `kubernetes/` | 92 manifests — NetworkPolicy, PDB, resource limits |
| Docker Security Configs | `ci-cd/dockerfiles/` | 11 Dockerfiles — non-root, minimal base images |
| Infrastructure Security | `terraform/` | KMS encryption, private subnets, VPC flow logs |

### 3.3 Operational Security Documents

| Document | Location | Status |
|----------|----------|--------|
| Incident Response Playbooks | `operational-docs/incident-response/` | 13 system-specific playbooks |
| Monitoring & Observability | `operational-docs/observability/` | Prometheus + Grafana + ELK stack configs |
| Operational Runbooks | `operational-docs/runbooks/` | 13 system-specific runbooks |
| Decommission Plans | `operational-docs/decommission/` | 13 system-specific plans |

## 4. Security Posture Summary

### 4.1 Key Security Controls Implemented

- **AC — Access Control:** RBAC via Kubernetes RBAC + AWS IAM/IRSA; zero-trust network architecture
- **AU — Audit & Accountability:** CloudWatch Logs with KMS encryption; VPC Flow Logs; application-level audit trails
- **CA — Security Assessment:** Automated SAST/DAST in CI/CD; infrastructure-as-code validation
- **CM — Configuration Management:** GitOps-driven configuration; immutable container images; Terraform state management
- **IA — Identification & Authentication:** AWS IAM with MFA; Kubernetes service accounts with IRSA
- **IR — Incident Response:** 13 system-specific IR playbooks with escalation procedures
- **RA — Risk Assessment:** Comprehensive risk register with 14-system coverage
- **SA — System & Services Acquisition:** SBOMs for supply chain transparency; dependency vulnerability scanning
- **SC — System & Communications Protection:** TLS 1.3 everywhere; KMS encryption at rest; network segmentation via VPC/NetworkPolicy
- **SI — System & Information Integrity:** Automated vulnerability scanning; container image scanning; runtime monitoring

### 4.2 Known Risks & Mitigations

| Risk | Severity | Mitigation | POA&M Item |
|------|----------|------------|------------|
| NASTRAN-95 Fortran code lacks modern memory safety | High | Containerized with strict resource limits; network-isolated | POA&M-001 |
| CICS Banking Sample requires mainframe runtime | High | Containerized CICS emulation with monitored access | POA&M-002 |
| OFBiz has 2,063 global mutable state instances | Medium | Flagged for incremental refactoring; monitored via APM | POA&M-003 |
| CFWheels has 46 SQL injection risk patterns | Medium | `encodeForHTML()` applied; parameterized queries recommended | POA&M-004 |
| Umbraco requires .NET SDK 10.0 (unreleased) | Low | Pinned to .NET 8; SDK 10.0 adoption planned | POA&M-005 |

### 4.3 Residual Risk Assessment

The overall residual risk for the modernized portfolio is assessed as **MODERATE**. All High-severity risks have documented mitigations and are tracked in the POA&M. The modernization has significantly reduced the attack surface by:

- Migrating from deprecated frameworks (javax → Jakarta EE, .NET Framework → .NET 8)
- Eliminating known vulnerable dependency versions
- Implementing defense-in-depth with container isolation, network segmentation, and encryption
- Adding automated security scanning to CI/CD pipelines

## 5. Pending Actions Requiring AO Decision

| # | Action | Owner | Decision Needed |
|---|--------|-------|-----------------|
| 1 | Approve ATO for initial pilot deployment (Monolith Enterprise) | AO | Authorize |
| 2 | Approve phased ATO for remaining Tier 2 systems | AO | Authorize |
| 3 | Authorize penetration testing scope and schedule | AO/ISSO | Approve |
| 4 | Accept residual risk for NASTRAN-95 Fortran memory safety | AO | Accept/Mitigate |
| 5 | Accept residual risk for CICS Banking mainframe emulation | AO | Accept/Mitigate |

## 6. Recommendation

Based on the comprehensive security documentation, automated scanning results, and defense-in-depth architecture implemented across all 14 systems, we recommend the Authorizing Official grant:

1. **Interim ATO (IATO)** for the pilot system (Monolith Enterprise) to validate the security posture in a controlled environment
2. **Conditional ATO** for Tier 2 systems contingent on successful pilot deployment and penetration testing results
3. **Phased ATO** for Tier 1 enterprise monoliths (OFBiz, Odoo, Alfresco) following Tier 2 deployment validation

The recommended ATO duration is **3 years** with annual security reviews and continuous monitoring.

## 7. Points of Contact

| Role | Name | Organization |
|------|------|-------------|
| Program Manager | [TBD] | [Organization] |
| ISSO | [TBD] | [Organization] |
| Security Engineer | [TBD] | [Organization] |
| AO | [TBD] | [Organization] |

---

**Enclosures:**
1. System Security Plan (SSP)
2. NIST 800-53 Rev. 5 Control Mapping
3. Plan of Action & Milestones (POA&M)
4. Risk Register
5. Risk Assessment Report
6. SAST Scan Results
7. Software Bills of Materials (SBOMs)
8. Infrastructure-as-Code Validation Results
9. Executive Briefing Package

---

*This document is CONTROLLED UNCLASSIFIED INFORMATION (CUI) and should be handled in accordance with 32 CFR Part 2002.*
