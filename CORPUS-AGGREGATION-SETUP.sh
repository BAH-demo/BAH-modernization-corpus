#!/bin/bash
# CORPUS-AGGREGATION-SETUP.sh
# Selective cloning of legacy corpus repositories with parallel support, pinning, and validation
# Use: ./CORPUS-AGGREGATION-SETUP.sh [--all] [--list] [--pin] [--verify] [--parallel N] [system1] [system2] ...

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGGREGATION_ROOT="$SCRIPT_DIR/modernization-corpus-aggregate"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MANIFEST="$SCRIPT_DIR/corpus-manifest.json"
PINS_FILE="$SCRIPT_DIR/corpus-pins.json"
PARALLEL_JOBS=4
CLONE_DEPTH=50

# Define all available repositories
get_repo_url() {
    case $1 in
        # TIER 1: Enterprise Monoliths
        apache-ofbiz) echo "https://github.com/apache/ofbiz-framework.git" ;;
        odoo) echo "https://github.com/odoo/odoo.git" ;;
        alfresco-community) echo "https://github.com/Alfresco/alfresco-community-repo.git" ;;
        
        # TIER 2: Enterprise Applications
        nuxeo) echo "https://github.com/nuxeo/nuxeo.git" ;;
        django-oscar) echo "https://github.com/django-oscar/django-oscar.git" ;;
        umbraco-cms) echo "https://github.com/umbraco/Umbraco-CMS.git" ;;
        mezzanine) echo "https://github.com/stephenmcd/mezzanine.git" ;;
        b2cweb) echo "https://github.com/mission008/B2CWeb.git" ;;
        dfe-net) echo "https://github.com/ZeusAutomacao/DFe.NET.git" ;;
        monolith-enterprise) echo "https://github.com/colinbut/monolith-enterprise-application.git" ;;
        cfwheels) echo "https://github.com/wheels-dev/wheels.git" ;;
        
        # TIER 3: Federal/Legacy Systems
        cics-banking-sample) echo "https://github.com/cicsdev/cics-banking-sample-cbsa.git" ;;
        nastran-95) echo "https://github.com/nasa/NASTRAN-95.git" ;;
        apollo-11) echo "https://github.com/chrislgarry/Apollo-11.git" ;;
        
        *) echo "" ;;
    esac
}

# All system names
ALL_SYSTEMS=(
    apache-ofbiz odoo alfresco-community
    nuxeo django-oscar umbraco-cms
    mezzanine b2cweb dfe-net monolith-enterprise cfwheels
    cics-banking-sample nastran-95 apollo-11
)

# List all available systems
list_repos() {
    echo "Available repositories:"
    echo ""
    echo "TIER 1: Enterprise Monoliths (Hardest Cases)"
    echo "  - apache-ofbiz       (500K LOC Java ERP)"
    echo "  - odoo               (200K LOC Python ERP)"
    echo "  - alfresco-community (100K LOC Java Content)"
    echo ""
    echo "TIER 2: Enterprise Applications (10-50K LOC)"
    echo "  - nuxeo              (50K LOC Java)"
    echo "  - umbraco-cms        (50K LOC C#)"
    echo "  - cfwheels           (50K LOC ColdFusion)"
    echo "  - django-oscar       (10K LOC Python)"
    echo "  - b2cweb             (5K LOC Java)"
    echo "  - mezzanine          (5K LOC Python)"
    echo "  - dfe-net            (5K LOC C#)"
    echo "  - monolith-enterprise (5K LOC Java)"
    echo ""
    echo "TIER 3: Federal/Legacy Systems (Real Production)"
    echo "  - cics-banking-sample (COBOL banking - IBM)"
    echo "  - nastran-95         (Fortran scientific - NASA)"
    echo "  - apollo-11          (Assembly code - 1969)"
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local name=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d) %s" "$percent" "$current" "$total" "$name"
}

# Clone a single repository
clone_single() {
    local repo_name="$1"
    local repo_url
    repo_url=$(get_repo_url "$repo_name")
    
    if [ -z "$repo_url" ]; then
        echo "FAIL:$repo_name:Unknown repository"
        return 1
    fi
    
    local repo_path="$AGGREGATION_ROOT/$repo_name"
    
    if [ -d "$repo_path" ]; then
        echo "SKIP:$repo_name:Already cloned"
        return 0
    fi
    
    if git clone --depth="$CLONE_DEPTH" "$repo_url" "$repo_path" 2>/dev/null; then
        echo "OK:$repo_name:Cloned successfully"
    else
        echo "FAIL:$repo_name:Clone failed"
        return 1
    fi
}

