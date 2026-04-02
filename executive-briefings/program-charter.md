# PROGRAM CHARTER

**Classification: CUI // SP-ADMIN**
**Program:** Federal Legacy Systems Modernization Initiative
**Date:** April 2026
**Version:** 1.0
**Prepared by:** Program Management Office
**Approved by:** [Agency CIO - Signature Required]

---

## 1. Program Identification

| Field | Value |
|:------|:------|
| **Program Name** | Federal Legacy Systems Modernization Initiative |
| **Program ID** | FLSMI-2026-001 |
| **Sponsoring Organization** | Agency CIO Office |
| **Program Manager** | [TBD] |
| **Executive Sponsor** | Agency CIO |
| **Authorization Date** | [TBD - Pending Approval] |
| **Estimated Duration** | 12 months (April 2026 - March 2027) |
| **Estimated Total Budget** | $1.2M - $1.8M (automated approach) |

---

## 2. Program Scope and Objectives

### 2.1 Program Scope

#### In Scope

The Federal Legacy Systems Modernization Initiative encompasses the following:

**Systems (14 Total):**

| Tier | System | Language | LOC | Scope |
|:-----|:-------|:---------|----:|:------|
| Tier 1 | Apache OFBiz | Java | 885,211 | Full modernization and cloud migration |
| Tier 1 | Odoo | Python | 3,007,247 | Full modernization and cloud migration |
| Tier 1 | Alfresco Community | Java | 1,883,473 | Full modernization and cloud migration |
| Tier 2 | Umbraco CMS | C# | 761,123 | Full modernization and cloud migration |
| Tier 2 | CFWheels | ColdFusion | 178,321 | Security hardening; framework migration assessment |
| Tier 2 | Nuxeo | Java | 1,197,472 | Full modernization and cloud migration |
| Tier 2 | Django Oscar | Python | 85,673 | Full modernization and cloud migration |
| Tier 2 | B2CWeb | Java | 6,507 | Full modernization and cloud migration |
| Tier 2 | Mezzanine | Python | 64,453 | Full modernization and cloud migration |
| Tier 2 | DFe.NET | C# | 112,701 | Full modernization and cloud migration |
| Tier 2 | Monolith Enterprise | Java | 5,897 | Full modernization and cloud migration |
| Tier 3 | CICS Banking Sample | COBOL | TBD | Mainframe modernization assessment |
| Tier 3 | NASTRAN-95 | Fortran | 417,500 | Fortran modernization; HPC cloud assessment |
| Tier 3 | Apollo-11 | Assembly | 130,186 | Historical preservation and documentation |

**Activities:**
1. Legacy system rationalization and analysis
2. Automated code refactoring and transformation
3. CI/CD pipeline implementation and build verification
4. ATO package development (SSP, POA&M, NIST 800-53 mapping)
5. Containerization and cloud migration
6. Staged cutover and legacy decommission
7. Sustainment (monitoring, dependency management, runbooks)

#### Out of Scope
- New feature development for any modernized system
- End-user retraining (unless interface changes result from modernization)
- Hardware procurement for on-premises infrastructure
- Organizational change management beyond IT operations
- Systems not listed in the 14-system inventory
- Data center physical security upgrades
- Network infrastructure replacement

### 2.2 Program Objectives

| # | Objective | Measurable Target | Timeline |
|:-:|:----------|:------------------|:---------|
| O-1 | Eliminate end-of-life framework dependencies | 0 EOL frameworks in production | Phase 2 (COMPLETE) |
| O-2 | Remediate critical security vulnerabilities | 100% critical/high findings remediated | Phase 4 |
| O-3 | Achieve ATO for all modernized systems | ATO granted for 13+ systems | Phase 4 |
| O-4 | Migrate systems to FedRAMP-authorized cloud | 11+ systems deployed to cloud | Phase 5-6 |
| O-5 | Establish automated CI/CD for all systems | CI/CD operational for 13+ systems | Phase 3 |
| O-6 | Reduce annual maintenance costs | 30%+ reduction vs. current baseline | Phase 7 |
| O-7 | Improve mean time to patch | < 72 hours for critical vulnerabilities | Phase 7 |
| O-8 | Decommission legacy infrastructure | Legacy environments shut down | Phase 6 |

---

## 3. Success Criteria

### 3.1 Phase-Level Success Criteria

