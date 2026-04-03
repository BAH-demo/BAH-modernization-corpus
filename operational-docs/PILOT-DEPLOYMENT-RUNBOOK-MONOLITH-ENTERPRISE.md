# Pilot Deployment Runbook: Monolith Enterprise on AWS EKS

**CONTROLLED UNCLASSIFIED INFORMATION (CUI)**

---

## 1. Overview

This runbook provides step-by-step instructions for deploying the Monolith Enterprise application as the pilot system on AWS EKS. Monolith Enterprise was selected as the pilot because:

- Smallest Java system in the portfolio (45,237 LOC)
- Build verified successfully (`mvn compile` passes with Jakarta EE dependencies)
- Representative of the Java/Jakarta EE migration pattern used across 5 systems
- Low-risk deployment with minimal external dependencies

### 1.1 Prerequisites

| Requirement | Version | Status |
|-------------|---------|--------|
| AWS CLI | 2.x | Required |
| kubectl | 1.28+ | Required |
| Helm | 3.x | Required |
| Terraform | 1.5+ | Required |
| Docker | 24+ | Required |
| Java JDK | 17+ | Required |
| Maven | 3.9+ | Required |
| AWS Account (GovCloud) | -- | Requires provisioning |

### 1.2 Architecture

```
+----------------------------------------------------------+
|                    AWS GovCloud VPC                        |
|  +--------------------+  +-----------------------------+ |
|  |   Public Subnets    |  |     Private Subnets         | |
|  |  +--------------+  |  |  +-----------------------+  | |
|  |  |  ALB/Ingress  |--|--|--|   EKS Node Group      |  | |
|  |  +--------------+  |  |  |  +-----------------+  |  | |
|  |                     |  |  |  | monolith-enter- |  |  | |
|  |  +--------------+  |  |  |  | prise (3 pods)  |  |  | |
|  |  |  NAT Gateway  |  |  |  |  +-----------------+  |  | |
|  |  +--------------+  |  |  +-----------------------+  | |
|  +--------------------+  |  +-----------------------+  | |
|                           |  |  RDS PostgreSQL 15    |  | |
|                           |  |  (monolith-enterprise |  | |
|                           |  |   -db, encrypted)     |  | |
|                           |  +-----------------------+  | |
|                           |  +-----------------------+  | |
|                           |  |  S3 (artifacts,       |  | |
|                           |  |   KMS-encrypted)      |  | |
|                           |  +-----------------------+  | |
|                           +-----------------------------+ |
+----------------------------------------------------------+
```

---

## 2. Phase 1: Infrastructure Provisioning (Terraform)

### 2.1 Configure AWS Credentials

```bash
# Configure AWS CLI for GovCloud
aws configure --profile govcloud
# AWS Access Key ID: [provided by admin]
# AWS Secret Access Key: [provided by admin]
# Default region: us-gov-west-1
# Default output format: json

export AWS_PROFILE=govcloud
```

### 2.2 Initialize Terraform

```bash
cd terraform/

# Review terraform configuration
terraform init

# Validate configuration (already verified -- 0 warnings)
terraform validate

# Plan infrastructure changes
terraform plan -out=pilot-plan.tfplan

# Review the plan output carefully before applying
# Expected resources: VPC, 6 subnets, EKS cluster, 2 node groups,
# 6 RDS instances, 3 S3 buckets, KMS keys, IAM roles
```

### 2.3 Apply Infrastructure

```bash
# Apply with manual approval
terraform apply pilot-plan.tfplan

# Expected provisioning time: 15-25 minutes
# EKS cluster: ~10 minutes
# RDS instances: ~5-10 minutes
# VPC/networking: ~2-3 minutes
```

### 2.4 Configure kubectl

```bash
# Update kubeconfig for the new EKS cluster
aws eks update-kubeconfig \
  --region us-gov-west-1 \
  --name modernization-cluster \
  --profile govcloud

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

---

## 3. Phase 2: Build & Package Application

### 3.1 Build Monolith Enterprise

```bash
cd modernization-corpus-aggregate/monolith-enterprise/

# Verify patches are applied
git diff --stat

# Build the application
mvn clean package -DskipTests

# Expected output: BUILD SUCCESS
# Artifact: target/enterprise-application-1.0-SNAPSHOT.jar
```

### 3.2 Build Docker Image

```bash
# Use the Dockerfile from ci-cd/dockerfiles/
cp ../../ci-cd/dockerfiles/Dockerfile.monolith-enterprise ./Dockerfile

# Build the image
docker build -t monolith-enterprise:1.0.0 .

# Tag for ECR
aws ecr get-login-password --region us-gov-west-1 | \
  docker login --username AWS --password-stdin \
  <ACCOUNT_ID>.dkr.ecr.us-gov-west-1.amazonaws.com

