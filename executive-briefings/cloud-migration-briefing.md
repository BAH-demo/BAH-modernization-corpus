# CLOUD MIGRATION READINESS BRIEFING

**Classification: CUI // SP-ADMIN**
**Prepared for:** Infrastructure/Cloud Leadership, CTO, Program Managers
**Date:** April 2026
**Program:** Federal Legacy Systems Modernization Initiative
**Version:** 1.0

---

## 1. Executive Summary

This briefing assesses the cloud migration readiness of 14 legacy systems following Phase 1 (Rationalization) and Phase 2 (Code Refactoring). The modernization effort has upgraded framework targets (Java 17, .NET 8, Python 3.12) and addressed critical dependency issues, establishing a foundation for containerization and cloud deployment. This document provides per-system readiness assessments, infrastructure requirements, cost projections, and a phased migration timeline.

---

## 2. Cloud Readiness Assessment Per System

### 2.1 Readiness Summary

| System | Language | LOC | Cloud Readiness | Containerizable | Effort Level | Priority |
|:-------|:---------|----:|:---------------:|:---------------:|:------------:|:--------:|
| Django Oscar | Python | 85K | HIGH | Yes | Low | 1 |
| Mezzanine | Python | 64K | HIGH | Yes | Low | 2 |
| B2CWeb | Java | 6K | HIGH | Yes | Low | 3 |
| Monolith Enterprise | Java | 5K | HIGH | Yes | Low | 4 |
| DFe.NET | C# | 112K | HIGH | Yes | Medium | 5 |
| Umbraco CMS | C# | 761K | MEDIUM | Yes | Medium | 6 |
| Odoo | Python | 3M | MEDIUM | Yes (complex) | High | 7 |
| Apache OFBiz | Java | 885K | MEDIUM | Yes (complex) | High | 8 |
| Nuxeo | Java | 1.2M | MEDIUM | Yes (complex) | High | 9 |
| Alfresco Community | Java | 1.9M | MEDIUM | Yes (complex) | High | 10 |
| CFWheels | ColdFusion | 178K | LOW | Partial | Very High | 11 |
| NASTRAN-95 | Fortran | 417K | LOW | Partial (HPC) | Very High | 12 |
| Apollo-11 | Assembly | 130K | N/A | No (preservation) | N/A | N/A |
| CICS Banking | COBOL | N/A | BLOCKED | No (mainframe) | Critical | BLOCKED |

### 2.2 Readiness Criteria

| Criteria | Weight | Description |
|:---------|:------:|:------------|
| Modern Runtime | 25% | Runs on current LTS runtime (Java 17+, .NET 8, Python 3.12) |
| Stateless Architecture | 20% | Can externalize state to databases/caches |
| 12-Factor Compliance | 20% | Config via environment, logs to stdout, disposable processes |
| Dependency Management | 15% | Modern package manager, no vendored legacy deps |
| Health Check Support | 10% | Supports HTTP health/readiness endpoints |
| Horizontal Scalability | 10% | Can run multiple instances behind load balancer |

---

## 3. Containerization Status

### 3.1 Containerization Readiness by System

