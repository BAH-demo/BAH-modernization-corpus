#!/bin/bash
# modernize-nuxeo.sh
# Modernization script for Nuxeo (Java 50K+ LOC Document Management)
# Strategy: java-simplification
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/nuxeo}"
RESULT_DIR="${2:-modernization-results/nuxeo}"
mkdir -p "$RESULT_DIR"

echo "=== Nuxeo Modernization Analysis ==="
echo "Strategy: Reduce abstraction layers + javax->jakarta + containerize"

# 1. javax imports
echo "[1/6] Scanning javax imports..."
JAVAX_COUNT=$(grep -r "import javax\." "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
grep -roh "import javax\.[a-z]*" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | sort | uniq -c | sort -rn > "$RESULT_DIR/javax-packages.txt" || true
echo "  javax imports: $JAVAX_COUNT"

# 2. Abstraction depth analysis
echo "[2/6] Analyzing abstraction depth..."
INTERFACE_COUNT=$(grep -r "^public interface\|^interface " "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
ABSTRACT_COUNT=$(grep -r "^public abstract class\|^abstract class" "$SYSTEM_DIR" --include="*.java" 2>/dev/null | wc -l)
echo "  Interfaces: $INTERFACE_COUNT | Abstract classes: $ABSTRACT_COUNT" > "$RESULT_DIR/abstraction-analysis.txt"

# 3. Plugin architecture scan
echo "[3/6] Scanning plugin architecture..."
find "$SYSTEM_DIR" -name "MANIFEST.MF" -o -name "plugin.xml" -o -name "OSGI-INF" -type d 2>/dev/null | wc -l > "$RESULT_DIR/plugin-count.txt" || true

# 4. Maven module structure
echo "[4/6] Analyzing Maven modules..."
POM_COUNT=$(find "$SYSTEM_DIR" -name "pom.xml" 2>/dev/null | wc -l)
echo "  POM files: $POM_COUNT"

# 5. Test files
echo "[5/6] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -name "*Test.java" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Security scan
echo "[6/6] Security scan..."
grep -rin "password\|credential\|secret" "$SYSTEM_DIR" --include="*.properties" --include="*.xml" --include="*.java" 2>/dev/null | grep -v "test\|mock\|example\|Test\|@param\|javadoc" | head -30 > "$RESULT_DIR/security-findings.txt" || true

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Nuxeo Migration Plan

## Phase 1: javax -> jakarta
- javax imports: $JAVAX_COUNT
## Phase 2: Simplify Abstractions
- Interfaces: $INTERFACE_COUNT | Abstract classes: $ABSTRACT_COUNT
- Flatten unnecessary abstraction layers
## Phase 3: Plugin Architecture Modernization
- Migrate OSGI-based plugins to Spring Boot starters
## Phase 4: Containerization
- POM modules: $POM_COUNT - consolidate where possible
## Estimated Effort: 10-14 months
EOF

echo "=== Analysis complete ==="
