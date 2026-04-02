# Production Cutover Master Checklist

## Federal Modernization Portfolio - All 13 Systems

---

## 1. Cutover Overview

This checklist covers the production cutover for migrating from legacy systems to their modernized replacements. It is designed to be executed sequentially with explicit go/no-go gates.

### 1.1 Cutover Timeline Template

```
T-30 days: Final preparations begin
T-14 days: Freeze legacy system changes
T-7 days:  Final rehearsal cutover in staging
T-3 days:  Pre-cutover readiness review
T-1 day:   Final data sync initiated
T-0:       CUTOVER DAY
T+1 day:   Intensive monitoring begins
T+7 days:  Stabilization review
T+30 days: Legacy decommission eligible
```

---

## 2. Pre-Cutover Phase (T-30 to T-1)

### 2.1 Planning and Approval (T-30 days)

- [ ] Cutover plan reviewed and approved by all stakeholders
- [ ] Cutover window scheduled and communicated
- [ ] CAB approval obtained for production change
- [ ] Rollback plan reviewed and approved
- [ ] Communication plan prepared (users, management, vendors)
- [ ] War room / command center established
- [ ] On-call schedule confirmed for cutover window + 7 days

### 2.2 Technical Readiness (T-14 days)

#### Infrastructure

- [ ] Target environment capacity validated (load tested)
- [ ] Network routes and firewall rules configured
- [ ] DNS records prepared (low TTL set 48 hours before)
- [ ] Load balancer configuration staged
- [ ] SSL certificates installed and validated
- [ ] Monitoring and alerting configured for new system
- [ ] Backup procedures tested for new system
- [ ] Disaster recovery tested for new system

#### Application Readiness

| System | Build Verified | Config Staged | Smoke Tests Pass |
|--------|---------------|---------------|------------------|
| Apache OFBiz | [ ] | [ ] | [ ] |
| Alfresco Community | [ ] | [ ] | [ ] |
| Nuxeo | [ ] | [ ] | [ ] |
| B2CWeb | [ ] | [ ] | [ ] |
| Monolith Enterprise | [ ] | [ ] | [ ] |
| Odoo | [ ] | [ ] | [ ] |
| Django Oscar | [ ] | [ ] | [ ] |
| Mezzanine | [ ] | [ ] | [ ] |
| Umbraco CMS | [ ] | [ ] | [ ] |
| DFe-NET | [ ] | [ ] | [ ] |
| CFWheels | [ ] | [ ] | [ ] |
| NASTRAN-95 | [ ] | [ ] | [ ] |
| Apollo-11 | [ ] | [ ] | [ ] |

#### Data Migration

- [ ] Full data migration rehearsal completed in staging
- [ ] Data migration scripts tested and timed
- [ ] Data validation queries prepared
- [ ] Delta sync mechanism tested
- [ ] Estimated migration duration documented

### 2.3 Security and Compliance (T-7 days)

- [ ] ATO (Authority to Operate) in place for new system
- [ ] Security scan (DAST/SAST) completed with no critical findings
- [ ] Penetration test completed (if required)
- [ ] Privacy Impact Assessment (PIA) updated
- [ ] System Security Plan (SSP) updated
- [ ] POA&M items documented and accepted
- [ ] ISSO sign-off obtained
- [ ] FedRAMP continuous monitoring configured

### 2.4 Rehearsal Cutover (T-7 days)

- [ ] Full cutover rehearsal executed in staging
- [ ] Actual timing recorded for each step
- [ ] Issues from rehearsal documented and resolved
- [ ] Rollback rehearsal executed successfully
- [ ] Updated cutover timing based on rehearsal results

### 2.5 Final Readiness Review (T-3 days)

- [ ] Go/No-Go meeting held
- [ ] All blockers resolved
- [ ] All team members confirmed available
- [ ] Vendor support confirmed on standby
- [ ] Executive sponsor sign-off obtained

---

## 3. Cutover Day (T-0)

