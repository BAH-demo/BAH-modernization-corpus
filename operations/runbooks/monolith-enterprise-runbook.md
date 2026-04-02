# Monolith Enterprise Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Monolith Enterprise |
| **Type** | Enterprise Application Platform |
| **Language** | Java |
| **Tier** | Tier 1 - Enterprise Monolith |
| **LOC** | 100,000+ |
| **Category** | Enterprise Application / Integration Platform |
| **Criticality** | High |

### Architecture

Monolith Enterprise is a large-scale Java EE application deployed on an application server:

- **Presentation Layer**: JSF (JavaServer Faces) with PrimeFaces components
- **Business Logic**: EJB (Enterprise JavaBeans) with CDI
- **Data Access**: JPA (Hibernate) with JDBC fallback
- **Messaging**: JMS (Java Message Service) for async processing
- **Integration**: SOAP/REST web services, JCA connectors

```
┌─────────────────────────────────────────┐
│           Load Balancer (L7)            │
├─────────────────────────────────────────┤
│      WildFly / JBoss EAP Server         │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────────┐ │
│  │ JSF  │ │ EJB  │ │ JPA  │ │  JMS   │ │
│  │ Views│ │ Beans│ │ Layer│ │ Queues │ │
│  └──────┘ └──────┘ └──────┘ └────────┘ │
├─────────────────────────────────────────┤
│   PostgreSQL / Oracle    │  ActiveMQ    │
└──────────────────────────┴──────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 8 GB | 16 GB |
| Disk | 50 GB SSD | 100 GB SSD |
| JDK | OpenJDK 11 | OpenJDK 17 |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Java Development Kit (JDK) 11 or 17
- WildFly 26+ or JBoss EAP 7.4+
- PostgreSQL 14+ or Oracle 19c
- Apache ActiveMQ 5.x (JMS broker)
- Nginx (reverse proxy)
- Maven 3.x (build)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Nginx) | Inbound |
| 8080 | WildFly HTTP | Internal |
| 8443 | WildFly HTTPS | Internal |
| 9990 | WildFly Admin | Internal |
| 5432 | PostgreSQL | Internal |
| 61616 | ActiveMQ | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Start database
sudo systemctl start postgresql

# 2. Start message broker
sudo systemctl start activemq

# 3. Start application server
sudo systemctl start wildfly

# 4. Verify
curl -s http://localhost:8080/enterprise/health
/opt/wildfly/bin/jboss-cli.sh --connect command=':read-attribute(name=server-state)'
```

### Shutdown Sequence

```bash
# Graceful shutdown
/opt/wildfly/bin/jboss-cli.sh --connect command=':shutdown(timeout=60)'
# or: sudo systemctl stop wildfly

sudo systemctl stop activemq
# Stop PostgreSQL only if dedicated
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/enterprise/health` | GET | HTTP 200 | App health |
| `/enterprise/api/status` | GET | HTTP 200 + JSON | API status |
| `:9990/health` | GET | HTTP 200 | WildFly health |
| `:9990/health/live` | GET | HTTP 200 | Liveness |
| `:9990/health/ready` | GET | HTTP 200 | Readiness |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:8080/enterprise"
ADMIN_URL="http://localhost:9990"

# App check
APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health")
if [ "$APP_STATUS" -ne 200 ]; then
    echo "CRITICAL: Enterprise app DOWN (HTTP $APP_STATUS)"
    exit 2
fi

# Server state
STATE=$(/opt/wildfly/bin/jboss-cli.sh --connect command=':read-attribute(name=server-state)' 2>/dev/null | grep result | awk -F'"' '{print $2}')
if [ "$STATE" != "running" ]; then
    echo "CRITICAL: WildFly state=$STATE"
    exit 2
fi

echo "OK: Enterprise app healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. EJB Transaction Timeouts

**Symptoms**: `javax.transaction.RollbackException`; slow operations

**Resolution**:
```bash
# Check transaction timeout
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=transactions:read-attribute(name=default-timeout)'

# Increase timeout
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=transactions:write-attribute(name=default-timeout,value=600)'

# Check for stuck transactions
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=transactions/log-store=log-store:read-children-resources(child-type=transactions)'
```

### 2. JMS Queue Buildup

**Symptoms**: Messages not being consumed; queue depth increasing

