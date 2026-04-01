# Alfresco Community Migration Plan

## Phase 1: javax -> jakarta Migration
- javax imports: 302
- Use Eclipse Transformer for automated migration
- Priority: javax.servlet, javax.persistence, javax.transaction

## Phase 2: Spring Boot 3.x Upgrade
- Migrate XML configs to Java annotations
- Upgrade to Spring Boot 3.x with Jakarta EE
- Replace legacy AOP configurations

## Phase 3: Content Model Modernization
- Model files: 47
- Migrate to modern content model APIs
- Add REST API layer for content operations

## Phase 4: Containerization
- Docker multi-stage builds
- Kubernetes with persistent volumes for content storage
- Health checks and readiness probes

## Estimated Effort
- javax migration: 3-6 weeks
- Spring Boot upgrade: 8-12 weeks
- Content model modernization: 3-6 months
- Total: 8-12 months
