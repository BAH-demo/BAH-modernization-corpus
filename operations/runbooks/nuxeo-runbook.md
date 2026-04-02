# Nuxeo Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Nuxeo Platform |
| **Type** | Content Services Platform |
| **Language** | Java |
| **Tier** | Tier 1 - Enterprise Monolith |
| **LOC** | 300,000+ |
| **Category** | Content Management / Digital Asset Management |
| **Criticality** | High |

### Architecture

Nuxeo is a modular Java-based content platform built on an OSGi-inspired runtime:

- **Nuxeo Runtime**: Core framework with extension point architecture
- **Content Repository**: VCS (Visible Content Store) or DBS (Document-Based Storage) backend
- **Elasticsearch**: Full-text search and aggregation engine
- **Redis**: Caching, work manager queues, and cluster coordination
- **Stream Processing**: Nuxeo Stream (Kafka or Chronicle-based) for async processing

```
┌─────────────────────────────────────────────┐
│              Load Balancer (L7)              │
├─────────────────────────────────────────────┤
│            Nuxeo Server Node(s)             │
│  ┌──────────┐ ┌───────────┐ ┌────────────┐ │
│  │ REST API │ │ Automation│ │  Rendition │ │
│  │ (JAX-RS) │ │  Engine   │ │  Service   │ │
│  └──────────┘ └───────────┘ └────────────┘ │
├─────────────┬─────────────┬─────────────────┤
│ PostgreSQL  │Elasticsearch│    Redis/Kafka  │
│ (Documents) │  (Search)   │  (Cache/Queue)  │
└─────────────┴─────────────┴─────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 8 GB | 16 GB |
| Disk | 100 GB SSD | 500 GB NVMe SSD |
| JDK | OpenJDK 11 | OpenJDK 17 |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Java Development Kit (JDK) 11 or 17
- PostgreSQL 14+ or MongoDB 6+
- Elasticsearch 7.x
- Redis 6+
- Apache Kafka 3.x (optional, for Nuxeo Stream)
- FFmpeg (video processing)
- LibreOffice (document conversion)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 8080 | Nuxeo HTTP | Inbound |
| 8443 | Nuxeo HTTPS | Inbound |
| 5432 | PostgreSQL | Internal |
| 9200 | Elasticsearch | Internal |
| 6379 | Redis | Internal |
| 9092 | Kafka | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

1. **Start infrastructure services**:
   ```bash
   sudo systemctl start postgresql
   sudo systemctl start elasticsearch
   sudo systemctl start redis
   sudo systemctl start kafka  # if applicable
   ```

2. **Start Nuxeo**:
   ```bash
   sudo systemctl start nuxeo
   # or manually:
   /opt/nuxeo/bin/nuxeoctl start
   ```

3. **Verify startup**:
   ```bash
   /opt/nuxeo/bin/nuxeoctl status
   curl -u Administrator:Administrator http://localhost:8080/nuxeo/runningstatus
   ```

### Shutdown Sequence

```bash
# Graceful shutdown
sudo systemctl stop nuxeo
# or: /opt/nuxeo/bin/nuxeoctl stop

# Stop infrastructure (if dedicated)
sudo systemctl stop kafka
sudo systemctl stop redis
sudo systemctl stop elasticsearch
sudo systemctl stop postgresql
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected Response | Purpose |
|----------|--------|-------------------|---------|
| `/nuxeo/runningstatus` | GET | HTTP 200 + JSON | Overall health |
| `/nuxeo/api/v1/me` | GET | HTTP 200 | API availability |
| `/nuxeo/site/automation` | GET | HTTP 200 | Automation engine |
| `/nuxeo/api/v1/directory/nature` | GET | HTTP 200 | Repository check |

### Health Check Script

```bash
#!/bin/bash
# nuxeo-healthcheck.sh
NUXEO_URL="http://localhost:8080/nuxeo"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$NUXEO_URL/runningstatus")
if [ "$STATUS" -ne 200 ]; then
    echo "CRITICAL: Nuxeo is DOWN (HTTP $STATUS)"
    exit 2
fi

# Check Elasticsearch connectivity
ES_STATUS=$(curl -s "http://localhost:9200/_cluster/health" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','unknown'))")
if [ "$ES_STATUS" = "red" ]; then
    echo "CRITICAL: Elasticsearch cluster is RED"
    exit 2
fi

# Check Redis
redis-cli ping > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "WARNING: Redis is unreachable"
    exit 1
fi

echo "OK: Nuxeo and dependencies healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Elasticsearch Index Out of Sync

**Symptoms**: Search returns stale or missing results

**Resolution**:
```bash
# Re-index repository
curl -u Administrator:Administrator -X POST \
  "http://localhost:8080/nuxeo/site/automation/Elasticsearch.Index" \
  -H "Content-Type: application/json" \
  -d '{"params":{"repositoryName":"default"}}'

# Monitor re-indexing
curl -s "http://localhost:9200/nuxeo/_count"
```

### 2. Work Manager Queue Stuck

**Symptoms**: Async operations not completing; bulkAction failures

**Resolution**:
```bash
# Check work manager status
curl -u Administrator:Administrator "http://localhost:8080/nuxeo/api/v1/management/work-manager"

