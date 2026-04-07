# ATLAS Modernization Factory — Disposition Decisions Log

**Document ID:** ATLAS-W0-DIS-001
**Classification:** CUI // Pre-Decisional
**Prepared:** April 2026
**Portfolio Scope:** FAA Legacy Systems — Representative Sample (14 of ~3,000)

---

## 1. Purpose

This document records the recommended disposition for each of the 14 legacy systems analyzed during Wave 0 Discovery. Every recommendation includes a rationale, risk assessment, consequences of overriding the recommendation, and a mandatory human approval status field. No system shall proceed to execution without explicit approval at the designated consent gate.

---

## 2. Disposition Categories

| Disposition | Definition | Typical Applicability |
|-------------|------------|----------------------|
| **Refactor** | Decompose and re-architect on modern platform | Systems with viable language ecosystems and clear domain boundaries |
| **API-Wrap** | Encapsulate behind modern API gateway; preserve core logic | Systems in scarce-skill languages (COBOL, Fortran) or with mission-critical logic that must not be altered |
| **Retain** | Maintain as-is with enhanced monitoring and documentation | Archival systems or systems where modernization cost exceeds benefit |
| **Retire** | Decommission; migrate data/functions to successor | End-of-life systems with no downstream dependents and available replacements |

---

## 3. Per-System Disposition Log

---

### System 1: Apache OFBiz

| Field | Value |
|-------|-------|
| **System** | Apache OFBiz |
| **Language** | Java |
| **LOC** | 500K+ |
| **Tier** | Tier 1 — Enterprise Monolith |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 5 (Critical) |
| **Assigned Wave** | Wave 4 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Apache OFBiz is the largest and most complex system in the portfolio. Its 20-year-old monolithic architecture features pervasive global state via a custom entity engine, making incremental modernization the only viable path. Java has a mature modernization toolchain and available talent pool. The Strangler Fig pattern is recommended to extract bounded contexts incrementally.

**Risks if Recommendation is Overridden:**
- If RETAINED: Technical debt compounds; entity engine becomes unmaintainable; security vulnerability surface grows
- If RETIRED: No equivalent open-source ERP replacement exists at this scale; data migration risk is extreme
- If API-WRAPPED only: Underlying monolith continues to degrade; wrapping 500K LOC without internal decomposition provides limited long-term value

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended without human review. This system's complexity and dependency-root status require program-level oversight at every phase of decomposition.

---

### System 2: Odoo

| Field | Value |
|-------|-------|
| **System** | Odoo |
| **Language** | Python |
| **LOC** | 200K+ |
| **Tier** | Tier 1 — Enterprise Monolith |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 4 (High) |
| **Assigned Wave** | Wave 3 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Odoo's plugin-based architecture provides natural module boundaries for decomposition. Python modernization tooling is mature. The multi-domain business logic (CRM, inventory, accounting, HR) maps well to microservice extraction. Active upstream community provides migration patterns.

**Risks if Recommendation is Overridden:**
- If RETAINED: Python 2.x compatibility debt (if present) creates security exposure; plugin interdependencies accumulate
- If RETIRED: No single replacement covers Odoo's multi-domain scope; would require procurement of 4+ SaaS products
- If API-WRAPPED only: Viable short-term but leaves monolithic core unaddressed; recommended as interim step during refactor

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended without human review. Odoo's multi-domain scope means disposition impacts multiple business units.

---

### System 3: Alfresco Community

| Field | Value |
|-------|-------|
| **System** | Alfresco Community |
| **Language** | Java |
| **LOC** | 100K+ |
| **Tier** | Tier 1 — Enterprise Monolith |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 4 (High) |
| **Assigned Wave** | Wave 3 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Alfresco's CMIS API surface must be preserved during migration to maintain compatibility with document management consumers. The content repository model is well-defined and suitable for modular extraction. Must be coordinated with Nuxeo (shared CMIS interface).

**Risks if Recommendation is Overridden:**
- If RETAINED: Content model technical debt increases; CMIS API version compatibility risk
- If RETIRED: Document management is a core enterprise function; retirement requires full content migration strategy
- If API-WRAPPED only: Viable interim approach; recommend as Phase 1 of refactor sequence

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended without human review. CMIS API changes impact all document management consumers across the enterprise.

---

### System 4: Umbraco CMS

| Field | Value |
|-------|-------|
| **System** | Umbraco CMS |
| **Language** | C# |
| **LOC** | 50K+ |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 3 (Moderate) |
| **Assigned Wave** | Wave 2 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Umbraco has an active open-source community and a clear migration path from .NET Framework to .NET 8+. The CMS domain is well-understood. Container deployment modernization is straightforward with established .NET tooling.

