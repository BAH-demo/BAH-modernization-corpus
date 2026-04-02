# Django Oscar Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Django Oscar |
| **Type** | E-commerce Platform |
| **Language** | Python (Django) |
| **Tier** | Tier 2 - Enterprise Application |
| **LOC** | 50,000+ |
| **Category** | E-commerce / Online Retail |
| **Criticality** | High |

### Architecture

Django Oscar is a Python-based e-commerce framework built on Django:

- **Web Layer**: Django views and templates with Oscar dashboard
- **Business Logic**: Oscar apps (catalogue, basket, checkout, order, payment)
- **ORM**: Django ORM with PostgreSQL
- **Task Queue**: Celery with Redis broker for async processing
- **Search**: Elasticsearch via django-oscar-elasticsearch or Solr
- **Cache**: Redis/Memcached for page and query caching

```
┌─────────────────────────────────────────────┐
│              Nginx Reverse Proxy             │
├─────────────────────────────────────────────┤
│          Gunicorn WSGI Server               │
│  ┌──────────────────────────────────────┐   │
│  │         Django Oscar App             │   │
│  │  ┌──────┐ ┌────────┐ ┌───────────┐  │   │
│  │  │Catalog│ │Checkout│ │ Dashboard │  │   │
│  │  └──────┘ └────────┘ └───────────┘  │   │
│  └──────────────────────────────────────┘   │
├──────────────┬──────────┬───────────────────┤
│  PostgreSQL  │  Redis   │  Elasticsearch    │
│  (Data)      │  (Cache) │  (Search)         │
└──────────────┴──────────┴───────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 20 GB SSD | 50 GB SSD |
| Python | 3.8+ | 3.10+ |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Python 3.8+ with pip and venv
- PostgreSQL 14+
- Redis 6+ (cache + Celery broker)
- Elasticsearch 7.x (search)
- Nginx (reverse proxy)
- Gunicorn (WSGI server)
- Celery (task queue)
- Node.js 16+ (asset compilation)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Nginx) | Inbound |
| 8000 | Gunicorn | Internal |
| 5432 | PostgreSQL | Internal |
| 6379 | Redis | Internal |
| 9200 | Elasticsearch | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Infrastructure services
sudo systemctl start postgresql redis elasticsearch

# 2. Application
sudo systemctl start oscar-web     # Gunicorn
sudo systemctl start oscar-celery  # Celery workers
sudo systemctl start oscar-beat    # Celery beat scheduler

# 3. Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health/
```

### Manual Start

```bash
cd /opt/oscar
source venv/bin/activate

# Web server
gunicorn config.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --timeout 120

# Celery worker (separate terminal)
celery -A config worker -l info --concurrency=4

# Celery beat (separate terminal)
celery -A config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

### Shutdown Sequence

```bash
sudo systemctl stop oscar-beat
sudo systemctl stop oscar-celery
sudo systemctl stop oscar-web
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/health/` | GET | HTTP 200 | Application health |
| `/api/` | GET | HTTP 200 | API availability |
| `/dashboard/` | GET | HTTP 302 (login) | Dashboard access |
| `/catalogue/` | GET | HTTP 200 | Catalogue browsing |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:8000"

# Web check
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/health/")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: Django Oscar is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

# Celery check
CELERY_PING=$(cd /opt/oscar && source venv/bin/activate && celery -A config inspect ping 2>/dev/null | grep -c "pong")
if [ "$CELERY_PING" -lt 1 ]; then
    echo "WARNING: Celery workers not responding"
    exit 1
fi

echo "OK: Django Oscar healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Celery Task Failures

**Symptoms**: Orders not processing; emails not sending

**Resolution**:
```bash
# Check Celery worker status
celery -A config inspect active

# Check failed tasks
celery -A config inspect reserved

# Check Redis broker
redis-cli info clients
redis-cli llen celery

# Restart workers
sudo systemctl restart oscar-celery
```

### 2. Search Index Stale

**Symptoms**: Products not appearing in search results

**Resolution**:
```bash
cd /opt/oscar && source venv/bin/activate

# Rebuild search index
python manage.py rebuild_index --noinput

# Or update index
python manage.py update_index

# Check Elasticsearch health
curl http://localhost:9200/_cluster/health
```

### 3. Static Files Missing

**Symptoms**: CSS/JS not loading; broken layout

**Resolution**:
```bash
cd /opt/oscar && source venv/bin/activate

