# Apache OFBiz Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Apache OFBiz |
| **Type** | Enterprise Resource Planning (ERP) |
| **Language** | Java |
| **Tier** | Tier 1 - Enterprise Monolith |
| **LOC** | 500,000+ |
| **Category** | ERP / Business Process Management |
| **Criticality** | High |

### Architecture

Apache OFBiz is a monolithic Java-based ERP system built on a custom MVC framework with an embedded Apache Tomcat servlet container. The architecture consists of:

- **Presentation Layer**: Freemarker templates, XML screen widgets, and Groovy-based view controllers
- **Business Logic Layer**: Java services, Groovy scripts, and XML-based service engine
- **Data Layer**: Entity Engine (custom ORM) with Apache Derby (default) or PostgreSQL/MySQL
- **Integration Layer**: REST/SOAP web services, XML-RPC endpoints

```
┌─────────────────────────────────────────┐
│           Load Balancer (L7)            │
├─────────────────────────────────────────┤
│         Apache OFBiz Instance(s)        │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │ Webapp  │ │ Service  │ │  Entity  │ │
│  │ Layer   │ │ Engine   │ │  Engine  │ │
│  └─────────┘ └──────────┘ └──────────┘ │
├─────────────────────────────────────────┤
│         Database (PostgreSQL)           │
├─────────────────────────────────────────┤
│         Shared Filesystem (NFS)         │
└─────────────────────────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disk | 50 GB SSD | 100 GB SSD |
| JDK | OpenJDK 11 | OpenJDK 17 |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Java Development Kit (JDK) 11 or 17
- Apache Gradle 7.x (bundled via wrapper)
- PostgreSQL 14+ (production) or Apache Derby (development only)
- Apache HTTP Server or Nginx (reverse proxy)
- Systemd (service management)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 8443 | HTTPS (OFBiz) | Inbound |
| 8080 | HTTP (OFBiz) | Inbound (redirect to HTTPS) |
| 5432 | PostgreSQL | Internal |
| 8009 | AJP Connector | Internal |
| 1099 | JMX Monitoring | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

1. **Verify database connectivity**:
   ```bash
   pg_isready -h $DB_HOST -p 5432 -U ofbiz
   ```

2. **Start OFBiz service**:
   ```bash
   sudo systemctl start ofbiz
   ```

3. **Manual start (if needed)**:
   ```bash
   cd /opt/ofbiz
   ./gradlew ofbiz --start
   ```

4. **Verify startup**:
   ```bash
   # Watch logs for successful startup
   tail -f /opt/ofbiz/runtime/logs/ofbiz.log | grep -i "started"
   
   # Check health endpoint
   curl -k https://localhost:8443/webtools/control/main
   ```

### Shutdown Sequence

1. **Graceful shutdown**:
   ```bash
   sudo systemctl stop ofbiz
   ```

2. **Manual shutdown**:
   ```bash
   cd /opt/ofbiz
   ./gradlew ofbiz --shutdown
   ```

3. **Force shutdown (last resort)**:
   ```bash
   # Find OFBiz PID
   ps aux | grep ofbiz | grep -v grep
   kill -SIGTERM <PID>
   # Wait 30 seconds, then force if needed
   kill -SIGKILL <PID>
   ```

### Startup Order (Full Stack)

1. PostgreSQL database
2. Shared filesystem mount verification
3. Apache OFBiz application
4. Reverse proxy (Nginx/Apache)
5. Monitoring agents

## Health Check Endpoints and Validation

### Application Health Checks

| Endpoint | Method | Expected Response | Purpose |
|----------|--------|-------------------|---------|
| `/webtools/control/main` | GET | HTTP 200 | Application availability |
| `/webtools/control/ViewServices` | GET | HTTP 200 | Service engine status |
| `/webtools/control/EntitySQLProcessor` | GET | HTTP 200 | Database connectivity |

### Health Check Script

```bash
#!/bin/bash
# ofbiz-healthcheck.sh

OFBIZ_URL="https://localhost:8443"
TIMEOUT=10

# Check application
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$OFBIZ_URL/webtools/control/main")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: OFBiz application not responding (HTTP $HTTP_CODE)"
    exit 2
fi

# Check JVM heap
HEAP_USED=$(curl -sk "$OFBIZ_URL/webtools/control/JMXViewProperties" | grep -o 'HeapMemoryUsage.*used=[0-9]*' | grep -o '[0-9]*$')
HEAP_MAX=$(curl -sk "$OFBIZ_URL/webtools/control/JMXViewProperties" | grep -o 'HeapMemoryUsage.*max=[0-9]*' | grep -o '[0-9]*$')