# Check Kafka lag (if using Kafka)
/opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --group nuxeo --describe

# Restart Nuxeo to reset work queues
sudo systemctl restart nuxeo
```

### 3. Binary Store Corruption

**Symptoms**: `BlobNotFoundException`; missing document content

**Resolution**:
```bash
# Run binary consistency check
curl -u Administrator:Administrator -X POST \
  "http://localhost:8080/nuxeo/site/automation/BlobConsistencyCheck" \
  -H "Content-Type: application/json"

# Identify orphaned blobs
find /opt/nuxeo/data/binaries -type f -mtime +365 | wc -l
```

### 4. Redis Connection Pool Exhaustion

**Symptoms**: `JedisConnectionException` in logs; slow response times

**Resolution**:
```bash
# Check Redis connections
redis-cli info clients

# Check Nuxeo Redis pool config
grep "nuxeo.redis" /opt/nuxeo/conf/nuxeo.conf

# Increase pool size in nuxeo.conf
# nuxeo.redis.pool.maxTotal=64
# nuxeo.redis.pool.maxIdle=16

sudo systemctl restart nuxeo
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Server Log | `/var/log/nuxeo/server.log` | Main application log |
| Console Log | `/var/log/nuxeo/console.log` | Stdout/stderr |
| Nuxeoctl Log | `/var/log/nuxeo/nuxeoctl.log` | Control script log |
| Audit Log | `/var/log/nuxeo/audit.log` | User activity audit |
| Classloader | `/var/log/nuxeo/classloader.log` | Bundle loading log |

### Log Analysis Commands

```bash
# Recent errors
grep "ERROR" /var/log/nuxeo/server.log | tail -50

# Track slow NXQL queries
grep "SlowQuery" /var/log/nuxeo/server.log | tail -20

# Check for failed bulk operations
grep "BulkCommand\|WorkFailure" /var/log/nuxeo/server.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/nuxeo/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database
pg_dump -U nuxeo -h $DB_HOST -Fc -f "$BACKUP_DIR/nuxeo_db.dump" nuxeo

# Binary store
rsync -av /opt/nuxeo/data/binaries/ "$BACKUP_DIR/binaries/"

# Configuration
tar czf "$BACKUP_DIR/nuxeo_config.tar.gz" /opt/nuxeo/conf/ /opt/nuxeo/templates/

# Elasticsearch snapshot
curl -X PUT "http://localhost:9200/_snapshot/nuxeo_backup/snap_$(date +%Y%m%d)" \
  -H "Content-Type: application/json" \
  -d '{"indices":"nuxeo*","ignore_unavailable":true}'

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop nuxeo

pg_restore -U nuxeo -h $DB_HOST -d nuxeo --clean --if-exists "$BACKUP_DIR/nuxeo_db.dump"
rsync -av "$BACKUP_DIR/binaries/" /opt/nuxeo/data/binaries/
tar xzf "$BACKUP_DIR/nuxeo_config.tar.gz" -C /

sudo systemctl start nuxeo

# Re-index Elasticsearch
curl -u Administrator:Administrator -X POST \
  "http://localhost:8080/nuxeo/site/automation/Elasticsearch.Index" \
  -H "Content-Type: application/json" \
  -d '{"params":{"repositoryName":"default"}}'
```

## Performance Tuning Parameters

### JVM Tuning

```bash
# /opt/nuxeo/conf/nuxeo.conf
JAVA_OPTS=-server -Xms4g -Xmx8g -XX:+UseG1GC -XX:MaxGCPauseMillis=200
```

### Nuxeo Configuration

```properties
# nuxeo.conf
nuxeo.vcs.max-pool-size=40
nuxeo.db.max-pool-size=100
nuxeo.redis.pool.maxTotal=64
elasticsearch.indexNumberOfReplicas=1
elasticsearch.indexNumberOfShards=5
```

### Elasticsearch Tuning

```yaml
# elasticsearch.yml
indices.memory.index_buffer_size: 30%
thread_pool.search.queue_size: 1000
thread_pool.write.queue_size: 500
```

## Scaling Procedures

### Horizontal Scaling

1. Deploy multiple Nuxeo nodes behind load balancer
2. Use shared PostgreSQL with read replicas
3. Configure Redis for cluster coordination
4. Use S3-compatible storage for binary store
5. Scale Elasticsearch cluster independently

### Vertical Scaling

1. Increase JVM heap proportional to content volume
2. Add CPU cores for concurrent processing
3. Increase Elasticsearch heap (max 31 GB)
4. Scale PostgreSQL shared_buffers

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop nuxeo

cp -r /opt/nuxeo /opt/nuxeo.rollback.$(date +%s)
rsync -a /opt/nuxeo-releases/$PREVIOUS_VERSION/ /opt/nuxeo/

if [ -f "/backup/nuxeo/pre-deploy/nuxeo_db.dump" ]; then
    pg_restore -U nuxeo -h $DB_HOST -d nuxeo --clean --if-exists \
      /backup/nuxeo/pre-deploy/nuxeo_db.dump
fi

sudo systemctl start nuxeo

sleep 30
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/nuxeo/runningstatus)
if [ "$STATUS" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE IMMEDIATELY"
    exit 1
fi
```
