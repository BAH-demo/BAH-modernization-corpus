# Monolith Enterprise Legacy System Decommission Plan

## Document Control

| Field | Value |
|-------|-------|
| **System** | Monolith Enterprise |
| **Type** | Enterprise Application |
| **Language** | Java |
| **Criticality** | Tier 1 - Business Critical |
| **Target Decommission Date** | [TBD] |
| **Modernized Replacement** | [Replacement System Name] |

---

## 1. Pre-Decommission Checklist

### 1.1 Stakeholder Approval

- [ ] System Owner sign-off obtained
- [ ] Business Unit approval documented
- [ ] ISSO security review completed
- [ ] Authorizing Official (AO) approval
- [ ] Change Advisory Board (CAB) approval

### 1.2 Replacement System Validation

- [ ] All EJB business services replicated in modernized system
- [ ] JMS message processing migrated
- [ ] JNDI resources transferred
- [ ] Batch processing jobs migrated
- [ ] All EAR modules accounted for in replacement
- [ ] Database schema migrated
- [ ] UAT completed for all business functions
- [ ] Parallel operation period completed (minimum 30 days)

### 1.3 Dependency Verification

- [ ] All JMS queue consumers migrated
- [ ] SOAP/REST web service consumers updated
- [ ] Batch job scheduling transferred
- [ ] LDAP/directory integration updated
- [ ] External system integrations reconfigured
- [ ] Reporting/BI tools pointed to replacement

---

## 2. Data Migration and Archival

### 2.1 Data Inventory

| Data Category | Volume | Retention | Archive Method |
|--------------|--------|-----------|----------------|
| Business data (Oracle/PostgreSQL) | ~2M records | 7 years | Database dump |
| JMS message archives | ~10M messages | 3 years | Export |
| EJB timer data | ~5K records | Not required | N/A |
| User accounts | ~10K records | 3 years | Encrypted archive |
| Audit logs | ~20M records | 7 years | Immutable archive |
| EAR/WAR deployments | ~500 MB | 3 years | File archive |
| WildFly configuration | ~100 files | 3 years | Git archive |

### 2.2 Archival Procedure

```bash
# Database archive
pg_dump -Fc -U monolith -d monolith_production > /archive/monolith/db_$(date +%Y%m%d).dump

# Application archive
tar czf /archive/monolith/deployments_$(date +%Y%m%d).tar.gz \
    /opt/wildfly/standalone/deployments/

# Configuration archive
tar czf /archive/monolith/config_$(date +%Y%m%d).tar.gz \
    /opt/wildfly/standalone/configuration/
```

---

## 3. DNS/Routing Cutover

| Step | Action | Duration |
|------|--------|----------|
| 1 | Lower DNS TTL | 5 min |
| 2 | Update service registry/JNDI | 30 min |
| 3 | Redirect SOAP endpoints | 15 min |
| 4 | Remove from load balancer | 5 min |
| 5 | Update DNS records | 5 min |
| 6 | Drain JMS queues | 1 hour |
| 7 | Monitor for errors | 4 hours |

---

## 4. Legacy System Shutdown Sequence

```
1. Stop batch job scheduler
2. Drain all JMS queues (wait for processing completion)
3. Stop WildFly application server
   └─> /opt/wildfly/bin/jboss-cli.sh --connect command=:shutdown
   └─> systemctl stop wildfly
4. Final database backup
5. Stop database (if dedicated)
6. Disable all services
7. Revoke network access
8. Archive and power down
```

---

## 5. Post-Decommission Validation

- [ ] All WildFly/JBoss endpoints inaccessible
- [ ] JMS queues drained and deleted
- [ ] SOAP services returning redirect or 404
- [ ] Replacement handling all business logic
- [ ] Batch jobs executing on replacement
- [ ] Monitoring alerts updated

---

## 6. Data Retention Compliance

| Record Type | Retention Period | Authority |
|-------------|-----------------|-----------|
| Business records | 7 years | Agency policy |
| Financial data | 7 years | 31 U.S.C. § 3512 |
| Audit logs | 7 years | FISMA |
| JMS message logs | 3 years | Agency policy |
| System documentation | 3 years | Agency policy |

---

## 7. Rollback Procedures

```
1. Restore database from final backup
2. Deploy EAR to WildFly: cp enterprise-app.ear /opt/wildfly/standalone/deployments/
3. Start WildFly: systemctl start wildfly
4. Verify JMS queues created and consuming
5. Update DNS/routing
6. Verify all EJB services operational
```

**Estimated rollback time**: 2-4 hours


## Decommission Timeline

| Phase | Duration | Activities | Exit Criteria |
|-------|----------|-----------|---------------|
| **Phase 1: Preparation** | Weeks 1-2 | Stakeholder notification, access audit, backup verification | All stakeholders acknowledged, backups validated |
| **Phase 2: Traffic Migration** | Weeks 3-4 | DNS cutover to modernized system, monitor error rates | Zero traffic to legacy system for 48 hours |
| **Phase 3: Read-Only Mode** | Weeks 5-6 | Disable write access, maintain read-only for audit trail | All data queries served by modernized system |
| **Phase 4: Shutdown** | Week 7 | Stop application services, revoke network access | All services stopped, no active connections |
| **Phase 5: Archive** | Week 8 | Final data export, archive to cold storage, documentation | Archive verified, retention policy applied |
| **Phase 6: Cleanup** | Weeks 9-10 | Remove infrastructure, decommission servers, close accounts | All resources released, cost savings confirmed |

### Key Milestones
- **T-30 days**: Stakeholder notification sent
- **T-14 days**: Final data backup completed and verified
- **T-7 days**: Read-only mode enabled
- **T-0**: Legacy system shutdown
- **T+7 days**: Post-shutdown verification complete
- **T+30 days**: Infrastructure cleanup complete
