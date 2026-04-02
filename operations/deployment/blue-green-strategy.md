# Blue-Green Deployment Strategy

## Federal Modernization Portfolio - All 13 Systems

---

## 1. Overview

Blue-green deployment maintains two identical production environments ("blue" and "green"). At any time, only one environment serves live traffic. New releases are deployed to the inactive environment, validated, then traffic is switched. This enables zero-downtime deployments and instant rollback.

```
                    ┌─────────────────┐
                    │   Load Balancer  │
                    │  / DNS Router    │
                    └────────┬────────┘
                             │
                   ┌─────────┴─────────┐
                   │                   │
            ┌──────▼──────┐    ┌───────▼─────┐
            │  BLUE ENV   │    │  GREEN ENV  │
            │  (Active)   │    │ (Standby)   │
            │             │    │             │
            │ App Servers │    │ App Servers │
            │ Databases   │    │ Databases   │
            │ Cache       │    │ Cache       │
            └─────────────┘    └─────────────┘
```

---

## 2. Environment Configuration

### 2.1 Environment Definitions

| Component | Blue Environment | Green Environment |
|-----------|-----------------|-------------------|
| **Network Segment** | 10.0.1.0/24 | 10.0.2.0/24 |
| **Load Balancer Pool** | pool-blue | pool-green |
| **DNS Label** | blue.internal.gov | green.internal.gov |
| **Database** | Shared (with read replicas) | Shared (with read replicas) |
| **Cache** | Dedicated Redis cluster | Dedicated Redis cluster |
| **File Storage** | Shared NFS/S3 | Shared NFS/S3 |

### 2.2 Per-System Environment Layout

#### Tier 1 - Java Systems

| System | Blue Instances | Green Instances | Port |
|--------|---------------|-----------------|------|
| Apache OFBiz | 3 | 3 | 8443 |
| Alfresco Community | 3 (repo) + 2 (share) | 3 (repo) + 2 (share) | 8080/8443 |
| Nuxeo | 3 | 3 | 8080 |
| B2CWeb | 2 | 2 | 8080 |
| Monolith Enterprise | 3 | 3 | 8080 |

#### Tier 2 - Python Systems

| System | Blue Instances | Green Instances | Port |
|--------|---------------|-----------------|------|
| Odoo | 3 (web) + 2 (worker) | 3 (web) + 2 (worker) | 8069 |
| Django Oscar | 3 (gunicorn) + 2 (celery) | 3 (gunicorn) + 2 (celery) | 8000 |
| Mezzanine | 2 | 2 | 8000 |

#### Tier 2 - C#/.NET Systems

| System | Blue Instances | Green Instances | Port |
|--------|---------------|-----------------|------|
| Umbraco CMS | 2 | 2 | 5000 |
| DFe-NET | 2 + 1 (worker) | 2 + 1 (worker) | 5000 |

#### Tier 2/3 - Other Systems

| System | Blue Instances | Green Instances | Port |
|--------|---------------|-----------------|------|
| CFWheels | 2 | 2 | 8888 |
| NASTRAN-95 | N/A (batch) | N/A (batch) | N/A |
| Apollo-11 | 1 (simulator) | 1 (simulator) | 8080 |

---

## 3. Deployment Procedure

### 3.1 Pre-Deployment

```bash
#!/bin/bash
# blue-green-pre-deploy.sh
# Determine current active and standby environments

ACTIVE_ENV=$(curl -s http://lb.internal.gov/api/active-pool)
if [ "$ACTIVE_ENV" = "blue" ]; then
    DEPLOY_ENV="green"
else
    DEPLOY_ENV="blue"
fi

echo "Active environment: $ACTIVE_ENV"
echo "Deploying to: $DEPLOY_ENV"

# Pre-deployment checklist
echo "=== Pre-Deployment Checklist ==="
echo "[ ] Release artifacts built and tested in CI"
echo "[ ] Database migrations compatible with both versions"
echo "[ ] Configuration changes applied to $DEPLOY_ENV"
echo "[ ] Smoke test suite prepared"
echo "[ ] Rollback procedure reviewed"
echo "[ ] Change ticket approved"
echo "[ ] Communication sent to stakeholders"
```

### 3.2 Deploy to Standby Environment

```bash
#!/bin/bash
# deploy-to-standby.sh <system-name> <version>

SYSTEM=$1
VERSION=$2
DEPLOY_ENV=$3  # blue or green

echo "=== Deploying $SYSTEM v$VERSION to $DEPLOY_ENV ==="

case $SYSTEM in
    "apache-ofbiz")
        # Deploy OFBiz to standby
        for host in $(get_hosts $DEPLOY_ENV ofbiz); do
            ssh $host "
                systemctl stop ofbiz
                cp /opt/ofbiz/build/libs/ofbiz.jar /opt/ofbiz/build/libs/ofbiz.jar.bak
                curl -o /opt/ofbiz/build/libs/ofbiz.jar $ARTIFACT_URL/ofbiz-${VERSION}.jar
                systemctl start ofbiz
            "
        done
        ;;
    "odoo")
        # Deploy Odoo to standby
        for host in $(get_hosts $DEPLOY_ENV odoo); do
            ssh $host "
                systemctl stop odoo
                pip install --upgrade odoo==$VERSION
                systemctl start odoo
            "
        done
        ;;
    "django-oscar")
        # Deploy Django Oscar to standby
        for host in $(get_hosts $DEPLOY_ENV oscar); do
            ssh $host "
                systemctl stop oscar-gunicorn oscar-celery
                cd /opt/oscar && git fetch && git checkout v$VERSION
                pip install -r requirements.txt
                python manage.py migrate --noinput
                python manage.py collectstatic --noinput
                systemctl start oscar-gunicorn oscar-celery
            "
        done
        ;;
    "umbraco-cms")
        # Deploy Umbraco to standby
        for host in $(get_hosts $DEPLOY_ENV umbraco); do
            ssh $host "
                systemctl stop umbraco
                dotnet publish /opt/umbraco-src -c Release -o /opt/umbraco
                systemctl start umbraco
            "
        done
        ;;
    *)
        echo "Unknown system: $SYSTEM"
        exit 1
        ;;
esac

echo "Deployment complete. Waiting for health checks..."
sleep 30
```

