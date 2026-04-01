#!/bin/bash
# modernize-alfresco-community.sh
# Modernization script for Alfresco Community (Java 100K+ LOC Content Management)
# Strategy: java-platform-upgrade
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/alfresco-community}"
RESULT_DIR="${2:-modernization-results/alfresco-community}"
mkdir -p "$RESULT_DIR"

echo "=== Alfresco Community Modernization Analysis ==="
echo "Strategy: Spring Boot 3.x migration + Java 17+ + containerization"

# 1. javax import scan
echo "[1/6] Scanning javax imports..."
JAVAX_COUNT=$(grep -r "import javax\." "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
grep -roh "import javax\.[a-z]*" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | sort | uniq -c | sort -rn > "$RESULT_DIR/javax-packages.txt" || true
echo "  javax import statements: $JAVAX_COUNT"

# 2. Spring Framework analysis
echo "[2/6] Analyzing Spring Framework usage..."
{
    echo "=== Spring Annotations ==="
    grep -roh "@\(Component\|Service\|Repository\|Controller\|RestController\|Autowired\|Bean\|Configuration\)" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | sort | uniq -c | sort -rn || echo "None found"
    echo ""
    echo "=== XML Configuration Files ==="
    find "$SYSTEM_DIR" -name "*context*.xml" -o -name "*spring*.xml" -o -name "applicationContext*.xml" 2>/dev/null | head -20 || echo "None found"
} > "$RESULT_DIR/spring-analysis.txt"

# 3. Content model analysis
echo "[3/6] Analyzing content model..."
find "$SYSTEM_DIR" -name "*.xml" -path "*/model/*" 2>/dev/null | head -50 > "$RESULT_DIR/content-models.txt" || true
MODEL_FILES=$(wc -l < "$RESULT_DIR/content-models.txt")
echo "  Content model XML files: $MODEL_FILES"

# 4. Build system
echo "[4/6] Analyzing Maven build..."
POM_COUNT=$(find "$SYSTEM_DIR" -name "pom.xml" 2>/dev/null | wc -l)
echo "  POM files: $POM_COUNT" > "$RESULT_DIR/build-analysis.txt"

# 5. Test baseline
echo "[5/6] Test coverage baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -name "*Test.java" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Security scan
echo "[6/6] Security scan..."
grep -rin "password\|credential\|secret" "$SYSTEM_DIR" --include="*.properties" --include="*.xml" 2>/dev/null | grep -v "test\|mock\|example" | head -30 > "$RESULT_DIR/security-findings.txt" || true

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Alfresco Community Migration Plan

## Phase 1: javax -> jakarta Migration
- javax imports: $JAVAX_COUNT
- Use Eclipse Transformer for automated migration
- Priority: javax.servlet, javax.persistence, javax.transaction

## Phase 2: Spring Boot 3.x Upgrade
- Migrate XML configs to Java annotations
- Upgrade to Spring Boot 3.x with Jakarta EE
- Replace legacy AOP configurations

## Phase 3: Content Model Modernization
- Model files: $MODEL_FILES
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
EOF

echo "=== Analysis complete ==="
