#!/bin/bash
# modernize-monolith-enterprise.sh
# Modernization script for Monolith Enterprise (Java 5K+ LOC)
# Strategy: java17-migration
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/monolith-enterprise}"
RESULT_DIR="${2:-modernization-results/monolith-enterprise}"
mkdir -p "$RESULT_DIR"

echo "=== Monolith Enterprise Modernization Analysis ==="
echo "Strategy: Java 7->17 migration + javax->jakarta + Spring upgrade"

# 1. Java version check
echo "[1/6] Checking Java version..."
JAVA_VER=$(grep -oP '<java.version>\K[^<]+' "$SYSTEM_DIR/pom.xml" 2>/dev/null | head -1) || JAVA_VER="unknown"
echo "  Java version: $JAVA_VER"
echo "java_version: $JAVA_VER" > "$RESULT_DIR/java-version.txt"

# 2. javax imports
echo "[2/6] javax import scan..."
JAVAX_COUNT=$(grep -r "import javax\." "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
grep -roh "import javax\.[a-z]*" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | sort | uniq -c | sort -rn > "$RESULT_DIR/javax-packages.txt" || true
echo "  javax imports: $JAVAX_COUNT"

# 3. Spring Framework version
echo "[3/6] Spring Framework analysis..."
{
    grep -i "spring" "$SYSTEM_DIR/pom.xml" 2>/dev/null | head -20 || echo "No Spring references in pom.xml"
} > "$RESULT_DIR/spring-analysis.txt"

# 4. Liquibase/database dependency
echo "[4/6] Database dependency analysis..."
LIQUIBASE=$(grep -c "liquibase" "$SYSTEM_DIR/pom.xml" 2>/dev/null) || LIQUIBASE=0
MYSQL=$(grep -c "mysql" "$SYSTEM_DIR/pom.xml" 2>/dev/null) || MYSQL=0
echo "  Liquibase refs: $LIQUIBASE | MySQL refs: $MYSQL"

# 5. Test files
echo "[5/6] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -name "*Test.java" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Deprecated APIs
echo "[6/6] Deprecated API usage..."
grep -rn "@Deprecated\|javax.annotation.PostConstruct\|javax.jms" "$SYSTEM_DIR" --include="*.java" 2>/dev/null > "$RESULT_DIR/deprecated-apis.txt" || true

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Monolith Enterprise Migration Plan

## CRITICAL: Java Version ($JAVA_VER -> 17)
- javax imports: $JAVAX_COUNT -> must migrate to jakarta
- javax.annotation.PostConstruct removed in Java 11+
- javax.jms -> jakarta.jms

## Phase 1: Java 17 Compatibility (3-4 weeks)
- Update pom.xml java.version to 17
- Migrate javax -> jakarta namespace
- Fix Spring Framework version conflicts
- Replace removed APIs

## Phase 2: Database Decoupling (2-3 weeks)
- Liquibase refs: $LIQUIBASE
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
EOF

echo "=== Analysis complete ==="
