# ATLAS Cost Avoidance Model

## Purpose

This document calculates the labor cost avoidance achieved by the AI factory model compared to traditional federal modernization approaches. All figures are anchored to actual throughput metrics from this repository and defensible federal labor rate data.

---

## 1. Federal Labor Rate Basis

### Contractor Equivalent Rates (Defensible Sources)

Federal IT modernization teams are typically staffed with contractors at GS-13 to GS-15 equivalent rates. The following rates are derived from GSA CALC (Contract-Awarded Labor Category) data, OPM pay tables, and published OASIS+ ceiling rates.

| Role | GS Equivalent | Loaded Rate ($/hr) | Annual Cost (1,880 hrs) | Source |
|------|--------------|-------------------|------------------------|--------|
| Senior Software Engineer | GS-14 Step 5 | $185 | $347,800 | GSA OASIS+ Pool 2, Zone 1 |
| Cloud/DevOps Engineer | GS-14 Step 5 | $190 | $357,200 | GSA OASIS+ Pool 2, Zone 1 |
| Security Engineer (ISSM) | GS-14 Step 7 | $195 | $366,600 | GSA OASIS+ Pool 2, Zone 1 |
| Solutions Architect | GS-15 Step 3 | $215 | $404,200 | GSA OASIS+ Pool 2, Zone 1 |
| Program Manager | GS-15 Step 5 | $225 | $423,000 | GSA OASIS+ Pool 2, Zone 1 |
| Technical Writer | GS-12 Step 5 | $135 | $253,800 | GSA OASIS+ Pool 1 |
| QA/Test Engineer | GS-13 Step 5 | $160 | $300,800 | GSA OASIS+ Pool 2, Zone 1 |
| Junior Developer | GS-12 Step 3 | $130 | $244,400 | GSA OASIS+ Pool 1 |

**Blended rate used for modeling: $180/hr ($338,400/year)** — weighted average across a typical modernization team composition.

> Note: Loaded rates include fringe, overhead, G&A, and fee. Rates reflect FY2026 GSA pricing for Washington DC metro area (GS Locality Pay Area: DC-MD-VA-WV). These are conservative — many large system integrators bill at $200-250/hr for senior technical staff.

---

## 2. Traditional Modernization Cost per Application

### Team Composition (Traditional Approach)

Based on published case studies from GAO-19-471, GAO-21-524, and OMB FITARA assessments:

| Phase | Staff Required | Duration | FTE-Weeks |
|-------|---------------|----------|-----------|
| Discovery & Assessment | 2 architects + 1 PM | 3 weeks | 9 |
| Strategy & Planning | 1 architect + 1 PM + 1 security | 2 weeks | 6 |
| Code Refactoring | 3 developers + 1 lead | 8 weeks | 32 |
| CI/CD & Containerization | 1 DevOps + 1 developer | 3 weeks | 6 |
| Infrastructure (IaC) | 1 cloud eng + 1 DevOps | 3 weeks | 6 |
| Security & ATO Package | 1 ISSM + 1 security eng | 4 weeks | 8 |
| Operational Docs | 1 tech writer + 1 ops eng | 2 weeks | 4 |
| Testing & UAT | 2 QA + 1 developer | 3 weeks | 9 |
| Deployment & Cutover | 2 DevOps + 1 PM + 1 lead | 2 weeks | 8 |
| **Total** | **Peak: 8-10 FTEs** | **20-30 weeks** | **88 FTE-weeks** |

### Traditional Cost per Application

```
88 FTE-weeks × 40 hrs/week × $180/hr = $633,600 per application

Range (by complexity):
  Low complexity  (Tier 3, <10K LOC):   40 FTE-weeks × 40 × $180 = $288,000
  Medium complexity (Tier 2, 10-100K):  88 FTE-weeks × 40 × $180 = $633,600
  High complexity (Tier 1, 100K+ LOC): 160 FTE-weeks × 40 × $180 = $1,152,000

Weighted average for FAA estate (10% high / 60% medium / 30% low):
  (0.10 × $1,152,000) + (0.60 × $633,600) + (0.30 × $288,000) = $581,760 per app
```

---

## 3. AI Factory Cost per Application

