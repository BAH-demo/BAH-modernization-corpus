# Alfresco Community Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Alfresco Community Edition |
| **Type** | Enterprise Content Management (ECM) |
| **Language** | Java |
| **Tier** | Tier 1 - Enterprise Monolith |
| **LOC** | 200,000+ |
| **Category** | Content Management / Document Repository |
| **Criticality** | High |

### Architecture

Alfresco Community is a Java-based ECM platform built on Spring Framework with a modular architecture:

- **Repository Layer**: Content storage, metadata management, versioning (Spring-based)
- **Search Layer**: Apache Solr for full-text indexing and search
- **Transformation Layer**: LibreOffice, ImageMagick for document transformations
- **Share UI**: Separate web application (Surf framework) for user interaction
- **REST API**: RESTful APIs for external integrations

```
┌─────────────────────────────────────────────┐
│              Load Balancer (L7)              │
├──────────────────┬──────────────────────────┤
│   Alfresco Share │   Alfresco Repository    │
│   (Surf/Aikau)   │   (Spring Boot)          │
├──────────────────┴──────────────────────────┤
│              Apache Solr 6                  │
├─────────────────────────────────────────────┤
│         PostgreSQL    │   Content Store      │
│         (Metadata)    │   (Filesystem/S3)    │
└─────────────────────────────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disk | 100 GB SSD | 500 GB SSD |
| JDK | OpenJDK 11 | OpenJDK 17 |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Java Development Kit (JDK) 11+
- Apache Tomcat 9.x
- PostgreSQL 14+ (metadata store)
- Apache Solr 6.x (search)
- LibreOffice 7.x (document transformation)
- ImageMagick 7.x (image transformation)
- ActiveMQ 5.x (messaging)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 8080 | Alfresco Repository | Inbound |
| 8443 | Alfresco Repository (SSL) | Inbound |
| 8180 | Alfresco Share | Inbound |
| 8983 | Apache Solr | Internal |
| 5432 | PostgreSQL | Internal |
| 61616 | ActiveMQ | Internal |
| 8161 | ActiveMQ Console | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

1. **Start PostgreSQL**:
   ```bash
   sudo systemctl start postgresql
   pg_isready -h localhost -p 5432
   ```

2. **Start ActiveMQ**:
   ```bash
   sudo systemctl start activemq
   ```

3. **Start Solr**:
   ```bash
   sudo systemctl start alfresco-search
   # Verify: curl http://localhost:8983/solr/admin/cores?action=STATUS
   ```

4. **Start Alfresco Repository**:
   ```bash
   sudo systemctl start alfresco
   ```

5. **Start Alfresco Share**:
   ```bash
   sudo systemctl start alfresco-share
   ```

6. **Verify startup**:
   ```bash
   curl -u admin:admin http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-
   ```

### Shutdown Sequence

1. **Stop Alfresco Share**:
   ```bash
   sudo systemctl stop alfresco-share
   ```

2. **Stop Alfresco Repository**:
   ```bash
   sudo systemctl stop alfresco
   ```

3. **Stop Solr**:
   ```bash
   sudo systemctl stop alfresco-search
   ```

4. **Stop ActiveMQ**:
   ```bash
   sudo systemctl stop activemq
   ```

5. **Stop PostgreSQL** (if not shared):
   ```bash
   sudo systemctl stop postgresql
   ```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected Response | Purpose |
|----------|--------|-------------------|---------|
| `/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-` | GET | HTTP 200 | Liveness |
| `/alfresco/api/-default-/public/alfresco/versions/1/probes/-ready-` | GET | HTTP 200 | Readiness |
| `/alfresco/s/api/server` | GET | HTTP 200 + JSON | Server info |
| `/share/page` | GET | HTTP 200 | Share UI availability |
| `http://localhost:8983/solr/admin/cores` | GET | HTTP 200 | Solr status |

### Health Check Script

