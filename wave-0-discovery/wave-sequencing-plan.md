# ATLAS Modernization Factory — Wave Sequencing Plan

**Document ID:** ATLAS-W0-SEQ-001
**Classification:** CUI // Pre-Decisional
**Prepared:** April 2026
**Portfolio Scope:** FAA Legacy Systems — Representative Sample (14 of ~3,000)

---

## 1. Purpose

This document defines the migration wave sequence for the 14 legacy systems profiled during Wave 0 Discovery. Waves are ordered by dependency cluster analysis — not by system size or alphabetical order — to ensure that no migration breaks downstream dependents. Each wave includes a mandatory consent gate requiring human approval before execution begins.

---

## 2. Wave Sequencing Principles

| Principle | Description |
|-----------|-------------|
| **Dependency-First Ordering** | Systems with no upstream dependencies migrate first; dependency roots migrate after interfaces are stabilized |
| **Cluster Cohesion** | Systems sharing databases, APIs, or infrastructure migrate together or in coordinated sequence |
| **Risk Graduation** | Lower-risk systems migrate in early waves to build factory confidence; highest-risk systems migrate last |
| **Consent Gates** | Every wave requires explicit human approval before execution. No autonomous execution permitted |
| **COBOL/Assembly Constraint** | COBOL and Assembly systems are API-Wrap or Retain only. Transpilation is NOT recommended in Year 1 |
| **Incremental Validation** | Each wave produces measurable outcomes validated before the next wave is authorized |

---

## 3. Wave Plan Overview

| Wave | Name | Systems | Duration (Est.) | Risk Level |
|------|------|---------|-----------------|------------|
| Wave 0 | Discovery & Planning | All 14 (analysis only) | 4–6 weeks | Low |
| Wave 1 | Quick Wins — Low-Dependency Applications | 5 systems | 3–4 weeks | Low |
| Wave 2 | Platform Consolidation — .NET & ColdFusion | 3 systems | 4–5 weeks | Moderate |
| Wave 3 | Enterprise Document Management | 3 systems | 6–8 weeks | High |
| Wave 4 | Enterprise Monolith Decomposition | 1 system | 10–14 weeks | Critical |
| Wave 5 | Federal Legacy — API Wrap & Retain | 3 systems | 8–12 weeks | Critical |

---

## 4. Detailed Wave Definitions

### Wave 0 — Discovery & Planning (This Document)

**Status:** IN PROGRESS
**Duration:** 4–6 weeks
**Systems:** All 14 (analysis only — no code changes)

| Deliverable | Status |
|-------------|--------|
| Portfolio Inventory | COMPLETE |
| Dependency Map | COMPLETE |
| Wave Sequencing Plan | COMPLETE |
| Disposition Decisions | COMPLETE |
| Executive Summary | COMPLETE |

**Objective:** Profile all systems, map dependencies, sequence waves, and obtain program leadership authorization to proceed to Wave 1.

**Exit Criteria:**
- [ ] All 14 systems profiled with risk scores and disposition recommendations
- [ ] Dependency clusters validated by technical SMEs
- [ ] Wave sequencing plan approved by Authorizing Official
- [ ] Consent gate signed for Wave 1 execution

> **CONSENT GATE W0 → W1:** Program leadership must review and approve all disposition recommendations before any execution activity begins.

---

### Wave 1 — Quick Wins: Low-Dependency Applications

**Status:** PENDING APPROVAL
**Duration:** 3–4 weeks (at factory cadence of 10–15 apps/week at full scale)
**Risk Level:** Low

| # | System | Language | LOC | Strategy | Rationale |
|---|--------|----------|-----|----------|-----------|
| 1 | Django Oscar | Python | 10–15K | Refactor | Clean Django architecture; low coupling; active community; well-understood patterns |
| 2 | B2CWeb | Java | 5–8K | Refactor | Small Java codebase; tight coupling is addressable at this scale |
| 3 | Mezzanine | Python | 5–10K | Retire | End-of-life Django CMS; migrate content to modern platform; no downstream dependents |
| 4 | DFe.NET | C# | 5K | API-Wrap | Legacy fiscal integration; wrap behind modern API to preserve compliance logic |
| 5 | Monolith Enterprise | Java | 5K+ | Refactor | Small monolith; ideal candidate for microservice decomposition demonstration |

