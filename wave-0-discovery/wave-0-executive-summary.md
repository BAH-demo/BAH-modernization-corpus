# ATLAS Modernization Factory — Wave 0 Executive Summary

**Document ID:** ATLAS-W0-EXEC-001
**Classification:** CUI // Pre-Decisional
**Prepared:** April 2026
**Prepared For:** FAA Program Leadership / Federal Acquisition Authority
**Portfolio Scope:** FAA Legacy Systems — Representative Sample (14 of ~3,000)

---

## Portfolio Health Snapshot

The ATLAS Modernization Factory has completed Wave 0 Discovery on a representative sample of **14 legacy systems totaling 750,000+ lines of code** across 7 programming languages. This sample spans the full spectrum of the FAA legacy estate: enterprise monoliths (500K+ LOC), mid-tier operational applications, and mission-critical federal systems written in COBOL, Fortran, and Assembly.

| Metric | Value |
|--------|-------|
| Systems profiled | 14 |
| Total lines of code analyzed | 750,000+ |
| Programming languages represented | 7 (Java, Python, C#, ColdFusion, COBOL, Fortran, Assembly) |
| Dependency clusters identified | 5 |
| Migration waves planned | 5 (plus Wave 0 Discovery) |
| Mean risk score (1–5 scale) | 3.4 |
| Systems rated critical risk (4–5) | 7 of 14 (50%) |
| Systems requiring mandatory human review | 7 of 14 (50%) |

### Portfolio Composition

| Tier | Description | Count | % of Sample |
|------|-------------|-------|-------------|
| Tier 1 | Enterprise Monoliths (100K+ LOC) | 3 | 21% |
| Tier 2 | Operational Applications (5K–50K LOC) | 8 | 57% |
| Tier 3 | Legacy-Federal (COBOL/Fortran/Assembly) | 3 | 21% |

### Recommended Dispositions

| Strategy | Count | % |
|----------|-------|---|
| Refactor (decompose to modern architecture) | 8 | 57% |
| API-Wrap (encapsulate behind modern APIs) | 3 | 21% |
| Retire (decommission, migrate functionality) | 2 | 14% |
| Retain (preserve as-is with documentation) | 1 | 7% |

---

## Wave Sequencing Rationale

Waves are sequenced by **dependency cluster analysis** — not by system size or organizational convenience. This ensures that no migration breaks downstream dependents and that the factory builds capability incrementally from low-risk to high-risk systems.

| Wave | Focus | Systems | Duration | Risk |
|------|-------|---------|----------|------|
| **Wave 0** | Discovery & Planning | All 14 (analysis only) | 4–6 weeks | Low |
| **Wave 1** | Quick Wins — Low-Dependency Apps | 5 systems (Django Oscar, B2CWeb, Mezzanine, DFe.NET, Monolith Enterprise) | 3–4 weeks | Low |
| **Wave 2** | Platform Consolidation — .NET & ColdFusion | 3 systems (Umbraco, CFWheels, DFe.NET infra) | 4–5 weeks | Moderate |
| **Wave 3** | Enterprise Document Management | 3 systems (Alfresco, Nuxeo, Odoo) | 6–8 weeks | High |
| **Wave 4** | Enterprise Monolith Decomposition | 1 system (Apache OFBiz — 500K+ LOC) | 10–14 weeks | Critical |
| **Wave 5** | Federal Legacy — API Wrap & Retain | 3 systems (CICS Banking, NASTRAN-95, Apollo-11) | 8–12 weeks | Critical |

**Key Sequencing Decision:** COBOL and Assembly systems are placed in the final wave intentionally. The factory must demonstrate capability on modern-language systems before addressing the highest-risk federal legacy targets.

---

## Estimated Timeline

### Sample Portfolio (14 Systems)

| Scenario | Duration |
|----------|----------|
| Sequential wave execution | 9–12 months |
| With parallel execution (Waves 2+3 overlap) | 7–10 months |

### Full FAA Estate Extrapolation (~3,000 Systems)

| Cadence | Annual Throughput | Est. Total Duration |
|---------|-------------------|---------------------|
| Conservative (10 apps/week) | ~520 systems/year | ~3.8 years (with parallelism) |
| Optimistic (15 apps/week) | ~780 systems/year | ~2.5 years (with parallelism) |

> **Note:** Full-estate timelines assume a fully ramped factory with patterns validated by the 14-system pilot. Actual cadence will be calibrated based on Wave 1–2 performance.

---

## Risk Flags Requiring Human Decision

The following items require explicit program leadership decision before the factory can proceed:

### 1. COBOL/Assembly Transpilation — NOT RECOMMENDED (Year 1)

> **Decision Required:** Confirm that COBOL-to-Java and Assembly-to-C transpilation will NOT be attempted in Year 1.

**Rationale:** The CICS Banking Sample processes financial transactions where logic corruption would have regulatory consequences. NASTRAN-95 performs structural analysis where numerical precision errors could have safety-of-flight implications. API-wrapping preserves proven logic while enabling modern access.

### 2. ColdFusion Retirement — Business Stakeholder Input Needed

> **Decision Required:** Approve retirement of CFWheels (ColdFusion) and confirm replacement platform selection.

**Rationale:** ColdFusion is end-of-mainstream-support with critically scarce developer availability. CFWheels has no downstream dependents, making retirement low-risk from a technical perspective, but business stakeholders must validate that no undocumented functionality will be lost.

### 3. Apache OFBiz Decomposition Strategy — Technical Review Board

> **Decision Required:** Approve Strangler Fig decomposition approach for 500K+ LOC monolith.

**Rationale:** OFBiz is the dependency root for the Java Enterprise cluster. Its entity engine data model is consumed by downstream systems. The decomposition strategy determines the sequencing and risk profile of all dependent migrations.

### 4. Factory Cadence Target — Resourcing Decision

> **Decision Required:** Confirm target cadence (10 vs. 15 apps/week) and authorize staffing plan.

**Rationale:** The difference between conservative and optimistic cadence represents ~1.3 years of total program duration at full estate scale. Staffing and tooling investments must be aligned to the chosen target.

### 5. Consent Gate Authority — Delegation of Approval

> **Decision Required:** Designate Authorizing Officials for each consent gate.

**Rationale:** Six consent gates have been defined (W0→W1 through W5→Complete). Each requires documented approval. The approver role must be assigned before Wave 1 can be authorized.

---

## Key Metrics Summary

| Category | Metric | Value |
|----------|--------|-------|
| **Discovery** | Systems profiled | 14 |
| **Discovery** | Languages analyzed | 7 |
| **Discovery** | Total LOC analyzed | 750,000+ |
| **Dependencies** | Dependency clusters identified | 5 |
| **Dependencies** | Cross-cluster dependencies (HIGH/MEDIUM) | 0 |
| **Dependencies** | Intra-cluster dependencies requiring sequencing | 3 |
| **Sequencing** | Migration waves planned | 5 |
| **Sequencing** | Consent gates defined | 6 |
| **Risk** | Systems rated critical risk (4–5) | 7 (50%) |
| **Risk** | Systems requiring mandatory human review | 7 (50%) |
| **Disposition** | Refactor recommendations | 8 (57%) |
| **Disposition** | API-Wrap recommendations | 3 (21%) |
| **Disposition** | Retire recommendations | 2 (14%) |
| **Disposition** | Retain recommendations | 1 (7%) |
| **Extrapolation** | Projected full estate size | ~3,000 systems |
| **Extrapolation** | Projected full estate LOC | ~160M+ |
| **Extrapolation** | Est. full estate migration (conservative) | ~3.8 years |

---

## Recommendations

1. **Approve Wave 1 execution** targeting 5 low-risk, low-dependency systems to validate factory cadence and modernization patterns.

2. **Confirm API-Wrap-only strategy** for COBOL (CICS Banking Sample) and Fortran (NASTRAN-95) systems. Do not authorize transpilation in Year 1.

3. **Designate Authorizing Officials** for the 6 defined consent gates to prevent authorization delays between waves.

4. **Fund full-estate discovery** to extend Wave 0 analysis from the 14-system sample to all ~3,000 applications in the FAA legacy portfolio.

5. **Initiate COBOL talent acquisition** immediately. COBOL developer scarcity is the highest-likelihood risk to Wave 5 execution.

6. **Establish independent V&V authority** for federal legacy systems (Wave 5) before those systems enter the migration pipeline.

---

## Next Steps

| Action | Owner | Timeline |
|--------|-------|----------|
| Review Wave 0 deliverables | Program Leadership | Week 1–2 |
| Designate consent gate approvers | Program Leadership | Week 2 |
| Approve Wave 1 execution | Authorizing Official | Week 3 |
| Begin Wave 1 (Quick Wins) | Factory Team | Week 4 |
| Initiate full-estate discovery (~3,000 apps) | Discovery Team | Week 4 (parallel) |

---

> **CONSENT GATE — WAVE 0 → WAVE 1**
>
> This document and accompanying deliverables (Portfolio Inventory, Dependency Map, Wave Sequencing Plan, Disposition Decisions) constitute the Wave 0 Discovery output. Program leadership review and written approval are required before any system proceeds to execution.

---

*Prepared by ATLAS Modernization Factory — Wave 0 Discovery*
*All recommendations subject to federal program leadership review and approval*