# Collect static files
python manage.py collectstatic --noinput

# Clear cache
redis-cli FLUSHDB

# Restart
sudo systemctl restart oscar-web
```

### 4. Database Migration Issues

**Symptoms**: `ProgrammingError: relation does not exist`

**Resolution**:
```bash
cd /opt/oscar && source venv/bin/activate

# Check migration status
python manage.py showmigrations | grep "\[ \]"

# Apply pending migrations
python manage.py migrate

# If stuck, check migration records
psql -U oscar -d oscar -c "SELECT * FROM django_migrations ORDER BY id DESC LIMIT 20;"
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Application Log | `/var/log/oscar/oscar.log` | Django application log |
| Gunicorn Access | `/var/log/oscar/gunicorn-access.log` | HTTP access log |
| Gunicorn Error | `/var/log/oscar/gunicorn-error.log` | WSGI errors |
| Celery Worker | `/var/log/oscar/celery-worker.log` | Async task log |
| Celery Beat | `/var/log/oscar/celery-beat.log` | Scheduler log |
| Nginx Access | `/var/log/nginx/oscar-access.log` | Proxy access log |

### Log Analysis Commands

```bash
# Recent Django errors
grep "ERROR\|CRITICAL\|Traceback" /var/log/oscar/oscar.log | tail -50

# Failed Celery tasks
grep "Task.*raised\|FAILURE" /var/log/oscar/celery-worker.log | tail -20

# Slow requests
awk '$NF > 5' /var/log/oscar/gunicorn-access.log | tail -20

# 500 errors from Nginx
grep " 500 " /var/log/nginx/oscar-access.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/oscar/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

pg_dump -U oscar -h $DB_HOST -Fc -f "$BACKUP_DIR/oscar_db.dump" oscar
tar czf "$BACKUP_DIR/oscar_media.tar.gz" /opt/oscar/media/
tar czf "$BACKUP_DIR/oscar_config.tar.gz" /opt/oscar/config/settings/

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop oscar-web oscar-celery oscar-beat
pg_restore -U oscar -h $DB_HOST -d oscar --clean --if-exists "$BACKUP_DIR/oscar_db.dump"
tar xzf "$BACKUP_DIR/oscar_media.tar.gz" -C /
sudo systemctl start oscar-web oscar-celery oscar-beat
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB + Media | Daily 02:00 UTC | 30 days |
| Transaction log | Continuous WAL | 7 days |
| Configuration | On change | 90 days |

## Performance Tuning Parameters

### Gunicorn Configuration

```python
# gunicorn.conf.py
workers = 4           # 2 * CPU cores + 1
worker_class = "gthread"
threads = 2
timeout = 120
max_requests = 1000
max_requests_jitter = 50
```

### Django Settings

```python
# settings/production.py
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://localhost:6379/0",
        "OPTIONS": {"CLIENT_CLASS": "django_redis.client.DefaultClient"},
        "TIMEOUT": 300,
    }
}
DATABASES = {
    "default": {
        "CONN_MAX_AGE": 600,
        "CONN_HEALTH_CHECKS": True,
        "OPTIONS": {"MAX_CONNS": 20},
    }
}
```

### PostgreSQL Tuning

```ini
shared_buffers = 2GB
effective_cache_size = 6GB
work_mem = 128MB
max_connections = 100
```

## Scaling Procedures

### Vertical Scaling

1. Increase Gunicorn workers (2 × CPU + 1)
2. Add threads per worker
3. Increase PostgreSQL resources
4. Scale Celery concurrency

### Horizontal Scaling

1. Multiple Gunicorn instances behind Nginx load balancer
2. Redis cluster for distributed caching
3. PostgreSQL read replicas for catalogue queries
4. Celery workers on dedicated nodes
5. Shared media storage (S3/NFS)
6. CDN for static assets

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop oscar-web oscar-celery oscar-beat

rsync -a /opt/oscar-releases/$PREVIOUS_VERSION/ /opt/oscar/

if [ -f "/backup/oscar/pre-deploy/oscar_db.dump" ]; then
    pg_restore -U oscar -h $DB_HOST -d oscar --clean --if-exists \
      /backup/oscar/pre-deploy/oscar_db.dump
fi

cd /opt/oscar && source venv/bin/activate && python manage.py collectstatic --noinput

sudo systemctl start oscar-web oscar-celery oscar-beat

sleep 15
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health/)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```