**Resolution**:
```bash
# Check queue depth
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=messaging-activemq/server=default/jms-queue=ExpiryQueue:read-attribute(name=message-count)'

# Restart message-driven beans
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/deployment=enterprise.ear:redeploy'
```

### 3. Connection Pool Exhaustion

**Symptoms**: `IJ000453: Unable to get managed connection` in logs

**Resolution**:
```bash
# Check pool statistics
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=datasources/data-source=EnterpriseDS/statistics=pool:read-resource(include-runtime=true)'

# Flush idle connections
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=datasources/data-source=EnterpriseDS:flush-idle-connection-in-pool'

# Increase pool size
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=datasources/data-source=EnterpriseDS:write-attribute(name=max-pool-size,value=100)'
```

### 4. Deployment Failures

**Symptoms**: Application fails to deploy; `DeploymentException` in logs

**Resolution**:
```bash
# Check deployment status
/opt/wildfly/bin/jboss-cli.sh --connect 'deployment-info'

# Undeploy and redeploy
/opt/wildfly/bin/jboss-cli.sh --connect \
  'undeploy enterprise.ear'
/opt/wildfly/bin/jboss-cli.sh --connect \
  'deploy /opt/deployments/enterprise.ear'
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Server Log | `/opt/wildfly/standalone/log/server.log` | Main application log |
| Audit Log | `/opt/wildfly/standalone/log/audit.log` | Security audit log |
| GC Log | `/opt/wildfly/standalone/log/gc.log` | JVM GC log |
| Access Log | `/opt/wildfly/standalone/log/access.log` | HTTP access log |

### Log Analysis Commands

```bash
# Recent errors
grep -i "ERROR\|FATAL" /opt/wildfly/standalone/log/server.log | tail -50

# Failed deployments
grep "WFLYSRV\|Deploy" /opt/wildfly/standalone/log/server.log | tail -20

# Transaction issues
grep "RollbackException\|TransactionTimeout" /opt/wildfly/standalone/log/server.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/enterprise/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

pg_dump -U enterprise -h $DB_HOST -Fc -f "$BACKUP_DIR/enterprise_db.dump" enterprise
tar czf "$BACKUP_DIR/wildfly_config.tar.gz" /opt/wildfly/standalone/configuration/
cp /opt/deployments/enterprise.ear "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop wildfly
pg_restore -U enterprise -h $DB_HOST -d enterprise --clean --if-exists "$BACKUP_DIR/enterprise_db.dump"
tar xzf "$BACKUP_DIR/wildfly_config.tar.gz" -C /
cp "$BACKUP_DIR/enterprise.ear" /opt/deployments/
sudo systemctl start wildfly
```

## Performance Tuning Parameters

### JVM Tuning

```bash
# /opt/wildfly/bin/standalone.conf
JAVA_OPTS="-server -Xms4g -Xmx8g -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200 -XX:+UseStringDeduplication \
  -Djboss.as.management.blocking.timeout=600"
```

### DataSource Pool

```bash
/opt/wildfly/bin/jboss-cli.sh --connect <<EOF
/subsystem=datasources/data-source=EnterpriseDS:write-attribute(name=min-pool-size,value=20)
/subsystem=datasources/data-source=EnterpriseDS:write-attribute(name=max-pool-size,value=100)
/subsystem=datasources/data-source=EnterpriseDS:write-attribute(name=idle-timeout-minutes,value=5)
EOF
```

### Thread Pool

```bash
/opt/wildfly/bin/jboss-cli.sh --connect \
  '/subsystem=io/worker=default:write-attribute(name=task-max-threads,value=64)'
```

## Scaling Procedures

### Vertical Scaling

1. Increase JVM heap and metaspace
2. Increase database connection pool
3. Scale WildFly worker threads
4. Add CPU cores

### Horizontal Scaling

1. Configure WildFly domain mode for clustering
2. Enable session replication (Infinispan)
3. Use load balancer with sticky sessions
4. Shared database with read replicas
5. Distributed JMS (ActiveMQ network of brokers)

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_EAR="$1"

sudo systemctl stop wildfly

cp "$PREVIOUS_EAR" /opt/deployments/enterprise.ear

if [ -f "/backup/enterprise/pre-deploy/enterprise_db.dump" ]; then
    pg_restore -U enterprise -h $DB_HOST -d enterprise --clean --if-exists \
      /backup/enterprise/pre-deploy/enterprise_db.dump
fi

sudo systemctl start wildfly

sleep 30
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/enterprise/health)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```
