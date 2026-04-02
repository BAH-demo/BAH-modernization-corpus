# SSP Summary: CICS Banking Sample

**System Identifier:** cics-banking-sample  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

The CICS Banking Sample is a COBOL-based mainframe banking application running on IBM CICS (Customer Information Control System). The application provides transaction processing for banking operations including account management, fund transfers, and balance inquiries. In the federal context, COBOL/CICS systems support legacy financial transaction processing within Treasury, payment processing, and benefits disbursement systems.

**Tier Classification:** Tier 3 — Federal/Legacy System (30K+ LOC, COBOL)  
**Primary Function:** Mainframe Transaction Processing (Banking/Financial)  
**User Base:** Internal agency staff (financial analysts, payment processors, system operators)

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | High | System processes financial records and potentially PII (account numbers, balances, transaction history); unauthorized disclosure could cause severe adverse effect |
| **Integrity** | High | Financial transaction integrity is critical; unauthorized modification could result in incorrect payments, fraud, or financial misstatement |
| **Availability** | High | Real-time transaction processing; extended outage would prevent financial operations critical to agency mission |

**Overall System Categorization:** **High**

`SC cics-banking-sample = {(confidentiality, high), (integrity, high), (availability, high)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Language | COBOL | COBOL 85 | Legacy (active vendor support from IBM) |
| Platform | IBM CICS | Transaction server | Active |
| Database | IBM DB2 / VSAM | Mainframe | Active |
| Runtime | IBM z/OS | Mainframe OS | Active (vendor supported) |

### Post-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Language | COBOL | Unchanged | **SKIPPED** |
| Platform | IBM CICS | Unchanged | **SKIPPED** |
| Database | IBM DB2 / VSAM | Unchanged | **SKIPPED** |
| Runtime | IBM z/OS | Unchanged | **SKIPPED** |

**Modernization Status:** ⚠️ **SKIPPED** — Repository returned HTTP 403 (Forbidden). No modernization activities were performed. System remains in pre-modernization state.

---

## 4. Security Controls Implemented During Modernization

**None — System was skipped due to repository access failure (HTTP 403).**

All security controls remain in their pre-modernization state. The following controls were planned but not implemented:

| Planned Control | Description | Status |
|----------------|-------------|--------|
| SI-2 Flaw Remediation | COBOL code review and vulnerability assessment | Not Started |
| CM-2 Baseline Configuration | Dependency inventory and SBOM | Not Started |
| SA-11 Developer Testing | Security regression testing | Not Started |
| RA-5 Vulnerability Scanning | COBOL-specific vulnerability analysis | Not Started |

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| CICS-001 | **System not modernized — repository inaccessible (403)** | All pre-existing vulnerabilities remain unaddressed; system is in unknown security state | **High** | Open | Q2 2026 |
| CICS-002 | COBOL/CICS talent shortage | Shrinking pool of qualified COBOL developers increases maintenance risk and key-person dependency | High | Open | Ongoing |
| CICS-003 | Mainframe security tooling not integrated with modern DevSecOps | Vulnerability scanning and SAST tools have limited COBOL/CICS support | Medium | Open | Q3 2026 |
| CICS-004 | COBOL programs may lack input validation | CICS BMS maps may accept unvalidated input; SQL injection via embedded SQL | High | Open | Q2 2026 |
| CICS-005 | RACF/ACF2 security configuration not audited | Mainframe access control configuration may have drift from baseline | Medium | Open | Q3 2026 |
| CICS-006 | Repository access must be restored to perform modernization | Cannot assess or remediate without source code access | **High** | Open | Q2 2026 |

---

## 6. Recommended Authorization Boundary

The cics-banking-sample authorization boundary should include:

- **Transaction tier:** CICS transaction server, COBOL application programs
- **Data tier:** DB2 database, VSAM datasets
- **Mainframe tier:** z/OS operating system, JES job entry subsystem
- **Security tier:** RACF/ACF2/Top Secret security manager
- **Network tier:** SNA/IP network connectivity, TN3270 terminal access

**Boundary Exclusions (Inherited Controls):**
- Physical mainframe data center controls
- Mainframe hardware maintenance (IBM)
- z/OS base operating system (IBM vendor-managed patches)

**Interconnections Requiring ISA:**
- Banking/payment network interfaces (outbound financial transactions)
- Terminal emulator access (TN3270 — inbound)
- Batch file transfer (FTP/SFTP — inbound/outbound)
- Mainframe-to-distributed bridges (MQ, CICS Transaction Gateway)
- SIEM integration (SMF records — outbound)

**Critical Recommendation:** Repository access (HTTP 403) must be resolved before any security assessment or modernization can proceed. This system has the highest FIPS 199 categorization (High/High/High) in the portfolio and should be the top priority for access restoration and subsequent modernization.
