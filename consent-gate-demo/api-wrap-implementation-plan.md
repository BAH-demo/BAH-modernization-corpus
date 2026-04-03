# API-Wrap Implementation Plan

## NASTRAN-95 and Apollo-11: Year 1 Modernization via Strangler Fig Pattern

**Status:** DRAFT — AWAITING HUMAN APPROVAL (see `consent-gate-workflow.md`, Gate 2)
**Plan Date:** 2026-04-03
**Plan Author:** ATLAS Engineering Factory (Automated)
**Approver:** TBD

---

## 1. Executive Summary

This plan details the technical implementation of API wrappers for NASTRAN-95 (Fortran) and Apollo-11 (AGC Assembly) using the **Strangler Fig** pattern. The wrapper layer exposes existing legacy functionality through modern REST/gRPC interfaces without modifying any legacy source code.

**Year 1 Goal:** Both systems are accessible via modern APIs. Legacy runtimes continue to operate unchanged.
**Year 2 Goal:** All dependents have migrated to the API layer. Legacy runtime environments can be retired.

---

## 2. NASTRAN-95 API-Wrap Implementation

### 2.1 Interface Design: REST Endpoints

The NASTRAN-95 wrapper exposes structural analysis capabilities through a RESTful API. The legacy system operates in batch mode (input file → computation → output file), so the API models this as asynchronous job submission.

#### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/analyses` | Submit a new structural analysis job |
| `GET` | `/api/v1/analyses/{id}` | Retrieve job status and results |
| `GET` | `/api/v1/analyses/{id}/status` | Poll job execution status |
| `GET` | `/api/v1/analyses/{id}/results` | Download analysis results (JSON or original F06 format) |
| `DELETE` | `/api/v1/analyses/{id}` | Cancel a running or queued analysis |
| `GET` | `/api/v1/analyses` | List all analyses (with pagination and filtering) |
| `GET` | `/api/v1/health` | Health check — confirms NASTRAN-95 runtime is available |
| `GET` | `/api/v1/capabilities` | Enumerate available solution types and element libraries |

#### Request/Response Examples

**Submit Analysis:**
```json
POST /api/v1/analyses
Content-Type: application/json

{
  "name": "bridge-stress-analysis-v3",
  "input_format": "bdf",
  "input_data": "<Base64-encoded BDF input deck>",
  "solution_type": "SOL101",
  "parameters": {
    "max_iterations": 500,
    "convergence_tolerance": 1e-6
  },
  "callback_url": "https://consumer.example.com/webhooks/nastran",
  "priority": "normal"
}
```

**Response:**
```json
{
  "id": "analysis-a1b2c3d4",
  "status": "queued",
  "submitted_at": "2026-04-03T16:30:00Z",
  "estimated_duration_seconds": 3600,
  "links": {
    "self": "/api/v1/analyses/analysis-a1b2c3d4",
    "status": "/api/v1/analyses/analysis-a1b2c3d4/status",
    "results": "/api/v1/analyses/analysis-a1b2c3d4/results",
    "cancel": "/api/v1/analyses/analysis-a1b2c3d4"
  }
}
```

**Retrieve Results:**
```json
GET /api/v1/analyses/analysis-a1b2c3d4/results
Accept: application/json

{
  "id": "analysis-a1b2c3d4",
  "status": "completed",
  "completed_at": "2026-04-03T17:15:00Z",
  "results": {
    "max_stress": 245.7,
    "max_displacement": 0.0034,
    "convergence_achieved": true,
    "iterations": 127,
    "warnings": []
  },
  "output_files": {
    "f06_report": "/api/v1/analyses/analysis-a1b2c3d4/results/f06",
    "punch_file": "/api/v1/analyses/analysis-a1b2c3d4/results/pch"
  }
}
```

### 2.2 Wrapper Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      API Gateway (Kong/Envoy)                  │
│   Rate limiting, authentication, TLS termination               │
└───────────────────────────┬────────────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────────────┐
│                   NASTRAN Wrapper Service                       │
│   Language: Python (FastAPI) or Go                              │
│                                                                 │
│   ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│   │ Input        │  │ Job Queue    │  │ Output               │ │
│   │ Transformer  │  │ (Redis/SQS)  │  │ Normalizer           │ │
│   │              │  │              │  │                      │ │
│   │ JSON → BDF   │  │ Manages      │  │ F06 → JSON           │ │
│   │ validation   │  │ execution    │  │ structured results   │ │
│   └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘ │
│          │                 │                      │             │
└──────────┼─────────────────┼──────────────────────┼─────────────┘
           │                 │                      │
