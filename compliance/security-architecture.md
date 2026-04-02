# Security Architecture Document — Legacy Modernization Portfolio

**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only  
**Prepared For:** Federal Legacy Modernization Program Office  
**Applicable Frameworks:** NIST SP 800-207 (Zero Trust), NIST SP 800-53 Rev 5, CISA Zero Trust Maturity Model

---

## 1. Purpose

This document defines the target security architecture for the modernized legacy system portfolio. It establishes architectural principles, security patterns, and integration requirements that all modernized systems must adopt. The architecture aligns with federal Zero Trust mandates (EO 14028, OMB M-22-09) and NIST guidance.

---

## 2. Zero Trust Architecture Principles

### 2.1 Alignment with NIST SP 800-207

The modernized portfolio adopts a Zero Trust Architecture (ZTA) model per NIST SP 800-207 and the CISA Zero Trust Maturity Model. The core tenets applied to the modernization are:

| ZTA Principle | Application to Modernized Systems |
|--------------|----------------------------------|
| **Never trust, always verify** | All service-to-service communication requires authentication; no implicit trust based on network location |
| **Assume breach** | Each system designed to contain compromise; blast radius minimization through segmentation |
| **Verify explicitly** | Every request authenticated and authorized based on all available data points (user identity, device health, location, data classification) |
| **Least privilege access** | Minimum necessary permissions granted; Java JPMS, .NET assembly trimming, and Python module isolation enforce boundaries |
| **Micro-segmentation** | Each system operates in its own network segment; lateral movement requires explicit authorization |

### 2.2 Zero Trust Maturity Targets (per CISA Model)

| Pillar | Current State | Target State | Key Actions |
|--------|--------------|-------------|-------------|
| **Identity** | Traditional (passwords, basic LDAP) | Advanced (MFA, PIV/CAC, conditional access) | Integrate all systems with agency IdP; enforce MFA for all users |
| **Devices** | Traditional (perimeter-based trust) | Advanced (device health attestation) | Implement endpoint compliance checks before granting access |
| **Networks** | Traditional (flat network, perimeter firewall) | Advanced (micro-segmented, encrypted) | Segment each system; encrypt all east-west traffic |
| **Applications** | Traditional (monolithic, implicit trust) | Advanced (API-based, explicit auth) | Modernize to authenticated API-first architecture; WAF on all endpoints |
| **Data** | Traditional (perimeter-protected) | Advanced (data-centric protection) | Classify data per FIPS 199; encrypt at rest and in transit; DLP integration |

### 2.3 System-Specific ZTA Implementation

| System Category | ZTA Approach |
|----------------|-------------|
| **Java systems (5)** | Jakarta Security API for declarative auth; JWT/OIDC token-based service communication; Java 17 module boundaries for internal isolation |
| **Python systems (3)** | Django middleware for request-level auth; OAuth2/OIDC integration; type-safe authorization decorators |
| **C# systems (2)** | ASP.NET Core policy-based authorization; nullable ref types prevent auth bypass; .NET 8 minimal APIs reduce attack surface |
| **ColdFusion (1)** | Application-level auth filters (compensating control); WAF for request validation; network segmentation to isolate legacy platform |
| **Fortran (1)** | OS-level access control (file permissions, user isolation); no network services exposed; sandboxed execution environment |
| **Assembly (1)** | Read-only archive; Git-based integrity verification; no runtime component |
| **COBOL (1)** | RACF/ACF2 for mainframe access control; TN3270 gateway with MFA; network segmentation from distributed systems |

---

## 3. Network Segmentation Strategy

### 3.1 Network Zones

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                    ┌──────┴──────┐
                    │   CDN/WAF   │  DDoS protection, TLS termination
                    │  (Zone 0)   │  FedRAMP-authorized provider
                    └──────┬──────┘
                           │
┌──────────────────────────┴──────────────────────────────────────┐
│                    DMZ (Zone 1)                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ Load        │  │ Reverse     │  │ API Gateway             │ │
│  │ Balancers   │  │ Proxies     │  │ (AuthN/AuthZ, Rate      │ │
│  │             │  │             │  │  Limiting, Logging)      │ │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘ │
└─────────┼────────────────┼──────────────────────┼───────────────┘
          │                │                      │