**Dependencies Cleared:** None required — these systems have no upstream dependencies within the portfolio.

**Wave 1 Objectives:**
- Demonstrate factory cadence and tooling on low-risk systems
- Establish modernization patterns (refactor playbook, API-wrap playbook, retirement checklist)
- Validate CI/CD pipeline for modernized components
- Build team confidence before tackling enterprise monoliths

**Exit Criteria:**
- [ ] All 5 systems modernized or wrapped per disposition recommendation
- [ ] Automated test coverage ≥ 80% for refactored components
- [ ] API contracts published for DFe.NET wrapper
- [ ] Mezzanine content migration verified; retirement executed
- [ ] Lessons learned documented for Wave 2

> **CONSENT GATE W1 → W2:** Wave 1 outcomes must be reviewed and approved before Wave 2 execution is authorized.

---

### Wave 2 — Platform Consolidation: .NET & ColdFusion

**Status:** PENDING APPROVAL
**Duration:** 4–5 weeks
**Risk Level:** Moderate

| # | System | Language | LOC | Strategy | Rationale |
|---|--------|----------|-----|----------|-----------|
| 1 | Umbraco CMS | C# | 50K+ | Refactor | Modern .NET ecosystem available; migrate from .NET Framework to .NET 8+; active community |
| 2 | CFWheels | ColdFusion | 50K+ | Retire | ColdFusion runtime is end-of-mainstream-support; developer scarcity; no downstream dependents |
| 3 | DFe.NET | C# | 5K | *(Completed in Wave 1 — infrastructure coordination only)* | Shared .NET infrastructure validation |

**Dependencies Cleared:**
- Wave 1 DFe.NET API-wrap validates .NET modernization pipeline
- CFWheels has no downstream dependents — safe to retire

**Wave 2 Objectives:**
- Consolidate .NET infrastructure modernization (.NET Framework → .NET 8+)
- Execute ColdFusion retirement (migrate functionality to modern stack)
- Validate platform migration patterns for larger .NET workloads

**Exit Criteria:**
- [ ] Umbraco CMS refactored to .NET 8+ with container deployment
- [ ] CFWheels functionality migrated or retired; ColdFusion runtime decommissioned
- [ ] .NET deployment pipeline validated for enterprise scale
- [ ] No regression in systems dependent on shared infrastructure

> **CONSENT GATE W2 → W3:** Platform consolidation outcomes must be validated before enterprise document management migration is authorized.

---

### Wave 3 — Enterprise Document Management

**Status:** PENDING APPROVAL
**Duration:** 6–8 weeks
**Risk Level:** High

| # | System | Language | LOC | Strategy | Rationale |
|---|--------|----------|-----|----------|-----------|
| 1 | Alfresco Community | Java | 100K+ | Refactor | Complex document model; CMIS API surface must be preserved; enterprise content dependencies |
| 2 | Nuxeo | Java | 50K+ | Refactor | CMIS-compatible; overlapping content model with Alfresco; must be coordinated |
| 3 | Odoo | Python | 200K+ | Refactor | Self-contained ERP; large but modular; scheduled here after factory has matured |

**Dependencies Cleared:**
- Wave 1/2 validated Java and Python modernization patterns
- Alfresco and Nuxeo share CMIS API surface — must migrate together or in tight sequence
- Odoo is independent but benefits from factory maturity

**Wave 3 Objectives:**
- Address enterprise-scale Java document management systems as a coordinated pair
- Preserve CMIS API compatibility throughout migration
- Tackle first 100K+ LOC system (Alfresco)
- Demonstrate factory capability on large Python ERP (Odoo)

**Exit Criteria:**
- [ ] Alfresco Community refactored with CMIS API backward compatibility verified
- [ ] Nuxeo refactored with content model migration validated
- [ ] Odoo modular decomposition initiated (minimum: 3 modules extracted)
- [ ] Integration tests confirm no data loss across document management systems
- [ ] Performance benchmarks meet or exceed baseline

