# SSP Summary: NASTRAN-95

**System Identifier:** nastran-95  
**Document Version:** 1.0  
**Date:** April 2, 2026  
**Classification:** CUI — For Official Use Only

---

## 1. System Description and Purpose

NASTRAN-95 (NASA Structural Analysis System, 1995 release) is a legacy Fortran-based finite element analysis (FEA) program originally developed by NASA for structural analysis of aerospace vehicles and structures. The system performs numerical computation for stress analysis, vibration analysis, and dynamic response calculations. In the federal context, NASTRAN-95 supports engineering analysis for infrastructure, defense, and aerospace applications.

**Tier Classification:** Tier 3 — Federal/Legacy System (150K+ LOC)  
**Primary Function:** Structural Finite Element Analysis (Scientific Computing)  
**User Base:** Internal agency engineers, structural analysts, research scientists

---

## 2. FIPS 199 Security Categorization

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| **Confidentiality** | Low | Analysis inputs/outputs may be sensitive for defense applications, but the software itself is publicly available; classify higher if processing classified structural data |
| **Integrity** | High | Computational integrity is critical — incorrect analysis results could lead to structural failures with life-safety implications |
| **Availability** | Low | Batch processing system; temporary unavailability would delay analysis but not endanger operations |

**Overall System Categorization:** **High** (due to Integrity high-water mark)

`SC nastran-95 = {(confidentiality, low), (integrity, high), (availability, low)}`

**Note:** If NASTRAN-95 processes classified or export-controlled structural data (ITAR/EAR), the Confidentiality categorization must be elevated accordingly.

---

## 3. Technology Stack

### Pre-Modernization

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| Language | Fortran 77 | F77 | Legacy (no vendor support) |
| Compiler | Various (gfortran, ifort) | Legacy | Active |
| Architecture | Batch processing | N/A | Active |
| Code Patterns | Implicit typing, GOTO, COMMON blocks | Legacy | Unmaintainable |
| Platform | Linux/Unix workstations | Various | Active |

### Post-Modernization

| Component | Technology | Version | Support End |
|-----------|-----------|---------|------------|
| Language | Fortran 77 (with modernization flags) | F77 | Legacy |
| Compiler | gfortran / ifort | Current | Active |
| Architecture | Batch processing | N/A | Active |
| Code Quality | IMPLICIT NONE added, GOTO/COMMON flagged | N/A | N/A |
| Platform | Linux workstations | Current | Active |

---

## 4. Security Controls Implemented During Modernization

### 4.1 SI-2 Flaw Remediation
- **IMPLICIT NONE added:** Eliminates implicit variable typing that can cause type confusion vulnerabilities and silent data corruption
- **GOTO statements flagged:** Identified unstructured control flow that complicates security review and may hide logic errors
- **COMMON blocks flagged:** Identified shared global state that could lead to data leakage between analysis runs

### 4.2 SI-7 Software Integrity
- IMPLICIT NONE ensures all variables are explicitly declared, preventing typo-induced computation errors
- Flagged patterns documented for future remediation to improve code auditability

### 4.3 SA-8 Security Engineering Principles
- IMPLICIT NONE enforces defensive programming practices
- Code analysis identifies high-risk patterns for prioritized remediation

### 4.4 CM-3 Configuration Change Control
- All modernization changes tracked in version control
- Original code preserved for comparison and verification
- Compiler warnings enabled to surface potential issues

---

## 5. Residual Risks and POA&M Items

| ID | Finding | Risk | Severity | Status | Target Date |
|----|---------|------|----------|--------|-------------|
| NAS-001 | GOTO statements remain in codebase (flagged but not removed) | Complex control flow hinders security review and may hide logic errors affecting structural analysis accuracy | Medium | Open | Q4 2026 |
| NAS-002 | COMMON blocks remain in codebase (flagged but not removed) | Shared mutable state could leak data between analysis runs or between users in multi-tenant configurations | Medium | Open | Q4 2026 |
| NAS-003 | No modern input validation framework for Fortran | Input files (BDF/NAS format) parsed without bounds checking | High | Open | Q3 2026 |
| NAS-004 | Legacy Fortran has no memory safety guarantees | Buffer overflows possible in array operations without explicit bounds checking | High | Open | Q3 2026 |
| NAS-005 | No automated test suite for regression verification | Cannot verify that modernization changes do not alter computation results | Medium | Open | Q3 2026 |
| NAS-006 | Limited Fortran security tooling available | SAST tools have minimal Fortran support; manual code review required | Medium | Open | Ongoing |

---

## 6. Recommended Authorization Boundary

The nastran-95 authorization boundary should include:

- **Compute tier:** Linux workstation or HPC cluster nodes running NASTRAN-95
- **Storage tier:** Input file storage (structural models), output file storage (analysis results)
- **User access tier:** SSH/terminal access for engineers submitting analysis jobs
- **Job scheduling tier:** Batch job scheduler (PBS/SLURM if on HPC)

**Boundary Exclusions (Inherited Controls):**
- HPC cluster infrastructure (if shared facility)
- Physical workstation/data center controls
- Network perimeter firewalls

**Interconnections Requiring ISA:**
- Engineering workstations (input file transfer — SCP/SFTP)
- Results visualization systems (post-processing — file transfer)
- HPC job scheduler (job submission — internal)
- SIEM platform (authentication log shipping — if applicable)

**Note:** NASTRAN-95 is a batch-processing application without network services. The primary attack surface is through crafted input files and local user access. Network-level controls are less relevant than input validation and access control for the compute environment.
