# Monolith Enterprise Migration Plan

## CRITICAL: Java Version (1.7 -> 17)
- javax imports: 54 -> must migrate to jakarta
- javax.annotation.PostConstruct removed in Java 11+
- javax.jms -> jakarta.jms

## Phase 1: Java 17 Compatibility (3-4 weeks)
- Update pom.xml java.version to 17
- Migrate javax -> jakarta namespace
- Fix Spring Framework version conflicts
- Replace removed APIs

## Phase 2: Database Decoupling (2-3 weeks)
- Liquibase refs: 3
- Replace MySQL hard dependency with H2 for dev/test
- Add database migration scripts

## Phase 3: Spring Boot 3.x (4-6 weeks)
- Migrate to Spring Boot 3.x starter
- Replace XML config with Java annotations
- Add actuator health checks

## Phase 4: Containerization (1-2 weeks)
- Multi-stage Docker build
- Docker Compose for local development

## Estimated Effort: 10-14 weeks
