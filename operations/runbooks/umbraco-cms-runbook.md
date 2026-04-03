# Umbraco CMS Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | Umbraco CMS |
| **Type** | Content Management System |
| **Language** | C# (.NET) |
| **Tier** | Tier 2 - Enterprise Application |
| **LOC** | 50,000+ |
| **Category** | CMS / Web Content Management |
| **Criticality** | Medium-High |

### Architecture

Umbraco is a .NET-based open-source CMS built on ASP.NET Core:

- **Web Layer**: ASP.NET Core MVC with Razor views
- **Back Office**: Angular-based admin interface
- **Content API**: Delivery API and Management API
- **Data Layer**: Entity Framework Core with SQL Server
- **Media**: Local filesystem or Azure Blob Storage
- **Cache**: In-memory distributed cache (NuCache)

```
┌─────────────────────────────────────────┐
│         Reverse Proxy (Nginx/IIS)       │
├─────────────────────────────────────────┤
│         ASP.NET Core (Kestrel)          │
│  ┌──────────────────────────────────┐   │
│  │         Umbraco CMS Core         │   │
│  │  ┌────────┐ ┌─────────────────┐  │   │
│  │  │Content │ │  Back Office    │  │   │
│  │  │Delivery│ │  (Angular SPA)  │  │   │
│  │  └────────┘ └─────────────────┘  │   │
│  └──────────────────────────────────┘   │
├─────────────────────────────────────────┤
│    SQL Server / SQLite    │   NuCache   │
└───────────────────────────┴─────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 20 GB SSD | 50 GB SSD |
| .NET | .NET 7+ | .NET 8 |
| OS | RHEL 8+ / Ubuntu 20.04+ / Windows Server 2019+ | Ubuntu 22.04 / Windows Server 2022 |

### Software Dependencies

- .NET 8 SDK and Runtime
- SQL Server 2019+ (or SQLite for dev)
- Nginx or IIS (reverse proxy)
- Node.js 18+ (back office build)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (reverse proxy) | Inbound |
| 5000 | Kestrel HTTP | Internal |
| 5001 | Kestrel HTTPS | Internal |
| 1433 | SQL Server | Internal |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Start SQL Server
sudo systemctl start mssql-server

# 2. Start Umbraco
sudo systemctl start umbraco

# 3. Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/umbraco/api/keepalive/ping
```

### Manual Start

```bash
cd /opt/umbraco
dotnet Umbraco.Web.dll --urls "http://0.0.0.0:5000"

# Or with environment
ASPNETCORE_ENVIRONMENT=Production dotnet Umbraco.Web.dll
```

### Shutdown Sequence

```bash
sudo systemctl stop umbraco
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/umbraco/api/keepalive/ping` | GET | HTTP 200 | Liveness |
| `/umbraco` | GET | HTTP 200/302 | Back office |
| `/` | GET | HTTP 200 | Frontend |
| `/api/health` | GET | HTTP 200 | Custom health check |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:5000"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/umbraco/api/keepalive/ping")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: Umbraco is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

# Check SQL Server
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "WARNING: SQL Server connectivity issue"
    exit 1
fi

echo "OK: Umbraco healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. NuCache Corruption

**Symptoms**: Stale content; content tree not loading in back office

**Resolution**:
```bash
# Stop Umbraco
sudo systemctl stop umbraco

# Delete NuCache files
rm -f /opt/umbraco/umbraco/Data/NuCache.*

# Restart - NuCache will rebuild
sudo systemctl start umbraco
```

### 2. Back Office Login Failures

**Symptoms**: Cannot log into /umbraco; authentication errors

**Resolution**:
```bash
# Check user lockout
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d UmbracoDb \
  -Q "SELECT Id, Name, IsLockedOut, FailedPasswordAttempts FROM umbracoUser WHERE IsLockedOut = 1;"

# Unlock user
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d UmbracoDb \
  -Q "UPDATE umbracoUser SET IsLockedOut = 0, FailedPasswordAttempts = 0 WHERE Name = 'admin';"
```

### 3. Media Upload Failures

**Symptoms**: Image/file uploads fail; disk space issues

**Resolution**:
```bash
# Check media folder permissions
ls -la /opt/umbraco/wwwroot/media/

# Check disk space
df -h /opt/umbraco/wwwroot/media/

# Fix permissions
chown -R www-data:www-data /opt/umbraco/wwwroot/media/
chmod -R 755 /opt/umbraco/wwwroot/media/
```

### 4. Database Connection Issues

**Symptoms**: `SqlException`; connection timeout errors

