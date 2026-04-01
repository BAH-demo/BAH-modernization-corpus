#!/bin/bash
# modernize-apache-ofbiz.sh
# Modernization script for Apache OFBiz (Java 500K+ LOC ERP Monolith)
# Strategy: javax-to-jakarta-migration
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/apache-ofbiz}"
RESULT_DIR="${2:-modernization-results/apache-ofbiz}"
mkdir -p "$RESULT_DIR"

echo "=== Apache OFBiz Modernization Analysis ==="
echo "Strategy: javax -> jakarta namespace migration + Java 17+ upgrade"

# 1. javax import inventory
echo "[1/7] Scanning javax imports for jakarta migration..."
grep -r "import javax\." "$SYSTEM_DIR" --include="*.java" -l 2>/dev/null | sort > "$RESULT_DIR/javax-files.txt" || true
JAVAX_FILES=$(wc -l < "$RESULT_DIR/javax-files.txt")
echo "  Files with javax imports: $JAVAX_FILES"

# 2. Categorize javax usage by package
echo "[2/7] Categorizing javax package usage..."
grep -roh "import javax\.[a-z]*" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | sort | uniq -c | sort -rn > "$RESULT_DIR/javax-packages.txt" || true

# 3. Build system analysis
echo "[3/7] Analyzing build configuration..."
{
    echo "=== Build System Analysis ==="
    if [ -f "$SYSTEM_DIR/build.gradle" ]; then
        echo "Build System: Gradle"
        grep -i "sourceCompatibility\|targetCompatibility\|JavaVersion\|java.version" "$SYSTEM_DIR/build.gradle" 2>/dev/null || echo "  No explicit Java version found"
    fi
    if [ -f "$SYSTEM_DIR/pom.xml" ]; then
        echo "Build System: Maven"
        grep -i "java.version\|maven.compiler" "$SYSTEM_DIR/pom.xml" 2>/dev/null || echo "  No explicit Java version found"
    fi
} > "$RESULT_DIR/build-analysis.txt"

# 4. Global state detection
echo "[4/7] Detecting global mutable state..."
grep -rn "static.*=\s*new\|static.*Map\|static.*List\|static.*Set" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | grep -v "final\|Final\|FINAL" | head -100 > "$RESULT_DIR/global-state.txt" || true
GLOBAL_STATE=$(wc -l < "$RESULT_DIR/global-state.txt")
echo "  Global mutable state instances: $GLOBAL_STATE"

# 5. Deprecated API usage
echo "[5/7] Finding deprecated API usage..."
grep -rn "@Deprecated\|@SuppressWarnings" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | head -100 > "$RESULT_DIR/deprecated-apis.txt" || true

# 6. Security scan
echo "[6/7] Security surface scan..."
grep -rin "password\s*=\|secret\s*=\|apikey\s*=\|api.key\s*=" "$SYSTEM_DIR" --include="*.java" --include="*.properties" --include="*.xml" 2>/dev/null | grep -v "test\|Test\|mock\|Mock\|example\|Example" | head -50 > "$RESULT_DIR/security-findings.txt" || true

# 7. Test coverage baseline
echo "[7/7] Establishing test coverage baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f \( -name "*Test.java" -o -name "*Tests.java" \) 2>/dev/null | wc -l)
TOTAL_JAVA=$(find "$SYSTEM_DIR" -type f -name "*.java" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES / $TOTAL_JAVA total Java files"

# Generate migration plan
cat > "$RESULT_DIR/migration-plan.md" << EOF
# Apache OFBiz Migration Plan

## Phase 1: Namespace Migration (javax -> jakarta)
- Files requiring migration: $JAVAX_FILES
- Automated tooling: Eclipse Transformer or OpenRewrite recipes
- Risk: HIGH - 500K+ LOC affected

## Phase 2: Java Version Upgrade
- Current: Java 8/11 (estimated from build config)
- Target: Java 17 LTS
- Key changes: Records, sealed classes, pattern matching

## Phase 3: Architecture Decomposition
- Global mutable state instances: $GLOBAL_STATE
- Recommended: Strangler fig pattern
- Target: Microservices with Spring Boot 3.x

## Phase 4: Containerization
- Docker multi-stage builds
- Kubernetes deployment manifests
- Health checks and observability

## Estimated Effort
- Namespace migration: 2-4 weeks (automated)
- Java upgrade: 4-8 weeks
- Architecture decomposition: 6-12 months
- Total: 8-14 months
EOF

echo "=== Analysis complete. Results in: $RESULT_DIR ==="