### 3.1 Pre-Cutover (T-0, Start of Window)

| Time | Step | Responsible | Status |
|------|------|-------------|--------|
| T+0:00 | Open war room / communication channel | Cutover Lead | [ ] |
| T+0:05 | Verify all team members present | Cutover Lead | [ ] |
| T+0:10 | Confirm go/no-go with stakeholders | Cutover Lead | [ ] |
| T+0:15 | Send maintenance notification to users | Communications | [ ] |
| T+0:20 | Enable maintenance pages on legacy systems | Operations | [ ] |

### 3.2 Legacy System Freeze

| Time | Step | Responsible | Status |
|------|------|-------------|--------|
| T+0:30 | Set legacy systems to read-only mode | Operations | [ ] |
| T+0:35 | Stop legacy batch jobs and schedulers | Operations | [ ] |
| T+0:40 | Verify no active write transactions | DBA | [ ] |
| T+0:45 | Take final legacy database backup | DBA | [ ] |
| T+0:50 | Verify backup integrity (checksum) | DBA | [ ] |

### 3.3 Data Migration

| Time | Step | Responsible | Status |
|------|------|-------------|--------|
| T+1:00 | Start final delta data sync | DBA | [ ] |
| T+1:30 | Run data validation queries (pre-migration checks) | DBA | [ ] |
| T+2:00 | Execute data migration scripts | DBA | [ ] |
| T+3:00 | Run post-migration validation queries | DBA | [ ] |
| T+3:30 | Verify row counts match | DBA | [ ] |
| T+3:45 | Verify data integrity (checksums, balances) | DBA | [ ] |
| T+4:00 | **GO/NO-GO: Data migration verification** | Cutover Lead | [ ] |

### 3.4 Application Cutover

| Time | Step | Responsible | Status |
|------|------|-------------|--------|
| T+4:00 | Start modernized applications | Operations | [ ] |
| T+4:15 | Run health checks on all systems | Operations | [ ] |
| T+4:30 | Execute smoke test suite | QA | [ ] |
| T+4:45 | Verify integration points | Operations | [ ] |
| T+5:00 | **GO/NO-GO: Application verification** | Cutover Lead | [ ] |

### 3.5 Traffic Cutover

| Time | Step | Responsible | Status |
|------|------|-------------|--------|
| T+5:00 | Update load balancer to route to new system | Network | [ ] |
| T+5:10 | Update DNS records | Network | [ ] |
| T+5:20 | Verify DNS propagation | Network | [ ] |
| T+5:30 | Remove maintenance pages | Operations | [ ] |
| T+5:35 | Send "system available" notification | Communications | [ ] |
| T+5:45 | Monitor error rates and performance | Operations | [ ] |
| T+6:00 | **GO/NO-GO: Traffic verification** | Cutover Lead | [ ] |

### 3.6 Validation

| Time | Step | Responsible | Status |
|------|------|-------------|--------|
| T+6:00 | Execute full regression test suite | QA | [ ] |
| T+6:30 | Verify all user-facing functionality | QA | [ ] |
| T+7:00 | Verify reporting and analytics | Business | [ ] |
| T+7:30 | Verify external integrations | Operations | [ ] |
| T+8:00 | **FINAL GO/NO-GO: Cutover complete** | Cutover Lead | [ ] |

---

## 4. Post-Cutover Phase (T+1 to T+30)

### 4.1 Immediate Post-Cutover (T+1 day)

- [ ] 24/7 monitoring active
- [ ] Dedicated support team available
- [ ] User feedback channel open
- [ ] Issue triage process active
- [ ] Performance baseline established

### 4.2 Stabilization (T+1 to T+7)

- [ ] Daily standup meetings for cutover team
- [ ] Error rates within acceptable thresholds
- [ ] Performance meets SLA targets
- [ ] No data integrity issues reported
- [ ] User adoption progressing as expected
- [ ] Critical defects triaged and resolved
- [ ] Batch jobs executing on schedule

