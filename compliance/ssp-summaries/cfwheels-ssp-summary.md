# SSP Summary: CFWheels

**System Identifier:** cfwheels  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

CFWheels is a ColdFusion MVC framework used to build web applications on the Adobe ColdFusion or Lucee CFML runtime. In the federal context, CFWheels-based applications support internal agency web portals, data entry systems, and workflow automation tools. ColdFusion remains in use across many federal agencies for legacy line-of-business applications.

**Tier Classification:** Tier 2 — Enterprise Application (5K–50K LOC)  
**Primary Function:** Internal Web Application Framework (ColdFusion)  
**User Base:** Internal agency staff (data entry, case management, workflow users)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System may process internal agency data, case records, and potentially PII; unauthorized disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Data entry and workflow integrity is important for operational accuracy; unauthorized modification could corrupt business records |
| **Availability** | Low | Internal-use application; temporary outage would delay operations but alternative manual processes exist |

**Overall System Categorization:** **Moderate** (due to Confidentiality/Integrity high-water mark)

`SC cfwheels = {(confidentiality, moderate), (integrity, moderate), (availability, low)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | Adobe ColdFusion / Lucee | Legacy version | Active (limited support) |
| Framework | CFWheels MVC | Legacy | Active |
| Database | SQL Server / MySQL | Various | Active |
| Web Server | IIS / Apache | Legacy | Active |
| Security | No systematic input validation | N/A | Vulnerable |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | Adobe ColdFusion / Lucee | Updated | Active |
| Framework | CFWheels MVC (hardened) | Updated | Active |
| Database | SQL Server / MySQL | Current | Active |
| Web Server | IIS / Apache | Current | Active |
| Security | XSS/SQL injection fixes applied | N/A | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- **SQL injection vulnerabilities remediated:** String concatenation in SQL queries replaced with parameterized queries (`cfqueryparam` / query parameters)
- **XSS vulnerabilities remediated:** User input output encoding applied (`encodeForHTML()`, `encodeForJavaScript()`, `encodeForURL()`)
- These fixes directly address OWASP Top 10 #A03:2021 (Injection) and #A07:2021 (XSS)

### 4.2 SI-10 Information Input Validation
- Server-side input validation added for all user-supplied data
- Parameterized queries enforce type-safe database access
- Output encoding prevents reflected and stored XSS

### 4.3 AC-4 Information Flow Enforcement
- XSS fixes prevent unauthorized information flow via script injection
- SQL injection fixes prevent unauthorized data extraction

### 4.4 SA-8 Security Engineering Principles
- Defense-in-depth: input validation, parameterized queries, AND output encoding
- Fail-secure: invalid input rejected rather than sanitized

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| CFW-001 | ColdFusion runtime itself has limited security update cadence | Zero-day vulnerabilities in CFML runtime may not be patched promptly | High | Open | Q2 2026 |
| CFW-002 | ColdFusion lacks modern security middleware patterns | No equivalent to Spring Security or ASP.NET Core Identity; security is application-level only | High | Open | Q3 2026 |
| CFW-003 | XSS/SQL injection fixes may not cover all code paths | Untested views or admin functions may retain vulnerabilities | Medium | Open | Q3 2026 |
| CFW-004 | ColdFusion developer talent pool is shrinking | Difficulty finding qualified security reviewers for CFML code | Medium | Open | Ongoing |
| CFW-005 | No FIPS 140-2 validated crypto module for ColdFusion runtime | Cryptographic operations may not meet federal standards | High | Open | Q2 2026 |
| CFW-006 | Framework should be considered for technology migration (retire ColdFusion) | Long-term technology risk; recommend replatforming to Java or .NET | Medium | Open | FY2027 |

---

## 6. Recommended Authorization Boundary

The cfwheels authorization boundary should include:

- **Web tier:** IIS/Apache web server with ColdFusion connector
- **Application tier:** ColdFusion runtime, CFWheels application code
- **Data tier:** SQL Server/MySQL database
- **Session tier:** ColdFusion session management (server-side)

**Boundary Exclusions (Inherited Controls):**
- Underlying server infrastructure
- Physical data center controls
- Network perimeter firewalls

**Interconnections Requiring ISA:**
- Active Directory (staff authentication — LDAP)
- Database servers (if shared with other applications)
- Email server (SMTP outbound)
- SIEM platform (outbound log shipping — may require custom logging)

**Recommendation:** Due to the elevated risk profile of the ColdFusion platform (CFW-001, CFW-002, CFW-005), this system should be prioritized for technology migration in the next modernization phase. Interim compensating controls (WAF rules, network segmentation, enhanced monitoring) should be implemented.