| Phase | Criteria | Metric | Threshold |
|:------|:---------|:-------|:----------|
| **Phase 1** | All systems analyzed | Systems completed | 13/14 (ACHIEVED - 1 blocked) |
| **Phase 1** | Strategies defined | Strategies documented | 14/14 (ACHIEVED) |
| **Phase 2** | Code transforms applied | Files changed with 0 retries | 641 files, 0 retries (ACHIEVED) |
| **Phase 2** | Patches generated | Reversible patches created | 13 patches (ACHIEVED) |
| **Phase 3** | Builds verified | Systems that compile clean | >= 11/14 |
| **Phase 3** | SAST completed | Systems scanned | 13/14 |
| **Phase 4** | ATO packages submitted | SSPs completed | >= 11/14 |
| **Phase 4** | POA&M items < 30 days old | Outstanding items | <= 5 |
| **Phase 5** | Containerized | Systems with Docker images | >= 11/14 |
| **Phase 5** | Cloud deployed (staging) | Systems in cloud staging | >= 8/14 |
| **Phase 6** | Production cutover | Systems live in cloud | >= 8/14 |
| **Phase 6** | Legacy decommissioned | Legacy environments shut down | >= 8/14 |
| **Phase 7** | Monitoring operational | Systems with observability | 100% of deployed |
| **Phase 7** | Dependency management | Systems with automated dep updates | 100% of deployed |

### 3.2 Program-Level Success Criteria

| Criterion | Target | Measurement Method |
|:----------|:-------|:-------------------|
| **Schedule Performance Index (SPI)** | >= 0.9 | Earned Value Management |
| **Cost Performance Index (CPI)** | >= 0.9 | Earned Value Management |
| **Security Posture** | No critical findings in production | SAST/DAST/pen test results |
| **Stakeholder Satisfaction** | >= 4.0 / 5.0 | Quarterly survey |
| **System Availability (post-migration)** | >= 99.5% | Monitoring platform |
| **Mean Time to Recovery** | < 4 hours | Incident records |

---

## 4. Governance Structure

### 4.1 Governance Bodies

| Body | Chair | Members | Frequency | Authority |
|:-----|:------|:--------|:---------:|:----------|
| **Executive Steering Committee** | CIO | CTO, CISO, PM, CO | Monthly | Strategic direction, phase authorization, budget approval |
| **Program Review Board** | PM | COR, Tech Leads, ISSO, Cloud Architect | Bi-weekly | Technical decisions, risk acceptance, scope changes |
| **Security Review Board** | CISO | ISSO, PM, Security Engineers | Monthly | Security architecture, ATO decisions, vulnerability acceptance |
| **Change Control Board** | PM | CTO delegate, System Owners, QA Lead | As needed | Scope changes, requirement modifications, baseline changes |
| **Technical Working Group** | Tech Lead | Dev Leads, Cloud Engineer, DBA | Weekly | Implementation decisions, technical standards |

### 4.2 Organizational Structure

```
                    Agency CIO (Executive Sponsor)
                              |
                    Agency CTO ---- Agency CISO
                              |
                     Program Manager
                    /       |       \
                   /        |        \
        Technical Lead   Security    Cloud Architect
              |           Lead            |
         Dev Teams      ISSO         Cloud Engineers
         (per system)   Security     Infrastructure
                        Engineers    Engineers
```

### 4.3 Decision Authority Matrix

| Decision Type | < $50K | $50K-$250K | > $250K |
|:-------------|:------:|:----------:|:-------:|
| Budget Allocation | PM | CO + COR | CIO |
| Schedule Change (< 2 weeks) | PM | PM | PM |
| Schedule Change (2-4 weeks) | PM + COR | PM + COR | CIO |
| Schedule Change (> 4 weeks) | CIO | CIO | CIO |
| Scope Change (minor) | PM | PM + CTO | CIO |
| Scope Change (major) | CIO | CIO | CIO |
| Security Waiver | CISO | CISO | CISO + CIO |
| Technology Selection | CTO | CTO | CTO + CIO |
| Vendor Selection | CO | CO | CO + CIO |

---

## 5. Resource Requirements

### 5.1 Personnel

| Role | Count | Allocation | Phase(s) | Source |
|:-----|:-----:|:----------:|:---------|:------|
| Program Manager | 1 | 100% | All | Government / Contractor |
| Technical Lead | 1 | 100% | All | Contractor |
| Java Developer (Senior) | 2 | 100% | 3-6 | Contractor |
| Python Developer (Senior) | 1 | 100% | 3-6 | Contractor |
| C#/.NET Developer (Senior) | 1 | 100% | 3-6 | Contractor |
| Cloud/DevOps Engineer | 2 | 100% | 3-7 | Contractor |
| Security Engineer | 1 | 100% | 3-5 | Contractor |
| ISSO | 1 | 50% | 4-7 | Government |
| QA/Test Engineer | 1 | 100% | 3-6 | Contractor |
| Fortran SME | 1 | 25% | 3-5 | Contractor / Government |
| COBOL/Mainframe SME | 1 | 25% | 3-5 | Contractor |
| Database Administrator | 1 | 50% | 5-6 | Contractor |
| Technical Writer | 1 | 50% | 4-7 | Contractor |

