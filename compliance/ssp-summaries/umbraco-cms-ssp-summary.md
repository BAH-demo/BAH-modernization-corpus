# SSP Summary: Umbraco CMS

**System Identifier:** umbraco-cms  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

Umbraco CMS is an open-source content management system built on the .NET platform, providing flexible content authoring, media management, multi-language support, and extensible publishing workflows. In the federal context, Umbraco supports agency intranet portals, knowledge management systems, and internal communication platforms.

**Tier Classification:** Tier 2 — Enterprise Application (5K–50K LOC)  
**Primary Function:** Intranet Content Management and Internal Publishing  
**User Base:** Internal agency staff (content authors, editors, administrators, all-staff readers)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System hosts internal agency communications and potentially sensitive policy documents; unauthorized external disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Content integrity is important for policy dissemination; unauthorized modification could distribute incorrect guidance |
| **Availability** | Low | Intranet portal; temporary outage would inconvenience staff but alternative communication channels exist |

**Overall System Categorization:** **Moderate** (due to Confidentiality/Integrity high-water mark)

`SC umbraco-cms = {(confidentiality, moderate), (integrity, moderate), (availability, low)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | .NET Framework 4.x | 4.7.x/4.8 | Maintenance mode |
| Framework | ASP.NET MVC / Web API | Legacy | Maintenance |
| CMS | Umbraco | Legacy version | Outdated |
| Database | SQL Server | Various | Active |
| Hosting | IIS on Windows Server | Legacy | Active |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | .NET 8 LTS | 8.x | November 2026 |
| Framework | ASP.NET Core | 8.x | Active |
| CMS | Umbraco (updated) | Current | Active |
| Database | SQL Server | Current | Active |
| Hosting | Kestrel / IIS (reverse proxy) | Current | Active |
| Type Safety | Nullable reference types enabled | C# 12 | N/A |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- .NET Framework → .NET 8 migration resolves known .NET Framework CVEs
- ASP.NET Core includes security fixes not backported to legacy ASP.NET
- Updated NuGet packages address known dependency vulnerabilities

### 4.2 SI-11 Error Handling
- Nullable reference types (NRT) enabled — compiler enforces null safety
- Eliminates entire class of NullReferenceException vulnerabilities
- Reduces information disclosure via unhandled exception paths

### 4.3 SC-13 Cryptographic Protection
- .NET 8 uses OS-level FIPS 140-2 validated cryptographic modules
- `System.Security.Cryptography` APIs leverage CNG (Windows) or OpenSSL (Linux) FIPS providers
- Data Protection API (DPAPI) for key management

### 4.4 CM-6 Configuration Settings
- ASP.NET Core defaults: HTTPS redirect, HSTS, anti-forgery tokens
- `Kestrel` server hardened with request size limits and header restrictions
- Development exception pages disabled in production

### 4.5 AC-3 Access Enforcement
- ASP.NET Core Identity with policy-based authorization
- Nullable reference types prevent null-bypass of `ClaimsPrincipal` checks

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| UMB-001 | Custom Umbraco backoffice extensions may not handle nullable references correctly | Runtime NullReferenceException in admin panel | Medium | Open | Q3 2026 |
| UMB-002 | .NET 8 LTS end-of-support November 2026 | Must plan migration to .NET 10 LTS before support expiration | Medium | Open | Q3 2026 |
| UMB-003 | Legacy Umbraco data types may expose raw HTML to editors | Stored XSS risk in content editing workflow | Medium | Open | Q3 2026 |
| UMB-004 | SQL Server connection string may be in plaintext configuration | Credential exposure if config files are compromised | Low | Open | Q4 2026 |

---

## 6. Recommended Authorization Boundary

The umbraco-cms authorization boundary should include:

- **Web tier:** IIS reverse proxy or cloud load balancer
- **Application tier:** Umbraco CMS application (Kestrel), backoffice admin interface
- **Data tier:** SQL Server database (content, users, configuration)
- **Media tier:** Media/file storage (local filesystem or blob storage)
- **Cache tier:** In-memory or distributed cache (if configured)

**Boundary Exclusions (Inherited Controls):**
- Underlying IaaS/PaaS infrastructure (if FedRAMP-authorized)
- Physical data center controls
- Network perimeter firewalls
- Active Directory/Azure AD (if used for authentication)

**Interconnections Requiring ISA:**
- Active Directory / Azure AD (staff authentication)
- Email service (notification — SMTP outbound)
- SIEM platform (outbound log shipping via ETW/Serilog)
- CDN (if internal content is cached — unusual for intranet)
