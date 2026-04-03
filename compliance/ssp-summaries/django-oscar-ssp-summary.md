# SSP Summary: Django Oscar

**System Identifier:** django-oscar  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

Django Oscar is an open-source e-commerce framework built on Django, providing a domain-driven e-commerce platform with customizable product catalog, checkout workflows, and order management. In the federal context, Django Oscar supports citizen-facing procurement portals and government marketplace applications.

**Tier Classification:** Tier 2 — Enterprise Application (5K–50K LOC)  
**Primary Function:** E-Commerce Platform and Government Marketplace  
**User Base:** External citizens/public users and internal agency staff (catalog managers, order processors)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Moderate | System processes citizen PII and potentially payment information; unauthorized disclosure could cause serious adverse effect |
| **Integrity** | Moderate | Order and transaction integrity is critical; unauthorized modification could result in incorrect fulfillment or financial loss |
| **Availability** | Low | E-commerce portal; temporary outage would inconvenience users but not endanger mission-critical functions |

**Overall System Categorization:** **Moderate** (due to Confidentiality/Integrity high-water mark)

`SC django-oscar = {(confidentiality, moderate), (integrity, moderate), (availability, low)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Runtime | Python 2.7/3.6 | Legacy | EOL |
| Framework | Django | Legacy version | Outdated |
| Module Imports | `imp` module | Deprecated | Removed in 3.12 |
| Database | PostgreSQL | Various | Active |
| Web Server | Gunicorn/uWSGI | Legacy | Active |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Runtime | Python 3.12 | 3.12.x | October 2028 |
| Framework | Django 5.x | Current | Active |
| Module Imports | `importlib` | Standard library | Active |
| Database | PostgreSQL | Current | Active |
| Web Server | Gunicorn | Current | Active |
| Type Safety | Type hints (PEP 484/604) | Native | N/A |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- Python 3.12 resolves known CPython vulnerabilities
- Django 5.x addresses web framework CVEs (CSRF, XSS, SQL injection protections)
- `imp`→`importlib` migration eliminates deprecated module loading path

### 4.2 SI-10 Information Input Validation
- Django form validation framework with updated validators
- Django ORM parameterized queries prevent SQL injection
- CSRF middleware enabled by default in Django 5.x

### 4.3 SC-8 Transmission Confidentiality
- Django `SECURE_SSL_REDIRECT`, `SECURE_HSTS_SECONDS` settings enforced
- Session cookies with `HttpOnly`, `Secure`, `SameSite` attributes

### 4.4 SA-8 Security Engineering Principles
- Type hints enable static analysis of data flows (order processing, payment handling)
- Django's "batteries included" security features (clickjacking protection, content type sniffing prevention)

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| OSC-001 | Architectural debt in checkout workflow | Complex checkout flow may have unvalidated state transitions | Medium | Open | Q3 2026 |
| OSC-002 | Payment processing integration not validated post-migration | Payment gateway communication may be disrupted | High | Open | Q2 2026 |
| OSC-003 | Custom Oscar dashboard views may have XSS vulnerabilities | Admin panel XSS could enable privilege escalation | Medium | Open | Q3 2026 |
| OSC-004 | Type hints incomplete in custom business logic | Static analysis coverage gaps in critical code paths | Low | Open | Q4 2026 |

---

## 6. Recommended Authorization Boundary

The django-oscar authorization boundary should include:

- **Web tier:** Reverse proxy/load balancer, WAF (for public-facing portal)
- **Application tier:** Django application server (Gunicorn), Oscar e-commerce modules
- **Data tier:** PostgreSQL database (product catalog, orders, user accounts)
- **Static/media tier:** Static file serving, user-uploaded content storage
- **Integration tier:** Payment gateway connector, notification service, search backend

**Boundary Exclusions (Inherited Controls):**
- CDN for static assets (if FedRAMP-authorized)
- Underlying IaaS/PaaS infrastructure
- Physical data center controls

**Interconnections Requiring ISA:**
- Payment gateway (PCI DSS scope — outbound)
- Login.gov or agency IdP (citizen authentication)
- Fulfillment/shipping systems (outbound)
- SIEM platform (outbound log shipping)