**Total FTEs:** ~12.5 FTE peak (Phases 3-5), ~6 FTE sustainment (Phase 7)

### 5.2 Technology and Tools

| Category | Tool/Service | Purpose | Cost Estimate |
|:---------|:-----------|:--------|:-------------|
| Cloud Platform | AWS GovCloud or Azure Gov | FedRAMP High hosting | $335K-$660K/year |
| Container Orchestration | EKS or AKS | Kubernetes managed service | Included above |
| CI/CD | GitHub Actions / GitLab CI | Build automation | $10K-$30K/year |
| SAST | Semgrep, Bandit, Trivy | Static analysis scanning | $0 (open source) |
| DAST | OWASP ZAP | Dynamic analysis scanning | $0 (open source) |
| Secrets Management | HashiCorp Vault | Credential management | $15K-$40K/year |
| Monitoring | Prometheus + Grafana | Observability | $15K-$30K/year |
| IaC | Terraform | Infrastructure as Code | $0 (open source core) |
| Project Tracking | JIRA / ServiceNow | Work management | Existing agency license |
| Documentation | SharePoint / Confluence | Document management | Existing agency license |

### 5.3 Budget Summary

| Phase | Duration | Labor | Tools/Infra | Total |
|:------|:---------|:------|:-----------|:------|
| Phase 1-2 (Complete) | < 1 hour | $30K | $0 | $30K |
| Phase 3 - CI/CD & Testing | 2-4 weeks | $80K-$120K | $10K | $90K-$130K |
| Phase 4 - ATO & Compliance | 4-8 weeks | $150K-$250K | $30K | $180K-$280K |
| Phase 5 - Containerization & Cloud | 6-12 weeks | $200K-$350K | $100K | $300K-$450K |
| Phase 6 - Staged Cutover | 4-8 weeks | $120K-$200K | $20K | $140K-$220K |
| Phase 7 - Sustainment (Year 1) | Ongoing | $200K-$300K | $80K | $280K-$380K |
| **TOTAL (Year 1)** | **12 months** | **$780K-$1.25M** | **$240K-$540K** | **$1.02M-$1.79M** |

---

## 6. Risk Management Approach

### 6.1 Risk Management Framework

The program will use a structured risk management process aligned with NIST SP 800-37 and agency risk management policy:

1. **Identify** - Continuous risk identification through all stakeholder channels
2. **Assess** - Likelihood x Impact scoring (5x5 matrix)
3. **Prioritize** - Risk ranking and resource allocation
4. **Mitigate** - Develop and implement mitigation strategies
5. **Monitor** - Ongoing tracking and reporting
6. **Report** - Bi-weekly to Program Review Board; monthly to Steering Committee

### 6.2 Risk Scoring Matrix

| | **Impact: Very Low (1)** | **Low (2)** | **Medium (3)** | **High (4)** | **Very High (5)** |
|:--|:---:|:---:|:---:|:---:|:---:|
| **Likelihood: Very High (5)** | 5 | 10 | 15 | 20 | 25 |
| **High (4)** | 4 | 8 | 12 | 16 | 20 |
| **Medium (3)** | 3 | 6 | 9 | 12 | 15 |
| **Low (2)** | 2 | 4 | 6 | 8 | 10 |
| **Very Low (1)** | 1 | 2 | 3 | 4 | 5 |

**Risk Appetite:**
- Scores 1-6: ACCEPT (monitor)
- Scores 7-12: MITIGATE (active management)
- Scores 13-19: ESCALATE (steering committee awareness)
- Scores 20-25: IMMEDIATE ACTION (steering committee decision)

### 6.3 Initial Risk Register