```bash
#!/bin/bash
# alfresco-healthcheck.sh

REPO_URL="http://localhost:8080"
SHARE_URL="http://localhost:8180"
SOLR_URL="http://localhost:8983"

# Check Repository
REPO_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$REPO_URL/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-")
if [ "$REPO_STATUS" -ne 200 ]; then
    echo "CRITICAL: Alfresco Repository is DOWN (HTTP $REPO_STATUS)"
    exit 2
fi

# Check Share
SHARE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SHARE_URL/share/page")
if [ "$SHARE_STATUS" -ne 200 ]; then
    echo "WARNING: Alfresco Share is DOWN (HTTP $SHARE_STATUS)"
    exit 1
fi

# Check Solr
SOLR_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SOLR_URL/solr/admin/cores?action=STATUS")
if [ "$SOLR_STATUS" -ne 200 ]; then
    echo "WARNING: Solr is DOWN (HTTP $SOLR_STATUS)"
    exit 1
fi

echo "OK: All Alfresco services healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Content Store Disk Full

**Symptoms**: Upload failures; `ContentIOException` in logs

**Resolution**:
```bash
# Check disk usage
df -h /opt/alfresco/alf_data/contentstore

# Identify large orphan content
find /opt/alfresco/alf_data/contentstore.deleted -mtime +30 -type f | xargs du -ch | tail -1

