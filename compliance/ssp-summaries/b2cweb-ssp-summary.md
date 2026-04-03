# SSP Summary: B2CWeb

**System Identifier:** b2cweb  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

B2CWeb is a Java-based business-to-consumer web application providing tightly coupled e-commerce and citizen-facing service delivery capabilities. In the federal context, B2CWeb supports citizen-facing portals for service requests, applications, and information dissemination.

**Tier Classification:** Tier 2 — Enterprise Application  
**Primary Function:** Citizen-Facing Web Portal and Service Delivery  
**User Base:** External citizens/public users and internal agency staff (content administrators)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System processes citizen PII (names, addresses, SSNs for service applications); unauthorized disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Service request integrity is critical; unauthorized modification could result in incorrect service delivery |
| **Availability** | Moderate | Public-facing portal; extended outage would prevent citizens from accessing government services |

**Overall System Categorization:** **Moderate**

`SC b2cweb = {(confidentiality, moderate), (integrity, moderate), (availability, moderate)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | Java 8 | 1.8.x | EOL |
| Framework | javax.servlet, JSP/JSF | javax.* namespace | Deprecated |
| Web Server | Apache Tomcat | 8.x/9.x | Legacy |
| Database | MySQL/PostgreSQL | Various | Active |
| Frontend | Server-rendered JSP | Legacy | Tightly coupled |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | Java 17 LTS | 17.x | September 2029 |
| Framework | Jakarta EE (jakarta.* namespace) | Jakarta EE 10 | Active |
| Web Server | Apache Tomcat 10.1+ | 10.1.x | Active |
| Database | PostgreSQL | Current | Active |
| Frontend | Updated server-rendered pages | Current | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- javax→jakarta migration eliminates deprecated Java EE library CVEs
- Java 17 addresses JDK-level security vulnerabilities
- Tomcat 10.1 fixes known Tomcat 8/9 vulnerabilities (CVE-2020-1938 AJP Ghostcat, etc.)

### 4.2 SI-10 Information Input Validation
- Jakarta Bean Validation for server-side input validation of citizen-submitted data
- CSRF protection via Jakarta Servlet session tokens
- XSS prevention via updated template engine output encoding

### 4.3 SC-8 Transmission Confidentiality
- TLS 1.3 support for citizen-facing HTTPS connections
- HSTS headers enforced
- Secure cookie attributes (HttpOnly, Secure, SameSite)

### 4.4 AC-14 Permitted Actions Without Authentication
- Default-deny posture: all endpoints require authentication unless explicitly public
- Public-facing pages explicitly declared; all others default to authenticated access

### 4.5 IA-2 Identification and Authentication
- Jakarta Security enables modern authentication mechanisms (OIDC, SAML) for Login.gov integration
- MFA support for internal administrative access

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| B2C-001 | Tight coupling between presentation and business logic | Difficult to isolate and contain security vulnerabilities; single point of failure | High | Open | Q4 2026 |
| B2C-002 | Server-rendered pages may have residual XSS vulnerabilities | Citizen-facing XSS could enable session hijacking or phishing | High | Open | Q2 2026 |
| B2C-003 | PII data handling not fully validated post-migration | Citizen PII may be exposed in logs or error messages | High | Open | Q2 2026 |
| B2C-004 | Session management migration from javax.servlet to jakarta.servlet | Session fixation or session handling bugs possible during transition | Medium | Open | Q2 2026 |
| B2C-005 | Legacy JSP includes may bypass new security filters | Unvalidated includes could serve unfiltered content | Medium | Open | Q3 2026 |

---

## 6. Recommended Authorization Boundary

The b2cweb authorization boundary should include:

- **Web tier:** Public-facing load balancer with WAF, Tomcat application server
- **Application tier:** B2CWeb application logic, service layer, data access layer
- **Data tier:** PostgreSQL database storing citizen data and service requests
- **Session tier:** Session storage (in-memory or external store)
- **Integration tier:** Backend service APIs, payment gateways (if applicable)

**Boundary Exclusions (Inherited Controls):**
- CDN/DDoS protection (if using FedRAMP-authorized provider)
- Underlying IaaS/PaaS infrastructure
- Physical data center controls

**Interconnections Requiring ISA:**
- Login.gov (citizen authentication — SAML/OIDC)
- Agency backend systems (service fulfillment — REST API)
- Email notification service (SMTP outbound)
- SIEM platform (outbound log shipping)
- Payment processor (if applicable — PCI DSS scope)