**Resolution**:
```bash
# Check SQL Server status
sudo systemctl status mssql-server

# Test connection
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT @@VERSION"

# Check connection string in appsettings.json
grep "ConnectionStrings" /opt/umbraco/appsettings.json
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Application Log | `/opt/umbraco/umbraco/Logs/UmbracoTraceLog.*.json` | Structured app log |
| Microsoft Log | `/opt/umbraco/umbraco/Logs/MicrosoftLog.*.json` | .NET framework log |
| SQL Server Log | `/var/opt/mssql/log/errorlog` | Database log |
| Nginx Log | `/var/log/nginx/umbraco-access.log` | Proxy access log |

### Log Analysis Commands

```bash
# Recent errors (structured JSON logs)
cat /opt/umbraco/umbraco/Logs/UmbracoTraceLog.$(date +%Y%m%d).json | \
  python3 -c "import sys,json; [print(json.dumps(l)) for l in (json.loads(line) for line in sys.stdin) if l.get('Level') in ('Error','Fatal')]" | tail -20

# Simpler grep approach
grep -i '"Error"\|"Fatal"' /opt/umbraco/umbraco/Logs/UmbracoTraceLog.*.json | tail -20

# SQL Server errors
grep -i "error\|fail" /var/opt/mssql/log/errorlog | tail -20
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/umbraco/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database backup
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
  -Q "BACKUP DATABASE UmbracoDb TO DISK = '$BACKUP_DIR/umbraco_db.bak' WITH COMPRESSION"

# Media files
tar czf "$BACKUP_DIR/umbraco_media.tar.gz" /opt/umbraco/wwwroot/media/

# Configuration
tar czf "$BACKUP_DIR/umbraco_config.tar.gz" \
  /opt/umbraco/appsettings.json \
  /opt/umbraco/appsettings.Production.json

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop umbraco

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
  -Q "RESTORE DATABASE UmbracoDb FROM DISK = '$BACKUP_DIR/umbraco_db.bak' WITH REPLACE"

tar xzf "$BACKUP_DIR/umbraco_media.tar.gz" -C /

sudo systemctl start umbraco
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB backup | Daily 02:00 UTC | 30 days |
| Transaction log | Every 15 min | 7 days |
| Media files | Daily 03:00 UTC | 30 days |
| Configuration | On change | 90 days |

## Performance Tuning Parameters

### ASP.NET Core / Kestrel

```json
{
  "Kestrel": {
    "Limits": {
      "MaxConcurrentConnections": 100,
      "MaxConcurrentUpgradedConnections": 100,
      "MaxRequestBodySize": 104857600,
      "RequestHeadersTimeout": "00:00:30"
    }
  }
}
```

### Umbraco Settings

```json
{
  "Umbraco": {
    "CMS": {
      "Runtime": {
        "MaxQueryStringLength": 90,
        "MaxRequestLength": 51200
      },
      "Content": {
        "ResolveUrlsFromTextString": false
      },
      "WebRouting": {
        "TryMatchingEndpointsForAllPages": false
      }
    }
  }
}
```

### SQL Server Tuning

```sql
-- Increase max memory
EXEC sp_configure 'max server memory', 4096;
RECONFIGURE;

-- Enable query store
ALTER DATABASE UmbracoDb SET QUERY_STORE = ON;
```

## Scaling Procedures

### Vertical Scaling

1. Increase Kestrel thread pool
2. Add SQL Server memory
3. Increase .NET thread pool workers

### Horizontal Scaling

1. Deploy multiple Umbraco instances (load balanced)
2. Configure distributed cache (e.g., NCache, Redis)
3. Use shared media storage (Azure Blob, S3, NFS)
4. SQL Server Always On availability groups
5. Enable Umbraco load balancing configuration

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop umbraco

rsync -a /opt/umbraco-releases/$PREVIOUS_VERSION/ /opt/umbraco/

if [ -f "/backup/umbraco/pre-deploy/umbraco_db.bak" ]; then
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
      -Q "RESTORE DATABASE UmbracoDb FROM DISK = '/backup/umbraco/pre-deploy/umbraco_db.bak' WITH REPLACE"
fi

sudo systemctl start umbraco

sleep 15
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/umbraco/api/keepalive/ping)
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


## Monitoring

### Health Check Endpoints
- **Liveness**: `/healthz` — returns 200 if process is running
- **Readiness**: `/readyz` — returns 200 if accepting traffic
- **Metrics**: `/metrics` — Prometheus-format metrics endpoint

### Key Metrics to Monitor
- Request rate (requests/second)
- Error rate (5xx responses / total responses)
- Response latency (P50, P95, P99)
- CPU and memory utilization
- Active database connections
- Pod restart count

### Dashboards
- Grafana: `legacy-modernization` dashboard
- CloudWatch: Custom namespace metrics