| System | Dockerfile Status | Base Image | Estimated Build Size | Notes |
|:-------|:-----------------:|:-----------|:--------------------:|:------|
| Django Oscar | Ready to Generate | python:3.12-slim | 250-400 MB | Standard Django app; pip dependencies |
| Mezzanine | Ready to Generate | python:3.12-slim | 200-350 MB | Standard Django app; pip dependencies |
| B2CWeb | Ready to Generate | eclipse-temurin:17-jre | 300-450 MB | Small Java webapp |
| Monolith Enterprise | Ready to Generate | eclipse-temurin:17-jre | 300-500 MB | Maven build; Spring Boot |
| DFe.NET | Ready to Generate | mcr.microsoft.com/dotnet/aspnet:8.0 | 200-350 MB | Multi-project solution |
| Umbraco CMS | Ready to Generate | mcr.microsoft.com/dotnet/aspnet:8.0 | 400-600 MB | 31 projects; complex build |
| Odoo | Ready to Generate | python:3.12-slim | 800 MB - 1.2 GB | Large dependency tree; PostgreSQL required |
| Apache OFBiz | Needs Work | eclipse-temurin:17-jre | 600 MB - 1 GB | Gradle build; multiple services |
| Nuxeo | Needs Work | eclipse-temurin:17-jre | 800 MB - 1.5 GB | Maven multi-module; plugin architecture |
| Alfresco Community | Needs Work | eclipse-temurin:17-jre | 1-2 GB | Complex deployment; multiple services |
| CFWheels | Requires Migration | lucee/lucee:latest | 500-800 MB | ColdFusion runtime; limited cloud tooling |
| NASTRAN-95 | Requires HPC Config | ubuntu:22.04 + gfortran | 300-500 MB | HPC workload; requires compute optimization |
| Apollo-11 | N/A | N/A | N/A | Historical preservation; no deployment |
| CICS Banking | BLOCKED | N/A | N/A | Mainframe; requires specialized modernization |

### 3.2 Container Orchestration Requirements

| Component | Recommendation | Justification |
|:----------|:---------------|:--------------|
| **Container Runtime** | containerd (via EKS/AKS) | FedRAMP-authorized managed Kubernetes |
| **Orchestration** | Amazon EKS or Azure AKS | FedRAMP High authorized |
| **Registry** | Amazon ECR / Azure ACR | FedRAMP-authorized container registry |
| **Service Mesh** | Istio or Linkerd | mTLS, traffic management, observability |
| **Ingress** | AWS ALB Ingress / NGINX | Layer 7 routing, TLS termination |
| **Secrets Management** | AWS Secrets Manager / HashiCorp Vault | External secrets injection |
| **Logging** | FluentBit -> CloudWatch / ELK | Centralized log aggregation |
| **Monitoring** | Prometheus + Grafana | Metrics collection and dashboards |

---

## 4. Infrastructure Requirements

### 4.1 Compute Requirements

| Tier | Systems | Total LOC | Estimated vCPU | Estimated RAM | Storage |
|:-----|:--------|:---------|:--------------:|:-------------:|:-------:|
| Tier 1 (Enterprise Monoliths) | OFBiz, Odoo, Alfresco | 5.8M | 24-48 vCPU | 64-128 GB | 500 GB - 1 TB |
| Tier 2 (Enterprise Apps) | 8 systems | 2.4M | 16-32 vCPU | 32-64 GB | 200-500 GB |
| Tier 3 (Federal/Legacy) | NASTRAN, Apollo | 548K | 8-16 vCPU (HPC burst) | 16-32 GB | 100-200 GB |
| **Shared Services** | CI/CD, monitoring, logging | - | 8-16 vCPU | 16-32 GB | 200-500 GB |
| **Total** | | **8.7M** | **56-112 vCPU** | **128-256 GB** | **1-2.2 TB** |

### 4.2 Database Requirements

| System | Database | Current | Cloud Target | Migration Complexity |
|:-------|:---------|:--------|:-------------|:--------------------:|
| Apache OFBiz | PostgreSQL/MySQL | On-prem | RDS/Aurora | Medium |
| Odoo | PostgreSQL | On-prem | RDS PostgreSQL | Medium |
| Alfresco Community | PostgreSQL | On-prem | RDS PostgreSQL | High |
| Nuxeo | PostgreSQL + MongoDB | On-prem | RDS + DocumentDB | High |
| Django Oscar | PostgreSQL | On-prem | RDS PostgreSQL | Low |
| Umbraco CMS | SQL Server | On-prem | RDS SQL Server | Medium |
| Mezzanine | PostgreSQL/SQLite | On-prem | RDS PostgreSQL | Low |
| DFe.NET | SQL Server | On-prem | RDS SQL Server | Medium |
| Monolith Enterprise | MySQL | On-prem | RDS MySQL | Low |