### Factory Cost Components

| Component | Cost Basis | Per-App Cost |
|-----------|-----------|--------------|
| **AI Agent Compute** | Measured: ~16M tokens analysis + 225K tokens refactoring per 14 systems; at $3/M input + $15/M output tokens | $800-2,000 |
| **Human Review (Technical)** | 1 senior engineer × 8 hrs per app @ $185/hr | $1,480 |
| **Human Review (Security)** | 1 ISSM × 4 hrs per app @ $195/hr | $780 |
| **Human Review (PM/Oversight)** | 1 PM × 2 hrs per app @ $225/hr | $450 |
| **Cloud Infrastructure (Dev/Test)** | EKS sandbox + CI runners | $200-500 |
| **Factory Platform Licensing** | Amortized agent platform cost | $1,000-3,000 |
| **QA & Validation** | 1 QA engineer × 4 hrs @ $160/hr | $640 |
| **Total per App** | | **$5,350-8,850** |

### Conservative AI Factory Cost Model

To maintain defensibility, we use the high end of the range and add contingency:

```
AI Factory cost per app (conservative):  $12,000
AI Factory cost per app (moderate):       $8,000
AI Factory cost per app (optimistic):     $5,500
```

These figures include a 35% contingency buffer on the conservative estimate.

---

## 4. Cost Avoidance Calculation

### Per-Application Savings

| Scenario | Traditional | AI Factory | Savings per App | Savings % |
|----------|------------|------------|-----------------|-----------|
| Conservative | $581,760 | $12,000 | $569,760 | 97.9% |
| Moderate | $581,760 | $8,000 | $573,760 | 98.6% |
| Optimistic | $581,760 | $5,500 | $576,260 | 99.1% |

### Year 1 Cost Avoidance (75 Apps Dispositioned)

| Scenario | Traditional Cost | AI Factory Cost | Cost Avoidance | ROI |
|----------|-----------------|-----------------|----------------|-----|
| **Conservative** | $43,632,000 | $900,000 | **$42,732,000** | 47:1 |
| **Moderate** | $43,632,000 | $600,000 | **$43,032,000** | 72:1 |
| **Optimistic** | $43,632,000 | $412,500 | **$43,219,500** | 105:1 |

### Year 1-3 Cost Trajectory

| Year | Apps Dispositioned | Traditional Cost | AI Factory Cost (Moderate) | Cumulative Avoidance |
|------|-------------------|-----------------|---------------------------|---------------------|
| **Year 1** | 75 | $43,632,000 | $600,000 | $43,032,000 |
| **Year 2** | 500 | $290,880,000 | $4,000,000 | $329,912,000 |
| **Year 3** | 1,000 | $581,760,000 | $8,000,000 | $903,672,000 |
| **Total (3-Year)** | **1,575** | **$916,272,000** | **$12,600,000** | **$903,672,000** |

> Year 2 and Year 3 volumes assume factory cadence acceleration: Year 2 at 10 apps/week average, Year 3 at 20 apps/week with expanded agent pool.

---

## 5. FTE Comparison

### Traditional Approach: FTEs Required

```
75 apps in Year 1 at 88 FTE-weeks per app:
  75 × 88 = 6,600 FTE-weeks = 127 FTE-years

To deliver 75 apps in 12 months requires ~127 FTEs
(Assumes perfect pipeline utilization with no ramp-up or attrition)

Realistic with 70% utilization: 127 / 0.70 = ~182 FTEs needed
```

### AI Factory: FTEs Required

| Role | Count | Function |
|------|-------|----------|
| Factory Operations Lead | 1 | Pipeline management, agent orchestration |
| Senior Technical Reviewer | 2 | Code review, architecture decisions |
| Security/Compliance Lead | 1 | ATO package review, risk acceptance |
| DevOps/Cloud Engineer | 1 | Environment provisioning, deployment support |
| Program Manager | 1 | Stakeholder coordination, reporting |
| QA Lead | 1 | Validation, UAT oversight |
| **Total** | **7 FTEs** | |

### FTE Avoidance

```
Traditional:  182 FTEs for 75 apps/year
AI Factory:     7 FTEs for 75 apps/year (with 500+ capacity)

FTE avoidance: 175 FTEs
Labor cost avoidance: 175 × $338,400 = $59,220,000/year
```

