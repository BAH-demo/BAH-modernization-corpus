#!/bin/bash
# run_all_tests.sh
# Orchestrator that detects modernization targets and runs their test suites
# Usage: ./test-framework/run_all_tests.sh [--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="$SCRIPT_DIR/results"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose) VERBOSE=true; shift ;;
        *) shift ;;
    esac
done

mkdir -p "$RESULTS_DIR"

log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TOTAL_PASS++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TOTAL_FAIL++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TOTAL_SKIP++))
}

# Run COBOL->Java tests (Maven/JUnit)
run_cobol_java_tests() {
    local target_dir="$REPO_ROOT/modernization-targets/cobol-to-java"
    
    if [ ! -d "$target_dir" ]; then
        log_skip "COBOL->Java: Target directory not found"
        return
    fi
    
    if [ ! -f "$target_dir/pom.xml" ]; then
        log_skip "COBOL->Java: No pom.xml found"
        return
    fi
    
    log "Running COBOL->Java tests (Maven/JUnit 5)..."
    
    if command -v mvn &>/dev/null; then
        if mvn -f "$target_dir/pom.xml" test -q 2>"$RESULTS_DIR/cobol-java-errors.log"; then
            log_pass "COBOL->Java: All JUnit tests passed"
            echo '{"target":"cobol-to-java","status":"passed","framework":"junit5"}' > "$RESULTS_DIR/cobol-java.json"
        else
            log_fail "COBOL->Java: JUnit tests failed (see $RESULTS_DIR/cobol-java-errors.log)"
            echo '{"target":"cobol-to-java","status":"failed","framework":"junit5"}' > "$RESULTS_DIR/cobol-java.json"
        fi
    else
        log_skip "COBOL->Java: Maven not installed"
        echo '{"target":"cobol-to-java","status":"skipped","reason":"maven not installed"}' > "$RESULTS_DIR/cobol-java.json"
    fi
}

# Run Fortran->Python tests (pytest)
run_fortran_python_tests() {
    local target_dir="$REPO_ROOT/modernization-targets/fortran-to-python"
    
    if [ ! -d "$target_dir" ]; then
        log_skip "Fortran->Python: Target directory not found"
        return
    fi
    
    log "Running Fortran->Python tests (pytest)..."
    
    if command -v pytest &>/dev/null || python3 -m pytest --version &>/dev/null 2>&1; then
        if python3 -m pytest "$target_dir/tests/" -v --tb=short 2>"$RESULTS_DIR/fortran-python-errors.log" | tee "$RESULTS_DIR/fortran-python-output.log"; then
            log_pass "Fortran->Python: All pytest tests passed"
            echo '{"target":"fortran-to-python","status":"passed","framework":"pytest"}' > "$RESULTS_DIR/fortran-python.json"
        else
            log_fail "Fortran->Python: pytest tests failed (see $RESULTS_DIR/fortran-python-errors.log)"
            echo '{"target":"fortran-to-python","status":"failed","framework":"pytest"}' > "$RESULTS_DIR/fortran-python.json"
        fi
    else
        log_skip "Fortran->Python: pytest not installed"
        echo '{"target":"fortran-to-python","status":"skipped","reason":"pytest not installed"}' > "$RESULTS_DIR/fortran-python.json"
    fi
}

# Run Assembly->C tests (make test)
run_assembly_c_tests() {
    local target_dir="$REPO_ROOT/modernization-targets/assembly-to-c"
    
    if [ ! -d "$target_dir" ]; then
        log_skip "Assembly->C: Target directory not found"
        return
    fi
    
    if [ ! -f "$target_dir/Makefile" ]; then
        log_skip "Assembly->C: No Makefile found"
        return
    fi
    
    log "Running Assembly->C tests (make test)..."
    
    if command -v gcc &>/dev/null; then
        if make -C "$target_dir" test 2>"$RESULTS_DIR/assembly-c-errors.log" | tee "$RESULTS_DIR/assembly-c-output.log"; then
            log_pass "Assembly->C: All C tests passed"
            echo '{"target":"assembly-to-c","status":"passed","framework":"c/unity"}' > "$RESULTS_DIR/assembly-c.json"
        else
            log_fail "Assembly->C: C tests failed (see $RESULTS_DIR/assembly-c-errors.log)"
            echo '{"target":"assembly-to-c","status":"failed","framework":"c/unity"}' > "$RESULTS_DIR/assembly-c.json"
        fi
    else
        log_skip "Assembly->C: gcc not installed"
        echo '{"target":"assembly-to-c","status":"skipped","reason":"gcc not installed"}' > "$RESULTS_DIR/assembly-c.json"
    fi
}

# Run analysis engine validation
run_analysis_engine_tests() {
    local engine_dir="$REPO_ROOT/analysis-engine"
    
    if [ ! -d "$engine_dir" ]; then
        log_skip "Analysis Engine: Directory not found"
        return
    fi
    
    log "Validating Analysis Engine..."
    
    # Check that analyzer.py can be imported
    if python3 -c "import sys; sys.path.insert(0, '$REPO_ROOT/analysis-engine'); from analyzers.base_analyzer import BaseAnalyzer; print('OK')" 2>/dev/null; then
        log_pass "Analysis Engine: Core imports successful"
        echo '{"target":"analysis-engine","status":"passed","framework":"python-import"}' > "$RESULTS_DIR/analysis-engine.json"
    else
        log_fail "Analysis Engine: Import errors"
        echo '{"target":"analysis-engine","status":"failed","framework":"python-import"}' > "$RESULTS_DIR/analysis-engine.json"
    fi
}

echo "=========================================="
echo "  Legacy Modernization - Test Runner"
echo "=========================================="
echo "Repository: $REPO_ROOT"
echo "Results:    $RESULTS_DIR"
echo "Timestamp:  $TIMESTAMP"
echo ""

# Detect and run tests
run_cobol_java_tests
echo ""
run_fortran_python_tests
echo ""
run_assembly_c_tests
echo ""
run_analysis_engine_tests

# Generate summary
echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $TOTAL_PASS${NC}"
echo -e "${RED}Failed: $TOTAL_FAIL${NC}"
echo -e "${YELLOW}Skipped: $TOTAL_SKIP${NC}"
echo ""

# Write summary JSON
cat > "$RESULTS_DIR/summary.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "total_passed": $TOTAL_PASS,
  "total_failed": $TOTAL_FAIL,
  "total_skipped": $TOTAL_SKIP,
  "overall_status": "$([ $TOTAL_FAIL -eq 0 ] && echo "passed" || echo "failed")"
}
EOF

echo "Results saved to: $RESULTS_DIR/summary.json"

if [ "$TOTAL_FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