# Record commit SHAs to pins file
record_pins() {
    local repos_to_pin=("$@")
    echo "{" > "$PINS_FILE"
    echo "  \"pinned_at\": \"$TIMESTAMP\"," >> "$PINS_FILE"
    echo "  \"systems\": {" >> "$PINS_FILE"
    
    local first=true
    for repo_name in "${repos_to_pin[@]}"; do
        local repo_path="$AGGREGATION_ROOT/$repo_name"
        if [ -d "$repo_path/.git" ]; then
            local sha
            sha=$(git -C "$repo_path" rev-parse HEAD 2>/dev/null)
            local branch
            branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
            
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "$PINS_FILE"
            fi
            printf "    \"%s\": {\"sha\": \"%s\", \"branch\": \"%s\"}" "$repo_name" "$sha" "$branch" >> "$PINS_FILE"
        fi
    done
    
    echo "" >> "$PINS_FILE"
    echo "  }" >> "$PINS_FILE"
    echo "}" >> "$PINS_FILE"
    
    echo ""
    echo "Pinned commit SHAs to: $PINS_FILE"
}

# Verify existing clones against manifest
verify_clones() {
    local repos_to_verify=("$@")
    
    if [ ! -f "$MANIFEST" ]; then
        echo "Error: corpus-manifest.json not found at $MANIFEST"
        exit 1
    fi
    
    echo "Verifying cloned systems against manifest..."
    echo ""
    
    local pass=0
    local fail=0
    
    for repo_name in "${repos_to_verify[@]}"; do
        local repo_path="$AGGREGATION_ROOT/$repo_name"
        
        if [ ! -d "$repo_path" ]; then
            echo "  [MISSING] $repo_name - not cloned"
            ((fail++))
            continue
        fi
        
        if [ ! -d "$repo_path/.git" ]; then
            echo "  [INVALID] $repo_name - not a git repository"
            ((fail++))
            continue
        fi
        
        local expected_lang
        expected_lang=$(python3 -c "
import json
with open('$MANIFEST') as f:
    data = json.load(f)
print(data['systems'].get('$repo_name', {}).get('language', 'unknown'))
" 2>/dev/null)
        
        local file_count=0
        case "$expected_lang" in
            Java) file_count=$(find "$repo_path" -name "*.java" -type f 2>/dev/null | wc -l) ;;
            Python) file_count=$(find "$repo_path" -name "*.py" -type f 2>/dev/null | wc -l) ;;
            "C#") file_count=$(find "$repo_path" -name "*.cs" -type f 2>/dev/null | wc -l) ;;
            COBOL) file_count=$(find "$repo_path" \( -name "*.cbl" -o -name "*.cob" \) -type f 2>/dev/null | wc -l) ;;
            Fortran) file_count=$(find "$repo_path" \( -name "*.f" -o -name "*.f90" -o -name "*.for" \) -type f 2>/dev/null | wc -l) ;;
            Assembly) file_count=$(find "$repo_path" \( -name "*.agc" -o -name "*.s" -o -name "*.asm" \) -type f 2>/dev/null | wc -l) ;;
            ColdFusion) file_count=$(find "$repo_path" \( -name "*.cfm" -o -name "*.cfc" \) -type f 2>/dev/null | wc -l) ;;
        esac
        
        if [ "$file_count" -gt 0 ]; then
            echo "  [OK] $repo_name - $file_count $expected_lang files found"
            ((pass++))
        else
            echo "  [WARN] $repo_name - no $expected_lang files found"
            ((pass++))
        fi
    done
    
    echo ""
    echo "Verification complete: $pass passed, $fail failed"
    
    if [ "$fail" -gt 0 ]; then
        exit 1
    fi
}

