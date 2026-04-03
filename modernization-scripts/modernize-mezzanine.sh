#!/bin/bash
# modernize-mezzanine.sh
# Modernization script for Mezzanine (Python 5K+ LOC CMS)
# Strategy: python312-compatibility
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/mezzanine}"
RESULT_DIR="${2:-modernization-results/mezzanine}"
mkdir -p "$RESULT_DIR"

echo "=== Mezzanine Modernization Analysis ==="
echo "Strategy: Replace imp module + Python 3.12+ compatibility"

# 1. imp module usage (critical blocker)
echo "[1/6] Scanning for deprecated imp module..."
grep -rn "import imp\b\|from imp " "$SYSTEM_DIR" --include="*.py" 2>/dev/null > "$RESULT_DIR/imp-usage.txt" || true
IMP_COUNT=$(wc -l < "$RESULT_DIR/imp-usage.txt")
echo "  imp module usage: $IMP_COUNT instances (BLOCKING for Python 3.12+)"

# 2. Other deprecated modules
echo "[2/6] Scanning other deprecated modules..."
grep -rn "import distutils\|from distutils\|import cgi\b\|from cgi \|import pipes\b" "$SYSTEM_DIR" --include="*.py" 2>/dev/null > "$RESULT_DIR/deprecated-modules.txt" || true

# 3. Django compatibility
echo "[3/6] Checking Django compatibility..."
grep -rn "from django.utils.encoding import.*python_2_unicode_compatible\|ugettext\|ugettext_lazy" "$SYSTEM_DIR" --include="*.py" 2>/dev/null > "$RESULT_DIR/django-compat.txt" || true
DJANGO_COMPAT=$(wc -l < "$RESULT_DIR/django-compat.txt")
echo "  Deprecated Django patterns: $DJANGO_COMPAT"

# 4. Type hint coverage
echo "[4/6] Type hint coverage..."
TOTAL_FUNCS=$(grep -r "def " "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l)
TYPED_FUNCS=$(grep -r "def .*->.*:" "$SYSTEM_DIR" --include="*.py" 2>/dev/null | wc -l)
COVERAGE=0
[ "$TOTAL_FUNCS" -gt 0 ] && COVERAGE=$((TYPED_FUNCS * 100 / TOTAL_FUNCS))
echo "  Coverage: ${COVERAGE}%"

# 5. Test files
echo "[5/6] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "tests.py" \) 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Security scan
echo "[6/6] Security scan..."
grep -rin "SECRET_KEY\|password\s*=" "$SYSTEM_DIR" --include="*.py" 2>/dev/null | grep -v "test\|Test\|#\|example" | head -20 > "$RESULT_DIR/security-findings.txt" || true

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Mezzanine Migration Plan

## CRITICAL: imp Module Replacement
- imp usage instances: $IMP_COUNT
- The \`imp\` module was removed in Python 3.12 (PEP 594)
- Must replace with \`importlib\` equivalents
- This is the #1 blocker for running on Python 3.12+

## Phase 1: Python 3.12 Compatibility (2-3 weeks)
- Replace imp -> importlib
- Fix deprecated Django patterns ($DJANGO_COMPAT instances)
- Update setup.py/pyproject.toml

## Phase 2: Type Safety (2-4 weeks)
- Current coverage: ${COVERAGE}%
- Add type hints to core modules
- Enable mypy checking

## Phase 3: Django Upgrade (2-4 weeks)
- Upgrade to Django 5.x LTS
- Replace deprecated patterns

## Estimated Effort: 6-10 weeks
EOF

echo "=== Analysis complete ==="
