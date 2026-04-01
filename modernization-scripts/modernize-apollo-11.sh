#!/bin/bash
# modernize-apollo-11.sh
# Modernization script for Apollo-11 (Assembly 8K+ LOC AGC Mission Code)
# Strategy: historical-preservation
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/apollo-11}"
RESULT_DIR="${2:-modernization-results/apollo-11}"
mkdir -p "$RESULT_DIR"

echo "=== Apollo-11 Modernization Analysis ==="
echo "Strategy: Historical preservation + documentation + simulation wrapper"

# 1. AGC source file inventory
echo "[1/5] AGC source inventory..."
AGC_FILES=$(find "$SYSTEM_DIR" -type f -iname "*.agc" 2>/dev/null | wc -l)
ASM_FILES=$(find "$SYSTEM_DIR" -type f \( -iname "*.s" -o -iname "*.asm" \) 2>/dev/null | wc -l)
echo "  AGC files: $AGC_FILES | Other assembly: $ASM_FILES"

# 2. Program module analysis
echo "[2/5] Program module analysis..."
{
    echo "=== AGC Program Structure ==="
    echo "Comanche (CM): $(find "$SYSTEM_DIR" -path "*Comanche*" -name "*.agc" 2>/dev/null | wc -l) files"
    echo "Luminary (LM): $(find "$SYSTEM_DIR" -path "*Luminary*" -name "*.agc" 2>/dev/null | wc -l) files"
} > "$RESULT_DIR/program-structure.txt"

# 3. Instruction analysis
echo "[3/5] AGC instruction analysis..."
if [ "$AGC_FILES" -gt 0 ]; then
    TOTAL_LINES=$(find "$SYSTEM_DIR" -name "*.agc" -exec cat {} + 2>/dev/null | wc -l)
    COMMENT_LINES=$(find "$SYSTEM_DIR" -name "*.agc" -exec cat {} + 2>/dev/null | grep -c "^#" 2>/dev/null) || COMMENT_LINES=0
    echo "  Total lines: $TOTAL_LINES | Comment lines: $COMMENT_LINES"
else
    TOTAL_LINES=0
    COMMENT_LINES=0
    echo "  No AGC files found"
fi

# 4. Memory bank references
echo "[4/5] Memory bank analysis..."
BANK_REFS=$(grep -ri "BANK\|SETLOC\|EBANK\|SBANK\|FBANK" "$SYSTEM_DIR" --include="*.agc" 2>/dev/null | wc -l)
echo "  Memory bank references: $BANK_REFS"

# 5. Transfer control (subroutine calls)
echo "[5/5] Transfer control analysis..."
TC_COUNT=$(grep -riE "^\s*(TC|TCF|CADR)\s" "$SYSTEM_DIR" --include="*.agc" 2>/dev/null | wc -l)
echo "  Transfer control instructions: $TC_COUNT"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Apollo-11 Preservation & Documentation Plan

## Historical Significance
This is the actual AGC (Apollo Guidance Computer) code that navigated
Apollo 11 to the Moon in 1969. Modernization means preservation and
educational accessibility, not rewriting.

## Codebase Profile
- AGC source files: $AGC_FILES
- Total lines: $TOTAL_LINES (including $COMMENT_LINES comments)
- Memory bank references: $BANK_REFS
- Transfer control instructions: $TC_COUNT

## Phase 1: Documentation (2-3 weeks)
- Document AGC instruction set
- Annotate key routines (P63 landing, P40 guidance)
- Create architectural overview
- Map program flow for key mission phases

## Phase 2: Simulation Wrapper (3-4 weeks)
- Create modern AGC simulator interface
- Web-based visualization of program execution
- Interactive mission phase exploration

## Phase 3: Educational Materials (2-3 weeks)
- Create guided walkthrough of landing code
- Comparison with modern equivalent algorithms
- Historical context documentation

## Note: This code should NEVER be "modernized" in the traditional sense.
## It is a historical artifact. The goal is preservation and accessibility.

## Estimated Effort: 6-10 weeks (documentation + simulation)
EOF

echo "=== Analysis complete ==="