┌──────────▼─────────────────▼──────────────────────▼─────────────┐
│                    Execution Sandbox                             │
│   - Containerized NASTRAN-95 Fortran runtime                    │
│   - Isolated filesystem for each job                            │
│   - Resource limits (CPU, memory, wall-clock time)              │
│   - Stdout/stderr capture for diagnostics                       │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  NASTRAN-95 Binary (Unmodified Fortran, compiled as-is)  │  │
│   └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 2.3 Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Async job model | Yes | NASTRAN analyses run minutes to hours; synchronous HTTP is inappropriate |
| Input format | Accept JSON with BDF passthrough | JSON for new consumers; raw BDF for backward compatibility |
| Output format | JSON + original F06 | JSON for modern consumers; F06 for legacy pipeline compatibility |
| Execution isolation | Container per job | Prevents resource contention; enables parallel execution |
| Legacy binary | Unmodified | Zero risk of behavioral changes; compiled from original Fortran source |

---

## 3. Apollo-11 API-Wrap Implementation

### 3.1 Interface Design: REST Endpoints

The Apollo-11 wrapper provides programmatic access to guidance algorithms, mission data, and source code analysis. Since Apollo-11 is primarily a reference/research system, the API emphasizes query and simulation capabilities.

#### Core Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/modules` | List all Apollo-11 software modules (Comanche, Luminary, etc.) |
| `GET` | `/api/v1/modules/{name}` | Retrieve module source code and metadata |
| `GET` | `/api/v1/modules/{name}/routines` | List routines/subroutines within a module |
| `GET` | `/api/v1/routines/{name}` | Retrieve specific routine with annotations |
| `POST` | `/api/v1/simulations` | Run a guidance algorithm simulation with custom parameters |
| `GET` | `/api/v1/simulations/{id}` | Retrieve simulation results |
| `GET` | `/api/v1/constants` | List all mission constants and their values |
| `GET` | `/api/v1/search` | Full-text search across source code and comments |
| `GET` | `/api/v1/health` | Health check |

#### Request/Response Examples

**Query Module:**
```json
GET /api/v1/modules/luminary

{
  "name": "Luminary",
  "description": "Lunar Module Apollo Guidance Computer software",
  "version": "Luminary099",
  "files": 82,
  "total_lines": 4827,
  "subsystems": [
    "EXECUTIVE",
    "INTERPRETER",
    "NAVIGATION",
    "DIGITAL_AUTOPILOT",
    "RADAR_INTERFACE"
  ],
  "links": {
    "self": "/api/v1/modules/luminary",
    "routines": "/api/v1/modules/luminary/routines",
    "source": "/api/v1/modules/luminary/source"
  }
}
```

**Run Simulation:**
```json
POST /api/v1/simulations
Content-Type: application/json

{
  "algorithm": "powered_descent_guidance",
  "parameters": {
    "initial_altitude_ft": 50000,
    "initial_velocity_fps": 5560,
    "target_altitude_ft": 0,
    "thrust_to_weight_ratio": 2.13
  },
  "output_format": "trajectory"
}
```

**Response:**
```json
{
  "id": "sim-e5f6g7h8",
  "status": "completed",
  "algorithm": "powered_descent_guidance",
  "results": {
    "trajectory_points": 1247,
    "final_velocity_fps": 3.2,
    "fuel_remaining_pct": 5.8,
    "guidance_alarms": [],
    "duration_seconds": 720
  },
  "links": {
    "trajectory_data": "/api/v1/simulations/sim-e5f6g7h8/trajectory",
    "visualization": "/api/v1/simulations/sim-e5f6g7h8/viz"
  }
}
```

### 3.2 Wrapper Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      API Gateway (Kong/Envoy)                  │
│   Rate limiting, authentication, TLS termination               │
└───────────────────────────┬────────────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────────────┐
│                   Apollo-11 Wrapper Service                     │
│   Language: Python (FastAPI) or Go                              │
│                                                                 │
│   ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐ │
│   │ Source Code  │  │ Simulation   │  │ Search               │ │
│   │ Index        │  │ Engine       │  │ Engine               │ │
│   │              │  │              │  │                      │ │
│   │ Parsed AGC   │  │ AGC emulator │  │ Full-text index      │ │
│   │ modules      │  │ integration  │  │ of source + comments │ │
│   └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘ │
│          │                 │                      │             │
└──────────┼─────────────────┼──────────────────────┼─────────────┘
           │                 │                      │
┌──────────▼─────────────────▼──────────────────────▼─────────────┐
│                    Data Layer                                    │
│   - Original AGC assembly source files (read-only mount)        │
│   - Parsed module/routine database (PostgreSQL or SQLite)       │
│   - AGC emulator (yaAGC) for simulation capabilities            │
│   - Search index (Elasticsearch or Meilisearch)                 │
│                                                                  │
│   ┌──────────────────────────────────────────────────────────┐  │
│   │  Apollo-11 Source Repository (Unmodified, Read-Only)      │  │
│   └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Strangler Fig Pattern Implementation Timeline

