# B2CWeb Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | B2CWeb |
| **Type** | Business-to-Consumer Web Application |
| **Language** | Java |
| **Tier** | Tier 2 - Enterprise Application |
| **LOC** | 20,000+ |
| **Category** | Web Application / E-commerce Front-End |
| **Criticality** | Medium-High |

### Architecture

B2CWeb is a tightly-coupled Java web application built on traditional servlet architecture:

- **Presentation Layer**: JSP pages with custom tag libraries
- **Controller Layer**: Servlet-based request handlers
- **Business Logic**: Java service classes with embedded business rules
- **Data Access**: JDBC-based data access with stored procedures
- **Session Management**: Server-side HTTP sessions

```
┌─────────────────────────────────────────┐
│           Load Balancer (L7)            │
├─────────────────────────────────────────┤
│          Apache Tomcat 9.x              │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ │
│  │   JSP   │ │ Servlet  │ │  Service  │ │
│  │  Views  │ │Controllers│ │  Layer   │ │
│  └─────────┘ └──────────┘ └──────────┘ │
├─────────────────────────────────────────┤
│     MySQL / PostgreSQL Database         │
└─────────────────────────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 20 GB SSD | 50 GB SSD |
| JDK | OpenJDK 8+ | OpenJDK 11 |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Java Development Kit (JDK) 8 or 11
- Apache Tomcat 9.x
- MySQL 8.0+ or PostgreSQL 14+
- Apache Maven 3.x (build)
- Nginx (reverse proxy)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Nginx) | Inbound |
| 8080 | Tomcat HTTP | Internal |
| 3306 | MySQL | Internal |
| 5432 | PostgreSQL | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Verify database
mysqladmin ping -h $DB_HOST -u b2cweb -p

# 2. Start Tomcat
sudo systemctl start tomcat

# 3. Verify application
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/b2cweb/health
```

### Shutdown Sequence

```bash
# Graceful shutdown
sudo systemctl stop tomcat

# Force if needed (wait 30s first)
sudo systemctl kill -s SIGKILL tomcat
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/b2cweb/health` | GET | HTTP 200 | Application health |
| `/b2cweb/` | GET | HTTP 200 | Homepage availability |
| `/b2cweb/api/status` | GET | HTTP 200 + JSON | API status |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:8080/b2cweb"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: B2CWeb is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

echo "OK: B2CWeb healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Session Management Issues

**Symptoms**: Users randomly logged out; session data lost

**Resolution**:
```bash
# Check Tomcat session count
curl -s "http://localhost:8080/manager/jmxproxy/?get=Catalina:type=Manager,host=localhost,context=/b2cweb&att=activeSessions"

# Increase session timeout in web.xml
# <session-timeout>30</session-timeout>

# If using session replication, check cluster status
grep "cluster\|session" /opt/tomcat/logs/catalina.out | tail -20
```

### 2. Database Connection Pool Exhaustion

**Symptoms**: `Cannot get a connection, pool error` in logs

**Resolution**:
```bash
# Check active DB connections
mysql -u root -e "SHOW PROCESSLIST;" | wc -l

# Update connection pool in context.xml
# maxActive="50" maxIdle="10" maxWait="10000"

sudo systemctl restart tomcat
```

### 3. JSP Compilation Errors

**Symptoms**: HTTP 500 errors on specific pages

**Resolution**:
```bash
# Clear compiled JSP cache
rm -rf /opt/tomcat/work/Catalina/localhost/b2cweb/

# Restart Tomcat
sudo systemctl restart tomcat
```

### 4. Slow Response Times

**Symptoms**: Page load times > 5 seconds

**Resolution**:
```bash
# Check thread pool utilization
curl -s "http://localhost:8080/manager/jmxproxy/?get=Catalina:type=ThreadPool,name=%22http-nio-8080%22&att=currentThreadsBusy"

# Enable slow query logging
mysql -u root -e "SET GLOBAL slow_query_log = 'ON'; SET GLOBAL long_query_time = 2;"

# Check slow queries
mysqldumpslow /var/log/mysql/slow-query.log | head -20
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Application Log | `/opt/tomcat/logs/b2cweb.log` | Application events |
| Catalina Log | `/opt/tomcat/logs/catalina.out` | Container log |
| Access Log | `/opt/tomcat/logs/access_log` | HTTP access log |
| GC Log | `/opt/tomcat/logs/gc.log` | Garbage collection |

### Log Analysis Commands

```bash
# Recent errors
grep -i "ERROR\|EXCEPTION" /opt/tomcat/logs/b2cweb.log | tail -50

