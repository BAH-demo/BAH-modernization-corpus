# Consent Gate Workflow for High-Risk Legacy Systems

## ATLAS Engineering Invariant: No Autonomous Production Changes

**Principle:** The ATLAS factory surfaces decisions. Humans make them. Every disposition for a high-risk legacy system must pass through a series of forced consent gates before any execution begins.

**Scope:** This workflow applies to all Tier 3 (Federal/Legacy) systems and any system classified as mission-critical, safety-critical, or compliance-bound.

---

## Workflow Overview

```
 ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
 │   GATE 1     │     │   GATE 2     │     │   GATE 3     │     │   GATE 4     │
 │  Discovery   │────▶│ Disposition  │────▶│    Wave      │────▶│    Pre-      │
 │  Complete    │     │ Recommended  │     │  Assignment  │     │  Execution   │
 │              │     │              │     │  Confirmed   │     │  Checklist   │
 └──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
        │                    │                    │                    │
   HUMAN REVIEW         HUMAN REVIEW         HUMAN REVIEW         HUMAN REVIEW
   & APPROVAL           & APPROVAL           & APPROVAL           & SIGN-OFF
        │                    │                    │                    │
   ┌────▼────┐          ┌────▼────┐          ┌────▼────┐          ┌────▼────┐
   │APPROVED │          │APPROVED │          │APPROVED │          │APPROVED │
   │or BLOCK │          │or BLOCK │          │or BLOCK │          │or BLOCK │
   └─────────┘          └─────────┘          └─────────┘          └─────────┘
```

**Critical Rule:** If ANY gate is blocked, execution STOPS. The factory does not proceed. The block is logged, escalated, and the system remains in its current state until the block is resolved.

---

## Gate 1: Discovery Complete

**Purpose:** Confirm that the ATLAS factory has accurately mapped the legacy system's dependencies, risk profile, and current state before any disposition is recommended.

### Information Surfaced to Human Reviewer

| Artifact | Description |
|----------|-------------|
| System Inventory | Language, LOC count, origin, current runtime environment |
| Dependency Map | All upstream and downstream systems that interact with or depend on this system |
| Risk Classification | Tier assignment (1/2/3), mission-criticality assessment, compliance obligations |
| Technical Debt Profile | Architectural patterns, known defects, testing coverage (or lack thereof) |
| Stakeholder Registry | Teams, agencies, and individuals who own, operate, or consume this system |
| Data Flow Diagram | How data enters, is processed by, and exits the system |

### Approval Requirements

| Field | Value |
|-------|-------|
| **Approver Role** | Technical Lead or System Owner |
| **Approval Method** | Explicit written approval in disposition tracking system |
| **SLA** | 5 business days from discovery completion |
| **Quorum** | At least 1 technical reviewer + 1 business stakeholder |

### If Blocked

1. Factory logs the block reason and timestamp
2. Discovery artifacts are preserved in their current state
3. Block is escalated to Program Manager after 5 business days
4. System remains in "Discovery In Progress" status — no disposition is recommended
5. Re-review is scheduled when block condition is resolved

### Audit Trail Requirements

- [ ] Discovery report generated and stored in version-controlled repository
- [ ] Dependency map reviewed by at least one domain expert
- [ ] Risk tier classification justified with supporting evidence
- [ ] Reviewer identity and timestamp recorded
- [ ] Approval or block decision recorded with rationale

### Current Status for Target Systems

| System | Gate 1 Status | Reviewer | Date |
|--------|--------------|----------|------|
| NASTRAN-95 | **PENDING APPROVAL** | TBD | — |
| Apollo-11 | **PENDING APPROVAL** | TBD | — |

---

## Gate 2: Disposition Recommended

**Purpose:** A human reviews and approves (or rejects) the factory's recommended modernization strategy before any planning or execution begins.

### Information Surfaced to Human Reviewer

