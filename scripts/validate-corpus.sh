#!/bin/bash
# validate-corpus.sh
# Validates cloned corpus repositories against corpus-manifest.json
# Usage: ./scripts/validate-corpus.sh [--verbose] [system1] [system2] ...

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$REPO_ROOT/corpus-manifest.json"
AGGREGATE_DIR="$REPO_ROOT/modernization-corpus-aggregate"
RESULTS_DIR="$REPO_ROOT/corpus-verification-results"

VERBOSE=false
SELECTED_SYSTEMS=()
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [--verbose] [system1] [system2] ..."
    echo ""
    echo "Validates cloned corpus repositories against corpus-manifest.json"
    echo ""
    echo "Options:"
    echo "  --verbose    Show detailed validation output"
    echo "  --help       Show this help message"
    echo ""
    echo "If no systems specified, validates all cloned systems."
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

log_info() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

# Check prerequisites
check_prerequisites() {
    if ! command -v cloc &>/dev/null; then
        echo -e "${YELLOW}Warning: 'cloc' not found. Install with: pip install cloc or apt-get install cloc${NC}"
        echo "Falling back to line-count estimation via wc -l"
        return 1
    fi
    return 0
}

# Get value from manifest JSON (portable - no jq dependency)
get_manifest_value() {
    local system="$1"
    local field="$2"
    python3 -c "
import json, sys
with open('$MANIFEST') as f:
    data = json.load(f)
systems = data.get('systems', {})
if '$system' in systems:
    print(systems['$system'].get('$field', ''))
else:
    sys.exit(1)
" 2>/dev/null
}

# Count LOC using cloc or fallback
count_loc() {
    local dir="$1"
    local language="$2"

    if command -v cloc &>/dev/null; then
        local total
        total=$(cloc --quiet --json "$dir" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('SUM', {}).get('code', 0))
" 2>/dev/null)
        echo "${total:-0}"
    else
        # Fallback: count lines based on primary language extensions
        local ext_pattern
        case "$language" in
            Java) ext_pattern="*.java" ;;
            Python) ext_pattern="*.py" ;;
            "C#") ext_pattern="*.cs" ;;
            COBOL) ext_pattern="*.cbl *.cob *.CBL *.COB" ;;
            Fortran) ext_pattern="*.f *.f90 *.f77 *.for *.F" ;;
            Assembly) ext_pattern="*.agc *.s *.asm" ;;
            ColdFusion) ext_pattern="*.cfm *.cfc" ;;
            *) ext_pattern="*" ;;
        esac

        local count=0
        for ext in $ext_pattern; do
            local found
            found=$(find "$dir" -name "$ext" -type f -exec cat {} + 2>/dev/null | wc -l)
            count=$((count + found))
        done
        echo "$count"
    fi
}