The Strangler Fig pattern incrementally routes traffic from direct legacy system access to the new API layer until the legacy interface is fully replaced.

### Phase 1: Foundation (Months 1-2)

| Week | NASTRAN-95 | Apollo-11 |
|------|-----------|-----------|
| 1-2 | Deploy containerized NASTRAN-95 runtime | Parse and index all AGC source modules |
| 3-4 | Implement input transformer (JSON → BDF) | Implement source code query endpoints |
| 5-6 | Implement output normalizer (F06 → JSON) | Integrate yaAGC emulator for simulations |
| 7-8 | Deploy job queue and async execution engine | Deploy search index and query API |

**Milestone:** Both wrappers deployed in staging environment. Core endpoints functional.

### Phase 2: Parallel Operation (Months 3-4)

| Week | NASTRAN-95 | Apollo-11 |
|------|-----------|-----------|
| 9-10 | Shadow mode: API accepts requests, results compared to direct execution | Shadow mode: API queries validated against direct file access |
| 11-12 | Onboard first consumer to API (read-only, non-critical workflow) | Onboard first consumer (educational platform or research tool) |
| 13-14 | Expand to 2-3 consumers; monitor performance and accuracy | Expand to additional consumers; validate simulation accuracy |
| 15-16 | Full API feature parity with direct access patterns | Full API feature parity with file-based access |

**Milestone:** Multiple consumers operating through API layer. Shadow mode confirms behavioral equivalence.

### Phase 3: Migration (Months 5-8)

| Activity | NASTRAN-95 | Apollo-11 |
|----------|-----------|-----------|
| Consumer migration | Migrate remaining consumers one at a time | Migrate remaining consumers one at a time |
| Legacy interface deprecation | Mark direct file access as deprecated | Mark direct repository access as deprecated |
| Monitoring | Track API vs. direct access ratios | Track API vs. direct access ratios |
| Documentation | Complete API documentation and migration guides | Complete API documentation and migration guides |

**Milestone:** >80% of traffic routed through API layer.

### Phase 4: Legacy Retirement Preparation (Months 9-12)

| Activity | NASTRAN-95 | Apollo-11 |
|----------|-----------|-----------|
| Final migration | Last consumers migrated to API | Last consumers migrated to API |
| Legacy access restriction | Direct access moved to read-only | Direct access moved to read-only |
| Retirement planning | Document runtime retirement procedure | Document archive-only access procedure |
| Year 2 handoff | Retirement execution plan delivered for Gate 4 approval | Retirement execution plan delivered for Gate 4 approval |

**Milestone:** Year 1 complete. All consumers on API. Legacy runtime retirement planned for Year 2.

### Strangler Fig Progression

```
Month 1-2:   [████░░░░░░░░░░░░░░░░]  10% API / 90% Direct
Month 3-4:   [████████░░░░░░░░░░░░]  30% API / 70% Direct
Month 5-6:   [████████████░░░░░░░░]  60% API / 40% Direct
Month 7-8:   [████████████████░░░░]  80% API / 20% Direct
Month 9-10:  [██████████████████░░]  95% API / 5% Direct
Month 11-12: [████████████████████] 100% API / 0% Direct
```

---

## 5. Rollback Plan

### Rollback Triggers

| Trigger | Threshold | Action |
|---------|-----------|--------|
| API error rate exceeds baseline | >5% error rate sustained for 15 minutes | Automatic traffic reroute to direct access |
| Numerical result divergence detected | Any deviation >1e-10 from expected output | Immediate halt; investigation required |
| Consumer reports incorrect results | Any confirmed report | Halt API for affected consumer; revert to direct access |
| Wrapper service unresponsive | Health check fails for >60 seconds | Circuit breaker activates; traffic reroutes automatically |
| Performance degradation | Latency >2x baseline for 10 minutes | Alert; manual review; optional reroute |

### Rollback Procedure

**Step 1: Detect** (Automated)
- Monitoring detects trigger condition
- Alert dispatched to on-call engineer
- Circuit breaker activates for affected endpoint

**Step 2: Assess** (Human Decision — 15 min SLA)
- On-call engineer reviews alert context
- Determines scope: single consumer, single endpoint, or full rollback
- Decision logged in incident management system

**Step 3: Execute Rollback** (Automated with Human Approval)
```
1. Route affected traffic to direct legacy access path
2. Preserve all in-flight API requests (complete or cancel gracefully)
3. Disable new API requests for affected scope
4. Verify direct access is functioning correctly
5. Notify affected consumers of rollback
```

