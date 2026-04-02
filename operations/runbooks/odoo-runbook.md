# Odoo Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Odoo |
| **Type** | Enterprise Resource Planning (ERP) |
| **Language** | Python |
| **Tier** | Tier 1 - Enterprise Monolith |
| **LOC** | 500,000+ |
| **Category** | ERP / Business Management Suite |
| **Criticality** | High |

### Architecture

Odoo is a Python-based modular ERP platform built on a custom ORM and web framework:

- **Web Layer**: Werkzeug WSGI server with custom routing and controllers
- **ORM Layer**: Custom Python ORM with PostgreSQL backend
- **Module System**: Plugin-based architecture with 30+ core modules
- **Report Engine**: QWeb templating engine with PDF generation (wkhtmltopdf)
- **Real-time**: Longpolling service for live notifications

```
┌─────────────────────────────────────────────┐
│              Nginx Reverse Proxy             │
├─────────────────┬───────────────────────────┤
│  Odoo Web (8069)│  Odoo Longpoll (8072)     │
│  ┌────────────┐ │  ┌─────────────────────┐  │
│  │ Controller │ │  │  Gevent Workers     │  │
│  │   Layer    │ │  │  (WebSocket/LP)     │  │
│  ├────────────┤ │  └─────────────────────┘  │
│  │  ORM/API   │ │                           │
│  ├────────────┤ │                           │
│  │  Modules   │ │                           │
│  └────────────┘ │                           │
├─────────────────┴───────────────────────────┤
│              PostgreSQL 14+                 │
└─────────────────────────────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 4 cores | 8 cores |
| RAM | 8 GB | 16 GB |
| Disk | 50 GB SSD | 200 GB SSD |
| Python | 3.8+ | 3.10+ |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Python 3.8+ with pip and venv
- PostgreSQL 14+
- Node.js 16+ (asset compilation)
- wkhtmltopdf 0.12.6+ (PDF reports)
- Nginx (reverse proxy)
- Redis (optional, for session store)
- Systemd (service management)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Nginx) | Inbound |
| 8069 | Odoo Web | Internal |
| 8072 | Odoo Longpoll | Internal |
| 5432 | PostgreSQL | Internal |
| 6379 | Redis | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Verify database
pg_isready -h $DB_HOST -p 5432 -U odoo

# 2. Start Odoo
sudo systemctl start odoo

# 3. Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:8069/web/health
```

### Manual Start (Development/Debug)

```bash
cd /opt/odoo
source venv/bin/activate
python odoo-bin \
  --config=/etc/odoo/odoo.conf \
  --workers=4 \
  --limit-memory-hard=2684354560 \
  --limit-memory-soft=2147483648 \
  --limit-time-real=120
```

### Shutdown Sequence

```bash
sudo systemctl stop odoo
# Force if needed
sudo systemctl kill -s SIGKILL odoo
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/web/health` | GET | HTTP 200 `OK` | Application health |
| `/web/login` | GET | HTTP 200 | Web UI availability |
| `/web/database/selector` | GET | HTTP 200 | Database manager |

### Health Check Script

```bash
#!/bin/bash
ODOO_URL="http://localhost:8069"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$ODOO_URL/web/health")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: Odoo is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

# Check worker count
WORKERS=$(ps aux | grep "odoo.*worker" | grep -v grep | wc -l)
if [ "$WORKERS" -lt 2 ]; then
    echo "WARNING: Only $WORKERS Odoo workers running"
    exit 1
fi

echo "OK: Odoo healthy ($WORKERS workers)"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Worker Process Crashes

**Symptoms**: HTTP 502/503 errors; workers restarting frequently

**Resolution**:
```bash
# Check worker status
ps aux | grep odoo | grep -v grep

# Check memory limits in odoo.conf
grep "limit_memory" /etc/odoo/odoo.conf

# Increase limits
# limit_memory_hard = 2684354560  (2.5GB)
# limit_memory_soft = 2147483648  (2GB)
# limit_time_real = 120

sudo systemctl restart odoo
```

### 2. Cron Job Failures

**Symptoms**: Scheduled actions not executing; `ir.cron` errors

**Resolution**:
```bash
# Check cron worker
ps aux | grep "odoo.*cron" | grep -v grep

# Check cron logs
grep "ir.cron\|cron.worker" /var/log/odoo/odoo-server.log | tail -20