**Risks if Recommendation is Overridden:**
- If RETAINED: .NET Framework end-of-support creates security risk; hosting cost increases on legacy Windows Server
- If RETIRED: CMS functionality must be replaced; content migration required
- If API-WRAPPED: Unnecessary complexity for a system with a clear refactor path

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable for standard refactoring tasks. Human review recommended for content migration decisions.

---

### System 5: CFWheels

| Field | Value |
|-------|-------|
| **System** | CFWheels |
| **Language** | ColdFusion |
| **LOC** | 50K+ |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | RETIRE |
| **Risk Score** | 4 (High) |
| **Assigned Wave** | Wave 2 |
| **Human Approval Status** | **PENDING** |

**Rationale:** ColdFusion is end-of-mainstream-support. Developer availability is critically scarce. The CFWheels framework has minimal community activity. No downstream systems depend on CFWheels. Functionality should be migrated to a modern web framework (e.g., Spring Boot, Django, or .NET).

**Risks if Recommendation is Overridden:**
- If REFACTORED: ColdFusion-to-modern-language refactoring is effectively a rewrite; higher cost than retirement + rebuild
- If RETAINED: Growing security vulnerability surface; inability to hire maintenance developers
- If API-WRAPPED: ColdFusion runtime must still be maintained; wrapping does not address language risk

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended without human review. Retirement involves functionality mapping and potential data migration that requires business stakeholder input.

---

### System 6: Nuxeo

| Field | Value |
|-------|-------|
| **System** | Nuxeo |
| **Language** | Java |
| **LOC** | 50K+ |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 3 (Moderate) |
| **Assigned Wave** | Wave 3 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Nuxeo shares CMIS API compatibility with Alfresco and must be migrated in coordination. Java ecosystem provides mature modernization tooling. Complex abstractions require careful domain analysis but are tractable.

**Risks if Recommendation is Overridden:**
- If RETAINED: Divergence from Alfresco CMIS API creates integration fragility
- If RETIRED: Document management capability loss; content migration required
- If API-WRAPPED: Viable interim step; recommended as Phase 1 of coordinated Alfresco/Nuxeo migration

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable for standard refactoring. Human review required for any changes to CMIS API contracts.

---

### System 7: Django Oscar

| Field | Value |
|-------|-------|
| **System** | Django Oscar |
| **Language** | Python |
| **LOC** | 10–15K |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 2 (Low) |
| **Assigned Wave** | Wave 1 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Django Oscar has a clean architecture with well-defined e-commerce domain patterns. Django framework provides modern tooling. Small codebase makes this an ideal early-wave candidate to demonstrate factory capability.

**Risks if Recommendation is Overridden:**
- If RETAINED: Architectural debt accumulates; Django version drift creates security exposure
- If RETIRED: E-commerce functionality must be replaced; potential revenue impact
- If API-WRAPPED: Unnecessary for a system this size with good internal architecture

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable. Low complexity and low risk.

---

### System 8: B2CWeb

| Field | Value |
|-------|-------|
| **System** | B2CWeb |
| **Language** | Java |
| **LOC** | 5–8K |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 2 (Low) |
| **Assigned Wave** | Wave 1 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Small Java e-commerce application with tight coupling as the primary technical debt. At 5–8K LOC, decomposition is tractable within a single sprint. Ideal candidate for demonstrating monolith-to-microservice patterns at small scale.

**Risks if Recommendation is Overridden:**
- If RETAINED: Tight coupling prevents feature evolution; maintenance cost disproportionate to system size
- If RETIRED: E-commerce functionality must be replaced
- If API-WRAPPED: Wrapping a tightly-coupled 5K LOC system adds complexity without addressing root cause

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable. Low complexity and low risk.

---

### System 9: Mezzanine

| Field | Value |
|-------|-------|
| **System** | Mezzanine |
| **Language** | Python |
| **LOC** | 5–10K |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | RETIRE |
| **Risk Score** | 3 (Moderate) |
| **Assigned Wave** | Wave 1 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Mezzanine is a Django-based CMS that has reached effective end-of-life. Upstream maintenance is minimal. Modern alternatives (Wagtail, Strapi, headless CMS platforms) provide superior functionality. Content migration is the primary retirement task.

**Risks if Recommendation is Overridden:**
- If REFACTORED: Refactoring an end-of-life framework yields diminishing returns; upstream community cannot support
- If RETAINED: Security vulnerabilities will not be patched upstream; Django version drift creates exposure
- If API-WRAPPED: Wrapping an EOL CMS preserves the underlying risk without addressing it

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable for content migration. Human review required for selection of replacement CMS platform.

---

### System 10: DFe.NET