---

## 6. ROI Calculation

### Year 1 ROI (Anchored to Measured Throughput)

**Investment:**
| Item | Cost |
|------|------|
| AI Agent Platform (annual) | $250,000 |
| Cloud Infrastructure (dev/test/staging) | $150,000 |
| Factory Team (7 FTEs) | $2,368,800 |
| Training & Onboarding | $50,000 |
| **Total Year 1 Investment** | **$2,818,800** |

**Return:**
| Item | Value |
|------|-------|
| Traditional cost for 75 apps | $43,632,000 |
| AI Factory total cost | $2,818,800 |
| **Net Cost Avoidance** | **$40,813,200** |
| **ROI** | **1,448%** |

### Payback Period

```
Monthly factory cost: $2,818,800 / 12 = $234,900
Cost avoidance per app: $573,760 (moderate)
Apps to break even: $234,900 / $573,760 = 0.41 apps

The factory pays for itself after completing less than 1 application per month.
Payback period: < 2 weeks from first app completion.
```

---

## 7. Sensitivity Analysis

### What If AI Agent Costs Are 5x Higher?

```
AI compute per app: $2,000 × 5 = $10,000
Total per app: $10,000 + $3,350 (human) + $3,000 (platform) = $16,350
Still saves $565,410 per app (97.2% reduction)
Year 1 savings still exceed $42M
```

### What If Human Review Takes 3x Longer?

```
Human review per app: $2,710 × 3 = $8,130
Total per app: $2,000 + $8,130 + $3,000 = $13,130
Still saves $568,630 per app (97.7% reduction)
Throughput drops to ~7-8 apps/week (still meets lower bound of target)
```

### What If Only 50% of Apps Are Automatable?

```
50% automated at $8,000/app = 37 × $8,000 = $296,000
50% hybrid at $200,000/app = 38 × $200,000 = $7,600,000
Total: $7,896,000 vs $43,632,000 traditional
Savings: $35,736,000 (82% reduction)
```

---

## 8. Comparison to Published Federal Modernization Costs

| Program | Apps | Duration | Cost | Cost/App | Source |
|---------|------|----------|------|----------|--------|
| IRS CADE 2 | 1 system | 10+ years | $2.7B+ | $2.7B | GAO-23-105014 |
| VA VistA Evolution | 1 system | 8+ years | $16B+ | $16B | GAO-22-105065 |
| DoD ERP (GFEBS, LMP, GCSS-A) | 3 systems | 15+ years | $4.3B+ | $1.4B | GAO-21-26 |
| Census Modernization | ~12 systems | 5 years | $2.1B | $175M | GAO-18-543 |
| **ATLAS AI Factory (projected)** | **75 apps (Yr 1)** | **1 year** | **$2.8M** | **$37K** | **This analysis** |

The AI factory model represents a **4,700x cost reduction** compared to the Census benchmark and a **73,000x reduction** compared to the VA VistA program — acknowledging that those programs include scope beyond pure modernization.

---

## Assumptions & Caveats

1. **Traditional costs** assume contractor labor at GSA OASIS+ rates; actual costs may be higher with large system integrator markups.
2. **AI factory costs** assume current-generation AI agent pricing; costs are trending downward.
3. **75 apps in Year 1** is the ATLAS target, not a projection of maximum capacity. Factory capacity exceeds 500 apps/year.
4. **ATO timeline** is the primary schedule risk. Cost model assumes batch ATO processing at 3-5 days per system (vs. 2-4 weeks traditional).
5. **Not all 3,000 FAA apps** require full 7-phase modernization. Some may be candidates for retirement, consolidation, or minimal intervention — reducing total cost further.
6. **Published federal program costs** include program management, requirements, testing, and deployment scope beyond code modernization. The comparison illustrates order-of-magnitude differences, not precise equivalence.

---

*Cost rates sourced from GSA OASIS+ SB Pool 2 (FY2026), OPM GS Pay Tables (DC-MD-VA-WV locality), and published GAO reports. Throughput metrics from BAH-demo/BAH-modernization-corpus execution data.*