# Clean orphaned content (after Alfresco trashcan cleanup)
rm -rf /opt/alfresco/alf_data/contentstore.deleted/*

# Run content store cleaner job via API
curl -u admin:admin -X POST "http://localhost:8080/alfresco/s/api/running-actions" \
  -H "Content-Type: application/json" \
  -d '{"actionedUponNode":"workspace://SpacesStore/company_home","actionDefinitionName":"contentStoreCleanup"}'
```

### 2. Solr Index Corruption

**Symptoms**: Search returns no/incorrect results; `SolrException` in logs

**Resolution**:
```bash
# Check Solr index status
curl "http://localhost:8983/solr/alfresco/admin/luke?show=index"

# Trigger full re-index
curl "http://localhost:8983/solr/admin/cores?action=purge&core=alfresco"
curl "http://localhost:8983/solr/admin/cores?action=purge&core=archive"

# Monitor re-indexing progress
curl "http://localhost:8983/solr/admin/cores?action=REPORT&core=alfresco"
```

### 3. ActiveMQ Queue Backup

**Symptoms**: Document transformations stalled; queue depth increasing

**Resolution**:
```bash
# Check queue depth
curl -u admin:admin "http://localhost:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=alfresco.transform.request"

# Purge stuck messages (caution!)
curl -u admin:admin -X POST "http://localhost:8161/api/jolokia/exec/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=alfresco.transform.request/purge"

# Restart transform service
sudo systemctl restart alfresco-transform
```

### 4. Out of Memory - Repository

**Symptoms**: `java.lang.OutOfMemoryError: Java heap space`

**Resolution**:
```bash
# Check current JVM settings
grep "JAVA_OPTS" /opt/alfresco/tomcat/bin/setenv.sh

# Update heap settings
sed -i 's/-Xmx[0-9]*[mg]/-Xmx8g/' /opt/alfresco/tomcat/bin/setenv.sh

# Restart Alfresco
sudo systemctl restart alfresco
```

## Log Locations and Log Analysis

### Log Files

| Log File | Path | Purpose |
|----------|------|---------|
| Alfresco Repository | `/opt/alfresco/tomcat/logs/alfresco.log` | Main application log |
| Share Application | `/opt/alfresco/tomcat-share/logs/share.log` | Share UI log |
| Solr | `/opt/alfresco/solr6/logs/solr.log` | Search indexing log |
| Tomcat Access | `/opt/alfresco/tomcat/logs/localhost_access.log` | HTTP access log |
| Catalina | `/opt/alfresco/tomcat/logs/catalina.out` | Container log |
| ActiveMQ | `/opt/activemq/data/activemq.log` | Message broker log |

### Log Analysis Commands

```bash
# Recent errors in repository
grep -i "ERROR\|FATAL" /opt/alfresco/tomcat/logs/alfresco.log | tail -50

# Track content upload issues
grep "ContentIOException\|content.store" /opt/alfresco/tomcat/logs/alfresco.log | tail -20

# Monitor Solr indexing
grep "Trackers\|Summary" /opt/alfresco/solr6/logs/solr.log | tail -20

# Check for authentication failures
grep "AuthenticationException\|Login failed" /opt/alfresco/tomcat/logs/alfresco.log | tail -20
```

## Backup and Restore Procedures

### Full Backup

```bash
#!/bin/bash
# alfresco-backup.sh
BACKUP_DIR="/backup/alfresco/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database backup
pg_dump -U alfresco -h $DB_HOST -Fc -f "$BACKUP_DIR/alfresco_db.dump" alfresco

# Content store backup
rsync -av /opt/alfresco/alf_data/contentstore/ "$BACKUP_DIR/contentstore/"

# Solr index backup (optional - can be rebuilt)
curl "http://localhost:8983/solr/alfresco/replication?command=backup&location=$BACKUP_DIR/solr"

# Configuration backup
tar czf "$BACKUP_DIR/alfresco_config.tar.gz" \
  /opt/alfresco/tomcat/shared/classes/alfresco-global.properties \
  /opt/alfresco/tomcat/shared/classes/alfresco/ \
  /opt/alfresco/tomcat/bin/setenv.sh

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
# alfresco-restore.sh
BACKUP_DIR="$1"

sudo systemctl stop alfresco alfresco-share alfresco-search

# Restore database
pg_restore -U alfresco -h $DB_HOST -d alfresco --clean --if-exists "$BACKUP_DIR/alfresco_db.dump"

# Restore content store
rsync -av "$BACKUP_DIR/contentstore/" /opt/alfresco/alf_data/contentstore/

# Restore configuration
tar xzf "$BACKUP_DIR/alfresco_config.tar.gz" -C /

sudo systemctl start alfresco alfresco-search alfresco-share
```

### Backup Schedule

| Type | Frequency | Retention | Storage |
|------|-----------|-----------|---------|
| Full DB + Content | Daily 01:00 UTC | 30 days | S3 |
| Incremental Content | Every 6 hours | 7 days | S3 |
| Configuration | On change | 90 days | Git + S3 |
| Solr Index | Weekly | 4 weeks | Local |

## Performance Tuning Parameters

### JVM Tuning (Repository)

```bash
# /opt/alfresco/tomcat/bin/setenv.sh
JAVA_OPTS="-server \
  -Xms4g -Xmx8g \
  -XX:+UseG1GC \
  -XX:+UseStringDeduplication \
  -XX:MaxGCPauseMillis=200 \
  -Djava.awt.headless=true"
```

### Alfresco Properties

```properties
# alfresco-global.properties
db.pool.max=100
db.pool.min=10
system.content.caching.maxUsageMB=4096
system.content.caching.minFileAgeMillis=0
cache.userToAuthoritySharedCache.maxItems=5000
cache.node.allRootNodesSharedCache.maxItems=1000
```

### PostgreSQL Tuning

```ini
shared_buffers = 4GB
effective_cache_size = 12GB
work_mem = 256MB
maintenance_work_mem = 1GB
max_connections = 200
```

## Scaling Procedures

### Vertical Scaling

1. Increase JVM heap in `setenv.sh`
2. Scale PostgreSQL resources
3. Increase Solr heap for larger indexes
4. Add CPU cores for concurrent document processing

### Horizontal Scaling

1. **Repository clustering**: Deploy multiple repository instances behind load balancer
2. **Content store**: Use shared NFS or S3-based content store
3. **Database**: Use PostgreSQL replication for read scaling
4. **Search**: Deploy Solr in SolrCloud mode for distributed search
5. **Transform**: Scale transform services independently

## Emergency Rollback Procedures

```bash
#!/bin/bash
# alfresco-rollback.sh
PREVIOUS_VERSION="$1"

sudo systemctl stop alfresco alfresco-share alfresco-search

# Restore application
rsync -a /opt/alfresco-releases/$PREVIOUS_VERSION/ /opt/alfresco/

# Restore database
pg_restore -U alfresco -h $DB_HOST -d alfresco --clean --if-exists \
  /backup/alfresco/pre-deploy/alfresco_db.dump

# Restore content store if needed
rsync -a /backup/alfresco/pre-deploy/contentstore/ /opt/alfresco/alf_data/contentstore/

sudo systemctl start alfresco alfresco-search alfresco-share

# Verify
sleep 60
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/alfresco/api/-default-/public/alfresco/versions/1/probes/-live-
```
