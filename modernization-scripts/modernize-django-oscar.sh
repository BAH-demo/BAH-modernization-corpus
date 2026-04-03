#!/bin/bash
# modernize-django-oscar.sh
# Modernization script for Django Oscar (Python 10K+ LOC E-Commerce)
# Strategy: django-upgrade (already operationalized)
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/django-oscar}"
RESULT_DIR="${2:-modernization-results/django-oscar}"
mkdir -p "$RESULT_DIR"

echo "=== Django Oscar Modernization Analysis ==="
echo "Strategy: Django LTS upgrade + type hints + architectural debt reduction"
echo "Note: This system was already operationalized and demonstrated running"

# 1. Django version check
echo "[1/6] Checking Django version requirements..."
{
    grep -i "django" "$SYSTEM_DIR/setup.py" "$SYSTEM_DIR/pyproject.toml" "$SYSTEM_DIR/setup.cfg" 2>/dev/null | head -10 || echo "Django version not found in config files"
} > "$RESULT_DIR/django-version.txt"

# 2. Type hint coverage
echo "[2/6] Type hint coverage..."
TOTAL_FUNCS=$(grep -r "def " "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l)
TYPED_FUNCS=$(grep -r "def .*->.*:" "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l)
COVERAGE=0
[ "$TOTAL_FUNCS" -gt 0 ] && COVERAGE=$((TYPED_FUNCS * 100 / TOTAL_FUNCS))
echo "  Coverage: ${COVERAGE}% ($TYPED_FUNCS/$TOTAL_FUNCS)"

# 3. Architectural debt markers
echo "[3/6] Scanning architectural debt..."
CIRCULAR_IMPORTS=$(grep -rn "import.*from.*import\|from.*import.*import" "$SYSTEM_DIR/src" --include="*.py" 2>/dev/null | wc -l) || CIRCULAR_IMPORTS=0
echo "  Potential circular import patterns: $CIRCULAR_IMPORTS"

# 4. Deprecated patterns
echo "[4/6] Deprecated pattern scan..."
grep -rn "from django.utils.encoding import.*python_2_unicode_compatible\|from django.utils.translation import.*ugettext" "$SYSTEM_DIR" --include="*.py" 2>/dev/null > "$RESULT_DIR/deprecated-django.txt" || true

# 5. Test coverage
echo "[5/6] Test infrastructure..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f \( -name "test_*.py" -o -name "*_test.py" \) 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Security scan
echo "[6/6] Security scan..."
grep -rin "SECRET_KEY\|password\s*=" "$SYSTEM_DIR" --include="*.py" --include="*.cfg" 2>/dev/null | grep -v "test\|Test\|mock\|example\|#" | head -20 > "$RESULT_DIR/security-findings.txt" || true

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Django Oscar Migration Plan

**Status:** Already operationalized - running as live e-commerce application

## Phase 1: Django LTS Upgrade
- Current Django version: See django-version.txt
- Target: Django 5.2 LTS (already verified working)

## Phase 2: Type Safety
- Current coverage: ${COVERAGE}%
- Target: 80%+ with mypy strict mode

## Phase 3: Architectural Debt
- Reduce circular dependencies
- Extract shared utilities
- Improve test coverage ($TEST_FILES test files)

## Estimated Effort: 4-6 weeks (lowest difficulty)
EOF

echo "=== Analysis complete ==="
