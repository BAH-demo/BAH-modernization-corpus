# SSP Summary: DfE .NET

**System Identifier:** dfe-net  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

DfE .NET is a .NET-based government services application providing citizen-facing digital services for education-related functions including applications, eligibility checking, and case management. In the federal context, this system represents a mid-scale government digital service built on the Microsoft technology stack.

**Tier Classification:** Tier 2 — Enterprise Application (5K–50K LOC)  
**Primary Function:** Citizen-Facing Education Services Portal  
**User Base:** External citizens (applicants, students, parents) and internal agency staff (case workers, administrators)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System processes citizen PII including educational records (FERPA-protected), contact information, and eligibility data; unauthorized disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Application and eligibility determination integrity is critical; unauthorized modification could result in incorrect benefits or denials |
| **Availability** | Moderate | Citizen-facing service portal; extended outage would prevent citizens from accessing education services during application periods |

**Overall System Categorization:** **Moderate**

`SC dfe-net = {(confidentiality, moderate), (integrity, moderate), (availability, moderate)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | .NET Framework 4.x | 4.7.x/4.8 | Maintenance mode |
| Framework | ASP.NET MVC / Web API | Legacy | Maintenance |
| Database | SQL Server | Various | Active |
| Hosting | IIS on Windows Server | Legacy | Active |
| ORM | Entity Framework 6.x | Legacy | Maintenance |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | .NET 8 LTS | 8.x | November 2026 |
| Framework | ASP.NET Core | 8.x | Active |
| Database | SQL Server | Current | Active |
| Hosting | Kestrel / IIS (reverse proxy) | Current | Active |
| ORM | Entity Framework Core 8.x | Current | Active |
| Type Safety | Nullable reference types enabled | C# 12 | N/A |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- .NET Framework → .NET 8 migration resolves known CVEs
- Entity Framework Core 8 replaces EF 6 with improved parameterized query generation
- ASP.NET Core security middleware stack replaces legacy HTTP modules

### 4.2 SI-10 Information Input Validation
- Model validation via data annotations and FluentValidation
- Nullable reference types enforce non-null constraints at compile time
- Anti-forgery tokens for all state-changing operations

### 4.3 AC-3 Access Enforcement
- ASP.NET Core policy-based authorization with claims
- Nullable reference types prevent null-bypass of authorization objects
- `[Authorize]` attribute with policy requirements on all protected endpoints

### 4.4 IA-2 Identification and Authentication
- ASP.NET Core Identity supports SAML/OIDC for Login.gov or agency IdP integration
- MFA enforcement for administrative access
- PIV/CAC authentication support via client certificate middleware

### 4.5 SC-8 Transmission Confidentiality
- .NET 8 Kestrel supports TLS 1.3
- HTTPS redirect and HSTS enforced by default
- Certificate-based mutual TLS available for service-to-service communication

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| DFE-001 | .NET 8 LTS support ends November 2026 | Must plan .NET 10 LTS migration before support expiration | Medium | Open | Q3 2026 |
| DFE-002 | Legacy EF 6 migrations may not translate cleanly to EF Core | Data access layer may have runtime errors post-migration | Medium | Open | Q2 2026 |
| DFE-003 | Citizen PII handling not fully validated for FERPA compliance post-migration | PII may be logged or cached inappropriately | High | Open | Q2 2026 |
| DFE-004 | Custom middleware from .NET Framework pipeline may not be fully ported | Security middleware gaps in request pipeline | Medium | Open | Q3 2026 |
| DFE-005 | Nullable reference types may cause warnings in untouched legacy code | False sense of security if NRT not applied uniformly | Low | Open | Q4 2026 |

---

## 6. Recommended Authorization Boundary

The dfe-net authorization boundary should include:

- **Web tier:** Public-facing load balancer with WAF, reverse proxy
- **Application tier:** ASP.NET Core application (Kestrel), background job processors
- **Data tier:** SQL Server database (citizen records, application data, case files)
- **Cache tier:** Distributed cache (Redis or SQL Server-based)
- **Integration tier:** API endpoints for external service connections

**Boundary Exclusions (Inherited Controls):**
- CDN/DDoS protection (if using FedRAMP-authorized provider)
- Underlying IaaS/PaaS infrastructure
- Physical data center controls

**Interconnections Requiring ISA:**
- Login.gov or agency IdP (citizen/staff authentication — SAML/OIDC)
- Education data systems (student records — inbound/outbound)
- Notification service (email/SMS — outbound)
- SIEM platform (outbound log shipping)
- Payment processing (if applicable)
