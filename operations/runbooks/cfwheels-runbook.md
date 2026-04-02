# CFWheels Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | CFWheels |
| **Type** | MVC Web Application Framework |
| **Language** | ColdFusion (CFML) |
| **Tier** | Tier 2 - Enterprise Application |
| **LOC** | 15,000+ |
| **Category** | Web Application Framework |
| **Criticality** | Medium |

### Architecture

CFWheels is a CFML-based MVC framework running on a ColdFusion application server:

- **MVC Framework**: Convention-over-configuration routing with controllers, models, and views
- **ORM**: Built-in ActiveRecord-style ORM
- **Template Engine**: CFML templates with layout system
- **Application Server**: Adobe ColdFusion or Lucee CFML engine
- **Web Server**: Apache/Nginx with mod_cfml or AJP connector

```
┌─────────────────────────────────────────┐
│      Apache/Nginx (Reverse Proxy)       │
├─────────────────────────────────────────┤
│    ColdFusion / Lucee Application Server│
│  ┌──────────────────────────────────┐   │
│  │       CFWheels MVC Framework     │   │
│  │  ┌────────┐ ┌──────┐ ┌───────┐  │   │
│  │  │ Routes │ │Models│ │ Views │  │   │
│  │  └────────┘ └──────┘ └───────┘  │   │
│  └──────────────────────────────────┘   │
├─────────────────────────────────────────┤
│     MySQL / PostgreSQL / SQL Server     │
└─────────────────────────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 20 GB SSD | 50 GB SSD |
| Java | JDK 11+ | JDK 17 |
| OS | RHEL 8+ / Ubuntu 20.04+ / Windows Server 2019+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Java Development Kit (JDK) 11 or 17
- Lucee 5.x or Adobe ColdFusion 2021+
- Apache HTTP Server or Nginx (with CFML connector)
- MySQL 8.0+ / PostgreSQL 14+ / SQL Server 2019+
- CommandBox (CLI tool, optional)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Apache/Nginx) | Inbound |
| 8888 | Lucee HTTP | Internal |
| 8500 | CF Admin | Internal |
| 3306 | MySQL | Internal |
| 5432 | PostgreSQL | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Start database
sudo systemctl start mysql

# 2. Start ColdFusion/Lucee
sudo systemctl start lucee
# or: sudo systemctl start coldfusion

# 3. Start web server
sudo systemctl start apache2

# 4. Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost/cfwheels/
```

### Using CommandBox

```bash
cd /opt/cfwheels
box server start \
  --host=0.0.0.0 \
  --port=8888 \
  --cfengine=lucee@5 \
  --jvmArgs="-Xmx2g -Xms1g"
```

### Shutdown Sequence

```bash
sudo systemctl stop apache2
sudo systemctl stop lucee
# or: box server stop
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/` | GET | HTTP 200 | Application home |
| `/wheels/info` | GET | HTTP 200 | Framework info (dev mode) |
| `/api/health` | GET | HTTP 200 | Custom health endpoint |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:8888"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: CFWheels is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

# Check Lucee server status
LUCEE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8888/lucee/admin/server.cfm")
if [ "$LUCEE_STATUS" -ne 200 ] && [ "$LUCEE_STATUS" -ne 302 ]; then
    echo "WARNING: Lucee admin not accessible"
    exit 1
fi

echo "OK: CFWheels healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. CFML Engine Out of Memory

**Symptoms**: Application freezes; `java.lang.OutOfMemoryError` in logs

**Resolution**:
```bash
# Check JVM heap usage
jstat -gc $(pgrep -f lucee) | tail -1

# Increase heap size
# Edit /opt/lucee/tomcat/bin/setenv.sh
# JAVA_OPTS="-Xms2g -Xmx4g"

sudo systemctl restart lucee
```

### 2. ORM/Database Connection Issues

**Symptoms**: `Application.cfc` errors; datasource not found

**Resolution**:
```bash
# Check datasource configuration in Lucee admin
# http://localhost:8888/lucee/admin/server.cfm -> Datasources

# Test MySQL connectivity
mysql -u cfwheels -p -h $DB_HOST -e "SELECT 1;"

# Check Application.cfc datasource definition
grep -i "datasource" /opt/cfwheels/config/app.cfm
```