# Validate a single system
validate_system() {
    local system="$1"
    local system_dir="$AGGREGATE_DIR/$system"

    echo ""
    echo "=== Validating: $system ==="

    # Check if directory exists
    if [ ! -d "$system_dir" ]; then
        log_fail "$system: Directory not found at $system_dir"
        return 1
    fi
    log_pass "$system: Directory exists"

    # Check if it's a git repo
    if [ ! -d "$system_dir/.git" ]; then
        log_fail "$system: Not a git repository"
        return 1
    fi
    log_pass "$system: Valid git repository"

    # Get manifest values
    local expected_lang
    expected_lang=$(get_manifest_value "$system" "language")
    local loc_min
    loc_min=$(get_manifest_value "$system" "loc_min")
    local loc_max
    loc_max=$(get_manifest_value "$system" "loc_max")
    local tier
    tier=$(get_manifest_value "$system" "tier")

    log_info "$system: Expected language=$expected_lang, LOC range=[$loc_min, $loc_max], tier=$tier"

    # Count LOC
    local actual_loc
    actual_loc=$(count_loc "$system_dir" "$expected_lang")

    log_info "$system: Actual LOC count = $actual_loc"

    # Validate LOC range (with 50% tolerance for estimation)
    local loc_min_tolerant=$((loc_min / 2))
    local loc_max_tolerant=$((loc_max * 2))

    if [ "$actual_loc" -ge "$loc_min_tolerant" ] && [ "$actual_loc" -le "$loc_max_tolerant" ]; then
        log_pass "$system: LOC count $actual_loc within expected range [$loc_min, $loc_max] (with tolerance)"
    elif [ "$actual_loc" -gt 0 ]; then
        log_warn "$system: LOC count $actual_loc outside expected range [$loc_min, $loc_max]"
    else
        log_fail "$system: LOC count is 0 or could not be determined"
    fi

    # Check for expected file types
    local file_count=0
    case "$expected_lang" in
        Java) file_count=$(find "$system_dir" -name "*.java" -type f 2>/dev/null | wc -l) ;;
        Python) file_count=$(find "$system_dir" -name "*.py" -type f 2>/dev/null | wc -l) ;;
        "C#") file_count=$(find "$system_dir" -name "*.cs" -type f 2>/dev/null | wc -l) ;;
        COBOL) file_count=$(find "$system_dir" \( -name "*.cbl" -o -name "*.cob" -o -name "*.CBL" -o -name "*.COB" \) -type f 2>/dev/null | wc -l) ;;
        Fortran) file_count=$(find "$system_dir" \( -name "*.f" -o -name "*.f90" -o -name "*.for" -o -name "*.F" \) -type f 2>/dev/null | wc -l) ;;
        Assembly) file_count=$(find "$system_dir" \( -name "*.agc" -o -name "*.s" -o -name "*.asm" \) -type f 2>/dev/null | wc -l) ;;
        ColdFusion) file_count=$(find "$system_dir" \( -name "*.cfm" -o -name "*.cfc" \) -type f 2>/dev/null | wc -l) ;;
    esac

    if [ "$file_count" -gt 0 ]; then
        log_pass "$system: Found $file_count $expected_lang files"
    else
        log_warn "$system: No $expected_lang files found (may use different extensions)"
    fi

    # Write result to results directory
    mkdir -p "$RESULTS_DIR"
    cat > "$RESULTS_DIR/${system}-validation.json" <<EOF
{
  "system": "$system",
  "validated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "directory_exists": true,
  "is_git_repo": true,
  "expected_language": "$expected_lang",
  "actual_loc": $actual_loc,
  "expected_loc_min": $loc_min,
  "expected_loc_max": $loc_max,
  "language_files_found": $file_count,
  "tier": $tier
}
EOF

    return 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            SELECTED_SYSTEMS+=("$1")
            shift
            ;;
    esac
done

# Check manifest exists
if [ ! -f "$MANIFEST" ]; then
    echo -e "${RED}Error: corpus-manifest.json not found at $MANIFEST${NC}"
    exit 1
fi

# Check aggregate directory exists
if [ ! -d "$AGGREGATE_DIR" ]; then
    echo -e "${RED}Error: Aggregation directory not found at $AGGREGATE_DIR${NC}"
    echo "Run CORPUS-AGGREGATION-SETUP.sh first to clone systems."
    exit 1
fi

check_prerequisites
HAS_CLOC=$?

echo "=================================="
echo "  Corpus Validation Report"
echo "=================================="
echo "Manifest: $MANIFEST"
echo "Corpus:   $AGGREGATE_DIR"
echo ""

# Determine systems to validate
if [ ${#SELECTED_SYSTEMS[@]} -eq 0 ]; then
    # Validate all cloned systems
    for dir in "$AGGREGATE_DIR"/*/; do
        if [ -d "$dir" ]; then
            system=$(basename "$dir")
            SELECTED_SYSTEMS+=("$system")
        fi
    done
fi

if [ ${#SELECTED_SYSTEMS[@]} -eq 0 ]; then
    echo "No systems found to validate."
    exit 1
fi

echo "Systems to validate: ${#SELECTED_SYSTEMS[@]}"

# Validate each system
for system in "${SELECTED_SYSTEMS[@]}"; do
    validate_system "$system" || true
done

# Summary
echo ""
echo "=================================="
echo "  Validation Summary"
echo "=================================="
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Warnings: $WARN_COUNT${NC}"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}Validation completed with failures.${NC}"
    exit 1
else
    echo -e "${GREEN}Validation completed successfully.${NC}"
    exit 0
fi