if [ -n "$HEAP_USED" ] && [ -n "$HEAP_MAX" ]; then
    HEAP_PCT=$((HEAP_USED * 100 / HEAP_MAX))
    if [ "$HEAP_PCT" -gt 90 ]; then
        echo "WARNING: JVM heap usage at ${HEAP_PCT}%"
        exit 1
    fi
fi

echo "OK: OFBiz healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. OFBiz Fails to Start

**Symptoms**: Service fails to start; logs show `java.lang.OutOfMemoryError`

**Resolution**:
```bash
# Check current JVM settings
grep -i "Xmx\|Xms" /opt/ofbiz/gradle.properties

# Increase heap size in gradle.properties
# org.gradle.jvmargs=-Xmx4096m -Xms2048m

# Restart
sudo systemctl restart ofbiz
```

### 2. Database Connection Pool Exhaustion

**Symptoms**: `GenericEntityException: Could not get connection` in logs

**Resolution**:
```bash
# Check active connections
psql -U ofbiz -c "SELECT count(*) FROM pg_stat_activity WHERE datname='ofbiz';"

# Check for long-running queries
psql -U ofbiz -c "SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '5 minutes';"

# Kill stale connections if needed
psql -U ofbiz -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='ofbiz' AND state='idle' AND query_start < now() - interval '30 minutes';"

# Increase pool size in entityengine.xml
# <datasource ... pool-maxsize="100" pool-minsize="10">
```

### 3. Entity Engine Cache Corruption

**Symptoms**: Stale data displayed; inconsistent entity reads

**Resolution**:
```bash
# Clear entity cache via web interface
curl -sk -X POST "https://localhost:8443/webtools/control/FindUtilCacheElements" \
  -d "UTIL_CACHE_NAME=entity.cache&UTIL_CACHE_ACTION=clear"

# Or restart OFBiz to clear all caches
sudo systemctl restart ofbiz
```

### 4. SSL Certificate Issues

**Symptoms**: `javax.net.ssl.SSLHandshakeException` in logs

**Resolution**:
```bash
# Check certificate expiry
keytool -list -v -keystore /opt/ofbiz/runtime/ofbiz-keystore.jks -storepass changeit | grep "Valid"

# Import new certificate
keytool -importcert -alias ofbiz -file /path/to/cert.pem \
  -keystore /opt/ofbiz/runtime/ofbiz-keystore.jks -storepass changeit

# Restart
sudo systemctl restart ofbiz
```

## Log Locations and Log Analysis

### Log Files

| Log File | Path | Purpose |
|----------|------|---------|
| Application Log | `/opt/ofbiz/runtime/logs/ofbiz.log` | Main application log |
| Access Log | `/opt/ofbiz/runtime/logs/access_log` | HTTP access log |
| Error Log | `/opt/ofbiz/runtime/logs/ofbiz-error.log` | Error-only log |
| GC Log | `/opt/ofbiz/runtime/logs/gc.log` | JVM garbage collection |
| Gradle Log | `/opt/ofbiz/runtime/logs/gradle.log` | Build/startup log |

### Log Rotation Configuration

```bash
# /etc/logrotate.d/ofbiz
/opt/ofbiz/runtime/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    maxsize 500M
}
```

### Common Log Analysis Commands

```bash
# Find recent errors
grep -i "error\|exception\|fatal" /opt/ofbiz/runtime/logs/ofbiz.log | tail -50

# Count errors by type
grep -oP 'Exception: \K[^:]+' /opt/ofbiz/runtime/logs/ofbiz.log | sort | uniq -c | sort -rn | head -20

# Check for slow requests (>5s)
awk '$NF > 5000' /opt/ofbiz/runtime/logs/access_log

# Monitor real-time errors
tail -f /opt/ofbiz/runtime/logs/ofbiz.log | grep --line-buffered -i "error\|exception"
```

## Backup and Restore Procedures

### Database Backup

```bash
#!/bin/bash
# ofbiz-backup.sh
BACKUP_DIR="/backup/ofbiz/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Full database dump
pg_dump -U ofbiz -h $DB_HOST -Fc -f "$BACKUP_DIR/ofbiz_db.dump" ofbiz

# Backup runtime data
tar czf "$BACKUP_DIR/ofbiz_runtime.tar.gz" /opt/ofbiz/runtime/data/

# Backup configuration
tar czf "$BACKUP_DIR/ofbiz_config.tar.gz" \
  /opt/ofbiz/framework/entity/config/entityengine.xml \
  /opt/ofbiz/framework/catalina/ofbiz-component.xml \
  /opt/ofbiz/gradle.properties

# Verify backup
pg_restore -l "$BACKUP_DIR/ofbiz_db.dump" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Backup successful: $BACKUP_DIR"
else
    echo "BACKUP VERIFICATION FAILED"
    exit 1
fi
```