# Slow requests from access log
awk -F'"' '{print $2, $NF}' /opt/tomcat/logs/access_log | awk '$NF > 5000' | tail -20

# Monitor in real-time
tail -f /opt/tomcat/logs/b2cweb.log | grep --line-buffered -i "error"
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/b2cweb/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database
mysqldump -u b2cweb -p -h $DB_HOST --single-transaction b2cweb > "$BACKUP_DIR/b2cweb_db.sql"

# Application
tar czf "$BACKUP_DIR/b2cweb_app.tar.gz" /opt/tomcat/webapps/b2cweb/

# Configuration
tar czf "$BACKUP_DIR/b2cweb_config.tar.gz" /opt/tomcat/conf/

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop tomcat

mysql -u b2cweb -p -h $DB_HOST b2cweb < "$BACKUP_DIR/b2cweb_db.sql"
tar xzf "$BACKUP_DIR/b2cweb_app.tar.gz" -C /
tar xzf "$BACKUP_DIR/b2cweb_config.tar.gz" -C /

sudo systemctl start tomcat
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB dump | Daily 02:00 UTC | 30 days |
| Application WAR | On deploy | 10 versions |
| Configuration | On change | 90 days |

## Performance Tuning Parameters

### JVM Tuning

```bash
# /opt/tomcat/bin/setenv.sh
JAVA_OPTS="-server -Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
```

### Tomcat Connector

```xml
<!-- server.xml -->
<Connector port="8080" protocol="org.apache.coyote.http11.Http11NioProtocol"
    maxThreads="200" minSpareThreads="25"
    acceptCount="100" connectionTimeout="20000"
    keepAliveTimeout="15000" maxKeepAliveRequests="100" />
```

### Database Connection Pool

```xml
<!-- context.xml -->
<Resource name="jdbc/b2cweb" type="javax.sql.DataSource"
    maxActive="50" maxIdle="10" maxWait="10000"
    validationQuery="SELECT 1" testOnBorrow="true" />
```

## Scaling Procedures

### Vertical Scaling

1. Increase JVM heap (max 75% of available RAM)
2. Increase Tomcat thread pool
3. Scale database resources

### Horizontal Scaling

1. Deploy behind load balancer with session affinity (sticky sessions required)
2. Configure external session store (Redis) for session sharing
3. All instances point to shared database
4. Static assets served from CDN

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_WAR="$1"

sudo systemctl stop tomcat

# Deploy previous WAR
rm -rf /opt/tomcat/webapps/b2cweb/
cp "$PREVIOUS_WAR" /opt/tomcat/webapps/b2cweb.war

# Restore DB if needed
if [ -f "/backup/b2cweb/pre-deploy/b2cweb_db.sql" ]; then
    mysql -u b2cweb -p -h $DB_HOST b2cweb < /backup/b2cweb/pre-deploy/b2cweb_db.sql
fi

sudo systemctl start tomcat

sleep 20
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/b2cweb/health)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```


## Alerting

### Alert Configuration
- **High CPU Usage** (>80% for 5 minutes): Page on-call engineer
- **High Memory Usage** (>85% for 5 minutes): Page on-call engineer
- **Pod Restart Loop** (>3 restarts in 10 minutes): Page on-call engineer
- **HTTP 5xx Error Rate** (>5% for 2 minutes): Page on-call engineer
- **Response Latency P99** (>2s for 5 minutes): Notify team channel
- **Disk Usage** (>90%): Page on-call engineer

### Alert Channels
- **PagerDuty**: Critical and high-severity alerts
- **Slack (#ops-alerts)**: All alerts including warnings
- **Email**: Daily digest of warning-level alerts
