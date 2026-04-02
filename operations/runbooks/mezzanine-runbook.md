# Mezzanine Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Mezzanine |
| **Type** | Content Management System (CMS) |
| **Language** | Python (Django) |
| **Tier** | Tier 2 - Enterprise Application |
| **LOC** | 20,000+ |
| **Category** | CMS / Blog Platform |
| **Criticality** | Medium |

### Architecture

Mezzanine is a Django-based CMS with built-in blogging, pages, and e-commerce support:

- **Web Layer**: Django views with Mezzanine templates and Cartridge (e-commerce)
- **Admin**: Django admin with Mezzanine customizations (inline editing)
- **ORM**: Django ORM (PostgreSQL recommended)
- **Cache**: Redis/Memcached for page caching
- **Media**: File-based or S3 media storage
- **Search**: Django Haystack with Elasticsearch/Whoosh

```
┌─────────────────────────────────────────┐
│           Nginx Reverse Proxy           │
├─────────────────────────────────────────┤
│         Gunicorn WSGI Server            │
│  ┌───────────────────────────────────┐  │
│  │        Mezzanine CMS App         │  │
│  │  ┌───────┐ ┌──────┐ ┌─────────┐ │  │
│  │  │ Pages │ │ Blog │ │ Gallery │ │  │
│  │  └───────┘ └──────┘ └─────────┘ │  │
│  └───────────────────────────────────┘  │
├──────────────────┬──────────────────────┤
│   PostgreSQL     │     Redis (Cache)    │
└──────────────────┴──────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 2 GB | 4 GB |
| Disk | 10 GB SSD | 50 GB SSD |
| Python | 3.8+ | 3.10+ |
| OS | RHEL 8+ / Ubuntu 20.04+ | RHEL 9 / Ubuntu 22.04 |

### Software Dependencies

- Python 3.8+ with pip and venv
- PostgreSQL 14+ (or SQLite for dev)
- Redis 6+ (caching)
- Nginx (reverse proxy)
- Gunicorn (WSGI server)
- Pillow (image processing)
- Node.js (optional, asset pipeline)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Nginx) | Inbound |
| 8000 | Gunicorn | Internal |
| 5432 | PostgreSQL | Internal |
| 6379 | Redis | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Infrastructure
sudo systemctl start postgresql redis

# 2. Application
sudo systemctl start mezzanine

# 3. Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/
```

### Manual Start

```bash
cd /opt/mezzanine
source venv/bin/activate
gunicorn project.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120
```

### Shutdown Sequence

```bash
sudo systemctl stop mezzanine
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/` | GET | HTTP 200 | Homepage availability |
| `/admin/` | GET | HTTP 302 | Admin interface |
| `/api/` | GET | HTTP 200 | API (if enabled) |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:8000"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: Mezzanine is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

echo "OK: Mezzanine healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Template Rendering Errors

**Symptoms**: HTTP 500 on specific pages; `TemplateSyntaxError`

**Resolution**:
```bash
# Enable debug temporarily
cd /opt/mezzanine && source venv/bin/activate
DEBUG=True python manage.py runserver 0.0.0.0:8001

# Check template directories
python manage.py shell -c "from django.conf import settings; print(settings.TEMPLATES)"

# Clear template cache
redis-cli FLUSHDB
sudo systemctl restart mezzanine
```

### 2. Media Upload Failures

**Symptoms**: Image/file uploads fail; `PermissionError`

**Resolution**:
```bash
# Check media directory permissions
ls -la /opt/mezzanine/media/

# Fix permissions
chown -R www-data:www-data /opt/mezzanine/media/
chmod -R 755 /opt/mezzanine/media/

# Check disk space
df -h /opt/mezzanine/media/
```

### 3. Database Connection Issues

**Symptoms**: `OperationalError: could not connect to server`

**Resolution**:
```bash
# Check PostgreSQL
pg_isready -h $DB_HOST -p 5432

# Check connection in Django
cd /opt/mezzanine && source venv/bin/activate
python manage.py dbshell -c "SELECT 1;"

# Check settings
grep DATABASE /opt/mezzanine/project/settings.py
```

### 4. Cache Invalidation Issues

**Symptoms**: Stale content displayed after edits

**Resolution**:
```bash
# Flush Redis cache
redis-cli FLUSHALL

# Or selective flush
redis-cli KEYS "mezzanine:*" | xargs redis-cli DEL

sudo systemctl restart mezzanine
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Application Log | `/var/log/mezzanine/mezzanine.log` | Django app log |
| Gunicorn Access | `/var/log/mezzanine/gunicorn-access.log` | HTTP access |
| Gunicorn Error | `/var/log/mezzanine/gunicorn-error.log` | WSGI errors |
| Nginx Access | `/var/log/nginx/mezzanine-access.log` | Proxy access |

### Log Analysis Commands

```bash
# Recent errors
grep "ERROR\|Traceback" /var/log/mezzanine/mezzanine.log | tail -30

# 5xx errors
grep " 50[0-9] " /var/log/nginx/mezzanine-access.log | tail -20

# Slow requests
awk '$NF > 3' /var/log/mezzanine/gunicorn-access.log | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/mezzanine/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

pg_dump -U mezzanine -h $DB_HOST -Fc -f "$BACKUP_DIR/mezzanine_db.dump" mezzanine
tar czf "$BACKUP_DIR/mezzanine_media.tar.gz" /opt/mezzanine/media/
tar czf "$BACKUP_DIR/mezzanine_config.tar.gz" /opt/mezzanine/project/

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop mezzanine
pg_restore -U mezzanine -h $DB_HOST -d mezzanine --clean --if-exists "$BACKUP_DIR/mezzanine_db.dump"
tar xzf "$BACKUP_DIR/mezzanine_media.tar.gz" -C /
sudo systemctl start mezzanine
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB + Media | Daily 02:00 UTC | 30 days |
| Configuration | On change | 90 days |

## Performance Tuning Parameters

### Gunicorn

```python
workers = 3
worker_class = "gthread"
threads = 2
timeout = 120
max_requests = 500
```

### Django/Mezzanine Settings

```python
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://localhost:6379/0",
        "TIMEOUT": 300,
    }
}
CACHE_MIDDLEWARE_SECONDS = 300
PAGE_MENU_TEMPLATES_DEFAULT = True
DATABASES = {"default": {"CONN_MAX_AGE": 600}}
```

## Scaling Procedures

### Vertical Scaling

1. Increase Gunicorn workers
2. Add Redis memory
3. Scale PostgreSQL resources

### Horizontal Scaling

1. Multiple Gunicorn instances behind Nginx
2. Shared media via S3/NFS
3. Redis cluster for distributed cache
4. PostgreSQL read replicas
5. CDN for static/media assets

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop mezzanine

rsync -a /opt/mezzanine-releases/$PREVIOUS_VERSION/ /opt/mezzanine/

if [ -f "/backup/mezzanine/pre-deploy/mezzanine_db.dump" ]; then
    pg_restore -U mezzanine -h $DB_HOST -d mezzanine --clean --if-exists \
      /backup/mezzanine/pre-deploy/mezzanine_db.dump
fi

sudo systemctl start mezzanine

sleep 10
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```