### Database Restore

```bash
#!/bin/bash
# ofbiz-restore.sh
BACKUP_DIR="$1"

# Stop OFBiz
sudo systemctl stop ofbiz

# Restore database
pg_restore -U ofbiz -h $DB_HOST -d ofbiz --clean --if-exists "$BACKUP_DIR/ofbiz_db.dump"

# Restore runtime data
tar xzf "$BACKUP_DIR/ofbiz_runtime.tar.gz" -C /

# Restore configuration
tar xzf "$BACKUP_DIR/ofbiz_config.tar.gz" -C /

# Start OFBiz
sudo systemctl start ofbiz
```

### Backup Schedule

| Type | Frequency | Retention | Storage |
|------|-----------|-----------|---------|
| Full DB dump | Daily 02:00 UTC | 30 days | S3 + local |
| Incremental WAL | Continuous | 7 days | S3 |
| Configuration | On change | 90 days | S3 + Git |
| Runtime data | Weekly | 12 weeks | S3 |

## Performance Tuning Parameters

### JVM Tuning

```properties
# gradle.properties
org.gradle.jvmargs=-server \
  -Xms4096m \
  -Xmx8192m \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 \
  -XX:+ParallelRefProcEnabled \
  -XX:+UnlockExperimentalVMOptions \
  -XX:G1NewSizePercent=20 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/opt/ofbiz/runtime/logs/heap_dump.hprof
```

### Database Connection Pool

```xml
<!-- entityengine.xml -->
<datasource name="localpostgres"
    helper-class="org.apache.ofbiz.entity.datasource.GenericHelperDAO"
    field-type-name="postgres"
    check-on-start="true"
    use-foreign-keys="true"
    pool-minsize="20"
    pool-maxsize="100"
    pool-sleeptime="300"
    pool-lifetime="600000"
    pool-deadlock-maxwait="300000"
    pool-deadlock-retrywait="10000">
```

### PostgreSQL Tuning

```ini
# postgresql.conf
shared_buffers = 4GB
effective_cache_size = 12GB
work_mem = 256MB
maintenance_work_mem = 1GB
max_connections = 200
checkpoint_completion_target = 0.9
wal_buffers = 64MB
random_page_cost = 1.1
effective_io_concurrency = 200
```

## Scaling Procedures

### Vertical Scaling

1. Increase JVM heap (`-Xmx`) proportional to available RAM (50-75% of total)
2. Increase database connection pool size
3. Tune PostgreSQL `shared_buffers` (25% of RAM)
4. Increase CPU cores for parallel GC threads

### Horizontal Scaling

OFBiz does not natively support clustering. Horizontal scaling requires:

1. **Session affinity**: Configure load balancer with sticky sessions
2. **Shared database**: All instances connect to the same PostgreSQL cluster
3. **Shared filesystem**: NFS or distributed storage for runtime data
4. **Cache synchronization**: Configure distributed cache (e.g., Hazelcast) or accept eventual consistency
5. **Load balancer configuration**:
   ```nginx
   upstream ofbiz_cluster {
       ip_hash;
       server ofbiz-1:8443;
       server ofbiz-2:8443;
       server ofbiz-3:8443;
   }
   ```

## Emergency Rollback Procedures

### Application Rollback

```bash
#!/bin/bash
# ofbiz-rollback.sh
PREVIOUS_VERSION="$1"

# Stop OFBiz
sudo systemctl stop ofbiz

# Backup current version
cp -r /opt/ofbiz /opt/ofbiz.rollback.$(date +%s)

# Restore previous version
rsync -a /opt/ofbiz-releases/$PREVIOUS_VERSION/ /opt/ofbiz/

# Restore database if needed
if [ -f "/backup/ofbiz/pre-deploy/ofbiz_db.dump" ]; then
    pg_restore -U ofbiz -h $DB_HOST -d ofbiz --clean --if-exists \
      /backup/ofbiz/pre-deploy/ofbiz_db.dump
fi

# Start OFBiz
sudo systemctl start ofbiz

# Verify
sleep 30
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:8443/webtools/control/main)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK VERIFICATION FAILED - ESCALATE IMMEDIATELY"
    exit 1
fi
```

### Rollback Decision Matrix

| Scenario | Action | RTO |
|----------|--------|-----|
| Failed deployment, no DB changes | Redeploy previous artifact | 15 min |
| Failed deployment, with DB migration | Restore pre-deploy DB backup + redeploy | 45 min |
| Data corruption | Restore from latest clean backup | 2 hours |
| Complete system failure | Full disaster recovery | 4 hours |