**Step 4: Investigate** (Human-Led)
- Root cause analysis within 48 hours
- Fix developed and tested in staging
- Re-deployment requires Gate 4 re-approval

### Rollback Time Estimates

| Scope | Estimated Rollback Time | Data Loss Risk |
|-------|------------------------|----------------|
| Single consumer reroute | <5 minutes | None — in-flight jobs complete via direct path |
| Single endpoint disable | <2 minutes | None — other endpoints continue operating |
| Full wrapper rollback | <15 minutes | None — legacy system was never modified |
| Legacy runtime issue (unrelated) | N/A — wrapper rollback cannot fix | Escalate to legacy system support |

### Why Rollback Is Safe

The API-wrap strategy guarantees safe rollback because:
1. **The legacy system is never modified.** It continues running exactly as before.
2. **The wrapper is an independent layer.** Removing it restores the previous access pattern.
3. **No data migration occurs.** Data stays in its original format and location.
4. **Consumer rollback is independent.** Each consumer can individually revert to direct access.

---

## 6. Success Criteria for Year 1 Wrap Completion

### NASTRAN-95

| Criterion | Metric | Target |
|-----------|--------|--------|
| API availability | Uptime percentage | ≥99.5% |
| Result accuracy | Deviation from direct execution | 0 (bit-identical results) |
| Consumer migration | % of consumers on API | ≥80% |
| Latency overhead | API latency vs. direct submission | <10% overhead |
| Job throughput | Concurrent analyses supported | ≥10 simultaneous jobs |
| Documentation | API documentation completeness | 100% of endpoints documented |
| Rollback tested | Rollback procedure validated | At least 2 successful drills |

### Apollo-11

| Criterion | Metric | Target |
|-----------|--------|--------|
| API availability | Uptime percentage | ≥99.5% |
| Source fidelity | API-served source matches repository | 100% byte-identical |
| Simulation accuracy | Emulator results match known baselines | ≤0.01% deviation |
| Consumer migration | % of consumers on API | ≥80% |
| Search completeness | Searchable source coverage | 100% of modules indexed |
| Query performance | Search response time | <500ms for 95th percentile |
| Documentation | API documentation completeness | 100% of endpoints documented |

### Combined Program Success

| Criterion | Target |
|-----------|--------|
| Both wrappers deployed and operational | By Month 4 |
| First consumers migrated | By Month 5 |
| 80% traffic through API | By Month 10 |
| Rollback plans tested | At least 2 drills per system |
| Zero data loss incidents | 0 incidents |
| Zero unplanned legacy modifications | 0 modifications to Fortran or Assembly source |
| All consent gates passed with human approval | 4 gates per system, 8 total |
| Year 2 retirement plan drafted | By Month 12 |

---

## 7. Technology Stack (Recommended)

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| API Framework | FastAPI (Python) or Gin (Go) | High performance, async support, auto-generated OpenAPI docs |
| API Gateway | Kong or Envoy | Rate limiting, auth, TLS, observability |
| Job Queue | Redis + Celery or AWS SQS | Reliable async job management |
| Container Runtime | Docker + Kubernetes | Isolation, scaling, resource management |
| Database | PostgreSQL | Job metadata, audit logs, module index |
| Search | Meilisearch or Elasticsearch | Full-text search for Apollo-11 source |
| Monitoring | Prometheus + Grafana | Metrics, alerting, dashboards |
| Tracing | OpenTelemetry + Jaeger | Distributed tracing across wrapper layers |
| CI/CD | GitHub Actions | Automated testing and deployment of wrapper code |

---

## 8. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| NASTRAN-95 Fortran compiler unavailable on modern OS | Medium | High | Pre-build container image with validated compiler; test on multiple base images |
| AGC emulator (yaAGC) accuracy limitations | Low | Medium | Validate against published mission data; document known limitations |
| Consumer resistance to API migration | Medium | Medium | Provide backward-compatible output formats; offer migration support |
| Wrapper introduces latency unacceptable for batch workflows | Low | Medium | Benchmark early; optimize I/O path; offer bulk submission endpoint |
| Team lacks Fortran/AGC domain expertise | Medium | High | Engage domain consultants during Phase 1; document all domain decisions |
| Scope creep — requests to add new functionality beyond wrapping | High | Medium | Strict scope control through consent gates; new features require separate disposition |

---

*This implementation plan is a factory-generated draft. Execution requires human approval through the Consent Gate process (see `consent-gate-workflow.md`). No implementation work begins until Gate 2 (Disposition Recommended) is approved by a named human approver.*