> **CONSENT GATE W3 → W4:** Enterprise document management migration must be fully validated — including CMIS compatibility and data integrity — before monolith decomposition is authorized.

---

### Wave 4 — Enterprise Monolith Decomposition

**Status:** PENDING APPROVAL
**Duration:** 10–14 weeks
**Risk Level:** Critical

| # | System | Language | LOC | Strategy | Rationale |
|---|--------|----------|-----|----------|-----------|
| 1 | Apache OFBiz | Java | 500K+ | Refactor | Largest system in portfolio; 20-year monolith; global state; entity engine dependency root |

**Dependencies Cleared:**
- Waves 1–3 validated all modernization patterns at increasing scale
- B2CWeb and Monolith Enterprise (OFBiz pattern consumers) already migrated in Wave 1
- Factory team has demonstrated capability on 100K+ LOC systems

**Wave 4 Objectives:**
- Decompose the 500K+ LOC Apache OFBiz monolith into bounded service domains
- Stabilize entity engine interfaces for any remaining downstream consumers
- This is the highest-complexity, highest-value modernization in the portfolio

**Decomposition Approach:**
1. **Domain Mapping:** Identify bounded contexts within OFBiz (Accounting, Order Management, Catalog, Party, etc.)
2. **Strangler Fig Pattern:** Extract domains incrementally behind API facade
3. **Entity Engine Abstraction:** Replace global state access with domain-specific data services
4. **Incremental Validation:** Each extracted domain validated independently before proceeding

**Exit Criteria:**
- [ ] Minimum 3 bounded contexts extracted as independent services
- [ ] Entity engine global state eliminated for extracted domains
- [ ] API facade provides backward compatibility for remaining monolith
- [ ] Load testing confirms no performance degradation
- [ ] Security scan confirms no new vulnerabilities introduced

> **CONSENT GATE W4 → W5:** Monolith decomposition must be validated by independent technical review before federal legacy systems are addressed.

---

### Wave 5 — Federal Legacy: API Wrap & Retain

**Status:** PENDING APPROVAL
**Duration:** 8–12 weeks
**Risk Level:** Critical

| # | System | Language | LOC | Strategy | Rationale |
|---|--------|----------|-----|----------|-----------|
| 1 | CICS Banking Sample | COBOL | 30K+ | API-Wrap | Mainframe coupling; CICS transaction dependency; wrap behind REST/gRPC API gateway |
| 2 | NASTRAN-95 | Fortran | 150K+ | API-Wrap | NASA scientific computing; numerical algorithms must be preserved exactly; wrap for modern consumption |
| 3 | Apollo-11 | Assembly | 8K+ | Retain | Historical mission code; no active operational use; preserve as archival reference with documentation |

**Dependencies Cleared:**
- All modern-language systems migrated in Waves 1–4
- Factory has demonstrated capability across all complexity tiers
- API-wrap patterns validated on DFe.NET (Wave 1)

> **CRITICAL CONSTRAINT — COBOL & ASSEMBLY:**
>
> - **Transpilation is NOT recommended for Year 1.** COBOL-to-Java or Assembly-to-C transpilation introduces unacceptable risk of logic corruption in financial and scientific computation systems.
> - **API-Wrap is the approved strategy.** Encapsulate existing COBOL and Fortran logic behind modern API layers (REST, gRPC, GraphQL) while preserving the original runtime.
> - **Retain is the approved strategy for Apollo-11.** This is archival code with historical significance. Modernization would destroy its value as a reference artifact.

**Wave 5 Objectives:**
- Wrap CICS Banking Sample COBOL transactions behind a modern API gateway
- Wrap NASTRAN-95 Fortran computational routines behind a modern API gateway
- Document Apollo-11 as archival reference; ensure long-term preservation
- Validate that wrapped APIs provide equivalent functionality to original interfaces