### 4.3 Stabilization Review (T+7)

- [ ] Cutover retrospective conducted
- [ ] Lessons learned documented
- [ ] Outstanding issues cataloged
- [ ] Performance metrics reviewed
- [ ] User satisfaction assessed

### 4.4 Legacy Decommission Decision (T+30)

- [ ] No rollback required in 30-day window
- [ ] All functionality verified on new system
- [ ] Legacy system can proceed to decommission phase
- [ ] Legacy system decommission plan initiated (see `operations/decommission/`)

---

## 5. Per-System Cutover Order

Systems should be cut over in the following order to minimize risk:

| Order | System | Risk | Rollback Complexity | Estimated Window |
|-------|--------|------|--------------------|--------------------|
| 1 | Apollo-11 | Low | Simple | 2 hours |
| 2 | Mezzanine | Low | Simple | 3 hours |
| 3 | CFWheels | Low | Simple | 3 hours |
| 4 | NASTRAN-95 | Low | Simple | 2 hours |
| 5 | B2CWeb | Medium | Simple | 4 hours |
| 6 | Umbraco CMS | Medium | Medium | 4 hours |
| 7 | Django Oscar | Medium | Medium | 6 hours |
| 8 | DFe-NET | Medium | Complex (regulatory) | 8 hours |
| 9 | Nuxeo | High | Complex (content) | 8 hours |
| 10 | Alfresco Community | High | Complex (content) | 10 hours |
| 11 | Monolith Enterprise | High | Complex (EJB/JMS) | 8 hours |
| 12 | Odoo | High | Complex (ERP) | 10 hours |
| 13 | Apache OFBiz | High | Complex (ERP) | 12 hours |

---

## 6. Rollback Triggers During Cutover

At any GO/NO-GO gate, if the answer is NO-GO:

```
1. Announce rollback decision in war room
2. Execute rollback procedure (see operations/deployment/rollback-procedures.md)
3. Restore legacy system to operational state
4. Verify legacy system functionality
5. Send user notification of delay
6. Conduct rollback retrospective
7. Schedule next cutover attempt
```

### 6.1 Maximum Rollback Window

| Phase | Max Rollback Window |
|-------|-------------------|
| Data migration | Before post-migration validation |
| Application cutover | 4 hours after traffic switch |
| Post-cutover | 24 hours (after which rollback requires extended downtime) |

---

## 7. Communication Templates

### 7.1 Pre-Cutover Notification

```
Subject: [PLANNED MAINTENANCE] System Migration - [DATE]

The following systems will undergo planned maintenance for migration
to modernized infrastructure on [DATE] from [START] to [END] UTC.

Affected systems: [LIST]
Expected downtime: [DURATION]

During this window, the above systems will be unavailable.
Please save your work and log out before the maintenance window.

For questions, contact: [SUPPORT EMAIL/PHONE]
```

### 7.2 Cutover Complete Notification

```
Subject: [COMPLETE] System Migration Successful - [DATE]

The planned system migration has been completed successfully.
All systems are now operational on the modernized infrastructure.

If you experience any issues, please contact [SUPPORT] immediately.
```

### 7.3 Rollback Notification

```
Subject: [UPDATE] System Migration Postponed - [DATE]

During the planned system migration, we identified issues that
require additional resolution before proceeding.

The migration has been rolled back and all systems are operational
on the original infrastructure. A new migration date will be
communicated once the issues are resolved.

No data was lost during this process.
```

---

## 8. Federal Compliance Requirements

- [ ] All cutover activities logged in change management system
- [ ] Security continuous monitoring maintained throughout
- [ ] Audit trail preserved during migration
- [ ] Privacy data handling procedures followed
- [ ] FISMA reporting updated
- [ ] FedRAMP documentation updated
- [ ] Authority to Operate (ATO) boundary documentation updated
- [ ] NIST 800-53 control implementations verified on new system
