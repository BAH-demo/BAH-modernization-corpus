# Canary Deployment Strategy

## Federal Modernization Portfolio - All 13 Systems

---

## 1. Overview

Canary deployment gradually shifts traffic from the current version to a new version, starting with a small percentage and increasing as confidence grows. This minimizes blast radius and allows detection of issues before full rollout.

```
                         ┌──────────────────┐
                         │   Load Balancer   │
                         │  (Traffic Split)  │
                         └────────┬─────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │              │
            ┌───────▼──────┐  Weight    ┌───────▼──────┐
            │  STABLE v1   │  Split     │  CANARY v2   │
            │  (95%)       │  ─────►    │  (5%)        │
            │              │            │              │
            │  N instances │            │  1 instance  │
            └──────────────┘            └──────────────┘
```

---

## 2. Canary Progression Stages

### 2.1 Standard Progression

| Stage | Traffic % | Duration | Criteria to Advance |
|-------|----------|----------|-------------------|
| 0 | 0% (deploy only) | 15 min | Health checks pass |
| 1 | 5% | 30 min | Error rate < 0.1%, latency within 10% of baseline |
| 2 | 10% | 30 min | Error rate < 0.1%, no alerts firing |
| 3 | 25% | 1 hour | Error rate < 0.1%, business metrics stable |
| 4 | 50% | 1 hour | All metrics within tolerance |
| 5 | 75% | 30 min | Final validation |
| 6 | 100% | - | Full rollout complete |

### 2.2 Expedited Progression (Hotfixes)

| Stage | Traffic % | Duration | Criteria |
|-------|----------|----------|----------|
| 0 | 0% | 5 min | Health checks pass |
| 1 | 10% | 15 min | Error rate < 0.1% |
| 2 | 50% | 15 min | Error rate < 0.1% |
| 3 | 100% | - | Full rollout |

### 2.3 Per-System Canary Configuration

| System | Min Canary Instances | Canary Cookie | Sticky Sessions |
|--------|---------------------|---------------|-----------------|
| Apache OFBiz | 1 | X-Canary-OFBiz | Yes (session) |
| Alfresco Community | 1 repo + 1 share | X-Canary-Alfresco | Yes |
| Nuxeo | 1 | X-Canary-Nuxeo | Yes |
| B2CWeb | 1 | X-Canary-B2CWeb | No |
| Monolith Enterprise | 1 | X-Canary-Monolith | Yes (EJB) |
| Odoo | 1 web + 1 worker | X-Canary-Odoo | Yes (session) |
| Django Oscar | 1 gunicorn + 1 celery | X-Canary-Oscar | No |
| Mezzanine | 1 | X-Canary-Mezzanine | No |
| Umbraco CMS | 1 | X-Canary-Umbraco | No |
| DFe-NET | 1 + 1 worker | X-Canary-DfeNet | Yes |
| CFWheels | 1 | X-Canary-CFWheels | Yes (CF session) |

---

## 3. Canary Deployment Procedure

### 3.1 Deploy Canary Instance

```bash
#!/bin/bash
# canary-deploy.sh <system-name> <version>

SYSTEM=$1
VERSION=$2

echo "=== Deploying canary for $SYSTEM v$VERSION ==="

# Deploy single canary instance
deploy_canary_instance() {
    local host=$1
    local system=$2
    local version=$3

    echo "Deploying canary to $host..."
    # System-specific deployment logic
    ansible-playbook deploy-${system}.yml \
        --limit "$host" \
        --extra-vars "version=$version canary=true"
}

# Get canary host
CANARY_HOST=$(get_canary_host $SYSTEM)
deploy_canary_instance "$CANARY_HOST" "$SYSTEM" "$VERSION"

# Wait for health
echo "Waiting for canary health check..."
for i in $(seq 1 30); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://${CANARY_HOST}:${PORT}/${SYSTEM}/health")
    if [ "$STATUS" = "200" ]; then
        echo "Canary is healthy"
        break
    fi
    sleep 10
done

echo "Canary deployed. Ready for traffic."
```

### 3.2 Gradual Traffic Shift

```bash
#!/bin/bash
# canary-shift-traffic.sh <system> <percentage>

SYSTEM=$1
PERCENTAGE=$2

echo "=== Setting canary traffic to ${PERCENTAGE}% for $SYSTEM ==="

# Update load balancer weight
curl -X PUT "http://lb.internal.gov/api/canary/${SYSTEM}" \
    -H "Content-Type: application/json" \
    -d "{\"canary_weight\": $PERCENTAGE, \"stable_weight\": $((100 - PERCENTAGE))}"

echo "Traffic split: ${PERCENTAGE}% canary, $((100 - PERCENTAGE))% stable"
```

### 3.3 Automated Canary Analysis