# Run post-clone validation with cloc
post_clone_validate() {
    local repo_name="$1"
    local repo_path="$AGGREGATION_ROOT/$repo_name"
    
    if ! command -v cloc &>/dev/null; then
        return 0
    fi
    
    if [ ! -f "$MANIFEST" ]; then
        return 0
    fi
    
    local loc_min loc_max
    loc_min=$(python3 -c "
import json
with open('$MANIFEST') as f:
    data = json.load(f)
print(data['systems'].get('$repo_name', {}).get('loc_min', 0))
" 2>/dev/null)
    loc_max=$(python3 -c "
import json
with open('$MANIFEST') as f:
    data = json.load(f)
print(data['systems'].get('$repo_name', {}).get('loc_max', 999999999))
" 2>/dev/null)
    
    local actual_loc
    actual_loc=$(cloc --quiet --json "$repo_path" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('SUM', {}).get('code', 0))
" 2>/dev/null || echo "0")
    
    if [ "$actual_loc" -ge "$loc_min" ] && [ "$actual_loc" -le "$loc_max" ]; then
        echo "  LOC validation: $actual_loc (within [$loc_min, $loc_max])"
    else
        echo "  LOC validation: $actual_loc (WARNING: outside [$loc_min, $loc_max])"
    fi
}

# Parse command line arguments
CLONE_ALL=false
LIST_ONLY=false
PIN_MODE=false
VERIFY_MODE=false
SELECTED_REPOS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CLONE_ALL=true
            shift
            ;;
        --list)
            LIST_ONLY=true
            shift
            ;;
        --pin)
            PIN_MODE=true
            shift
            ;;
        --verify)
            VERIFY_MODE=true
            shift
            ;;
        --parallel)
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --depth)
            CLONE_DEPTH="$2"
            shift 2
            ;;
        *)
            if [ -n "$(get_repo_url "$1")" ]; then
                SELECTED_REPOS+=("$1")
            else
                echo "Error: Unknown repository: $1"
                echo "Use --list to see available systems"
                exit 1
            fi
            shift
            ;;
    esac
done