| Field | Value |
|-------|-------|
| **System** | DFe.NET |
| **Language** | C# |
| **LOC** | 5K |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | API-WRAP |
| **Risk Score** | 2 (Low) |
| **Assigned Wave** | Wave 1 |
| **Human Approval Status** | **PENDING** |

**Rationale:** DFe.NET provides fiscal invoicing integration with legacy XML/SOAP interfaces. The compliance logic is well-tested and must be preserved exactly. Wrapping behind a modern REST API provides modern consumption patterns while preserving certified fiscal logic.

**Risks if Recommendation is Overridden:**
- If REFACTORED: Risk of introducing errors in certified fiscal computation logic; re-certification may be required
- If RETIRED: Fiscal invoicing is a mandatory compliance function; cannot be decommissioned without replacement
- If RETAINED: Legacy SOAP interfaces increasingly incompatible with modern consumers

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable for API gateway configuration. Human review required for any changes to fiscal computation logic.

---

### System 11: Monolith Enterprise

| Field | Value |
|-------|-------|
| **System** | Monolith Enterprise |
| **Language** | Java |
| **LOC** | 5K+ |
| **Tier** | Tier 2 — Operational |
| **Recommended Disposition** | REFACTOR |
| **Risk Score** | 2 (Low) |
| **Assigned Wave** | Wave 1 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Small Java monolith exhibiting real enterprise patterns (layered architecture, JDBC persistence, servlet-based UI). Ideal candidate for demonstrating microservice decomposition at minimal risk. Serves as a training exercise for the factory team.

**Risks if Recommendation is Overridden:**
- If RETAINED: Monolithic patterns prevent scalability; maintenance overhead disproportionate to value
- If RETIRED: Enterprise functionality must be replaced
- If API-WRAPPED: System is small enough that full refactoring is more cost-effective than wrapping

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is acceptable. Low complexity and low risk.

---

### System 12: CICS Banking Sample

| Field | Value |
|-------|-------|
| **System** | CICS Banking Sample |
| **Language** | COBOL |
| **LOC** | 30K+ |
| **Tier** | Tier 3 — Legacy-Federal |
| **Recommended Disposition** | API-WRAP |
| **Risk Score** | 5 (Critical) |
| **Assigned Wave** | Wave 5 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Real IBM CICS mainframe banking application with COBOL business logic governing financial transactions. COBOL developer scarcity and transaction integrity requirements make refactoring or transpilation unacceptably risky. API-wrapping via a modern gateway (e.g., IBM z/OS Connect, MuleSoft) preserves transaction integrity while enabling modern consumer access.

> **CRITICAL CONSTRAINT:** Transpilation (COBOL-to-Java) is **NOT** recommended in Year 1. Financial transaction logic must be preserved in its original, tested form. Transpilation introduces unacceptable risk of logic corruption in banking computations.

**Risks if Recommendation is Overridden:**
- If REFACTORED/TRANSPILED: Risk of financial calculation errors; potential regulatory exposure; loss of CICS transaction guarantees
- If RETIRED: Banking functionality is mission-critical; cannot decommission without full replacement system
- If RETAINED without wrapping: Mainframe access remains limited to 3270 terminal interface; modern integration blocked

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended. All changes to financial transaction systems require human review, regulatory compliance verification, and explicit authorization.

---

### System 13: NASTRAN-95

| Field | Value |
|-------|-------|
| **System** | NASTRAN-95 |
| **Language** | Fortran |
| **LOC** | 150K+ |
| **Tier** | Tier 3 — Legacy-Federal |
| **Recommended Disposition** | API-WRAP |
| **Risk Score** | 5 (Critical) |
| **Assigned Wave** | Wave 5 |
| **Human Approval Status** | **PENDING** |

**Rationale:** NASA scientific computing system with 150K+ lines of Fortran implementing validated numerical algorithms for structural analysis. These algorithms have been verified over decades of aerospace engineering use. Transpilation or rewriting risks introducing numerical precision errors that could have safety-of-flight implications. API-wrapping provides modern access to proven computational routines.

> **CRITICAL CONSTRAINT:** Transpilation (Fortran-to-C/C++) is **NOT** recommended in Year 1. Numerical algorithms must be preserved in their original, validated form. Even minor floating-point behavior differences between Fortran and target languages can produce incorrect structural analysis results.

**Risks if Recommendation is Overridden:**
- If REFACTORED/TRANSPILED: Numerical precision errors in structural analysis; potential safety-of-flight implications; re-validation cost measured in years
- If RETIRED: No equivalent open-source structural analysis package exists; NASA mission dependency
- If RETAINED without wrapping: Batch-only access limits modern integration; computational resources underutilized

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended. All changes to scientific computing systems with safety-of-flight implications require independent V&V and explicit authorization from NASA program office.

---

### System 14: Apollo-11