### 3. URL Rewriting Issues

**Symptoms**: 404 errors on clean URLs; routes not matching

**Resolution**:
```bash
# Check Apache mod_rewrite
apachectl -M | grep rewrite

# Verify .htaccess
cat /opt/cfwheels/.htaccess

# Check CFWheels route configuration
cat /opt/cfwheels/config/routes.cfm

# Restart Apache
sudo systemctl restart apache2
```

### 4. Session Handling Problems

**Symptoms**: Users logged out unexpectedly; session variables lost

**Resolution**:
```bash
# Check session configuration in Application.cfc
grep -i "session" /opt/cfwheels/Application.cfc

# Check Lucee session storage settings
# Lucee Admin -> Server -> Scope -> Session

# Increase session timeout
# this.sessionTimeout = createTimeSpan(0, 2, 0, 0); // 2 hours

sudo systemctl restart lucee
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Lucee Server Log | `/opt/lucee/tomcat/logs/catalina.out` | Server log |
| Application Log | `/opt/lucee/tomcat/logs/application.log` | Application events |
| Exception Log | `/opt/lucee/web/logs/exception.log` | CFML exceptions |
| Apache Access | `/var/log/apache2/cfwheels-access.log` | HTTP access |
| Apache Error | `/var/log/apache2/cfwheels-error.log` | Web server errors |

### Log Analysis Commands

```bash
# Recent CFML exceptions
tail -100 /opt/lucee/web/logs/exception.log | grep -i "error\|exception"

# Application errors
grep "ERROR\|FATAL" /opt/lucee/tomcat/logs/catalina.out | tail -30

# Slow requests
awk '$NF > 5000' /var/log/apache2/cfwheels-access.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/cfwheels/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database
mysqldump -u cfwheels -p -h $DB_HOST --single-transaction cfwheels_db > "$BACKUP_DIR/cfwheels_db.sql"

# Application code and uploads
tar czf "$BACKUP_DIR/cfwheels_app.tar.gz" /opt/cfwheels/

# Lucee configuration
tar czf "$BACKUP_DIR/lucee_config.tar.gz" /opt/lucee/web/ /opt/lucee/server/

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop lucee
mysql -u cfwheels -p -h $DB_HOST cfwheels_db < "$BACKUP_DIR/cfwheels_db.sql"
tar xzf "$BACKUP_DIR/cfwheels_app.tar.gz" -C /
tar xzf "$BACKUP_DIR/lucee_config.tar.gz" -C /
sudo systemctl start lucee
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB dump | Daily 02:00 UTC | 30 days |
| Application code | On deploy | 10 versions |
| Configuration | On change | 90 days |

## Performance Tuning Parameters

### JVM Tuning

```bash
# /opt/lucee/tomcat/bin/setenv.sh
JAVA_OPTS="-server -Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Lucee Configuration

```
# Lucee Admin -> Performance/Caching
Template Cache: 1024
Query Cache: 256
Component Cache: Enabled
Save Class Files: Yes
```

### CFWheels Settings

```cfm
<!--- config/settings.cfm --->
<cfset set(cacheQueries=true)>
<cfset set(cacheActions=true)>
<cfset set(cachePages=true)>
<cfset set(cachePartials=true)>
<cfset set(cacheImages=true)>
```

## Scaling Procedures

### Vertical Scaling

1. Increase JVM heap
2. Increase database resources
3. Tune Lucee template cache sizes
4. Add CPU cores

### Horizontal Scaling

1. Multiple Lucee instances behind load balancer
2. Sticky sessions (required for server-side sessions)
3. Externalized session store (Redis/Memcached)
4. Shared database
5. Shared filesystem for uploads (NFS/S3)

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop lucee

rsync -a /opt/cfwheels-releases/$PREVIOUS_VERSION/ /opt/cfwheels/

if [ -f "/backup/cfwheels/pre-deploy/cfwheels_db.sql" ]; then
    mysql -u cfwheels -p -h $DB_HOST cfwheels_db < /backup/cfwheels/pre-deploy/cfwheels_db.sql
fi

sudo systemctl start lucee

sleep 15
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```