```bash
#!/bin/bash
# canary-analyze.sh <system> <duration-minutes>

SYSTEM=$1
DURATION=$2

echo "=== Analyzing canary for $SYSTEM over ${DURATION} minutes ==="

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION * 60))

while [ $(date +%s) -lt $END_TIME ]; do
    # Compare canary vs stable error rates
    CANARY_ERROR=$(curl -s "http://prometheus:9090/api/v1/query" \
        --data-urlencode "query=rate(http_server_requests_total{job=\"${SYSTEM}\",instance=~\"canary.*\",status=~\"5..\"}[5m])")

    STABLE_ERROR=$(curl -s "http://prometheus:9090/api/v1/query" \
        --data-urlencode "query=rate(http_server_requests_total{job=\"${SYSTEM}\",instance!~\"canary.*\",status=~\"5..\"}[5m])")

    # Compare canary vs stable latency
    CANARY_P95=$(curl -s "http://prometheus:9090/api/v1/query" \
        --data-urlencode "query=histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{job=\"${SYSTEM}\",instance=~\"canary.*\"}[5m]))")

    STABLE_P95=$(curl -s "http://prometheus:9090/api/v1/query" \
        --data-urlencode "query=histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{job=\"${SYSTEM}\",instance!~\"canary.*\"}[5m]))")

    echo "$(date): Canary error=$CANARY_ERROR, Stable error=$STABLE_ERROR"
    echo "$(date): Canary P95=$CANARY_P95, Stable P95=$STABLE_P95"

    # Auto-rollback conditions
    CANARY_ERR_VAL=$(echo $CANARY_ERROR | jq -r '.data.result[0].value[1] // "0"')
    if (( $(echo "$CANARY_ERR_VAL > 0.05" | bc -l 2>/dev/null) )); then
        echo "ALERT: Canary error rate too high. Initiating rollback."
        ./canary-rollback.sh $SYSTEM
        exit 1
    fi

    sleep 30
done

echo "=== Canary analysis PASSED ==="
```

---

## 4. Canary Success Criteria

### 4.1 Metrics Comparison

| Metric | Threshold | Action if Exceeded |
|--------|-----------|-------------------|
| Error rate (5xx) | > 2x stable | Auto-rollback |
| P95 latency | > 1.5x stable | Alert, manual review |
| P99 latency | > 2x stable | Auto-rollback |
| CPU usage | > 1.5x stable | Alert |
| Memory usage | > 1.3x stable | Alert |
| Business metric (orders/min) | < 0.9x stable | Alert, manual review |

### 4.2 Automatic Rollback Triggers

- Error rate exceeds 5% for more than 2 minutes
- Health check fails 3 consecutive times
- Memory usage exceeds 95% on canary
- Latency P99 exceeds 10 seconds
- Any SEV-1 alert fires on canary

---

## 5. Rollback Procedure

```bash
#!/bin/bash
# canary-rollback.sh <system>

SYSTEM=$1

echo "=== Rolling back canary for $SYSTEM ==="

# Remove canary from load balancer immediately
curl -X PUT "http://lb.internal.gov/api/canary/${SYSTEM}" \
    -H "Content-Type: application/json" \
    -d '{"canary_weight": 0, "stable_weight": 100}'

echo "Canary removed from traffic"

# Stop canary instance
CANARY_HOST=$(get_canary_host $SYSTEM)
ssh $CANARY_HOST "systemctl stop $SYSTEM"

# Redeploy stable version to canary host
STABLE_VERSION=$(get_stable_version $SYSTEM)
deploy_canary_instance "$CANARY_HOST" "$SYSTEM" "$STABLE_VERSION"

echo "Rollback complete. All traffic on stable version."
```

**Rollback time**: < 10 seconds (traffic shift) + instance revert time

---

## 6. Promoting Canary to Full Deployment

```bash
#!/bin/bash
# canary-promote.sh <system> <version>

SYSTEM=$1
VERSION=$2

echo "=== Promoting $SYSTEM v$VERSION from canary to full deployment ==="

# Rolling update of stable instances
STABLE_HOSTS=$(get_stable_hosts $SYSTEM)
for host in $STABLE_HOSTS; do
    echo "Updating $host to v$VERSION..."

    # Remove from LB, update, add back
    curl -X POST "http://lb.internal.gov/api/drain/$host"
    sleep 30  # drain connections

    # Deploy new version
    ansible-playbook deploy-${SYSTEM}.yml \
        --limit "$host" \
        --extra-vars "version=$VERSION"

    # Wait for health
    wait_for_health "$host" "$SYSTEM"

    # Add back to LB
    curl -X POST "http://lb.internal.gov/api/activate/$host"

    echo "$host updated successfully"
done

# Remove canary routing (all instances now on same version)
curl -X DELETE "http://lb.internal.gov/api/canary/${SYSTEM}"

echo "=== Full promotion complete ==="
```

---

## 7. Federal Compliance Notes

- Canary instances must meet the same security controls as stable instances
- All canary deployments logged in change management system
- Canary analysis results archived for audit
- Traffic split configuration changes auditable
- Rollback events automatically generate incident records