### 3.3 Validate Standby Environment

```bash
#!/bin/bash
# validate-standby.sh <system-name> <deploy-env>

SYSTEM=$1
DEPLOY_ENV=$2

echo "=== Validating $SYSTEM on $DEPLOY_ENV ==="

# Health check
HEALTH_URL="http://${DEPLOY_ENV}.internal.gov/${SYSTEM}/health"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

if [ "$HTTP_STATUS" != "200" ]; then
    echo "FAIL: Health check returned $HTTP_STATUS"
    exit 1
fi
echo "PASS: Health check returned 200"

# Smoke tests
echo "Running smoke tests against $DEPLOY_ENV..."
./smoke-tests/$SYSTEM/run.sh --env $DEPLOY_ENV
SMOKE_RESULT=$?

if [ $SMOKE_RESULT -ne 0 ]; then
    echo "FAIL: Smoke tests failed"
    exit 1
fi
echo "PASS: Smoke tests passed"

# Version verification
DEPLOYED_VERSION=$(curl -s "http://${DEPLOY_ENV}.internal.gov/${SYSTEM}/version")
echo "Deployed version: $DEPLOYED_VERSION"

echo "=== Validation PASSED ==="
```

### 3.4 Traffic Switch

```bash
#!/bin/bash
# switch-traffic.sh <from-env> <to-env>

FROM_ENV=$1
TO_ENV=$2

echo "=== Switching traffic from $FROM_ENV to $TO_ENV ==="

# Pre-switch validation
echo "Final health check on $TO_ENV..."
./validate-standby.sh all $TO_ENV || exit 1

# Switch load balancer
echo "Updating load balancer..."
curl -X POST "http://lb.internal.gov/api/switch" \
    -H "Content-Type: application/json" \
    -d "{\"active_pool\": \"pool-${TO_ENV}\"}"

# Verify switch
sleep 5
ACTIVE=$(curl -s http://lb.internal.gov/api/active-pool)
if [ "$ACTIVE" = "$TO_ENV" ]; then
    echo "Traffic switch successful: $TO_ENV is now active"
else
    echo "ERROR: Traffic switch may have failed. Active: $ACTIVE"
    exit 1
fi

# Monitor for errors
echo "Monitoring error rates for 5 minutes..."
for i in $(seq 1 30); do
    ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=sum(rate(http_server_requests_total{status=~'5..'}[1m]))" | jq '.data.result[0].value[1]')
    if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
        echo "WARNING: Error rate elevated: $ERROR_RATE"
    fi
    sleep 10
done

echo "=== Traffic switch complete ==="
```

---

## 4. Database Considerations

### 4.1 Shared Database Strategy

Both blue and green environments share the same database. This means:

- Database migrations must be **backward-compatible**
- New columns must have default values or be nullable
- Column removals happen in a subsequent release after code no longer references them
- Use feature flags for schema-dependent features

### 4.2 Migration Sequence

```
1. Apply backward-compatible schema changes (additive only)
2. Deploy new code to standby environment
3. Switch traffic to standby
4. (Next release) Remove deprecated columns/tables
```

---

## 5. Rollback

### 5.1 Instant Rollback

```bash
#!/bin/bash
# rollback.sh - Switch traffic back to previous environment

CURRENT_ACTIVE=$(curl -s http://lb.internal.gov/api/active-pool)
if [ "$CURRENT_ACTIVE" = "blue" ]; then
    ROLLBACK_TO="green"
else
    ROLLBACK_TO="blue"
fi

echo "Rolling back: $CURRENT_ACTIVE -> $ROLLBACK_TO"

# Verify rollback target is still healthy
./validate-standby.sh all $ROLLBACK_TO || {
    echo "CRITICAL: Rollback target is not healthy!"
    exit 1
}

# Switch traffic
curl -X POST "http://lb.internal.gov/api/switch" \
    -H "Content-Type: application/json" \
    -d "{\"active_pool\": \"pool-${ROLLBACK_TO}\"}"

echo "Rollback complete. Traffic now on $ROLLBACK_TO"
```

**Rollback time**: < 30 seconds (load balancer switch only)

---

## 6. Federal Compliance Notes

- All deployments must be logged in the change management system
- CAB approval required for production deployments
- Both environments must meet the same FedRAMP/FISMA security controls
- Deployment automation scripts must be version-controlled and auditable
- Blue-green environments must reside in the same FedRAMP-authorized boundary