# Manually trigger cron
python3 -c "
import xmlrpc.client
common = xmlrpc.client.ServerProxy('http://localhost:8069/xmlrpc/2/common')
uid = common.authenticate('$DB_NAME', 'admin', '$ADMIN_PASSWORD', {})
models = xmlrpc.client.ServerProxy('http://localhost:8069/xmlrpc/2/object')
models.execute_kw('$DB_NAME', uid, '$ADMIN_PASSWORD', 'ir.cron', 'method_direct_trigger', [[cron_id]])
"
```

### 3. Module Installation Failures

**Symptoms**: Module install hangs or fails; migration errors

**Resolution**:
```bash
# Check module state
psql -U odoo -d $DB_NAME -c "SELECT name, state FROM ir_module_module WHERE state = 'to upgrade' OR state = 'to install';"

# Reset stuck modules
psql -U odoo -d $DB_NAME -c "UPDATE ir_module_module SET state='installed' WHERE state='to upgrade';"

# Force module update
/opt/odoo/odoo-bin -c /etc/odoo/odoo.conf -d $DB_NAME -u module_name --stop-after-init
```

### 4. Database Lock Contention

**Symptoms**: Slow queries; deadlock warnings in PostgreSQL logs

**Resolution**:
```bash
# Find blocking queries
psql -U odoo -c "SELECT pid, age(clock_timestamp(), query_start), usename, query, state FROM pg_stat_activity WHERE state != 'idle' AND query NOT ILIKE '%pg_stat_activity%' ORDER BY query_start;"

# Kill long-running queries
psql -U odoo -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'active' AND query_start < now() - interval '10 minutes' AND usename = 'odoo';"
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Server Log | `/var/log/odoo/odoo-server.log` | Main application log |
| Access Log | `/var/log/nginx/odoo-access.log` | HTTP access log |
| Error Log | `/var/log/nginx/odoo-error.log` | Nginx error log |
| PostgreSQL | `/var/log/postgresql/postgresql-14-main.log` | Database log |

### Log Analysis Commands

```bash
# Recent errors
grep "ERROR\|CRITICAL" /var/log/odoo/odoo-server.log | tail -50

# Slow RPC calls
grep "RPC.*ms" /var/log/odoo/odoo-server.log | awk -F'ms' '{if ($1 > 5000) print}' | tail -20

# Module errors
grep "module\|ModuleNotFound\|ImportError" /var/log/odoo/odoo-server.log | tail -20

# Worker crashes
grep "Worker\|kill\|SIGKILL\|SIGTERM" /var/log/odoo/odoo-server.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/odoo/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database
pg_dump -U odoo -h $DB_HOST -Fc -f "$BACKUP_DIR/odoo_db.dump" $DB_NAME

# Filestore
tar czf "$BACKUP_DIR/odoo_filestore.tar.gz" /opt/odoo/.local/share/Odoo/filestore/$DB_NAME/

# Configuration
cp /etc/odoo/odoo.conf "$BACKUP_DIR/"

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop odoo
pg_restore -U odoo -h $DB_HOST -d $DB_NAME --clean --if-exists "$BACKUP_DIR/odoo_db.dump"
tar xzf "$BACKUP_DIR/odoo_filestore.tar.gz" -C /
sudo systemctl start odoo
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB + Filestore | Daily 02:00 UTC | 30 days |
| WAL archiving | Continuous | 7 days |
| Configuration | On change | 90 days |

## Performance Tuning Parameters

### Odoo Configuration

```ini
# /etc/odoo/odoo.conf
[options]
workers = 4
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_real = 120
limit_time_cpu = 60
limit_request = 8192
db_maxconn = 64
```

### PostgreSQL Tuning

```ini
shared_buffers = 4GB
effective_cache_size = 12GB
work_mem = 256MB
maintenance_work_mem = 1GB
max_connections = 200
```

### Nginx Configuration

```nginx
upstream odoo {
    server 127.0.0.1:8069;
}
upstream odoochat {
    server 127.0.0.1:8072;
}

server {
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    client_max_body_size 200m;
}
```

## Scaling Procedures

### Vertical Scaling

1. Increase workers (1 worker per CPU core, +1 for cron)
2. Increase memory limits per worker
3. Scale PostgreSQL resources
4. Tune PostgreSQL connection pool

### Horizontal Scaling

1. Multiple Odoo instances behind load balancer with sticky sessions
2. Shared PostgreSQL with PgBouncer connection pooler
3. Shared filestore (NFS/S3)
4. Redis for session management across instances
5. Dedicated cron worker instance

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop odoo

cp -r /opt/odoo /opt/odoo.rollback.$(date +%s)
rsync -a /opt/odoo-releases/$PREVIOUS_VERSION/ /opt/odoo/

if [ -f "/backup/odoo/pre-deploy/odoo_db.dump" ]; then
    pg_restore -U odoo -h $DB_HOST -d $DB_NAME --clean --if-exists \
      /backup/odoo/pre-deploy/odoo_db.dump
fi

sudo systemctl start odoo

sleep 20
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8069/web/health)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```
