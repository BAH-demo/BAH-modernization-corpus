# DFe-NET Runbook

## System Overview

| Field | Value |
|-------|-------|
| **System Name** | DFe-NET |
| **Type** | Fiscal Document Management |
| **Language** | C# (.NET) |
| **Tier** | Tier 2 - Enterprise Application |
| **LOC** | 15,000+ |
| **Category** | Fiscal / Electronic Document Processing |
| **Criticality** | High (regulatory compliance) |

### Architecture

DFe-NET is a .NET application for electronic fiscal document (NF-e, NFC-e) processing:

- **API Layer**: ASP.NET Core Web API for document submission/query
- **Processing Engine**: XML signing, validation, and transmission to government SEFAZ services
- **Certificate Management**: X.509 digital certificate handling for document signing
- **Data Layer**: Entity Framework Core with SQL Server
- **Queue**: Background job processing for batch document operations

```
┌─────────────────────────────────────────┐
│         Reverse Proxy (Nginx)           │
├─────────────────────────────────────────┤
│       ASP.NET Core Web API              │
│  ┌──────────┐ ┌───────────┐ ┌────────┐ │
│  │ Document │ │XML Signing│ │ SEFAZ  │ │
│  │   API    │ │  Engine   │ │ Client │ │
│  └──────────┘ └───────────┘ └────────┘ │
├──────────────────┬──────────────────────┤
│   SQL Server     │  Certificate Store   │
└──────────────────┴──────────────────────┘
```

## Prerequisites and Dependencies

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 cores | 4 cores |
| RAM | 4 GB | 8 GB |
| Disk | 20 GB SSD | 50 GB SSD |
| .NET | .NET 6+ | .NET 8 |
| OS | RHEL 8+ / Ubuntu 20.04+ / Windows Server 2019+ | Ubuntu 22.04 |

### Software Dependencies

- .NET 8 SDK and Runtime
- SQL Server 2019+
- Nginx (reverse proxy)
- X.509 Digital Certificates (A1 or A3 type)
- OpenSSL (certificate management)

### Network Requirements

| Port | Service | Direction |
|------|---------|-----------|
| 443 | HTTPS (Nginx) | Inbound |
| 5000 | Kestrel HTTP | Internal |
| 1433 | SQL Server | Internal |
| 443 | SEFAZ Web Services | Outbound |

## Startup and Shutdown Procedures

### Startup Sequence

```bash
# 1. Start SQL Server
sudo systemctl start mssql-server

# 2. Start DFe-NET
sudo systemctl start dfe-net

# 3. Verify
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/health
```

### Manual Start

```bash
cd /opt/dfe-net
ASPNETCORE_ENVIRONMENT=Production dotnet DfeNet.Web.dll --urls "http://0.0.0.0:5000"
```

### Shutdown Sequence

```bash
sudo systemctl stop dfe-net
```

## Health Check Endpoints and Validation

| Endpoint | Method | Expected | Purpose |
|----------|--------|----------|---------|
| `/api/health` | GET | HTTP 200 | Application health |
| `/api/health/certificate` | GET | HTTP 200 | Certificate validity check |
| `/api/health/sefaz` | GET | HTTP 200 | SEFAZ connectivity |
| `/api/status` | GET | HTTP 200 + JSON | Detailed system status |

### Health Check Script

```bash
#!/bin/bash
APP_URL="http://localhost:5000"

# App health
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/api/health")
if [ "$HTTP_CODE" -ne 200 ]; then
    echo "CRITICAL: DFe-NET is DOWN (HTTP $HTTP_CODE)"
    exit 2
fi

# Certificate check
CERT_STATUS=$(curl -s "$APP_URL/api/health/certificate" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status','unknown'))")
if [ "$CERT_STATUS" = "expiring" ]; then
    echo "WARNING: Digital certificate expiring soon"
    exit 1
fi
if [ "$CERT_STATUS" != "valid" ]; then
    echo "CRITICAL: Digital certificate invalid ($CERT_STATUS)"
    exit 2
fi

# SEFAZ connectivity
SEFAZ_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/api/health/sefaz")
if [ "$SEFAZ_CODE" -ne 200 ]; then
    echo "WARNING: SEFAZ connectivity issue"
    exit 1
fi

echo "OK: DFe-NET healthy"
exit 0
```

## Common Troubleshooting Scenarios

### 1. Digital Certificate Expiration

**Symptoms**: Document signing failures; `CryptographicException`

**Resolution**:
```bash
# Check certificate expiry
openssl x509 -in /opt/dfe-net/certs/signing.pfx -noout -enddate 2>/dev/null || \
openssl pkcs12 -in /opt/dfe-net/certs/signing.pfx -nodes -passin pass:$CERT_PASS | \
  openssl x509 -noout -enddate

# Install new certificate
cp /path/to/new-cert.pfx /opt/dfe-net/certs/signing.pfx
chown dfe-net:dfe-net /opt/dfe-net/certs/signing.pfx
chmod 600 /opt/dfe-net/certs/signing.pfx

# Update password in config if changed
# Update appsettings.Production.json

sudo systemctl restart dfe-net
```

### 2. SEFAZ Communication Failures

**Symptoms**: Document transmission failures; SOAP timeouts

