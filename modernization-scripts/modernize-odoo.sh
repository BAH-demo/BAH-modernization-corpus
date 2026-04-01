#!/bin/bash
# modernize-odoo.sh
# Modernization script for Odoo (Python 200K+ LOC ERP)
# Strategy: python-modernization
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/odoo}"
RESULT_DIR="${2:-modernization-results/odoo}"
mkdir -p "$RESULT_DIR"

echo "=== Odoo Modernization Analysis ==="
echo "Strategy: Python 3.12+ upgrade + type hints + modularization"

# 1. Python version compatibility
echo "[1/7] Checking Python version compatibility..."
{
    echo "=== Python Compatibility ==="
    grep -r "python_requires" "$SYSTEM_DIR/setup.py" "$SYSTEM_DIR/setup.cfg" "$SYSTEM_DIR/pyproject.toml" 2>/dev/null || echo "No python_requires found"
    echo ""
    echo "=== Deprecated module usage ==="
    grep -rn "import imp\b\|from imp \|import distutils\|from distutils\|import cgi\b" "$SYSTEM_DIR" --include="*.py" 2>/dev/null | head -50 || echo "No deprecated modules found"
} > "$RESULT_DIR/python-compat.txt"

# 2. Type hint coverage
echo "[2/7] Analyzing type hint coverage..."
TOTAL_FUNCS=$(grep -r "def " "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l)
TYPED_FUNCS=$(grep -r "def .*->.*:" "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l)
COVERAGE=0
[ "$TOTAL_FUNCS" -gt 0 ] && COVERAGE=$((TYPED_FUNCS * 100 / TOTAL_FUNCS))
echo "  Functions: $TOTAL_FUNCS | Typed: $TYPED_FUNCS | Coverage: ${COVERAGE}%"
echo "total_functions: $TOTAL_FUNCS" > "$RESULT_DIR/type-coverage.txt"
echo "typed_functions: $TYPED_FUNCS" >> "$RESULT_DIR/type-coverage.txt"
echo "coverage_pct: $COVERAGE" >> "$RESULT_DIR/type-coverage.txt"

# 3. Module structure analysis
echo "[3/7] Analyzing module structure..."
find "$SYSTEM_DIR/addons" -maxdepth 1 -type d 2>/dev/null | wc -l > "$RESULT_DIR/module-count.txt" || echo "0" > "$RESULT_DIR/module-count.txt"
MODULES=$(cat "$RESULT_DIR/module-count.txt")
echo "  Odoo addon modules: $MODULES"

# 4. ORM usage patterns
echo "[4/7] Scanning ORM patterns..."
grep -rn "models.Model\|fields\.\|api.multi\|api.one\|api.model\|api.depends" "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l > "$RESULT_DIR/orm-usage.txt" || echo "0" > "$RESULT_DIR/orm-usage.txt"

# 5. Security scan
echo "[5/7] Security surface scan..."
grep -rin "password\|secret\|token\s*=" "$SYSTEM_DIR" --include="*.py" --include="*.cfg" 2>/dev/null | grep -v "test\|Test\|mock\|doc\|#" | head -50 > "$RESULT_DIR/security-findings.txt" || true

# 6. Test infrastructure
echo "[6/7] Assessing test infrastructure..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f \( -name "test_*.py" -o -name "*_test.py" \) 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 7. JavaScript/frontend assessment
echo "[7/7] Frontend modernization scan..."
JS_FILES=$(find "$SYSTEM_DIR" -type f -name "*.js" 2>/dev/null | wc -l)
echo "  JavaScript files: $JS_FILES"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Odoo Modernization Plan

## Phase 1: Python 3.12+ Compatibility
- Replace deprecated modules (imp, distutils, cgi)
- Update string formatting to f-strings
- Fix async/await patterns

## Phase 2: Type Safety Campaign
- Current coverage: ${COVERAGE}%
- Target: 60%+ on business logic modules
- Tool: mypy with strict mode
- Priority: Core ORM models first

## Phase 3: Module Decoupling
- Current modules: $MODULES
- Identify circular dependencies
- Extract shared utilities
- Define clear module boundaries

## Phase 4: Frontend Modernization
- JavaScript files: $JS_FILES
- Migrate to modern JS framework (Vue/React)
- Add TypeScript

## Estimated Effort
- Python compatibility: 2-4 weeks
- Type safety campaign: 8-12 weeks
- Module decoupling: 3-6 months
- Frontend modernization: 6-12 months
- Total: 12-18 months
EOF

echo "=== Analysis complete. Results in: $RESULT_DIR ==="
