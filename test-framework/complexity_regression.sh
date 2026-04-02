#!/bin/bash
# complexity_regression.sh
# Runs lizard on original and modernized code, fails if modernized code has higher average complexity
# Usage: ./test-framework/complexity_regression.sh [--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$SCRIPT_DIR/results"
VERBOSE=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose) VERBOSE=true; shift ;;
        *) shift ;;
    esac
done

mkdir -p "$RESULTS_DIR"

# Check lizard availability
if ! command -v lizard &>/dev/null && ! python3 -m lizard --version &>/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: lizard not installed. Install with: pip install lizard${NC}"
    echo '{"status":"skipped","reason":"lizard not installed"}' > "$RESULTS_DIR/complexity-regression.json"
    exit 0
fi

LIZARD_CMD="python3 -m lizard"

get_avg_complexity() {
    local dir="$1"
    local extensions="$2"
    
    if [ ! -d "$dir" ]; then
        echo "0"
        return
    fi
    
    local result
    result=$($LIZARD_CMD "$dir" $extensions --csv 2>/dev/null | \
        python3 -c "
import sys, csv
reader = csv.reader(sys.stdin)
complexities = []
for row in reader:
    try:
        complexities.append(float(row[1]))  # CCN column
    except (IndexError, ValueError):
        pass
if complexities:
    print(f'{sum(complexities)/len(complexities):.2f}')
else:
    print('0')
" 2>/dev/null || echo "0")
    echo "$result"
}

echo "=========================================="
echo "  Complexity Regression Analysis"
echo "=========================================="
echo ""

REGRESSION_FOUND=false
RESULTS=()

# Define comparison pairs: original_dir modernized_dir name
declare -A COMPARISONS
COMPARISONS=(
    ["COBOL->Java"]="modernization-corpus-aggregate/cics-banking-sample|modernization-targets/cobol-to-java/src"
    ["Fortran->Python"]="modernization-corpus-aggregate/nastran-95|modernization-targets/fortran-to-python/nastran_modern"
    ["Assembly->C"]="modernization-corpus-aggregate/apollo-11|modernization-targets/assembly-to-c/src"
)

for name in "${!COMPARISONS[@]}"; do
    IFS='|' read -r orig_rel mod_rel <<< "${COMPARISONS[$name]}"
    orig_dir="$REPO_ROOT/$orig_rel"
    mod_dir="$REPO_ROOT/$mod_rel"
    
    echo "Comparing: $name"
    
    if [ ! -d "$orig_dir" ]; then
        echo -e "  ${YELLOW}Original not found: $orig_dir (skipping)${NC}"
        continue
    fi
    
    if [ ! -d "$mod_dir" ]; then
        echo -e "  ${YELLOW}Modernized not found: $mod_dir (skipping)${NC}"
        continue
    fi
    
    orig_cc=$(get_avg_complexity "$orig_dir" "")
    mod_cc=$(get_avg_complexity "$mod_dir" "")
    
    echo "  Original avg complexity:   $orig_cc"
    echo "  Modernized avg complexity: $mod_cc"
    
    if python3 -c "exit(0 if float('$mod_cc') <= float('$orig_cc') or float('$mod_cc') == 0 else 1)" 2>/dev/null; then
        echo -e "  ${GREEN}[PASS] Complexity maintained or improved${NC}"
    else
        echo -e "  ${RED}[FAIL] Complexity regression detected${NC}"
        REGRESSION_FOUND=true
    fi
    
    RESULTS+=("{\"comparison\":\"$name\",\"original_cc\":$orig_cc,\"modernized_cc\":$mod_cc}")
    echo ""
done

# Write results
RESULTS_JSON=$(printf '%s,' "${RESULTS[@]}" | sed 's/,$//')
cat > "$RESULTS_DIR/complexity-regression.json" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "regression_detected": $REGRESSION_FOUND,
  "comparisons": [$RESULTS_JSON]
}
EOF

echo "Results saved to: $RESULTS_DIR/complexity-regression.json"

if [ "$REGRESSION_FOUND" = true ]; then
    echo -e "${RED}Complexity regression detected!${NC}"
    exit 1
fi

echo -e "${GREEN}No complexity regressions found.${NC}"
exit 0
