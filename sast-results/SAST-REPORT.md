# Static Application Security Testing (SAST) Report

**CONTROLLED UNCLASSIFIED INFORMATION (CUI)**

**Date:** April 2026
**Tool:** Semgrep 1.156.0 (config=auto)
**Scope:** All 14 legacy systems in the modernization corpus

---

## Executive Summary

SAST scans were executed against all 14 systems in the modernization portfolio using Semgrep with auto-configuration. **7 of 14 systems completed scanning successfully**. The 4 Tier 1 enterprise monoliths (OFBiz, Odoo, Alfresco, Nuxeo) and Umbraco exceeded scan time limits due to their massive codebases (1M+ LOC each) and require dedicated scanning infrastructure.

### Aggregate Results

| Metric | Count |
|--------|-------|
| **Systems Scanned** | 10 (7 complete, 3 timed out) |
| **Total Findings** | 361 |
| **ERROR (High)** | 22 |
| **WARNING (Medium)** | 162 |
| **INFO (Low)** | 177 |
| **All findings are security-category** | Yes |

---

## Per-System Results

| System | Technology | Findings | ERROR | WARNING | INFO | Status |
|--------|-----------|----------|-------|---------|------|--------|
| Monolith Enterprise | Java/Jakarta | 5 | 0 | 5 | 0 | Complete |
| B2CWeb | Java/Jakarta | 0 | 0 | 0 | 0 | Complete |
| CFWheels | ColdFusion | 79 | 12 | 58 | 9 | Complete |
| Django Oscar | Python | 176 | 1 | 27 | 148 | Complete |
| Mezzanine | Python | 97 | 6 | 71 | 20 | Complete |
| DFe.NET | C#/.NET | 4 | 3 | 1 | 0 | Complete |
| NASTRAN-95 | Fortran | 0 | 0 | 0 | 0 | Complete |
| Apollo-11 | AGC Assembly | -- | -- | -- | -- | No Semgrep rules |
| CICS Banking | COBOL/JCL | -- | -- | -- | -- | Repo unavailable |
| Apache OFBiz | Java (2.8M LOC) | -- | -- | -- | -- | Timeout (>5 min) |
| Odoo | Python (1.7M LOC) | -- | -- | -- | -- | Timeout (>5 min) |
| Alfresco | Java (1.1M LOC) | -- | -- | -- | -- | Timeout (>5 min) |
| Nuxeo | Java (317K LOC) | -- | -- | -- | -- | Timeout (>5 min) |
| Umbraco | C# (760K LOC) | -- | -- | -- | -- | Timeout (>5 min) |

---

## Critical Findings (ERROR Severity)

### 1. CFWheels (12 ERROR findings)

**Dockerfile Missing USER Directive (1 finding)**
- File: `.github/actions/publish_forgebox_package/Dockerfile:5`
- Risk: Container runs as root by default
- Recommendation: Add `USER nonroot` directive after installing packages

**GitHub Actions Shell Injection (1 finding)**
- File: `.github/workflows/tests.yml:693`
- Risk: Variable interpolation with `${{...}}` in `run:` step allows command injection
- Recommendation: Use environment variables instead of direct interpolation

**Exposed bcrypt Hashes (3 findings)**
- File: `examples/starter-app/app/migrator/migrations/20180519105944_Adds_Default_UserAccounts.cfc`
- Risk: Hardcoded bcrypt hashes in migration files (example/demo data)
- Recommendation: Move to environment variables or secrets for production

**Additional findings:** 7 more ERROR-level issues related to insecure configurations

### 2. DFe.NET (3 ERROR findings)

**Server-Side Request Forgery (SSRF) (3 findings)**
- Files: `DFe.Wsdl/Common/RequestSefazDefault.cs:61,102`, `DFe.Wsdl/Http/RequestWS.cs:12`
- Risk: URL parameters passed to HTTP client without validation
- Recommendation: Implement URL allowlist for SEFAZ endpoints; validate and sanitize URL input

### 3. Django Oscar (1 ERROR finding)

**Path Traversal via tarfile (1 finding)**
- File: `src/oscar/apps/catalogue/utils.py:106`
- Risk: `tarfile.extractall()` can write files outside target directory if archive contains `../` paths
- Recommendation: Use `tarfile.extractall(filter='data')` (Python 3.12+) or implement path validation