docker tag monolith-enterprise:1.0.0 \
  <ACCOUNT_ID>.dkr.ecr.us-gov-west-1.amazonaws.com/monolith-enterprise:1.0.0

# Push to ECR
docker push \
  <ACCOUNT_ID>.dkr.ecr.us-gov-west-1.amazonaws.com/monolith-enterprise:1.0.0
```

### 3.3 Verify Image Security

```bash
# Scan image for vulnerabilities
trivy image monolith-enterprise:1.0.0

# Expected: No CRITICAL vulnerabilities
# Review and document any HIGH findings in POA&M
```

---

## 4. Phase 3: Database Setup

### 4.1 Initialize Database

```bash
# Get RDS endpoint from Terraform output
RDS_ENDPOINT=$(terraform output -raw monolith_enterprise_rds_endpoint)

# Connect to RDS and initialize schema
psql -h $RDS_ENDPOINT -U monolith_admin -d monolith_enterprise

-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create application user with least privilege
CREATE USER app_user WITH PASSWORD '<generated-password>';
GRANT USAGE ON SCHEMA app TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA app
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
```

### 4.2 Run Database Migrations

```bash
# Apply Flyway/Liquibase migrations if present
# For Monolith Enterprise, the JPA/Hibernate auto-DDL handles schema creation
# Set spring.jpa.hibernate.ddl-auto=validate in production
```

---

## 5. Phase 4: Kubernetes Deployment

### 5.1 Create Namespace and Secrets

```bash
# Create namespace
kubectl create namespace monolith-enterprise

# Create database credentials secret
kubectl create secret generic monolith-enterprise-db \
  --namespace monolith-enterprise \
  --from-literal=DB_HOST=$RDS_ENDPOINT \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=monolith_enterprise \
  --from-literal=DB_USER=app_user \
  --from-literal=DB_PASSWORD='<generated-password>'

# Create application secrets
kubectl create secret generic monolith-enterprise-app \
  --namespace monolith-enterprise \
  --from-literal=JWT_SECRET='<generated-secret>' \
  --from-literal=ENCRYPTION_KEY='<generated-key>'
```

### 5.2 Apply Kubernetes Manifests

```bash
# Apply manifests in order
kubectl apply -f kubernetes/monolith-enterprise/configmap.yaml
kubectl apply -f kubernetes/monolith-enterprise/deployment.yaml
kubectl apply -f kubernetes/monolith-enterprise/service.yaml
kubectl apply -f kubernetes/monolith-enterprise/hpa.yaml
kubectl apply -f kubernetes/monolith-enterprise/pdb.yaml
kubectl apply -f kubernetes/monolith-enterprise/networkpolicy.yaml
kubectl apply -f kubernetes/monolith-enterprise/ingress.yaml

# Verify deployment
kubectl get pods -n monolith-enterprise -w
# Wait for all pods to show Running status (3/3 expected)
```

### 5.3 Verify Deployment Health

```bash
# Check pod status
kubectl get pods -n monolith-enterprise

# Check service endpoints
kubectl get endpoints -n monolith-enterprise

# Check HPA status
kubectl get hpa -n monolith-enterprise

# View pod logs
kubectl logs -n monolith-enterprise -l app=monolith-enterprise --tail=100