**Resolution**:
```bash
# Test SEFAZ endpoint connectivity
curl -v https://nfe.sefaz.gov.br/nfe4/services/NFeAutorizacao4

# Check if SEFAZ is in contingency mode
# (Government services may be down)

# Enable contingency mode
curl -X POST http://localhost:5000/api/config/contingency \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "mode": "SVC-AN"}'

# Check DNS resolution
dig nfe.sefaz.gov.br
```

### 3. XML Schema Validation Errors

**Symptoms**: Documents rejected by SEFAZ; schema mismatch

**Resolution**:
```bash
# Check current schema version
ls -la /opt/dfe-net/schemas/

# Update schemas
cd /opt/dfe-net/schemas
wget https://www.nfe.fazenda.gov.br/portal/listaConteudo.aspx?tipoConteudo=BMPFMBoln3w=

# Validate XML manually
xmllint --schema /opt/dfe-net/schemas/nfe_v4.00.xsd /tmp/test-nfe.xml

sudo systemctl restart dfe-net
```

### 4. Batch Processing Backlog

**Symptoms**: Document queue growing; processing delays

**Resolution**:
```bash
# Check queue depth
curl http://localhost:5000/api/queue/status

# Check background worker status
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -d DfeDb \
  -Q "SELECT Status, COUNT(*) as Cnt FROM DocumentQueue GROUP BY Status;"

# Increase worker concurrency (if applicable)
# Update appsettings: "BackgroundWorkers": { "Concurrency": 8 }

sudo systemctl restart dfe-net
```

## Log Locations and Log Analysis

| Log File | Path | Purpose |
|----------|------|---------|
| Application Log | `/var/log/dfe-net/app.log` | Main application log |
| SEFAZ Communication | `/var/log/dfe-net/sefaz.log` | Government API interactions |
| Signing Log | `/var/log/dfe-net/signing.log` | Certificate/signing operations |
| SQL Server Log | `/var/opt/mssql/log/errorlog` | Database log |

### Log Analysis Commands

```bash
# SEFAZ communication errors
grep "SEFAZ\|Rejection\|cStat" /var/log/dfe-net/sefaz.log | tail -30

# Signing failures
grep "CryptographicException\|SigningError" /var/log/dfe-net/signing.log | tail -20

# Recent application errors
grep "Error\|Fatal" /var/log/dfe-net/app.log | tail -50
```

## Backup and Restore Procedures

### Backup

```bash
#!/bin/bash
BACKUP_DIR="/backup/dfe-net/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Database (critical - contains fiscal documents)
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
  -Q "BACKUP DATABASE DfeDb TO DISK = '$BACKUP_DIR/dfe_db.bak' WITH COMPRESSION"

# Certificates (critical)
tar czf "$BACKUP_DIR/dfe_certs.tar.gz" /opt/dfe-net/certs/

# XML archives (regulatory requirement)
tar czf "$BACKUP_DIR/dfe_xml_archive.tar.gz" /opt/dfe-net/xml-archive/

# Configuration
tar czf "$BACKUP_DIR/dfe_config.tar.gz" /opt/dfe-net/appsettings*.json

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
BACKUP_DIR="$1"

sudo systemctl stop dfe-net

/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
  -Q "RESTORE DATABASE DfeDb FROM DISK = '$BACKUP_DIR/dfe_db.bak' WITH REPLACE"

tar xzf "$BACKUP_DIR/dfe_certs.tar.gz" -C /
tar xzf "$BACKUP_DIR/dfe_xml_archive.tar.gz" -C /

sudo systemctl start dfe-net
```

### Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Full DB backup | Daily 01:00 UTC | 5 years (regulatory) |
| Transaction log | Every 15 min | 30 days |
| XML archives | Daily | 10 years (regulatory) |
| Certificates | On change | Indefinite |

## Performance Tuning Parameters

### ASP.NET Core

```json
{
  "Kestrel": {
    "Limits": {
      "MaxConcurrentConnections": 100,
      "MaxRequestBodySize": 52428800
    }
  },
  "BackgroundWorkers": {
    "Concurrency": 4,
    "BatchSize": 50,
    "PollingIntervalSeconds": 5
  }
}
```

### SQL Server

```sql
EXEC sp_configure 'max server memory', 4096;
RECONFIGURE;
ALTER DATABASE DfeDb SET QUERY_STORE = ON;
```

## Scaling Procedures

### Vertical Scaling

1. Increase .NET thread pool
2. Add SQL Server memory and CPU
3. Increase background worker concurrency

### Horizontal Scaling

1. Multiple API instances behind load balancer
2. Dedicated worker nodes for batch processing
3. SQL Server Always On for HA
4. Shared certificate store (HSM recommended for production)

## Emergency Rollback Procedures

```bash
#!/bin/bash
PREVIOUS_VERSION="$1"

sudo systemctl stop dfe-net

rsync -a /opt/dfe-net-releases/$PREVIOUS_VERSION/ /opt/dfe-net/

if [ -f "/backup/dfe-net/pre-deploy/dfe_db.bak" ]; then
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" \
      -Q "RESTORE DATABASE DfeDb FROM DISK = '/backup/dfe-net/pre-deploy/dfe_db.bak' WITH REPLACE"
fi

sudo systemctl start dfe-net

sleep 10
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/health)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "Rollback successful"
else
    echo "ROLLBACK FAILED - ESCALATE"
    exit 1
fi
```
