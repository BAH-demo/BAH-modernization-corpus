# Service Outage Response Playbook

## Document Control

| Field | Value |
|-------|-------|
| **Document ID** | IR-PLAY-003 |
| **Version** | 1.0 |
| **Classification** | CUI (Controlled Unclassified Information) |
| **Framework** | NIST SP 800-61 Rev. 2 |
| **Applicable Systems** | All 13 Modernized Legacy Systems |
| **Review Cycle** | Annual or after major outage |

## Purpose

This playbook provides procedures for responding to service outages affecting the modernized legacy systems. It covers complete outages, degraded performance, and cascading failures across the 13-system portfolio.

---

## Phase 1: Preparation

### 1.1 Availability Targets

| System | Target SLA | Max Downtime/Month | Maintenance Window |
|--------|-----------|--------------------|--------------------|
| Apache OFBiz | 99.9% | 43 min | Sun 02:00-06:00 UTC |
| Alfresco Community | 99.9% | 43 min | Sun 02:00-06:00 UTC |
| Nuxeo | 99.9% | 43 min | Sun 02:00-06:00 UTC |
| Odoo | 99.9% | 43 min | Sun 02:00-06:00 UTC |
| Django Oscar | 99.9% | 43 min | Sun 02:00-06:00 UTC |
| DFe-NET | 99.95% | 22 min | Sun 02:00-04:00 UTC |
| B2CWeb | 99.5% | 3.6 hours | Sun 02:00-06:00 UTC |
| Monolith Enterprise | 99.5% | 3.6 hours | Sun 02:00-06:00 UTC |
| Umbraco CMS | 99.5% | 3.6 hours | Sun 02:00-06:00 UTC |
| Mezzanine | 99.5% | 3.6 hours | Sun 02:00-06:00 UTC |
| CFWheels | 99.5% | 3.6 hours | Sun 02:00-06:00 UTC |
| NASTRAN-95 | 99.0% | 7.2 hours | Anytime with notice |
| Apollo-11 | 95.0% | 36 hours | Anytime with notice |

### 1.2 Dependency Map

```
                    ┌──────────┐
                    │   DNS    │
                    └────┬─────┘
                         │
                    ┌────┴─────┐
                    │   CDN    │
                    └────┬─────┘
                         │
               ┌─────────┴──────────┐
               │   Load Balancer    │
               └─────────┬──────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
┌───┴───┐          ┌─────┴────┐         ┌────┴────┐
│ Java  │          │  Python  │         │   C#    │
│Systems│          │ Systems  │         │ Systems │
└───┬───┘          └────┬─────┘         └────┬────┘
    │                   │                    │
┌───┴────────────────────┴────────────────────┴───┐
│              Shared Infrastructure               │
│  ┌──────────┐ ┌───────┐ ┌──────┐ ┌───────────┐ │
│  │PostgreSQL│ │ Redis │ │ ES   │ │ ActiveMQ  │ │
│  └──────────┘ └───────┘ └──────┘ └───────────┘ │
└─────────────────────────────────────────────────┘
```

### 1.3 Outage Preparation Checklist

- [ ] Health check endpoints documented for all 13 systems
- [ ] Automated monitoring alerting on all health endpoints
- [ ] StatusPage configured for external communication
- [ ] On-call rotation established and tested
- [ ] Runaway process kill procedures documented
- [ ] Failover procedures tested (quarterly)
- [ ] Capacity thresholds documented and monitored
- [ ] Backup restoration tested (monthly)

---

## Phase 2: Detection and Analysis

### 2.1 Outage Detection Sources

| Source | Detection Method | Alert Time |
|--------|-----------------|------------|
| Prometheus | Health check probe failures | 30 seconds |
| Synthetic Monitoring | External URL checks | 60 seconds |
| Load Balancer | Backend health failures | Immediate |
| User Reports | Helpdesk tickets | Variable |
| Network Monitoring | SNMP/flow analysis | 30 seconds |
| Database Monitoring | Connection/replication lag | 30 seconds |

### 2.2 Rapid Triage Decision Tree