| Artifact | Description |
|----------|-------------|
| Disposition Recommendation | Specific strategy (API-Wrap, Transpile, Retire, Replace, Retain) with rationale |
| Risk Comparison Matrix | Side-by-side comparison of all viable strategies with risk, cost, and timeline |
| Semantic Drift Analysis | For any strategy involving code transformation: detailed risk of behavioral changes |
| Effort Estimate | Person-months, cost range, team composition for recommended strategy |
| Alternative Strategies | Why other approaches were considered and rejected |
| Dependency Impact Assessment | What breaks, what migrates, what stays the same under the recommended strategy |
| Rollback Plan Summary | High-level rollback approach if the recommended strategy fails |

### Approval Requirements

| Field | Value |
|-------|-------|
| **Approver Role** | Enterprise Architect or Modernization Program Lead |
| **Approval Method** | Signed disposition decision record (see `disposition-decision-log.md`) |
| **SLA** | 10 business days from recommendation delivery |
| **Quorum** | At least 1 enterprise architect + 1 security reviewer + 1 business owner |
| **Override Authority** | CTO or equivalent — can override recommendation with documented justification |

### If Blocked

1. Factory logs the block reason, timestamp, and blocking party
2. Recommendation is preserved; alternative strategies are queued for review
3. Block is escalated to Enterprise Architecture Review Board after 10 business days
4. If the block is due to insufficient information, factory re-enters Gate 1 to gather additional discovery data
5. System remains in "Disposition Pending" status — no wave assignment occurs

### Audit Trail Requirements

- [ ] Disposition recommendation document generated and versioned
- [ ] Risk comparison matrix reviewed by security team
- [ ] Cost estimate validated by finance/procurement
- [ ] All reviewer identities and timestamps recorded
- [ ] Approval, rejection, or override decision recorded with full rationale
- [ ] If overridden: override justification document signed by override authority

### Current Status for Target Systems

| System | Gate 2 Status | Recommended Disposition | Reviewer | Date |
|--------|--------------|------------------------|----------|------|
| NASTRAN-95 | **PENDING APPROVAL** | API-Wrap | TBD | — |
| Apollo-11 | **PENDING APPROVAL** | API-Wrap | TBD | — |

---

## Gate 3: Wave Assignment Confirmed

**Purpose:** A human approves the specific execution window (wave) in which the approved disposition will be carried out, ensuring no conflicts with other modernization activities, change freezes, or operational constraints.

### Information Surfaced to Human Reviewer

| Artifact | Description |
|----------|-------------|
| Proposed Wave | Specific calendar window for execution (e.g., "Wave 3: Q3 2026") |
| Wave Conflict Analysis | Other systems being modernized in the same wave; resource contention risks |
| Change Freeze Calendar | Known blackout periods (fiscal year-end, audit windows, peak usage) |
| Resource Allocation Plan | Named team members, availability windows, skill requirements |
| Dependency Sequencing | Order of operations — which dependents must migrate first |
| Parallel Execution Risks | What other modernization efforts are in flight and could interfere |

### Approval Requirements

| Field | Value |
|-------|-------|
| **Approver Role** | Program Manager or Release Manager |
| **Approval Method** | Wave assignment confirmation in project management system |
| **SLA** | 5 business days from wave proposal |
| **Quorum** | Program Manager + at least 1 representative from each affected team |

### If Blocked

1. Factory logs the block reason and proposed alternative waves
2. System returns to wave planning queue
3. Block is escalated to Program Director after 5 business days
4. If blocked due to resource constraints, factory proposes reduced-scope execution or alternative wave
5. System remains in "Wave Pending" status — no execution planning begins

### Audit Trail Requirements

- [ ] Wave proposal document generated with conflict analysis
- [ ] Resource allocation confirmed by team leads
- [ ] Change freeze calendar verified against proposed window
- [ ] All reviewer identities and timestamps recorded
- [ ] Wave assignment or deferral decision recorded with rationale

### Current Status for Target Systems

| System | Gate 3 Status | Proposed Wave | Reviewer | Date |
|--------|--------------|---------------|----------|------|
| NASTRAN-95 | **PENDING APPROVAL** | TBD | TBD | — |
| Apollo-11 | **PENDING APPROVAL** | TBD | TBD | — |

---

## Gate 4: Pre-Execution Checklist

