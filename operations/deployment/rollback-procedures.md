# System-Wide Rollback Procedures

## Federal Modernization Portfolio - All 13 Systems

---

## 1. Rollback Decision Framework

### 1.1 When to Rollback

| Condition | Action | Authority |
|-----------|--------|-----------|
| SEV-1 incident caused by deployment | Immediate rollback | On-call engineer |
| Error rate > 5% for > 5 minutes | Immediate rollback | On-call engineer |
| Data corruption detected | Immediate rollback + incident | On-call engineer + ISSO |
| Critical functionality broken | Rollback within 30 min | Team lead |
| Performance degradation > 50% | Rollback within 1 hour | Team lead |
| Security vulnerability in new release | Immediate rollback | ISSO |
| Compliance violation detected | Immediate rollback | Compliance officer |
| Business stakeholder escalation | Rollback within 2 hours | System owner |

### 1.2 Rollback Decision Tree

```
Is the system experiencing a critical outage?
├── YES → Initiate IMMEDIATE rollback (no approval needed)
│         └── Notify CAB within 1 hour post-rollback
└── NO
    ├── Is data integrity at risk?
    │   ├── YES → Initiate IMMEDIATE rollback + data assessment
    │   └── NO
    │       ├── Can the issue be hotfixed within 30 minutes?
    │       │   ├── YES → Attempt hotfix, rollback if fix fails
    │       │   └── NO → Initiate planned rollback
    │       └── Is the issue affecting < 5% of users?
    │           ├── YES → Monitor, plan rollback in next window
    │           └── NO → Initiate rollback within 1 hour
```

---

## 2. Per-System Rollback Procedures

### 2.1 Java Systems

#### Apache OFBiz

```bash
#!/bin/bash
# rollback-ofbiz.sh <previous-version>
VERSION=$1
echo "Rolling back OFBiz to v$VERSION"

for host in $(get_hosts production ofbiz); do
    ssh $host "
        systemctl stop ofbiz
        cp /opt/ofbiz/build/libs/ofbiz.jar.bak /opt/ofbiz/build/libs/ofbiz.jar
        systemctl start ofbiz
    "
    wait_for_health $host ofbiz
done

# Rollback database migrations if needed
if [ -f "migrations/ofbiz-${VERSION}-rollback.sql" ]; then
    psql -U ofbiz -d ofbiz_production -f "migrations/ofbiz-${VERSION}-rollback.sql"
fi

echo "OFBiz rollback complete"
```

#### Alfresco Community

```bash
#!/bin/bash
# rollback-alfresco.sh <previous-version>
VERSION=$1
echo "Rolling back Alfresco to v$VERSION"

# Stop in reverse dependency order
for host in $(get_hosts production alfresco-share); do
    ssh $host "systemctl stop alfresco-share"
done

for host in $(get_hosts production alfresco-repo); do
    ssh $host "
        systemctl stop alfresco
        # Restore previous WAR files
        cp /opt/alfresco/backup/alfresco.war /opt/alfresco/tomcat/webapps/
        cp /opt/alfresco/backup/share.war /opt/alfresco/tomcat/webapps/
        systemctl start alfresco
    "
    wait_for_health $host alfresco
done

for host in $(get_hosts production alfresco-share); do
    ssh $host "systemctl start alfresco-share"
done

echo "Alfresco rollback complete"
```

#### Nuxeo

```bash
#!/bin/bash
echo "Rolling back Nuxeo to v$1"
for host in $(get_hosts production nuxeo); do
    ssh $host "
        nuxeoctl stop
        # Restore previous packages
        cp -r /opt/nuxeo/backup/packages/* /opt/nuxeo/server/packages/
        nuxeoctl start
    "
    wait_for_health $host nuxeo
done
```

#### B2CWeb

```bash
#!/bin/bash
echo "Rolling back B2CWeb to v$1"
for host in $(get_hosts production b2cweb); do
    ssh $host "
        systemctl stop tomcat
        cp /opt/tomcat/backup/b2cweb.war /opt/tomcat/webapps/
        systemctl start tomcat
    "
    wait_for_health $host b2cweb
done
```

#### Monolith Enterprise

```bash
#!/bin/bash
echo "Rolling back Monolith Enterprise to v$1"
for host in $(get_hosts production monolith); do
    ssh $host "
        /opt/wildfly/bin/jboss-cli.sh --connect command=':shutdown'
        cp /opt/wildfly/backup/enterprise-app.ear /opt/wildfly/standalone/deployments/
        systemctl start wildfly
    "
    wait_for_health $host monolith
done
```

### 2.2 Python Systems

#### Odoo

```bash
#!/bin/bash
echo "Rolling back Odoo to v$1"
for host in $(get_hosts production odoo); do
    ssh $host "
        systemctl stop odoo
        pip install odoo==$1
        systemctl start odoo
    "
    wait_for_health $host odoo
done
```

#### Django Oscar

```bash
#!/bin/bash
echo "Rolling back Django Oscar to v$1"
for host in $(get_hosts production oscar); do
    ssh $host "
        systemctl stop oscar-gunicorn oscar-celery oscar-celery-beat
        cd /opt/oscar && git checkout v$1
        pip install -r requirements.txt
        python manage.py migrate --noinput
        systemctl start oscar-gunicorn oscar-celery oscar-celery-beat
    "
    wait_for_health $host oscar
done
```

#### Mezzanine