### 4.3 Networking Requirements

| Component | Specification | Notes |
|:----------|:-------------|:------|
| **VPC** | Dedicated VPC with public/private subnets | Multi-AZ for high availability |
| **Transit Gateway** | Connection to agency on-prem network | Hybrid connectivity for phased migration |
| **Load Balancer** | Application Load Balancer (Layer 7) | TLS termination, path-based routing |
| **DNS** | Route 53 / Azure DNS | Weighted routing for blue/green deployment |
| **WAF** | AWS WAF / Azure Front Door | OWASP rule sets, rate limiting |
| **VPN/Direct Connect** | Site-to-site VPN or Direct Connect | Secure connectivity to legacy systems during migration |
| **Network Bandwidth** | 1-10 Gbps | Data migration and ongoing operations |

---

## 5. Cost Projections

### 5.1 Current On-Premises Cost Estimate (Annual)

| Cost Category | Estimate | Notes |
|:-------------|:---------|:------|
| Server Hardware (depreciation) | $180K - $250K | 14 systems across multiple servers |
| Data Center (power, cooling, space) | $120K - $180K | Allocated costs |
| Operating System Licenses | $60K - $100K | Windows Server, RHEL |
| Database Licenses | $80K - $150K | SQL Server, Oracle (if applicable) |
| Network Infrastructure | $40K - $70K | Switches, firewalls, load balancers |
| Backup and DR | $50K - $80K | Tape/disk backup, DR site |
| System Administration (FTEs) | $300K - $450K | 2-3 FTEs for legacy system maintenance |
| **Total On-Premises Annual** | **$830K - $1.28M** | |

### 5.2 Projected Cloud Cost Estimate (Annual, Steady State)

| Cost Category | Estimate | Notes |
|:-------------|:---------|:------|
| Compute (EKS/AKS + EC2/VM) | $150K - $280K | Reserved instances, auto-scaling |
| Database (RDS/Managed DB) | $80K - $160K | Multi-AZ, automated backups |
| Storage (EBS, S3, EFS) | $20K - $50K | Tiered storage with lifecycle policies |
| Networking (NAT, ALB, bandwidth) | $30K - $60K | Data transfer, load balancing |
| Container Registry | $5K - $10K | ECR/ACR image storage |
| Monitoring & Logging | $15K - $30K | CloudWatch/Prometheus/Grafana |
| Security Services (WAF, KMS, GuardDuty) | $20K - $40K | FedRAMP-required security controls |
| Managed Kubernetes | $15K - $30K | EKS/AKS control plane |
| **Total Cloud Annual (Steady State)** | **$335K - $660K** | |

### 5.3 Migration Cost (One-Time)

| Cost Category | Estimate | Notes |
|:-------------|:---------|:------|
| Cloud Architecture Design | $80K - $120K | Solution architecture, network design |
| Containerization Engineering | $100K - $200K | Dockerfile creation, testing, optimization |
| Data Migration | $60K - $120K | Schema migration, data transfer, validation |
| CI/CD Pipeline Development | $40K - $80K | GitHub Actions / GitLab CI configuration |
| IaC Development (Terraform) | $50K - $100K | Infrastructure as Code for all environments |
| Testing & Validation | $60K - $100K | Integration, performance, security testing |
| Training | $20K - $40K | Cloud operations training for team |
| **Total Migration (One-Time)** | **$410K - $760K** | |

### 5.4 Total Cost of Ownership Comparison (3-Year)

| Scenario | Year 1 | Year 2 | Year 3 | 3-Year Total |
|:---------|:------:|:------:|:------:|:------------:|
| **On-Premises (Status Quo)** | $1.05M | $1.10M | $1.15M | $3.30M |
| **Cloud Migration** | $1.10M* | $500K | $530K | $2.13M |
| **Savings** | -$50K | +$600K | +$620K | **+$1.17M** |

*Year 1 includes one-time migration costs*