| Field | Value |
|-------|-------|
| **System** | Apollo-11 |
| **Language** | Assembly (AGC) |
| **LOC** | 8K+ |
| **Tier** | Tier 3 — Legacy-Federal |
| **Recommended Disposition** | RETAIN |
| **Risk Score** | 4 (High) |
| **Assigned Wave** | Wave 5 |
| **Human Approval Status** | **PENDING** |

**Rationale:** Apollo Guidance Computer (AGC) assembly code from the 1969 lunar mission. This is archival/reference code with historical significance. There is no active operational use case that would benefit from modernization. The system's value lies in its preservation as a historical artifact and educational resource.

> **CRITICAL CONSTRAINT:** Modernization of Apollo-11 code is **NOT** recommended. Transpilation of AGC assembly would destroy the historical and educational value of the artifact. The code should be retained, documented, and preserved.

**Risks if Recommendation is Overridden:**
- If REFACTORED/TRANSPILED: Historical value destroyed; no operational benefit; reputational risk
- If RETIRED: Loss of historical reference; contrary to NASA preservation mandate
- If API-WRAPPED: No operational interface exists to wrap; no consumers to serve

> **AUTONOMOUS ACTION FLAG:** Autonomous execution is **NOT** recommended. Any changes to historical artifacts require review by NASA History Office or equivalent authority.

---

## 4. Disposition Summary

| Disposition | Count | Systems |
|-------------|-------|---------|
| Refactor | 8 | Apache OFBiz, Odoo, Alfresco, Umbraco, Nuxeo, Django Oscar, B2CWeb, Monolith Enterprise |
| API-Wrap | 3 | DFe.NET, CICS Banking Sample, NASTRAN-95 |
| Retire | 2 | CFWheels, Mezzanine |
| Retain | 1 | Apollo-11 |

---

## 5. Autonomous Action Summary

| System | Autonomous Execution Acceptable? | Reason |
|--------|----------------------------------|--------|
| Apache OFBiz | NO | Dependency root; enterprise-scale complexity |
| Odoo | NO | Multi-domain business impact |
| Alfresco Community | NO | CMIS API cross-system dependency |
| Umbraco CMS | YES (standard tasks) | Clear migration path; moderate complexity |
| CFWheels | NO | Retirement requires business stakeholder input |
| Nuxeo | YES (standard tasks) | Human review for API contract changes |
| Django Oscar | YES | Low complexity; low risk |
| B2CWeb | YES | Low complexity; low risk |
| Mezzanine | YES (migration tasks) | Human review for CMS platform selection |
| DFe.NET | YES (gateway config) | Human review for fiscal logic changes |
| Monolith Enterprise | YES | Low complexity; low risk |
| CICS Banking Sample | NO | Financial transactions; regulatory compliance |
| NASTRAN-95 | NO | Safety-of-flight implications; requires IV&V |
| Apollo-11 | NO | Historical artifact; preservation mandate |

**Systems requiring mandatory human review before any action:** 7 of 14 (50%)

---

## 6. Consent Gate Status

> **CONSENT GATE — ALL SYSTEMS**
>
> All 14 disposition recommendations carry a status of **PENDING**. No system shall proceed to execution without explicit written approval from the designated Authorizing Official. This consent gate applies to all disposition categories including Retain (which requires affirmative approval to NOT modernize).

| System | Disposition | Approval Status | Approver |
|--------|-------------|-----------------|----------|
| Apache OFBiz | Refactor | **PENDING** | TBD — Program Leadership |
| Odoo | Refactor | **PENDING** | TBD — Program Leadership |
| Alfresco Community | Refactor | **PENDING** | TBD — Program Leadership |
| Umbraco CMS | Refactor | **PENDING** | TBD — Program Leadership |
| CFWheels | Retire | **PENDING** | TBD — Program Leadership |
| Nuxeo | Refactor | **PENDING** | TBD — Program Leadership |
| Django Oscar | Refactor | **PENDING** | TBD — Program Leadership |
| B2CWeb | Refactor | **PENDING** | TBD — Program Leadership |
| Mezzanine | Retire | **PENDING** | TBD — Program Leadership |
| DFe.NET | API-Wrap | **PENDING** | TBD — Program Leadership |
| Monolith Enterprise | Refactor | **PENDING** | TBD — Program Leadership |
| CICS Banking Sample | API-Wrap | **PENDING** | TBD — Program Leadership + Regulatory |
| NASTRAN-95 | API-Wrap | **PENDING** | TBD — Program Leadership + IV&V Authority |
| Apollo-11 | Retain | **PENDING** | TBD — Program Leadership + NASA History Office |

---

*Prepared by ATLAS Modernization Factory — Wave 0 Discovery*
*All recommendations subject to federal program leadership review and approval*