**Purpose:** Final human sign-off before any changes are made to production systems or their interfaces. This gate ensures that rollback plans are tested, communication plans are in place, and all stakeholders are prepared.

### Information Surfaced to Human Reviewer

| Artifact | Description |
|----------|-------------|
| Detailed Execution Plan | Step-by-step implementation plan with owners and timelines |
| Rollback Plan (Tested) | Documented and tested rollback procedure with estimated rollback time |
| Communication Plan | Who is notified before, during, and after execution |
| Monitoring & Alerting Setup | Dashboards, alerts, and health checks that will be active during execution |
| Smoke Test Plan | First validation steps to confirm the change is working |
| Incident Response Plan | Who to contact, escalation path, and decision authority during execution |
| Go/No-Go Criteria | Explicit, measurable criteria that determine whether execution proceeds |

### Approval Requirements

| Field | Value |
|-------|-------|
| **Approver Role** | System Owner + Operations Lead |
| **Approval Method** | Signed pre-execution checklist (all items must be checked) |
| **SLA** | 3 business days from checklist delivery |
| **Quorum** | System Owner + Operations Lead + Security Representative |
| **Final Authority** | System Owner has ultimate go/no-go decision |

### If Blocked

1. Factory logs the block reason and specific checklist items that failed
2. Execution is halted — no changes are made
3. Failed checklist items are remediated and re-submitted for review
4. If block persists beyond 2 re-submissions, escalated to Enterprise Architecture Review Board
5. System remains in "Execution Pending" status

### Pre-Execution Checklist Items

| # | Item | Status | Sign-Off |
|---|------|--------|----------|
| 1 | Rollback procedure documented and tested in staging | PENDING | — |
| 2 | All dependent system owners notified of change window | PENDING | — |
| 3 | Monitoring dashboards configured and validated | PENDING | — |
| 4 | Incident response contacts confirmed and available | PENDING | — |
| 5 | Smoke test scripts written and validated in staging | PENDING | — |
| 6 | Data backup completed and verified | PENDING | — |
| 7 | Communication plan distributed to all stakeholders | PENDING | — |
| 8 | Go/no-go criteria reviewed and agreed upon | PENDING | — |
| 9 | Security scan of wrapper code completed | PENDING | — |
| 10 | Performance baseline captured for comparison | PENDING | — |

### Audit Trail Requirements

- [ ] Completed checklist stored in version-controlled repository
- [ ] Each checklist item signed off individually with reviewer identity and timestamp
- [ ] Rollback test results documented with evidence (logs, screenshots)
- [ ] Final go/no-go decision recorded with all approver signatures
- [ ] Post-execution review scheduled and calendar invites sent

### Current Status for Target Systems

| System | Gate 4 Status | Reviewer | Date |
|--------|--------------|----------|------|
| NASTRAN-95 | **PENDING APPROVAL** | TBD | — |
| Apollo-11 | **PENDING APPROVAL** | TBD | — |

---

## Escalation Path

If any gate remains blocked beyond its SLA:

```
Day 0-SLA:    Assigned Reviewer
SLA+1:        Program Manager
SLA+5:        Program Director
SLA+10:       Enterprise Architecture Review Board
SLA+15:       CTO / Agency Head
```

At each escalation level, the escalation recipient receives:
- Original gate artifacts
- Block reason and history
- Recommended resolution options
- Impact assessment of continued delay

---

## Consent Gate Principles

1. **The factory never acts autonomously on high-risk systems.** Every gate requires explicit human approval.
2. **Silence is not consent.** If a gate is not explicitly approved, execution does not proceed.
3. **Blocks are not failures.** A blocked gate means the process is working — risk was identified and escalated.
4. **Audit trails are mandatory.** Every decision, approval, block, and override is permanently recorded.
5. **Rollback is always an option.** No gate is passed unless a tested rollback plan exists.
6. **Process stability over tool autonomy.** The factory optimizes for predictable, auditable outcomes, not speed.

---

*This workflow is enforced by the ATLAS Engineering Factory. Compliance is mandatory for all Tier 3 and mission-critical systems. See `disposition-decision-log.md` for current system statuses.*