**ROI:** 3-year cloud migration yields estimated **$1.17M savings** (35% reduction) with additional benefits in scalability, security posture, and operational agility.

---

## 6. Migration Timeline and Phasing

### 6.1 Migration Waves

| Wave | Timeline | Systems | Rationale |
|:-----|:---------|:--------|:----------|
| **Wave 0: Foundation** | April - May 2026 | None (infrastructure) | Cloud landing zone, CI/CD, security controls |
| **Wave 1: Quick Wins** | May - July 2026 | Django Oscar, Mezzanine, B2CWeb, Monolith Enterprise | Small, high-readiness Python/Java apps |
| **Wave 2: Mid-Tier** | July - September 2026 | DFe.NET, Umbraco CMS, CFWheels | .NET and ColdFusion systems requiring more configuration |
| **Wave 3: Enterprise** | September - December 2026 | Odoo, Apache OFBiz, Nuxeo, Alfresco | Large, complex systems with deep dependencies |
| **Wave 4: Federal/Legacy** | January - March 2027 | NASTRAN-95, CICS Banking | Specialized HPC and mainframe workloads |
| **Preservation** | Ongoing | Apollo-11 | Static archive; no cloud deployment needed |

### 6.2 Detailed Migration Timeline

```
Apr 2026  |===== Wave 0: Cloud Landing Zone =====|
May 2026  |  LZ  |===== Wave 1: Quick Wins ========|
Jun 2026  |      |     Wave 1 (cont.)     |
Jul 2026  |      |  W1  |===== Wave 2: Mid-Tier ===|
Aug 2026  |      |      |     Wave 2 (cont.)       |
Sep 2026  |      |      |  W2  |==== Wave 3: Ent ===|
Oct 2026  |      |      |      |   Wave 3 (cont.)   |
Nov 2026  |      |      |      |   Wave 3 (cont.)   |
Dec 2026  |      |      |      |  W3  | Stabilize   |
Jan 2027  |      |      |      |      |== Wave 4 ===|
Feb 2027  |      |      |      |      | Wave 4 cont |
Mar 2027  |      |      |      |      |  W4  | Done |
```

### 6.3 Key Milestones

| Milestone | Target Date | Dependencies |
|:----------|:------------|:-------------|
| Cloud Landing Zone Operational | May 2026 | Cloud account provisioning, IAM setup |
| First System in Cloud (Django Oscar) | June 2026 | Wave 0 complete, ATO for LZ |
| Wave 1 Complete (4 systems) | July 2026 | Build verification (Phase 3) |
| Wave 2 Complete (3 systems) | September 2026 | .NET compatibility testing |
| Wave 3 Complete (4 systems) | December 2026 | Enterprise architecture review |
| NASTRAN-95 HPC Deployment | February 2027 | HPC cluster configuration |
| CICS Banking Migration | March 2027 | Repository access, mainframe expertise |
| Full Migration Complete | March 2027 | All waves complete, legacy decommissioned |

---

## 7. Risk Assessment for Cloud Migration

### 7.1 Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|:-----|:---------:|:------:|:-----------|
| **Data loss during migration** | Low | Critical | Blue/green deployment; rollback procedures; data validation checksums |
| **Extended downtime** | Medium | High | Canary releases; parallel run with legacy; automated rollback |
| **Performance degradation** | Medium | Medium | Load testing pre-migration; auto-scaling; performance baselines |
| **Cost overrun** | Medium | Medium | Reserved instances; cost alerts; monthly review |
| **FedRAMP compliance gaps** | Medium | High | Pre-migration compliance assessment; CSP partnership |
| **CICS Banking inaccessible** | High | High | Escalate access issue; plan alternative mainframe approach |
| **ColdFusion cloud incompatibility** | High | Medium | Lucee/CommandBox containerization; long-term rewrite plan |
| **NASTRAN HPC performance** | Medium | High | Benchmark on cloud HPC; compare with on-prem baseline |
| **Staff skill gaps** | Medium | Medium | Training program; cloud-native consulting support |
| **Vendor lock-in** | Low | Medium | Multi-cloud IaC (Terraform); portable container images |