┌─────────┼────────────────┼──────────────────────┼───────────────┐
│         │     APPLICATION ZONE (Zone 2)         │               │
│  ┌──────┴──────────────────────┐  ┌─────────────┴─────────────┐ │
│  │ Web Application Tier        │  │ Service/API Tier           │ │
│  │                             │  │                            │ │
│  │ • b2cweb (Java/Tomcat)     │  │ • apache-ofbiz (Jakarta)  │ │
│  │ • django-oscar (Gunicorn)  │  │ • alfresco (Spring/Jakarta)│ │
│  │ • mezzanine (Gunicorn)     │  │ • nuxeo (Jakarta)         │ │
│  │ • umbraco-cms (Kestrel)    │  │ • odoo (Werkzeug)         │ │
│  │ • dfe-net (Kestrel)        │  │ • monolith-ent (Jakarta)  │ │
│  │ • cfwheels (ColdFusion)    │  │                            │ │
│  └──────┬──────────────────────┘  └─────────────┬─────────────┘ │
└─────────┼───────────────────────────────────────┼───────────────┘
          │                                       │
┌─────────┼───────────────────────────────────────┼───────────────┐
│         │         DATA ZONE (Zone 3)            │               │
│  ┌──────┴──────────────────────┐  ┌─────────────┴─────────────┐ │
│  │ Relational Databases        │  │ Search / Document Stores   │ │
│  │ • PostgreSQL (Java/Python) │  │ • Elasticsearch (Nuxeo)   │ │
│  │ • SQL Server (C#)          │  │ • Solr (Alfresco)         │ │
│  │ • MySQL (ColdFusion)       │  │ • MongoDB (Nuxeo)         │ │
│  └─────────────────────────────┘  └───────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  LEGACY ZONE (Zone 4)                             │
│  ┌───────────────────────┐  ┌─────────────────────────────────┐ │
│  │ Mainframe Segment      │  │ HPC/Scientific Segment          │ │
│  │ • cics-banking (COBOL)│  │ • nastran-95 (Fortran)          │ │
│  │ • DB2, VSAM            │  │ • Batch job scheduler           │ │
│  │ • RACF security        │  │ • File-based I/O               │ │
│  └───────────────────────┘  └─────────────────────────────────┘ │
│  ┌───────────────────────┐                                       │
│  │ Archive Segment        │                                      │
│  │ • apollo-11 (Assembly)│                                       │
│  │ • Read-only Git repo  │                                       │
│  └───────────────────────┘                                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                  MANAGEMENT ZONE (Zone 5)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ CI/CD        │  │ Logging &    │  │ Identity Provider      │ │
│  │ Pipeline     │  │ SIEM         │  │ (SAML/OIDC)            │ │
│  │ (Jenkins/GH) │  │ (Splunk/ELK) │  │ PIV/CAC Auth           │ │
│  └──────────────┘  └──────────────┘  └────────────────────────┘ │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐ │
│  │ Vulnerability│  │ Config Mgmt  │  │ Secret Management      │ │
│  │ Scanner      │  │ (Ansible/    │  │ (Vault/KMS)            │ │
│  │ (Tenable)    │  │  Terraform)  │  │                        │ │
│  └──────────────┘  └──────────────┘  └────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Segmentation Rules

| Source Zone | Destination Zone | Allowed Traffic | Authentication Required |
|------------|-----------------|----------------|------------------------|
| Internet → Zone 0 | CDN/WAF | HTTPS (443) | N/A (public) |
| Zone 0 → Zone 1 | DMZ | HTTPS (443) | TLS mutual auth (optional) |
| Zone 1 → Zone 2 | Application | HTTPS (8443) | JWT/OIDC token |
| Zone 2 → Zone 3 | Data | DB protocols (TLS) | Service account + TLS |
| Zone 2 → Zone 4 | Legacy | Custom protocols (TLS) | System credentials + MFA |
| Zone 5 → All Zones | Management | SSH (22), HTTPS (443) | PIV/CAC + MFA |
| All Zones → Zone 5 | Management | Syslog/HTTPS (outbound) | mTLS or API key |
| Zone 2 ↔ Zone 2 | Application (east-west) | HTTPS | JWT/OIDC — **no implicit trust** |

### 3.3 Micro-Segmentation per System

Each of the 13 active systems operates in its own network segment (VLAN, security group, or namespace):

- **Inbound:** Only accepts traffic from the API gateway or authorized upstream systems
- **Outbound:** Only permitted to reach its own data store, logging infrastructure, and authorized downstream systems
- **East-west:** No direct communication between application segments without API gateway mediation

---

## 4. Data Protection Architecture

### 4.1 Data-at-Rest Encryption

| System Category | Encryption Method | Key Management | FIPS 140-2 Compliant |
|----------------|------------------|---------------|---------------------|
| **Java (5)** | AES-256-GCM via JCE | Java KeyStore (PKCS#12) or HSM-backed | Yes — JCE with FIPS provider |
| **Python (3)** | AES-256-GCM via `cryptography` library | Hashicorp Vault or AWS KMS | Yes — OpenSSL FIPS module |
| **C# (2)** | AES-256-GCM via System.Security.Cryptography | DPAPI, Azure Key Vault, or HSM | Yes — CNG/BCrypt FIPS provider |
| **ColdFusion (1)** | Database-level TDE; application-level via Java JCE | Java KeyStore | Partial — requires JVM FIPS configuration |
| **Fortran (1)** | Filesystem-level encryption (LUKS/dm-crypt) | OS key management | Yes — dm-crypt with FIPS kernel module |
| **Assembly (1)** | Repository-level (Git encrypted backups) | Backup encryption key | Yes — OS-level encryption |
| **COBOL (1)** | z/OS dataset encryption, DB2 native encryption | ICSF (Integrated Cryptographic Service Facility) | Yes — IBM CPACF |

### 4.2 Data-in-Transit Encryption

| Communication Path | Protocol | Minimum Version | Cipher Suites |
|-------------------|----------|----------------|---------------|
| Client → Load Balancer | TLS | 1.2 (prefer 1.3) | TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256 |
| Load Balancer → Application | TLS | 1.2 | ECDHE-RSA-AES256-GCM-SHA384 |
| Application → Database | TLS | 1.2 | Per database vendor recommendation |
| Application → Application (east-west) | mTLS | 1.2 (prefer 1.3) | TLS_AES_256_GCM_SHA384 |
| Application → SIEM (log shipping) | TLS | 1.2 | Syslog-over-TLS (RFC 5425) |
| Management → Systems (SSH) | SSH | OpenSSH 8.x+ | chacha20-poly1305, aes256-gcm |
| Mainframe (TN3270) | TLS | 1.2 | AT-TLS (Application Transparent TLS) |

### 4.3 Data Classification and Handling

| Classification Level | Examples | Storage Requirements | Transmission Requirements | Access Requirements |
|--------------------|---------|---------------------|--------------------------|-------------------|
| **Public** | Published web content (Mezzanine) | Standard encryption | HTTPS | Read: public; Write: authenticated |
| **CUI** | Internal documents, case files | Encrypted at rest; access-controlled | TLS 1.2+ | Role-based; MFA for modification |
| **PII** | Citizen data (B2CWeb, DfE, Oscar) | Encrypted at rest; data masking in non-prod | TLS 1.2+; no PII in URLs/logs | Least privilege; audit logged |
| **Financial** | Transactions (OFBiz, CICS, Odoo) | Encrypted at rest; tamper-evident logging | TLS 1.2+; message integrity | Segregation of duties; dual approval |
| **ITAR/Export-Controlled** | Structural analysis data (NASTRAN-95) | Encrypted at rest; access-controlled storage | Encrypted; no cloud transit without authorization | Need-to-know; citizenship verification |

---

## 5. Identity and Access Management Architecture

### 5.1 Identity Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    IDENTITY TIER                             │
│                                                              │
│  ┌───────────────────┐    ┌─────────────────────────────┐   │
│  │ Agency IdP         │    │ PIV/CAC Infrastructure       │  │
│  │ (SAML 2.0/OIDC)   │◄──│ OCSP Responder               │  │
│  │                    │    │ Certificate Authority         │  │
│  └────────┬──────────┘    └─────────────────────────────┘   │
│           │                                                   │
│  ┌────────┴──────────┐    ┌─────────────────────────────┐   │
│  │ MFA Service        │    │ Privileged Access Mgmt (PAM)│   │
│  │ (PIV + OTP/Push)  │    │ Session recording            │   │
│  │                    │    │ Just-in-time access           │   │
│  └───────────────────┘    └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION TIER                           │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ API Gateway / Service Mesh                            │   │
│  │ • Token validation (JWT verification)                 │   │
│  │ • Policy enforcement point (PEP)                      │   │
│  │ • Rate limiting, request logging                      │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                     │
│  ┌──────────┐ ┌────────┴───┐ ┌───────────┐ ┌────────────┐  │
│  │ Java     │ │ Python     │ │ C#        │ │ ColdFusion │  │
│  │ Apps     │ │ Apps       │ │ Apps      │ │ Apps       │  │
│  │          │ │            │ │           │ │            │  │
│  │ Jakarta  │ │ Django     │ │ ASP.NET   │ │ App-level  │  │
│  │ Security │ │ Auth       │ │ Core      │ │ Auth       │  │
│  │ API      │ │ Middleware │ │ Identity  │ │ Filters    │  │
│  └──────────┘ └────────────┘ └───────────┘ └────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Authentication Requirements

| User Type | Primary Authentication | Secondary Factor | Session Duration | Re-authentication |
|-----------|----------------------|-----------------|-----------------|-------------------|
| Internal Staff | PIV/CAC Smart Card | PIN (inherent to PIV) | 8 hours max | On privilege escalation |
| System Administrator | PIV/CAC Smart Card | PIV PIN + OTP | 4 hours max | Every privileged action |
| External Citizen | Login.gov / Agency Portal | MFA (SMS/TOTP/Push) | 30 minutes idle timeout | On sensitive transactions |
| Service Account | X.509 Client Certificate | N/A (non-interactive) | Per-request | Per-request |
| Mainframe User | RACF credentials | PIV via TN3270 gateway | Per-session | On session start |

### 5.3 Authorization Model

| Layer | Method | Implementation |
|-------|--------|---------------|
| **API Gateway** | Token-based policy enforcement | JWT claims validation; deny-by-default |
| **Application** | Role-Based Access Control (RBAC) | Jakarta `@RolesAllowed`, Django `@permission_required`, ASP.NET `[Authorize(Policy)]` |
| **Data** | Row-Level Security (where supported) | PostgreSQL RLS policies; SQL Server row filters |
| **Network** | Network policy enforcement | Security groups, firewall rules per micro-segment |
| **Mainframe** | RACF profiles | Resource-level access rules; transaction-level security |

### 5.4 Privileged Access Management

- **Just-in-time (JIT) access:** Administrative privileges granted only for defined time windows
- **Session recording:** All privileged sessions recorded for audit
- **Break-glass procedures:** Emergency access with dual-approval and post-incident review
- **Service account rotation:** Automated credential rotation every 90 days (or less)

---

## 6. Logging and Monitoring Architecture

### 6.1 Logging Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION SOURCES                        │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │ Java     │ │ Python   │ │ C#       │ │ Other    │      │
│  │ SLF4J/  │ │ logging  │ │ Serilog/ │ │ Custom   │      │
│  │ Logback  │ │ module   │ │ NLog     │ │ logging  │      │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘      │
│       │            │            │            │              │
│       └────────────┼────────────┼────────────┘              │
│                    │            │                             │
│            ┌───────┴────────────┴───────┐                    │
│            │   Structured JSON Output    │                   │
│            │   (Common Log Schema)       │                   │
│            └─────────────┬──────────────┘                    │
└──────────────────────────┼──────────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────┐
│                    LOG COLLECTION TIER                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Log Forwarders (Fluentd / Filebeat / OTEL Collector)  │  │
│  │ • Structured JSON parsing                              │  │
│  │ • PII redaction (regex-based scrubbing)                │  │
│  │ • Log enrichment (system name, environment, host)      │  │
│  │ • TLS transport to SIEM                                │  │
│  └──────────────────────────┬───────────────────────────┘   │
└─────────────────────────────┼───────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────┐
│                    SIEM / ANALYTICS TIER                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ SIEM         │  │ SOAR         │  │ Dashboards       │  │
│  │ (Splunk /    │  │ (Automated   │  │ (Grafana /       │  │
│  │  ELK GovCld) │  │  Response)   │  │  Kibana)         │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Common Log Schema

All modernized systems must emit logs in the following structured JSON format:

```json
{
  "timestamp": "2026-04-02T18:45:00.000Z",
  "level": "INFO|WARN|ERROR|AUDIT",
  "system": "apache-ofbiz",
  "service": "order-service",
  "correlationId": "uuid-v4",
  "userId": "user@agency.gov",
  "sessionId": "session-hash",
  "sourceIp": "10.0.1.42",
  "action": "ORDER_CREATED",
  "resource": "/api/orders",
  "method": "POST",
  "statusCode": 201,
  "duration_ms": 245,
  "message": "Order created successfully",
  "metadata": {}
}
```

### 6.3 Audit Events (Mandatory Logging)

All systems must log the following events per AU-2:

| Event Category | Events | Retention |
|---------------|--------|-----------|
| **Authentication** | Login success/failure, logout, MFA challenge, account lockout | 1 year (online), 3 years (archive) |
| **Authorization** | Access granted/denied, privilege escalation, role changes | 1 year (online), 3 years (archive) |
| **Data Access** | Read/write/delete of sensitive data, bulk data export, query of PII | 1 year (online), 6 years (archive) |
| **Configuration** | System config changes, user account CRUD, permission changes | 1 year (online), 6 years (archive) |
| **Security** | Vulnerability scan results, WAF blocks, anomaly detection alerts | 1 year (online), 3 years (archive) |
| **System** | Start/stop, error/exception, health check failures, deployment events | 90 days (online), 1 year (archive) |

### 6.4 Monitoring Stack

| Layer | Tool/Service | Purpose | Alert Threshold |
|-------|-------------|---------|----------------|
| **APM** | OpenTelemetry + Jaeger/Zipkin | Distributed tracing, latency monitoring | P99 latency > 2s |
| **Infrastructure** | Prometheus + Node Exporter | CPU, memory, disk, network metrics | CPU > 80%, Memory > 85% |
| **Application** | Custom metrics (Micrometer/StatsD) | Business metrics, error rates | Error rate > 1% |
| **Security** | SIEM correlation rules | Brute force, anomalous access, data exfiltration | Per correlation rule |
| **Availability** | Synthetic monitoring (Pingdom/UptimeRobot) | Endpoint availability, response time | Downtime > 1 min |
| **Compliance** | SCAP/OpenSCAP | Configuration baseline compliance | Any deviation |

---

## 7. Incident Response Integration Points

### 7.1 Detection and Alerting

| Detection Source | Alert Channel | Response Team | SLA |
|-----------------|--------------|---------------|-----|
| SIEM correlation rule | PagerDuty / OpsGenie | SOC Tier 1 | 15 min acknowledgment |
| WAF block (high volume) | SIEM + Email | SOC Tier 1 | 30 min acknowledgment |
| Vulnerability scan (Critical) | Jira/ServiceNow ticket | DevSecOps | 48 hour remediation |
| Failed authentication (threshold) | SIEM alert | SOC Tier 1 | 15 min acknowledgment |
| Configuration drift | SCAP dashboard | System Admin | 24 hour remediation |
| Dependency CVE (Critical) | Dependabot/Snyk alert | Development Team | 48 hour remediation |

### 7.2 Incident Response Playbook Integration

| System Category | Playbook | Key Actions |
|----------------|----------|-------------|
| **Java Web Applications** | Web Application Compromise | 1. Isolate affected container/pod 2. Capture memory dump 3. Review access logs 4. Check for lateral movement 5. Rotate credentials |
| **Python Web Applications** | Web Application Compromise | Same as Java + check Django debug mode, review pip packages |
| **C# Web Applications** | Web Application Compromise | Same as Java + check Kestrel configuration, review NuGet packages |
| **ColdFusion Applications** | Legacy Web Application Compromise | 1. Isolate server 2. Check for webshell uploads 3. Review ColdFusion admin access 4. Scan for known CF exploits |
| **Fortran Batch Systems** | Scientific Computing Incident | 1. Halt batch jobs 2. Verify input file integrity 3. Check for unauthorized access 4. Compare results to baseline |
| **Mainframe (COBOL)** | Mainframe Security Incident | 1. Review SMF records 2. Check RACF violations 3. Isolate affected CICS region 4. IBM support engagement |
| **Supply Chain** | Dependency Compromise | 1. Identify affected systems via SBOM 2. Pin to last known-good version 3. Scan for indicators of compromise 4. Rotate any exposed credentials |

### 7.3 Forensic Readiness

| Requirement | Implementation |
|------------|---------------|
| Log preservation | Immutable log storage (WORM); no log deletion without approval |
| Memory capture | Container/VM snapshot capability within 15 minutes of incident |
| Network capture | Packet capture capability at zone boundaries |
| Chain of custody | Documented evidence handling procedures per agency forensics SOP |
| Timeline reconstruction | Correlated timestamps across all systems (NTP synced, UTC) |

---

## 8. Continuous Integration / Continuous Deployment (CI/CD) Security

### 8.1 Secure Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD SECURITY GATES                       │
│                                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ 1. Commit │ │ 2. Build  │ │ 3. Test   │ │ 4. Security  │ │
│  │          │ │          │ │          │ │    Scan       │  │
│  │ • Signed │ │ • SBOM   │ │ • Unit   │ │ • SAST       │  │
│  │   commits│ │   gen    │ │   tests  │ │ • DAST       │  │
│  │ • Pre-   │ │ • Dep    │ │ • Integ  │ │ • Container  │  │
│  │   commit │ │   audit  │ │   tests  │ │   scan       │  │
│  │   hooks  │ │ • License│ │ • Sec    │ │ • License    │  │
│  │          │ │   check  │ │   tests  │ │   compliance │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘  │
│       │            │            │               │           │
│       ▼            ▼            ▼               ▼           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │ 5. Artif │ │ 6. Stage │ │ 7. Apprvl│ │ 8. Deploy    │  │
│  │    act   │ │    Deploy│ │          │ │              │  │
│  │ • Sign   │ │ • Staging│ │ • Manual │ │ • Blue/green │  │
│  │   image  │ │   env    │ │   gate   │ │ • Canary     │  │
│  │ • Push   │ │ • Smoke  │ │ • Change │ │ • Rollback   │  │
│  │   to reg │ │   tests  │ │   board  │ │   ready      │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Security Gate Criteria

| Gate | Pass Criteria | Failure Action |
|------|--------------|---------------|
| **Commit** | Signed with verified GPG key; no secrets detected (git-secrets) | Block push |
| **Build** | Clean build; SBOM generated; no critical license violations | Block pipeline |
| **Test** | All unit/integration tests pass; code coverage > threshold | Block pipeline |
| **SAST** | No critical/high findings; medium findings reviewed | Block deploy; create POA&M for medium |
| **DAST** | No critical/high findings in staging scan | Block production deploy |
| **Container Scan** | No critical CVEs in base image or dependencies | Block deploy; rebuild with patched base |
| **Approval** | Change board approval for production deployment | Block deploy until approved |
| **Deploy** | Health checks pass; canary metrics within threshold | Auto-rollback on failure |

---

## 9. References

| Document | Relevance |
|----------|-----------|
| NIST SP 800-207 | Zero Trust Architecture |
| NIST SP 800-53 Rev 5 | Security and Privacy Controls |
| NIST SP 800-137 | Continuous Monitoring |
| NIST SP 800-190 | Container Security |
| CISA Zero Trust Maturity Model v2 | Federal ZTA implementation guidance |
| EO 14028 | Improving the Nation's Cybersecurity |
| OMB M-22-09 | Federal Zero Trust Strategy |
| FIPS 140-2/140-3 | Cryptographic Module Validation |
| FedRAMP Authorization Boundary Guidance | Cloud system boundaries |
| CISA BOD 22-01 | Known Exploited Vulnerabilities |
| CISA BOD 23-01 | Asset Visibility and Vulnerability Detection |

---

## 10. Document Approval

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Enterprise Architect | _________________ | _________________ | ________ |
| CISO / ISSO | _________________ | _________________ | ________ |
| System Owner | _________________ | _________________ | ________ |
| Authorizing Official | _________________ | _________________ | ________ |