# Test health endpoint
kubectl port-forward -n monolith-enterprise svc/monolith-enterprise 8080:8080 &
curl http://localhost:8080/health
```

---

## 6. Phase 5: Validation & Smoke Testing

### 6.1 Functional Smoke Tests

```bash
# Get ingress URL
INGRESS_URL=$(kubectl get ingress -n monolith-enterprise \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Health check
curl -s https://$INGRESS_URL/health | jq .
# Expected: {"status": "UP"}

# API smoke test
curl -s https://$INGRESS_URL/api/v1/status | jq .

# Database connectivity test
curl -s https://$INGRESS_URL/api/v1/db-health | jq .
```

### 6.2 Security Validation

```bash
# Verify TLS configuration
openssl s_client -connect $INGRESS_URL:443 -tls1_3 < /dev/null 2>/dev/null | \
  openssl x509 -noout -subject -dates

# Verify network policy enforcement
# This should FAIL (pod cannot reach external internet)
kubectl exec -n monolith-enterprise deploy/monolith-enterprise -- \
  curl -s --connect-timeout 5 https://example.com && \
  echo "FAIL: External access not blocked" || \
  echo "PASS: External access blocked by NetworkPolicy"

# Verify pod security context
kubectl get pod -n monolith-enterprise \
  -o jsonpath='{.items[0].spec.containers[0].securityContext}'
# Expected: runAsNonRoot=true, readOnlyRootFilesystem=true
```

### 6.3 Performance Baseline

```bash
# Run load test with Apache Bench
ab -n 1000 -c 50 https://$INGRESS_URL/api/v1/status

# Expected metrics:
# - Response time (mean): < 200ms
# - 99th percentile: < 1000ms
# - Error rate: 0%
# - Throughput: > 100 req/s

# Monitor HPA scaling
kubectl get hpa -n monolith-enterprise -w
```

---

## 7. Phase 6: Monitoring & Observability Setup

### 7.1 Deploy Monitoring Stack

```bash
# Apply observability configurations from operational-docs
kubectl apply -f operational-docs/observability/prometheus-config.yaml
kubectl apply -f operational-docs/observability/grafana-dashboards.yaml

# Verify metrics collection
kubectl port-forward -n monitoring svc/prometheus 9090:9090 &
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
```

### 7.2 Configure Alerts

Key alerts to configure:
- Pod restart count > 3 in 5 minutes
- Response time p99 > 2 seconds
- Error rate > 1%
- CPU utilization > 80% sustained for 5 minutes
- Memory utilization > 85%
- Database connection pool exhaustion
- Certificate expiration < 30 days

### 7.3 CloudWatch Integration

```bash
# Verify CloudWatch Logs are flowing
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/modernization-cluster" \
  --profile govcloud

# Verify CloudWatch metrics
aws cloudwatch list-metrics \
  --namespace "ContainerInsights" \
  --profile govcloud | jq '.Metrics | length'
```

---

## 8. Rollback Procedures

### 8.1 Application Rollback

```bash
# Rollback to previous deployment revision
kubectl rollout undo deployment/monolith-enterprise -n monolith-enterprise

# Verify rollback
kubectl rollout status deployment/monolith-enterprise -n monolith-enterprise

# Check pod health after rollback
kubectl get pods -n monolith-enterprise
```

### 8.2 Database Rollback

```bash
# Restore from RDS automated snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier monolith-enterprise-db-restored \
  --db-snapshot-identifier <snapshot-id> \
  --profile govcloud
```

### 8.3 Full Infrastructure Rollback

```bash
# If infrastructure needs to be torn down
cd terraform/
terraform destroy -target=module.monolith_enterprise

# WARNING: This is destructive. Ensure data has been backed up.
```

---

## 9. Post-Deployment Checklist

| # | Task | Owner | Status |
|---|------|-------|--------|
| 1 | Infrastructure provisioned via Terraform | DevOps | Pending |
| 2 | Docker image built and pushed to ECR | DevOps | Pending |
| 3 | Image vulnerability scan -- no CRITICAL findings | Security | Pending |
| 4 | Database initialized and migrations applied | DBA | Pending |
| 5 | Kubernetes manifests applied | DevOps | Pending |
| 6 | All pods healthy (3/3 Running) | DevOps | Pending |
| 7 | Health endpoint returns 200 OK | QA | Pending |
| 8 | TLS 1.3 verified on ingress | Security | Pending |
| 9 | NetworkPolicy blocks external egress | Security | Pending |
| 10 | Pod runs as non-root with read-only filesystem | Security | Pending |
| 11 | Load test passes performance baseline | QA | Pending |
| 12 | Monitoring dashboards show metrics | SRE | Pending |
| 13 | Alerts configured and tested | SRE | Pending |
| 14 | CloudWatch Logs flowing | SRE | Pending |
| 15 | Rollback procedure tested | DevOps | Pending |
| 16 | ISSO sign-off on security validation | Security | Pending |
| 17 | Stakeholder notification sent | PM | Pending |

---

## 10. Success Criteria

The pilot deployment is considered successful when:

1. **Availability:** Application is accessible via HTTPS with valid TLS certificate
2. **Health:** All 3 pods are Running with no restarts for 24 hours
3. **Performance:** Mean response time < 200ms, error rate < 0.1%
4. **Security:** All security validation checks pass
5. **Monitoring:** Metrics and logs are flowing to CloudWatch and Prometheus
6. **Rollback:** Rollback procedure has been tested and documented

Upon meeting these criteria, the pilot is ready for ISSO review and AO approval to proceed with Tier 2 system deployments.

---

## 11. Next Steps After Successful Pilot

1. **Week 1-2:** ISSO security review of pilot deployment
2. **Week 2-3:** Penetration testing on pilot system
3. **Week 3-4:** AO review and conditional ATO
4. **Week 4-8:** Deploy remaining Tier 2 systems using same pattern
5. **Week 8-12:** Deploy Tier 1 enterprise monoliths
6. **Week 12+:** Decommission legacy systems per decommission plans

---

*This document is CONTROLLED UNCLASSIFIED INFORMATION (CUI) and should be handled in accordance with 32 CFR Part 2002.*