```
Alert Received: System Unavailable
│
├─ Is it a single system or multiple?
│  ├─ MULTIPLE → Check shared infrastructure
│  │  ├─ Database down? → DB recovery procedure
│  │  ├─ Network issue? → Network team escalation
│  │  ├─ DNS issue? → DNS provider check
│  │  └─ Load balancer? → LB failover
│  │
│  └─ SINGLE → Check system-specific issues
│     ├─ Process running? → Check health endpoint
│     ├─ Process crashed? → Check logs, restart
│     ├─ Disk full? → Emergency cleanup
│     ├─ Memory exhaustion? → Restart with tuning
│     └─ Certificate expired? → Certificate renewal
│
├─ Was there a recent deployment?
│  ├─ YES → Rollback candidate (see deployment/rollback-procedures.md)
│  └─ NO → Continue investigation
│
└─ Is this during a maintenance window?
   ├─ YES → Expected, verify scope
   └─ NO → Unplanned outage, escalate per severity
```

### 2.3 Quick Diagnostic Commands by System Type

#### Java Systems (OFBiz, Alfresco, Nuxeo, B2CWeb, Monolith)

```bash
# Check JVM process
ps aux | grep java | grep -v grep

# Check heap usage
jstat -gc $(pgrep -f <system>) | tail -1

# Check thread dump (if hung)
jstack $(pgrep -f <system>) > /tmp/thread_dump_$(date +%s).txt

# Check GC activity
jstat -gcutil $(pgrep -f <system>) 1000 5

# Check network listeners
ss -tlnp | grep java
```

#### Python Systems (Odoo, Django Oscar, Mezzanine)

```bash
# Check Gunicorn/Odoo workers
ps aux | grep -E "gunicorn|odoo" | grep -v grep

# Check worker memory
ps aux | grep -E "gunicorn|odoo" | awk '{sum+=$6} END {print sum/1024 " MB"}'

# Check for stuck workers
kill -TTIN $(cat /var/run/gunicorn.pid)  # Prints stack trace to logs

# Check database connections
psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

#### C# Systems (Umbraco, DFe-NET)

```bash
# Check .NET process
ps aux | grep dotnet | grep -v grep

# Check process details
dotnet-counters monitor --process-id $(pgrep -f Umbraco)

# Check ports
ss -tlnp | grep dotnet
```

### 2.4 Shared Infrastructure Diagnostics

#### PostgreSQL

```bash
# Connection check
pg_isready -h $DB_HOST -p 5432

# Active connections by database
psql -U postgres -c "SELECT datname, state, count(*) FROM pg_stat_activity GROUP BY datname, state ORDER BY datname;"

# Replication lag (if applicable)
psql -U postgres -c "SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication;"

# Long-running queries
psql -U postgres -c "SELECT pid, now() - query_start AS duration, query FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '1 minute' ORDER BY duration DESC;"
```

#### Redis

```bash
# Connection check
redis-cli ping

# Memory usage
redis-cli info memory | grep "used_memory_human"

# Connected clients
redis-cli info clients | grep "connected_clients"
```

#### Elasticsearch

```bash
# Cluster health
curl -s http://localhost:9200/_cluster/health | python3 -m json.tool

# Node status
curl -s http://localhost:9200/_cat/nodes?v

# Index status
curl -s http://localhost:9200/_cat/indices?v&health=red
```

---

## Phase 3: Containment, Eradication, and Recovery

### 3.1 Immediate Response Actions

| Impact Level | Action | Who |
|-------------|--------|-----|
| Single system degraded | Restart service, check resources | On-call engineer |
| Single system down | Failover, restart, check dependencies | On-call + system owner |
| Multiple systems down | Check shared infra, activate IRT | Full IRT |
| Complete outage | All hands, executive notification | IRT + Management |

### 3.2 Common Outage Resolution Procedures

#### Application Process Crash

```bash
# 1. Check why process died
journalctl -u <service-name> --since "10 minutes ago" | tail -50

# 2. Check for resource issues
free -h        # Memory
df -h          # Disk
uptime         # Load average

# 3. Restart service
sudo systemctl restart <service-name>

# 4. Verify recovery
curl -s -o /dev/null -w "%{http_code}" <health-endpoint>

# 5. If restart fails, check for port conflicts
ss -tlnp | grep <port>
```

#### Database Outage

```bash
# 1. Check PostgreSQL status
sudo systemctl status postgresql

# 2. If down, attempt restart
sudo systemctl restart postgresql

# 3. If restart fails, check logs
tail -100 /var/log/postgresql/postgresql-14-main.log

# 4. Common fixes:
#    - Disk full: Clear WAL/temp files
#    - Shared memory: Check kernel parameters
#    - Connection limit: Increase max_connections or kill idle
#    - Corruption: Initiate recovery from backup

# 5. After DB recovery, restart all dependent applications
for svc in ofbiz alfresco nuxeo odoo oscar mezzanine umbraco dfe-net; do
    sudo systemctl restart $svc 2>/dev/null