**Exit Criteria:**
- [ ] CICS Banking Sample accessible via REST API with transaction integrity verified
- [ ] NASTRAN-95 computational routines callable via modern API with numerical accuracy validated to 12+ decimal places
- [ ] Apollo-11 documentation updated; archival repository secured
- [ ] No modifications to original COBOL, Fortran, or Assembly source code
- [ ] Independent security review of API gateway configurations

> **CONSENT GATE W5 → COMPLETE:** Federal legacy system wrapping must pass independent verification and validation (IV&V) before the portfolio migration is declared complete.

---

## 5. Timeline Summary

```
Wave 0  [======]                                    4-6 weeks   (Discovery)
Wave 1         [====]                               3-4 weeks   (Quick Wins)
Wave 2              [=====]                          4-5 weeks   (Platform)
Wave 3                    [========]                 6-8 weeks   (Doc Mgmt)
Wave 4                             [==============]  10-14 weeks (Monolith)
Wave 5                                        [==========]  8-12 weeks (Federal)
        |-------|-------|-------|-------|-------|-------|-------|
        M1      M3      M5      M7      M9      M11     M13

Total Estimated Duration: 9–12 months (sequential execution)
With Parallel Execution (Waves 2+3 overlap): 7–10 months
```

---

## 6. Factory Cadence Extrapolation

**Sample portfolio (14 systems):** 5 waves, ~9–12 months

**Full FAA estate (~3,000 systems) at factory cadence of 10–15 apps/week:**

| Metric | Conservative (10/wk) | Optimistic (15/wk) |
|--------|----------------------|---------------------|
| Discovery (all systems) | 8–12 weeks | 6–8 weeks |
| Total migration duration | ~300 weeks (~5.8 years) | ~200 weeks (~3.8 years) |
| With parallel wave execution | ~200 weeks (~3.8 years) | ~130 weeks (~2.5 years) |
| Annual throughput | ~520 systems | ~780 systems |

> **Note:** These estimates assume a fully ramped factory with trained teams, validated tooling, and established patterns from the 14-system pilot. Actual cadence will be informed by Wave 1–2 performance metrics.

---

## 7. Risk Registry

| Risk ID | Description | Likelihood | Impact | Mitigation |
|---------|-------------|-----------|--------|------------|
| R-01 | COBOL developer scarcity delays API-wrap | High | High | Engage IBM mainframe services partnership; begin talent acquisition in Wave 0 |
| R-02 | OFBiz entity engine dependencies not fully mapped | Medium | Critical | Conduct deep-dive technical assessment in Wave 3; allocate buffer weeks |
| R-03 | ColdFusion retirement reveals undocumented integrations | Medium | Medium | Run traffic analysis on CFWheels production instance before retirement |
| R-04 | NASTRAN-95 numerical accuracy lost in API wrapping | Low | Critical | Mandate 12+ decimal place validation; independent V&V of all wrapped computations |
| R-05 | Factory cadence slower than projected in early waves | Medium | Medium | Build 25% schedule buffer into Wave 1–2; adjust cadence targets based on actuals |
| R-06 | Shared infrastructure migration causes cross-system outage | Low | High | Stage infrastructure changes in pre-production; implement rollback procedures |

---

## 8. Consent Gate Summary

| Gate | Approver | Trigger | Approval Status |
|------|----------|---------|-----------------|
| W0 → W1 | Program Leadership | Wave 0 deliverables reviewed | **PENDING** |
| W1 → W2 | Program Leadership | Wave 1 outcomes validated | **PENDING** |
| W2 → W3 | Program Leadership | Platform consolidation verified | **PENDING** |
| W3 → W4 | Program Leadership + Technical Review Board | Enterprise migration verified | **PENDING** |
| W4 → W5 | Program Leadership + IV&V Authority | Monolith decomposition verified | **PENDING** |
| W5 → Complete | Authorizing Official | Federal legacy wrapping verified by IV&V | **PENDING** |

> All consent gates require documented approval. No wave proceeds without the prior gate being signed.

---

*Prepared by ATLAS Modernization Factory — Wave 0 Discovery*
*All recommendations subject to federal program leadership review and approval*
