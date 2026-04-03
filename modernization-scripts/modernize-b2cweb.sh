#!/bin/bash
# modernize-b2cweb.sh
# Modernization script for B2CWeb (Java 5K LOC E-Commerce)
# Strategy: java-rebuild
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/b2cweb}"
RESULT_DIR="${2:-modernization-results/b2cweb}"
mkdir -p "$RESULT_DIR"

echo "=== B2CWeb Modernization Analysis ==="
echo "Strategy: Rebuild from SSH framework to Spring Boot"

# 1. Framework detection
echo "[1/6] Detecting framework dependencies..."
{
    echo "=== Framework Analysis ==="
    grep -rn "struts\|spring\|hibernate\|ssh\|ibatis\|mybatis" "$SYSTEM_DIR" --include="*.xml" --include="*.java" --include="*.properties" 2>/dev/null | head -30 || echo "No framework references found"
} > "$RESULT_DIR/framework-analysis.txt"

# 2. javax imports
echo "[2/6] javax import scan..."
JAVAX_COUNT=$(grep -r "import javax\." "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
echo "  javax imports: $JAVAX_COUNT"

# 3. Database layer
echo "[3/6] Database layer analysis..."
JDBC_DIRECT=$(grep -rn "DriverManager\|getConnection\|Statement\|PreparedStatement\|ResultSet" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
echo "  Direct JDBC usage: $JDBC_DIRECT patterns" > "$RESULT_DIR/database-analysis.txt"

# 4. JSP/Servlet analysis
echo "[4/6] JSP/Servlet analysis..."
JSP_COUNT=$(find "$SYSTEM_DIR" -type f -name "*.jsp" 2>/dev/null | wc -l)
echo "  JSP files: $JSP_COUNT"

# 5. Test files
echo "[5/6] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -name "*Test.java" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Build system
echo "[6/6] Build system check..."
HAS_MAVEN="false"
HAS_GRADLE="false"
[ -f "$SYSTEM_DIR/pom.xml" ] && HAS_MAVEN="true"
[ -f "$SYSTEM_DIR/build.gradle" ] && HAS_GRADLE="true"
echo "  Maven: $HAS_MAVEN | Gradle: $HAS_GRADLE"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# B2CWeb Migration Plan

## Challenge: No Modern Build System
- Maven: $HAS_MAVEN | Gradle: $HAS_GRADLE
- Chinese documentation only
- Requires Eclipse IDE, Tomcat, MySQL

## Phase 1: Build System (2-3 weeks)
- Create Maven/Gradle build from scratch
- Extract dependencies from lib/ directory
- Add CI/CD pipeline

## Phase 2: Framework Migration (4-8 weeks)
- SSH (Struts+Spring+Hibernate) -> Spring Boot 3.x
- javax imports ($JAVAX_COUNT) -> jakarta
- Replace JSPs ($JSP_COUNT) with REST API + modern frontend

## Phase 3: Database Modernization (2-4 weeks)
- Direct JDBC ($JDBC_DIRECT patterns) -> JPA/Hibernate
- Add connection pooling
- Database migration scripts

## Phase 4: Internationalization (2 weeks)
- Add i18n support
- Translate Chinese UI strings

## Estimated Effort: 10-16 weeks
EOF

echo "=== Analysis complete ==="