### 7.2 Risk Summary

| Risk Level | Count |
|:-----------|:-----:|
| Critical | 1 (data loss) |
| High | 4 (downtime, FedRAMP, CICS, NASTRAN) |
| Medium | 4 (performance, cost, ColdFusion, skills) |
| Low | 1 (vendor lock-in) |

---

## 8. FedRAMP Cloud Requirements

### 8.1 Cloud Service Provider Requirements

| Requirement | Specification |
|:-----------|:-------------|
| **Authorization Level** | FedRAMP High (for federal systems) |
| **Data Residency** | CONUS data centers only |
| **Encryption at Rest** | FIPS 140-2/3 validated modules |
| **Encryption in Transit** | TLS 1.2+ (TLS 1.3 preferred) |
| **Key Management** | Customer-managed keys (BYOK) |
| **Audit Logging** | CloudTrail/Activity Log with tamper-evident storage |
| **Access Control** | PIV/CAC integration for administrative access |
| **Incident Response** | 1-hour notification for security incidents |
| **Continuous Monitoring** | ConMon program with monthly vulnerability scans |
| **Penetration Testing** | Annual third-party assessment |

### 8.2 Recommended Cloud Providers (FedRAMP High Authorized)

| Provider | Authorization | GovCloud Region | Kubernetes Service |
|:---------|:-------------|:----------------|:-------------------|
| AWS GovCloud | FedRAMP High | us-gov-west-1, us-gov-east-1 | EKS |
| Azure Government | FedRAMP High | US Gov Virginia, US Gov Arizona | AKS |
| Google Cloud (IL4) | FedRAMP High | us-central1, us-east1 | GKE |

### 8.3 FedRAMP Documentation Requirements for Cloud Migration

| Document | Status | Action Required |
|:---------|:------:|:----------------|
| System Security Plan (SSP) | NOT STARTED | Phase 4 deliverable |
| Security Assessment Report (SAR) | NOT STARTED | Requires 3PAO engagement |
| Plan of Action & Milestones (POA&M) | DRAFT | Formalize from Phase 2 findings |
| Continuous Monitoring Strategy | NOT STARTED | Phase 7 deliverable |
| Configuration Management Plan | NOT STARTED | Phase 5 deliverable |
| Incident Response Plan | NOT STARTED | Phase 7 deliverable |
| Architecture Diagrams | NOT STARTED | Phase 5 deliverable |
| Data Flow Diagrams | NOT STARTED | Phase 5 deliverable |
| Interconnection Security Agreements | NOT STARTED | Required for hybrid connectivity |

---

## 9. Recommendations

1. **Begin Cloud Landing Zone immediately** - Provision FedRAMP-authorized cloud environment to unblock Wave 1
2. **Prioritize Wave 1 systems** - Django Oscar, Mezzanine, B2CWeb, and Monolith Enterprise are ready for containerization with minimal additional work
3. **Engage FedRAMP 3PAO early** - Third-party assessment organization lead time is typically 3-6 months
4. **Resolve CICS Banking access** - Mainframe modernization is on the critical path for Wave 4
5. **Establish HPC benchmark baseline** - NASTRAN-95 cloud performance must be validated against on-prem before migration commitment
6. **Plan ColdFusion exit strategy** - CFWheels requires long-term framework migration; containerize Lucee as interim solution
7. **Implement reserved instance purchasing** - Commit to 1-year reserved instances for predictable workloads to reduce cloud costs by 30-40%

---

*Prepared by: Federal Legacy Modernization Program Office - Cloud Architecture Team*
*Distribution: CTO, Infrastructure Director, Cloud Engineering Lead, Program Manager*
*Classification: CUI // SP-ADMIN*
*Next Review: Bi-weekly Cloud Migration Status Review*