| ID | Risk | L | I | Score | Mitigation | Owner |
|:--:|:-----|:-:|:-:|:-----:|:-----------|:------|
| R-01 | CICS Banking repository access blocked | 5 | 4 | 20 | Escalate to infrastructure team; identify alternate access path | PM |
| R-02 | Cloud cost exceeds projections | 3 | 3 | 9 | Reserved instances; cost alerts; monthly review | Cloud Architect |
| R-03 | ATO process delays (3PAO availability) | 4 | 4 | 16 | Engage 3PAO early; prepare documentation ahead of schedule | ISSO |
| R-04 | Staff skill gaps in legacy languages | 3 | 3 | 9 | Identify Fortran/COBOL SMEs early; training budget | Tech Lead |
| R-05 | Modernized code introduces regressions | 3 | 4 | 12 | Comprehensive testing; golden-file regression baselines | QA Lead |
| R-06 | Stakeholder resistance to cloud migration | 2 | 3 | 6 | Early engagement; demonstrate benefits; phased approach | PM |
| R-07 | ColdFusion runtime incompatibility in cloud | 4 | 3 | 12 | Lucee containerization; long-term framework migration | Tech Lead |
| R-08 | Data loss during migration | 1 | 5 | 5 | Blue/green deployment; checksums; rollback procedures | DBA |
| R-09 | NASTRAN-95 HPC performance in cloud | 3 | 4 | 12 | Benchmark testing; GPU/HPC instance selection | Cloud Architect |
| R-10 | Budget shortfall for Phases 5-7 | 2 | 4 | 8 | Early budget justification; phased funding approach | PM |

---

## 7. Quality Assurance Approach

### 7.1 Quality Standards

| Standard | Application | Requirement |
|:---------|:-----------|:------------|
| NIST SP 800-53 Rev 5 | Security controls | All systems must map to applicable controls |
| NIST SP 800-37 | Risk management | Risk assessment for each phase transition |
| NIST SP 800-160 | Systems security engineering | Secure design principles in modernization |
| IEEE 730 | Software quality assurance | QA processes for code transforms |
| ISO 27001 | Information security management | Security management framework alignment |
| Agency SDLC Policy | Development lifecycle | Compliance with agency development standards |

### 7.2 Quality Gates

| Gate | Phase Transition | Criteria | Approver |
|:-----|:----------------|:---------|:---------|
| **QG-1** | Phase 2 -> Phase 3 | All transforms applied; patches generated; zero retries | PM + Tech Lead |
| **QG-2** | Phase 3 -> Phase 4 | Builds pass; SAST complete; no critical findings unmitigated | PM + ISSO |
| **QG-3** | Phase 4 -> Phase 5 | ATO package submitted; POA&M accepted; pen test complete | CISO + PM |
| **QG-4** | Phase 5 -> Phase 6 | Containers built and tested; IaC validated; staging deployed | CTO + PM |
| **QG-5** | Phase 6 -> Phase 7 | Production cutover successful; legacy decommissioned; monitoring live | CIO + PM |

### 7.3 Testing Strategy

| Test Type | Phase | Scope | Tools | Responsibility |
|:----------|:-----:|:------|:------|:---------------|
| Unit Tests | 3 | Per-system regression | JUnit, pytest, NUnit, FUnit | Dev Teams |
| Integration Tests | 3 | Cross-module verification | Automated harnesses | QA Engineer |
| SAST | 3 | All source code | Semgrep, Bandit, Trivy | Security Engineer |
| DAST | 3-4 | Running applications | OWASP ZAP | Security Engineer |
| Performance Tests | 5 | Cloud-deployed systems | k6, JMeter | QA Engineer |
| Penetration Test | 4 | Per-system | Third-party assessor | ISSO |
| UAT | 6 | Business process validation | Manual + automated | System Owners |
| Smoke Tests | 6 | Post-cutover validation | Automated harnesses | Dev Teams |

---

## 8. Change Management Strategy

### 8.1 Change Management Principles

1. **Transparency** - All changes documented and communicated to affected stakeholders
2. **Traceability** - Changes linked to requirements, risks, or defects
3. **Reversibility** - All code changes implemented as reversible patches
4. **Minimal Disruption** - Changes phased to minimize operational impact
5. **Stakeholder Engagement** - Affected parties consulted before significant changes

### 8.2 Change Categories

| Category | Description | Approval Authority | Lead Time |
|:---------|:-----------|:-------------------|:----------|
| **Standard** | Pre-approved routine changes (patches, config updates) | PM | 24 hours |
| **Normal** | Planned changes with moderate risk | Change Control Board | 5 business days |
| **Major** | Scope changes, architecture changes, budget changes > 10% | Executive Steering Committee | 10 business days |
| **Emergency** | Critical security patches, system failures | PM + CISO (post-approval by CCB) | Immediate |

### 8.3 Change Request Process

```
1. Change Request Submitted (Requestor)
   |
2. Impact Assessment (Technical Lead + PM)
   |
3. Categorization (PM)
   |
4. Review & Approval (Per authority matrix)
   |
5. Implementation Planning (Technical Lead)
   |
6. Implementation (Development Team)
   |
7. Verification & Validation (QA)
   |
8. Closure & Documentation (PM)
```

