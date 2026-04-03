# SSP Summary: Apollo-11

**System Identifier:** apollo-11  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

The Apollo-11 codebase is the original Apollo Guidance Computer (AGC) software written in AGC Assembly language, used for the 1969 lunar landing mission. This codebase is maintained as a historical preservation and educational artifact. It is not deployed in any operational environment. In the federal context, Apollo-11 serves as a reference implementation for understanding mission-critical software engineering practices and as a benchmark for code analysis tools.

**Tier Classification:** Tier 3 — Federal/Legacy System (8K+ LOC, Assembly)  
**Primary Function:** Historical Preservation and Documentation / Research Reference  
**User Base:** Researchers, historians, software analysis tool developers

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Low | Codebase is publicly available on GitHub; no confidential information |
| **Integrity** | Moderate | Historical accuracy is important for research and educational purposes; unauthorized modification would compromise archival integrity |
| **Availability** | Low | Non-operational system; unavailability would not impact any mission function |

**Overall System Categorization:** **Moderate** (due to Integrity high-water mark)

`SC apollo-11 = {(confidentiality, low), (integrity, moderate), (availability, low)}`

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Language | AGC Assembly | 1960s | Historical |
| Platform | Apollo Guidance Computer | Block II | Decommissioned |
| Repository | Source code archive | Various | Preserved |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Language | AGC Assembly (unchanged) | 1960s | N/A (preserved) |
| Platform | N/A (not deployable) | N/A | N/A |
| Documentation | Enhanced inline documentation and annotations | Current | N/A |
| Preservation | Git-based version control with archival integrity | Current | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-7 Software Integrity
- **Documentation and preservation activities** ensure historical integrity of the codebase
- Git commit history provides tamper-evident audit trail
- No code modifications made to the original source — preservation only

### 4.2 CM-2 Baseline Configuration
- Original codebase preserved as immutable baseline
- Documentation added as supplementary materials without altering original files
- Version control provides complete change history

### 4.3 CM-3 Configuration Change Control
- All documentation additions tracked via Git
- No modifications to original Assembly source permitted
- Change review process for any supplementary materials

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| APL-001 | No operational deployment — limited security relevance | System is a preservation artifact; traditional security controls have limited applicability | Low | Accepted | N/A |
| APL-002 | If used as input to analysis tools, crafted Assembly could exploit parser vulnerabilities | Tool-chain risk if AGC Assembly is parsed by vulnerable analysis tools | Low | Open | Q4 2026 |
| APL-003 | Historical accuracy dependent on upstream repository integrity | If upstream GitHub repository is compromised, preserved copy may be needed as authoritative source | Low | Open | Ongoing |

---

## 6. Recommended Authorization Boundary

The apollo-11 authorization boundary should include:

- **Repository tier:** Git repository containing preserved AGC Assembly source and documentation
- **Documentation tier:** Supplementary analysis and annotation files

**Boundary Exclusions:**
- This system has no runtime components, databases, or network services
- All traditional infrastructure controls are not applicable

**Interconnections:**
- No external interconnections (read-only archive)
- GitHub upstream repository (reference only — pull, no push)

**Note:** Apollo-11 is a non-operational preservation artifact. The SSP is maintained for portfolio completeness and to document the system's role in the modernization corpus. Security controls focus exclusively on integrity preservation. A lightweight ATO approach (e.g., attestation letter) may be more appropriate than a full ATO package for this system.
