#!/bin/bash
# modernize-nastran-95.sh
# Modernization script for NASTRAN-95 (Fortran 150K+ LOC NASA Scientific Computing)
# Strategy: fortran-modernization
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/nastran-95}"
RESULT_DIR="${2:-modernization-results/nastran-95}"
mkdir -p "$RESULT_DIR"

echo "=== NASTRAN-95 Modernization Analysis ==="
echo "Strategy: F77 -> Modern Fortran + parallelization + algorithm inventory"

# 1. Fortran file inventory
echo "[1/6] Fortran source file inventory..."
F77_FILES=$(find "$SYSTEM_DIR" -type f \( -iname "*.f" -o -iname "*.f77" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | wc -l)
F90_FILES=$(find "$SYSTEM_DIR" -type f \( -iname "*.f90" -o -iname "*.f95" -o -iname "*.f03" \) 2>/dev/null | wc -l)
echo "  Fortran 77 files: $F77_FILES | Modern Fortran: $F90_FILES"

# 2. COMMON blocks (global state)
echo "[2/6] COMMON block analysis..."
COMMON_BLOCKS=$(grep -ri "COMMON " "$SYSTEM_DIR" --include="*.f" --include="*.f77" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
grep -roh "COMMON\s*/[A-Z0-9]*/" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | sort | uniq -c | sort -rn > "$RESULT_DIR/common-blocks.txt" || true
echo "  COMMON block references: $COMMON_BLOCKS"

# 3. GOTO analysis (spaghetti code indicator)
echo "[3/6] GOTO statement analysis..."
GOTO_COUNT=$(grep -ri "GO TO\|GOTO" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
COMPUTED_GOTO=$(grep -ri "GO TO\s*(" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
echo "  Total GOTOs: $GOTO_COUNT | Computed GOTOs: $COMPUTED_GOTO"

# 4. EQUIVALENCE (memory aliasing)
echo "[4/6] EQUIVALENCE analysis..."
EQUIV_COUNT=$(grep -ri "EQUIVALENCE" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
echo "  EQUIVALENCE statements: $EQUIV_COUNT"

# 5. Subroutine/function inventory
echo "[5/6] Subroutine inventory..."
SUBROUTINE_COUNT=$(grep -riE "^\s*SUBROUTINE\s+" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
FUNCTION_COUNT=$(grep -riE "^\s*(REAL|INTEGER|DOUBLE|COMPLEX|LOGICAL|CHARACTER)?\s*FUNCTION\s+" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
echo "  Subroutines: $SUBROUTINE_COUNT | Functions: $FUNCTION_COUNT"
grep -riE "^\s*SUBROUTINE\s+\w+" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | grep -oP "SUBROUTINE\s+\K\w+" | sort > "$RESULT_DIR/subroutine-inventory.txt" || true

# 6. Parallelization opportunities
echo "[6/6] Parallelization scan..."
DO_LOOPS=$(grep -ri "^\s*DO\s" "$SYSTEM_DIR" --include="*.f" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l)
echo "  DO loops (parallelization candidates): $DO_LOOPS"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# NASTRAN-95 Migration Plan

## Codebase Complexity
- F77 source files: $F77_FILES
- COMMON blocks: $COMMON_BLOCKS (global state - hardest challenge)
- GOTO statements: $GOTO_COUNT ($COMPUTED_GOTO computed)
- EQUIVALENCE: $EQUIV_COUNT (memory aliasing)
- Subroutines: $SUBROUTINE_COUNT | Functions: $FUNCTION_COUNT

## Phase 1: Algorithm Inventory (4-6 weeks)
- Catalog all $SUBROUTINE_COUNT subroutines
- Identify core numerical algorithms
- Document input/output specifications
- Classify by computational domain (structural, thermal, dynamic)

## Phase 2: F77 -> Modern Fortran (6-12 months)
- Replace COMMON blocks with MODULE variables
- Replace GOTO with structured control flow
- Remove EQUIVALENCE with proper typing
- Add IMPLICIT NONE everywhere
- Convert fixed-form to free-form source

## Phase 3: Parallelization (3-6 months)
- DO loops: $DO_LOOPS (candidates for OpenMP)
- Identify data dependencies
- Add OpenMP directives for shared-memory parallelism
- Consider MPI for distributed computing

## Phase 4: Testing & Validation (4-8 weeks)
- Create reference test cases from original code
- Validate numerical accuracy
- Performance benchmarking

## Estimated Effort: 18-24 months
## Risk: VERY HIGH - numerical accuracy must be preserved
EOF

echo "=== Analysis complete ==="