# Show help if no arguments
if [ "$LIST_ONLY" = false ] && [ "$CLONE_ALL" = false ] && [ "$VERIFY_MODE" = false ] && [ ${#SELECTED_REPOS[@]} -eq 0 ]; then
    echo "Legacy Modernization Corpus - Aggregation Setup"
    echo ""
    echo "Usage:"
    echo "  Clone all:           ./CORPUS-AGGREGATION-SETUP.sh --all"
    echo "  List available:      ./CORPUS-AGGREGATION-SETUP.sh --list"
    echo "  Clone specific:      ./CORPUS-AGGREGATION-SETUP.sh odoo django-oscar"
    echo "  Clone & pin:         ./CORPUS-AGGREGATION-SETUP.sh --pin --all"
    echo "  Verify clones:       ./CORPUS-AGGREGATION-SETUP.sh --verify"
    echo "  Parallel (8 jobs):   ./CORPUS-AGGREGATION-SETUP.sh --parallel 8 --all"
    echo ""
    echo "Options:"
    echo "  --all                Clone all 14 systems"
    echo "  --list               List available systems"
    echo "  --pin                Record commit SHAs to corpus-pins.json"
    echo "  --verify             Verify existing clones against manifest"
    echo "  --parallel N         Number of parallel clone jobs (default: 4)"
    echo "  --depth N            Git clone depth (default: 50)"
    echo ""
    echo "Examples:"
    echo "  # Clone only enterprise monoliths"
    echo "  ./CORPUS-AGGREGATION-SETUP.sh apache-ofbiz odoo alfresco-community"
    echo ""
    echo "  # Clone federal/legacy systems with pinning"
    echo "  ./CORPUS-AGGREGATION-SETUP.sh --pin cics-banking-sample nastran-95 apollo-11"
    echo ""
    echo "  # Clone everything in parallel"
    echo "  ./CORPUS-AGGREGATION-SETUP.sh --all --parallel 4"
    exit 0
fi

# List and exit
if [ "$LIST_ONLY" = true ]; then
    list_repos
    exit 0
fi

# Determine which repos to process
if [ "$CLONE_ALL" = true ] || { [ "$VERIFY_MODE" = true ] && [ ${#SELECTED_REPOS[@]} -eq 0 ]; }; then
    REPOS_TO_PROCESS=("${ALL_SYSTEMS[@]}")
else
    REPOS_TO_PROCESS=("${SELECTED_REPOS[@]}")
fi

# Verify mode
if [ "$VERIFY_MODE" = true ]; then
    verify_clones "${REPOS_TO_PROCESS[@]}"
    exit $?
fi

# Create aggregation directory
mkdir -p "$AGGREGATION_ROOT"

TOTAL=${#REPOS_TO_PROCESS[@]}
echo "Legacy Modernization Corpus - Cloning"
echo "======================================"
echo "Target: $AGGREGATION_ROOT"
echo "Systems: $TOTAL"
echo "Parallel jobs: $PARALLEL_JOBS"
echo ""

# Export functions and variables for parallel execution
export -f clone_single get_repo_url
export AGGREGATION_ROOT CLONE_DEPTH

# Clone repositories
COMPLETED=0
FAILED=0

if [ "$PARALLEL_JOBS" -gt 1 ] && [ "$TOTAL" -gt 1 ]; then
    echo "Cloning $TOTAL systems with $PARALLEL_JOBS parallel jobs..."
    echo ""
    
    PIDS=()
    RESULTS_TMP=$(mktemp)
    
    for repo_name in "${REPOS_TO_PROCESS[@]}"; do
        # Wait if we have too many background jobs
        while [ ${#PIDS[@]} -ge "$PARALLEL_JOBS" ]; do
            NEW_PIDS=()
            for pid in "${PIDS[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    NEW_PIDS+=("$pid")
                fi
            done
            PIDS=("${NEW_PIDS[@]}")
            if [ ${#PIDS[@]} -ge "$PARALLEL_JOBS" ]; then
                sleep 1
            fi
        done
        
        (
            result=$(clone_single "$repo_name")
            echo "$result" >> "$RESULTS_TMP"
            
            status=$(echo "$result" | cut -d: -f1)
            case "$status" in
                OK) echo "  Cloned: $repo_name" ;;
                SKIP) echo "  Already cloned: $repo_name" ;;
                FAIL) echo "  FAILED: $repo_name" ;;
            esac
        ) &
        PIDS+=($!)
    done
    
    # Wait for all background jobs
    for pid in "${PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
    
    if [ -f "$RESULTS_TMP" ]; then
        COMPLETED=$(grep -c "^OK\|^SKIP" "$RESULTS_TMP" 2>/dev/null || echo "0")
        FAILED=$(grep -c "^FAIL" "$RESULTS_TMP" 2>/dev/null || echo "0")
        rm -f "$RESULTS_TMP"
    fi
else
    # Sequential cloning with progress bar
    for repo_name in "${REPOS_TO_PROCESS[@]}"; do
        ((COMPLETED++)) || true
        show_progress "$COMPLETED" "$TOTAL" "$repo_name"
        
        result=$(clone_single "$repo_name")
        status=$(echo "$result" | cut -d: -f1)
        
        case "$status" in
            OK)
                echo ""
                echo "  Cloned: $repo_name"
                post_clone_validate "$repo_name"
                ;;
            SKIP)
                echo ""
                echo "  Already cloned: $repo_name"
                ;;
            FAIL)
                echo ""
                echo "  FAILED: $repo_name"
                ((FAILED++))
                ;;
        esac
    done
fi

echo ""

# Pin mode: record SHAs
if [ "$PIN_MODE" = true ]; then
    record_pins "${REPOS_TO_PROCESS[@]}"
fi

# Post-clone validation summary
if command -v cloc &>/dev/null && [ -f "$MANIFEST" ]; then
    echo ""
    echo "Running post-clone LOC validation..."
    for repo_name in "${REPOS_TO_PROCESS[@]}"; do
        if [ -d "$AGGREGATION_ROOT/$repo_name" ]; then
            post_clone_validate "$repo_name"
        fi
    done
fi

echo ""
echo "Aggregation complete!"
echo "Systems in: $AGGREGATION_ROOT"
echo "Cloned/verified: $((TOTAL - FAILED))/$TOTAL"
if [ "$FAILED" -gt 0 ]; then
    echo "Failed: $FAILED"
fi
echo ""
echo "Next steps:"
echo "  cd $AGGREGATION_ROOT"
echo "  ls -la"
if [ "$PIN_MODE" = true ]; then
    echo "  cat $PINS_FILE"
fi