```bash
#!/bin/bash
echo "Rolling back Mezzanine to v$1"
for host in $(get_hosts production mezzanine); do
    ssh $host "
        systemctl stop mezzanine-gunicorn
        cd /opt/mezzanine && git checkout v$1
        pip install -r requirements.txt
        systemctl start mezzanine-gunicorn
    "
    wait_for_health $host mezzanine
done
```

### 2.3 C#/.NET Systems

#### Umbraco CMS

```bash
#!/bin/bash
echo "Rolling back Umbraco to v$1"
for host in $(get_hosts production umbraco); do
    ssh $host "
        systemctl stop umbraco
        cp -r /opt/umbraco/backup/* /opt/umbraco/
        rm -f /opt/umbraco/umbraco/Data/NuCache.*
        systemctl start umbraco
    "
    wait_for_health $host umbraco
done
```

#### DFe-NET

```bash
#!/bin/bash
echo "Rolling back DFe-NET to v$1"

# CRITICAL: Check for in-flight fiscal documents first
PENDING=$(curl -s "http://dfe-net:5000/api/queue/pending" | jq '.count')
if [ "$PENDING" -gt 0 ]; then
    echo "WARNING: $PENDING fiscal documents in flight. Wait for completion or force rollback?"
    read -p "Force rollback? (yes/no): " FORCE
    if [ "$FORCE" != "yes" ]; then
        echo "Waiting for pending documents..."
        while [ "$PENDING" -gt 0 ]; do
            sleep 10
            PENDING=$(curl -s "http://dfe-net:5000/api/queue/pending" | jq '.count')
        done
    fi
fi

for host in $(get_hosts production dfe-net); do
    ssh $host "
        systemctl stop dfe-net dfe-net-worker
        cp -r /opt/dfe-net/backup/* /opt/dfe-net/
        systemctl start dfe-net dfe-net-worker
    "
    wait_for_health $host dfe-net
done
```

### 2.4 Other Systems

#### CFWheels

```bash
#!/bin/bash
echo "Rolling back CFWheels to v$1"
for host in $(get_hosts production cfwheels); do
    ssh $host "
        systemctl stop lucee
        cp -r /opt/lucee/backup/cfwheels/* /opt/lucee/web/cfwheels/
        systemctl start lucee
    "
    wait_for_health $host cfwheels
done
```

#### NASTRAN-95

```bash
#!/bin/bash
echo "Rolling back NASTRAN-95 to v$1"
# NASTRAN is batch-oriented; rollback means reverting the module
ssh hpc-master "
    cp /opt/modules/nastran95/$1 /opt/modules/nastran95/current
    module purge && module load nastran95
    # Run benchmark to verify
    nastran /opt/nastran95/benchmarks/test001.bdf
"
```

#### Apollo-11

```bash
#!/bin/bash
echo "Rolling back Apollo-11 simulator to v$1"
ssh apollo-host "
    systemctl stop yaagc-simulator
    cd /opt/virtualagc && git checkout v$1
    make -C yaAGC clean && make -C yaAGC
    systemctl start yaagc-simulator
"
```

---

## 3. Database Rollback

### 3.1 Schema Rollback Guidelines

```
CRITICAL RULES:
1. Database rollbacks must be tested in staging FIRST
2. Only rollback schema changes that are backward-incompatible
3. Forward-compatible schema changes should NOT be rolled back
4. Take a snapshot before any schema rollback
5. Data loss risk must be assessed before proceeding
```

### 3.2 PostgreSQL Rollback

```bash
#!/bin/bash
# db-rollback-postgres.sh <system> <backup-file>
SYSTEM=$1
BACKUP=$2

echo "=== Database rollback for $SYSTEM ==="

# Take snapshot before rollback
pg_dump -Fc -U $SYSTEM -d ${SYSTEM}_production > \
    /backup/pre-rollback-${SYSTEM}-$(date +%Y%m%d%H%M).dump

# Apply rollback migration
if [ -f "$BACKUP" ] && [[ "$BACKUP" == *.sql ]]; then
    psql -U $SYSTEM -d ${SYSTEM}_production -f "$BACKUP"
elif [ -f "$BACKUP" ] && [[ "$BACKUP" == *.dump ]]; then
    # Full restore (destructive)
    dropdb -U $SYSTEM ${SYSTEM}_production
    createdb -U $SYSTEM ${SYSTEM}_production
    pg_restore -U $SYSTEM -d ${SYSTEM}_production "$BACKUP"
fi
```

### 3.3 SQL Server Rollback

```sql
-- Restore from backup
USE master;
ALTER DATABASE UmbracoDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
RESTORE DATABASE UmbracoDB
FROM DISK = '/backup/umbraco_pre_deploy.bak'
WITH REPLACE, RECOVERY;
ALTER DATABASE UmbracoDB SET MULTI_USER;
```

---

## 4. Post-Rollback Checklist

- [ ] All services healthy (health checks passing)
- [ ] Error rates returned to baseline
- [ ] User-reported issues resolved
- [ ] Monitoring alerts cleared
- [ ] Incident record created/updated
- [ ] Stakeholders notified of rollback
- [ ] Root cause analysis initiated
- [ ] Rollback logged in change management system
- [ ] Failed deployment artifacts preserved for analysis
- [ ] Post-incident review scheduled

---

## 5. Emergency Contact Escalation

| Role | Contact Method | Response SLA |
|------|---------------|-------------|
| On-call Engineer | PagerDuty | 5 min |
| Team Lead | Phone/Slack | 15 min |
| System Owner | Phone/Email | 30 min |
| ISSO | Phone/Email | 30 min |
| CAB Chair | Email | 1 hour |
| CIO/CTO | Phone (SEV-1 only) | 1 hour |