### 8.4 Organizational Change Management

| Stakeholder Group | Change Impact | Support Required |
|:-----------------|:-------------|:----------------|
| IT Operations | HIGH - New cloud platforms, new monitoring tools, new processes | Training, runbooks, shadow period |
| System Owners | MEDIUM - New hosting, same functionality | Communication, UAT participation |
| End Users | LOW - Minimal visible changes | Notification of maintenance windows |
| Security Team | HIGH - New security tools, new compliance processes | Training, process documentation |
| Help Desk | MEDIUM - New troubleshooting procedures | Updated knowledge base, escalation paths |

### 8.5 Training Plan

| Audience | Training Topic | Method | Duration | Timeline |
|:---------|:-------------|:-------|:--------:|:---------|
| Dev Teams | Cloud-native development (K8s, containers) | Workshop | 3 days | Phase 3 |
| Dev Teams | Modern framework features (Java 17, .NET 8) | Self-paced | 2 days | Phase 3 |
| Operations | Cloud operations (EKS/AKS, Terraform) | Workshop | 5 days | Phase 5 |
| Operations | Monitoring tools (Prometheus, Grafana) | Hands-on lab | 2 days | Phase 7 |
| Security | Cloud security (GuardDuty, WAF, container scanning) | Workshop | 3 days | Phase 4 |
| System Owners | Post-migration system administration | Briefing | 1 day | Phase 6 |
| Help Desk | Updated troubleshooting procedures | Knowledge base | Self-paced | Phase 6 |

---

## 9. Program Phases and Milestones

| Phase | Name | Start | End | Key Deliverables |
|:------|:-----|:------|:----|:-----------------|
| **1** | Rationalization & Analysis | April 2026 | April 2026 | Rationalization report, per-system strategies (COMPLETE) |
| **2** | Code Refactoring | April 2026 | April 2026 | 641 files refactored, 13 patch files (COMPLETE) |
| **3** | CI/CD & Testing | April 2026 | May 2026 | CI/CD pipelines, build verification, SAST/DAST |
| **4** | ATO & Compliance | April 2026 | June 2026 | SSP, POA&M, NIST mapping, pen test |
| **5** | Containerization & Cloud | June 2026 | September 2026 | Dockerfiles, K8s manifests, IaC, cloud deployment |
| **6** | Staged Cutover | September 2026 | November 2026 | Blue/green deployment, legacy decommission |
| **7** | Sustainment | November 2026 | Ongoing | Monitoring, dependency management, runbooks |

---

## 10. Assumptions and Constraints

### 10.1 Assumptions

1. All 14 system repositories will be accessible (CICS Banking access to be resolved)
2. FedRAMP-authorized cloud environment will be provisioned by Phase 5
3. Agency will provide domain SMEs for business logic validation
4. Budget will be approved for all seven phases
5. 3PAO will be available for ATO assessment within planned timeline
6. No major organizational restructuring during program execution
7. Existing agency SDLC and change management policies remain applicable

### 10.2 Constraints

1. All systems must achieve ATO before production cloud deployment
2. Cloud deployment must use FedRAMP High authorized CSP
3. Data must remain within CONUS
4. FIPS 140-2/3 validated cryptography required
5. PIV/CAC authentication required for administrative access
6. Apollo-11 is preservation-only; no code modifications permitted
7. Budget ceiling per agency allocation

### 10.3 Dependencies

| Dependency | Source | Impact if Not Met |
|:-----------|:-------|:-----------------|
| Cloud account provisioning | Infrastructure team | Phase 5 blocked |
| CICS Banking repo access | Repository administrator | COBOL modernization blocked |
| 3PAO engagement | Procurement | ATO timeline delayed |
| Domain SME availability | Business units | Validation quality risk |
| Funding approval (Phases 3-7) | CFO / Budget office | Program halted |

---

## 11. Approval

| Role | Name | Signature | Date |
|:-----|:-----|:----------|:-----|
| **Executive Sponsor (CIO)** | [TBD] | __________________ | _______ |
| **Technical Authority (CTO)** | [TBD] | __________________ | _______ |
| **Security Authority (CISO)** | [TBD] | __________________ | _______ |
| **Program Manager** | [TBD] | __________________ | _______ |
| **Contracting Officer** | [TBD] | __________________ | _______ |

---

*Prepared by: Federal Legacy Modernization Program Office*
*Classification: CUI // SP-ADMIN*
*This charter is effective upon signature by the Executive Sponsor.*
*Amendments require Executive Steering Committee approval.*
