#!/bin/bash
# modernize-cfwheels.sh
# Modernization script for CFWheels (ColdFusion 50K+ LOC Framework)
# Strategy: framework-migration
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/cfwheels}"
RESULT_DIR="${2:-modernization-results/cfwheels}"
mkdir -p "$RESULT_DIR"

echo "=== CFWheels Modernization Analysis ==="
echo "Strategy: ColdFusion -> modern framework migration assessment"

# 1. ColdFusion file inventory
echo "[1/5] ColdFusion file inventory..."
CFM_FILES=$(find "$SYSTEM_DIR" -type f -name "*.cfm" 2>/dev/null | wc -l)
CFC_FILES=$(find "$SYSTEM_DIR" -type f -name "*.cfc" 2>/dev/null | wc -l)
echo "  CFM templates: $CFM_FILES | CFC components: $CFC_FILES"

# 2. Deprecated CFML tags
echo "[2/5] Deprecated tag scan..."
DEPRECATED_TAGS=$(grep -ri "<cfform\|<cfgrid\|<cfapplet\|<cfservlet\|<cfpod" "$SYSTEM_DIR" --include="*.cfm" --include="*.cfc" 2>/dev/null | wc -l)
echo "  Deprecated tags: $DEPRECATED_TAGS"

# 3. SQL injection risk
echo "[3/5] SQL injection risk assessment..."
SQL_RISK=$(grep -ri "cfquery" "$SYSTEM_DIR" --include="*.cfm" --include="*.cfc" 2>/dev/null | grep "#" | wc -l)
echo "  Potential SQL injection patterns: $SQL_RISK"

# 4. Route/controller analysis
echo "[4/5] MVC structure analysis..."
CONTROLLERS=$(find "$SYSTEM_DIR" -type f -name "*.cfc" -path "*/controllers/*" 2>/dev/null | wc -l)
MODELS=$(find "$SYSTEM_DIR" -type f -name "*.cfc" -path "*/models/*" 2>/dev/null | wc -l)
VIEWS=$(find "$SYSTEM_DIR" -type f -name "*.cfm" -path "*/views/*" 2>/dev/null | wc -l)
echo "  Controllers: $CONTROLLERS | Models: $MODELS | Views: $VIEWS"

# 5. Test files
echo "[5/5] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -iname "*test*" \( -name "*.cfm" -o -name "*.cfc" \) 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# CFWheels Migration Plan

## Assessment: ColdFusion -> Modern Framework
- CFM templates: $CFM_FILES
- CFC components: $CFC_FILES
- MVC: Controllers=$CONTROLLERS, Models=$MODELS, Views=$VIEWS

## Option A: Node.js/Express Migration
- Map CFC components to Express routes/controllers
- Convert CFM templates to EJS/Pug/React
- Migrate database queries to Sequelize/Prisma

## Option B: Python/Django Migration
- Map MVC to Django MVT pattern
- Convert CFML business logic to Python
- Use Django ORM for database layer

## Security Fixes (Immediate)
- SQL injection patterns: $SQL_RISK (HIGH PRIORITY)
- Deprecated tags: $DEPRECATED_TAGS
- Add parameterized queries

## Estimated Effort: 6-12 months (full migration)
EOF

echo "=== Analysis complete ==="