done
```

#### Disk Space Emergency

```bash
# 1. Identify what's consuming space
du -sh /* 2>/dev/null | sort -rh | head -10

# 2. Quick wins - clear logs and temp
find /var/log -name "*.gz" -mtime +7 -delete
find /tmp -mtime +1 -delete
journalctl --vacuum-size=500M

# 3. System-specific cleanup
# Java: Clear old GC logs and heap dumps
find /opt/*/runtime/logs -name "gc.*.log*" -mtime +7 -delete
find /opt -name "*.hprof" -delete

# 4. Database: Clear old WAL files (PostgreSQL)
# pg_archivecleanup /var/lib/postgresql/14/main/pg_wal <oldest-needed-wal>

# 5. Monitor recovery
watch df -h
```

#### Certificate Expiration

```bash
# 1. Identify expired certificates
for host in ofbiz alfresco nuxeo b2cweb monolith odoo oscar mezzanine umbraco dfe-net cfwheels; do
    echo "=== $host ==="
    echo | openssl s_client -connect ${host}:443 -servername ${host} 2>/dev/null | openssl x509 -noout -dates
done

# 2. Replace certificate
sudo cp /path/to/new/cert.pem /etc/ssl/certs/
sudo cp /path/to/new/key.pem /etc/ssl/private/

# 3. Restart reverse proxy
sudo systemctl restart nginx

# 4. For Java keystores
keytool -importcert -alias server -file cert.pem -keystore keystore.jks -storepass changeit
```

### 3.3 Cascading Failure Mitigation

When one system failure causes others to fail:

```
1. IDENTIFY the root failing component
   └─> Database? Cache? Message broker? Network?

2. ISOLATE affected systems
   └─> Remove from load balancer
   └─> Enable circuit breakers where available

3. RECOVER root component first
   └─> Follow component-specific recovery

4. RESTART dependent systems in order
   └─> Infrastructure (DB, cache, MQ) → Applications → Reverse proxy

5. VERIFY end-to-end
   └─> Test each system's health endpoint
   └─> Test cross-system integrations
```

### 3.4 Recovery Verification

```bash
#!/bin/bash
# verify-all-systems.sh - Verify all 13 systems are healthy

declare -A ENDPOINTS=(
    ["ofbiz"]="https://ofbiz.example.gov/webtools/control/main"
    ["alfresco"]="https://alfresco.example.gov/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-"
    ["nuxeo"]="https://nuxeo.example.gov/nuxeo/runningstatus"
    ["b2cweb"]="https://b2cweb.example.gov/b2cweb/health"
    ["monolith"]="https://monolith.example.gov/enterprise/health"
    ["odoo"]="https://odoo.example.gov/web/health"
    ["oscar"]="https://oscar.example.gov/health/"
    ["mezzanine"]="https://mezzanine.example.gov/"
    ["umbraco"]="https://umbraco.example.gov/umbraco/api/keepalive/ping"
    ["dfe-net"]="https://dfe-net.example.gov/api/health"
    ["cfwheels"]="https://cfwheels.example.gov/"
)

FAILED=0
for system in "${!ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "${ENDPOINTS[$system]}")
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "OK: $system (HTTP $HTTP_CODE)"
    else
        echo "FAIL: $system (HTTP $HTTP_CODE)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Results: $((${#ENDPOINTS[@]} - FAILED))/${#ENDPOINTS[@]} systems healthy"
[ $FAILED -eq 0 ] && exit 0 || exit 1
```

---

## Phase 4: Post-Incident Activity

### 4.1 Outage-Specific PIR Items

- What was the root cause of the outage?
- Was monitoring adequate to detect the issue?
- How long before the first alert fired?
- Was the on-call engineer able to resolve independently?
- Were runbooks sufficient for the scenario?
- Could this outage have been prevented?
- Are similar outages possible in other systems?

### 4.2 Availability Metrics

| Metric | Calculation | Target |
|--------|------------|--------|
| Uptime % | (Total - Downtime) / Total × 100 | Per system SLA |
| MTTR | Total downtime / Number of incidents | < 1 hour |
| MTBF | Total uptime / Number of failures | > 30 days |
| Incident Frequency | Incidents per system per quarter | < 2 |

### 4.3 Improvement Actions

- Update alerting rules based on undetected failures
- Add missing health checks
- Update runbooks with new troubleshooting steps
- Add automation for common recovery procedures
- Review and adjust SLA targets if needed
- Schedule capacity planning review