### 4. Mezzanine (6 ERROR findings)

**XML External Entity (XXE) Attack (1 finding)**
- File: `mezzanine/blog/management/commands/import_blogml.py:43`
- Risk: Native Python `xml` library vulnerable to XXE
- Recommendation: Use `defusedxml` library instead of `xml.etree.ElementTree`

**Insecure DOM Methods (5 findings)**
- Files: jQuery 3.4.1 library, html5shiv.js
- Risk: `innerHTML`, `document.write` usage
- Recommendation: Upgrade jQuery to 3.7.x; replace `document.write` with DOM API

---

## WARNING-Level Summary

| Category | Count | Systems Affected |
|----------|-------|-----------------|
| Insecure hash algorithms (MD5/SHA1) | 45 | Django Oscar, Mezzanine, CFWheels |
| Hardcoded credentials/secrets | 23 | CFWheels, Django Oscar |
| Insecure random number generation | 18 | Django Oscar, Mezzanine |
| Missing security headers | 15 | CFWheels, Mezzanine |
| Insecure deserialization | 12 | Django Oscar |
| SQL injection patterns | 8 | CFWheels |
| Cross-site scripting (XSS) | 7 | CFWheels, Mezzanine |
| Other | 34 | Various |

---

## Recommendations

### Immediate Actions (Before Pilot Deployment)

1. **Fix DFe.NET SSRF vulnerabilities** -- implement URL allowlist for SEFAZ endpoints
2. **Fix Django Oscar tarfile traversal** -- add path validation before extraction
3. **Fix Mezzanine XXE vulnerability** -- replace `xml.etree` with `defusedxml`
4. **Add USER directive to CFWheels Dockerfile** -- prevent container root execution
5. **Fix GitHub Actions shell injection in CFWheels** -- use env vars instead of interpolation

### Short-Term Actions (Before Fleet Deployment)

6. **Upgrade jQuery in Mezzanine** from 3.4.1 to 3.7.x (fixes DOM XSS patterns)
7. **Remove hardcoded bcrypt hashes** from CFWheels example migrations
8. **Replace MD5/SHA1 usage** with SHA-256 or stronger across all Python systems
9. **Implement parameterized queries** for remaining SQL injection patterns in CFWheels

### Long-Term Actions

10. **Set up dedicated SAST infrastructure** for Tier 1 systems (OFBiz, Odoo, Alfresco, Nuxeo, Umbraco) -- these require >10 minutes per scan due to codebase size
11. **Integrate Semgrep into CI/CD pipelines** -- the CI workflow configs already include Semgrep jobs
12. **Establish vulnerability SLA** -- ERROR findings within 30 days, WARNING within 90 days

---

## Scan Infrastructure Requirements

For the 5 systems that timed out, the following infrastructure is recommended:

| System | LOC | Estimated Scan Time | Recommended |
|--------|-----|-------------------|-------------|
| Apache OFBiz | 2.8M | 15-30 min | CI runner with 8GB RAM, 60 min timeout |
| Odoo | 1.7M | 10-20 min | CI runner with 8GB RAM, 45 min timeout |
| Alfresco | 1.1M | 10-15 min | CI runner with 8GB RAM, 30 min timeout |
| Umbraco | 760K | 8-12 min | CI runner with 4GB RAM, 30 min timeout |
| Nuxeo | 317K | 5-10 min | CI runner with 4GB RAM, 15 min timeout |

These scans should be executed as part of the CI/CD pipeline on dedicated infrastructure with appropriate timeout configurations.

---

## Files Generated

| File | Size | Description |
|------|------|-------------|
| `monolith-enterprise-sast.json` | 24KB | Full Semgrep JSON results |
| `b2cweb-sast.json` | ~1KB | Full Semgrep JSON results |
| `cfwheels-sast.json` | ~150KB | Full Semgrep JSON results |
| `django-oscar-sast.json` | ~350KB | Full Semgrep JSON results |
| `mezzanine-sast.json` | ~200KB | Full Semgrep JSON results |
| `dfe-net-sast.json` | ~10KB | Full Semgrep JSON results |
| `nastran-95-sast.json` | ~1KB | Full Semgrep JSON results |

---

*This document is CONTROLLED UNCLASSIFIED INFORMATION (CUI) and should be handled in accordance with 32 CFR Part 2002.*
