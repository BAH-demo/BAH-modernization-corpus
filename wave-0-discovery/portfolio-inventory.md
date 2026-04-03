# ATLAS Modernization Factory — Portfolio Inventory

**Document ID:** ATLAS-W0-INV-001
**Classification:** CUI // Pre-Decisional
**Prepared:** April 2026
**Portfolio Scope:** FAA Legacy Systems — Representative Sample (14 of ~3,000)

---

## 1. Purpose

This document provides the complete portfolio inventory for the 14 legacy systems analyzed during Wave 0 Discovery. Each system has been profiled by language, lines of code (LOC), tier classification, recommended modernization strategy, composite risk score, and preliminary wave assignment. These assessments are subject to human review and approval at the designated consent gates prior to any execution activity.

---

## 2. Tier Classification Methodology

| Tier | Label | Criteria |
|------|-------|----------|
| Tier 1 | Enterprise Monolith | 100K+ LOC; complex multi-domain business logic; deep integration surface |
| Tier 2 | Operational Application | 5K–50K LOC; domain-specific; moderate integration complexity |
| Tier 3 | Legacy-Federal | Any LOC; non-modern language (COBOL, Fortran, Assembly); mission-critical federal systems |

---

## 3. Modernization Strategy Definitions

| Strategy | Definition |
|----------|------------|
| **Refactor** | Decompose monolith into microservices or modular architecture; migrate to modern runtime |
| **API-Wrap** | Encapsulate existing system behind a modern API gateway; preserve core logic unchanged |
| **Retain** | Maintain current system with minimal changes; invest in monitoring and documentation only |
| **Retire** | Decommission system; migrate data/functions to successor platform |

---

## 4. Risk Scoring Methodology

Composite risk score (1–5) based on weighted factors:

| Factor | Weight | Description |
|--------|--------|-------------|
| Codebase Age | 20% | Years since initial commit; older = higher risk |
| Language Risk | 25% | Availability of skilled developers; tooling maturity; community support |
| Security Findings | 20% | Known CVE exposure; dependency vulnerability surface |
| Integration Complexity | 20% | Number of external dependencies; shared databases; API consumers |
| LOC / Structural Complexity | 15% | Raw size and cyclomatic complexity indicators |

---

## 5. Full Portfolio Inventory

| # | System | Language | LOC | Tier | Modernization Strategy | Risk Score (1–5) | Est. Wave |
|---|--------|----------|-----|------|------------------------|-------------------|-----------|
| 1 | Apache OFBiz | Java | 500K+ | Tier 1 — Enterprise Monolith | Refactor | 5 | Wave 4 |
| 2 | Odoo | Python | 200K+ | Tier 1 — Enterprise Monolith | Refactor | 4 | Wave 4 |
| 3 | Alfresco Community | Java | 100K+ | Tier 1 — Enterprise Monolith | Refactor | 4 | Wave 3 |
| 4 | Umbraco CMS | C# | 50K+ | Tier 2 — Operational | Refactor | 3 | Wave 2 |
| 5 | CFWheels | ColdFusion | 50K+ | Tier 2 — Operational | Retire | 4 | Wave 2 |
| 6 | Nuxeo | Java | 50K+ | Tier 2 — Operational | Refactor | 3 | Wave 3 |
| 7 | Django Oscar | Python | 10–15K | Tier 2 — Operational | Refactor | 2 | Wave 1 |
| 8 | B2CWeb | Java | 5–8K | Tier 2 — Operational | Refactor | 2 | Wave 1 |
| 9 | Mezzanine | Python | 5–10K | Tier 2 — Operational | Retire | 3 | Wave 1 |
| 10 | DFe.NET | C# | 5K | Tier 2 — Operational | API-Wrap | 2 | Wave 1 |
| 11 | Monolith Enterprise | Java | 5K+ | Tier 2 — Operational | Refactor | 2 | Wave 1 |
| 12 | CICS Banking Sample | COBOL | 30K+ | Tier 3 — Legacy-Federal | API-Wrap | 5 | Wave 5 |
| 13 | NASTRAN-95 | Fortran | 150K+ | Tier 3 — Legacy-Federal | API-Wrap | 5 | Wave 5 |
| 14 | Apollo-11 | Assembly | 8K+ | Tier 3 — Legacy-Federal | Retain | 4 | Wave 5 |

---

## 6. Inventory Summary Statistics

| Metric | Value |
|--------|-------|
| Total Systems Profiled | 14 |
| Total LOC (estimated) | 750,000+ |
| Tier 1 Systems | 3 (21%) |
| Tier 2 Systems | 8 (57%) |
| Tier 3 Systems | 3 (21%) |
| Mean Risk Score | 3.4 |
| Systems Rated Risk 4–5 | 7 (50%) |
| Recommended for Refactor | 8 (57%) |
| Recommended for API-Wrap | 3 (21%) |
| Recommended for Retire | 2 (14%) |
| Recommended for Retain | 1 (7%) |

---

## 7. Language Distribution

| Language | System Count | Combined LOC | % of Portfolio LOC |
|----------|-------------|-------------|-------------------|
| Java | 5 | ~660K+ | ~65% |
| Python | 3 | ~215K+ | ~21% |
| C# / .NET | 2 | ~55K | ~5% |
| Fortran | 1 | ~150K+ | ~5% |
| COBOL | 1 | ~30K+ | ~2% |
| ColdFusion | 1 | ~50K+ | ~1.5% |
| Assembly | 1 | ~8K+ | ~0.5% |

---

## 8. Risk Distribution

| Risk Score | Count | Systems |
|-----------|-------|---------|
| 5 (Critical) | 3 | Apache OFBiz, CICS Banking Sample, NASTRAN-95 |
| 4 (High) | 3 | Odoo, Alfresco Community, CFWheels, Apollo-11 |
| 3 (Moderate) | 3 | Umbraco CMS, Nuxeo, Mezzanine |
| 2 (Low) | 4 | Django Oscar, B2CWeb, DFe.NET, Monolith Enterprise |
| 1 (Minimal) | 0 | — |

---

## 9. Consent Gate Notice

> **CONSENT GATE — MANDATORY**
>
> No system listed in this inventory shall proceed to execution (migration, refactoring, wrapping, or retirement) without explicit written approval from the designated Authorizing Official. All disposition recommendations in this document are PENDING human review. See `disposition-decisions.md` for per-system approval status.

---

## 10. Extrapolation to Full FAA Estate

This inventory represents 14 of an estimated ~3,000 applications in the FAA legacy portfolio. At this sample ratio (~0.47%), the following extrapolations apply:

| Metric | Sample (14) | Projected Estate (~3,000) |
|--------|-------------|--------------------------|
| Tier 1 Systems | 3 | ~640 |
| Tier 2 Systems | 8 | ~1,710 |
| Tier 3 Systems | 3 | ~650 |
| Systems Risk 4–5 | 7 | ~1,500 |
| Est. Total LOC | 750K+ | ~160M+ |

> **Note:** Extrapolations are directional estimates based on the representative sample. Full portfolio discovery across all ~3,000 applications is required before wave sequencing can be finalized at enterprise scale.

---

*Prepared by ATLAS Modernization Factory — Wave 0 Discovery*
*All recommendations subject to federal program leadership review and approval*
