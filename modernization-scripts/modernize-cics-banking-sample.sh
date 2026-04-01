#!/bin/bash
# modernize-cics-banking-sample.sh
# Modernization script for CICS Banking Sample (COBOL 30K+ LOC)
# Strategy: mainframe-modernization
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/cics-banking-sample}"
RESULT_DIR="${2:-modernization-results/cics-banking-sample}"
mkdir -p "$RESULT_DIR"

echo "=== CICS Banking Sample Modernization Analysis ==="
echo "Strategy: Business rule extraction + API wrapping + microservice migration"

# Check if directory exists (may have failed to clone)
if [ ! -d "$SYSTEM_DIR" ]; then
    echo "  SKIPPED: Clone failed (403 - repository may be restricted)"
    echo "status: SKIPPED - clone returned HTTP 403" > "$RESULT_DIR/analysis.txt"
    cat > "$RESULT_DIR/migration-plan.md" << EOF
# CICS Banking Sample Migration Plan

## Status: BLOCKED
Repository clone returned HTTP 403. The IBM CICS Banking Sample may have been:
- Made private or archived
- Moved to a new location
- Restricted access

## Planned Strategy (if access restored):
1. Extract COBOL business rules into documented APIs
2. Map CICS transaction flows to REST endpoints
3. Identify DB2/VSAM data access patterns
4. Create Java/Spring Boot microservice equivalents
5. Implement side-by-side testing framework
EOF
    exit 0
fi

# 1. COBOL program inventory
echo "[1/6] COBOL program inventory..."
CBL_FILES=$(find "$SYSTEM_DIR" -type f \( -iname "*.cbl" -o -iname "*.cob" \) 2>/dev/null | wc -l)
CPY_FILES=$(find "$SYSTEM_DIR" -type f -iname "*.cpy" 2>/dev/null | wc -l)
JCL_FILES=$(find "$SYSTEM_DIR" -type f -iname "*.jcl" 2>/dev/null | wc -l)
echo "  COBOL programs: $CBL_FILES | Copybooks: $CPY_FILES | JCL: $JCL_FILES"

# 2. CICS command analysis
echo "[2/6] CICS command analysis..."
CICS_CMDS=$(grep -ri "EXEC CICS" "$SYSTEM_DIR" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l)
echo "  CICS EXEC commands: $CICS_CMDS"

# 3. SQL analysis
echo "[3/6] Embedded SQL analysis..."
SQL_STMTS=$(grep -ri "EXEC SQL" "$SYSTEM_DIR" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l)
echo "  Embedded SQL statements: $SQL_STMTS"

# 4. Data structure analysis
echo "[4/6] Data structure analysis..."
WORKING_STORAGE=$(grep -ri "WORKING-STORAGE" "$SYSTEM_DIR" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l)
echo "  WORKING-STORAGE sections: $WORKING_STORAGE"

# 5. Control flow complexity
echo "[5/6] Control flow analysis..."
PERFORM_COUNT=$(grep -ri "PERFORM " "$SYSTEM_DIR" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l)
GOTO_COUNT=$(grep -ri "GO TO\|GOTO" "$SYSTEM_DIR" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l)
echo "  PERFORM: $PERFORM_COUNT | GOTO: $GOTO_COUNT"

# 6. Transaction identification
echo "[6/6] Transaction identification..."
grep -ri "EXEC CICS.*RECEIVE\|EXEC CICS.*SEND\|EXEC CICS.*RETURN" "$SYSTEM_DIR" --include="*.cbl" --include="*.cob" 2>/dev/null > "$RESULT_DIR/transactions.txt" || true
TRANS_COUNT=$(wc -l < "$RESULT_DIR/transactions.txt")
echo "  Transaction I/O operations: $TRANS_COUNT"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# CICS Banking Sample Migration Plan

## Phase 1: Business Rule Extraction (4-6 weeks)
- COBOL programs: $CBL_FILES
- Copybooks: $CPY_FILES
- Document all business rules in structured format
- Map PERFORM chains to service boundaries

## Phase 2: API Definition (3-4 weeks)
- CICS commands: $CICS_CMDS -> REST API endpoints
- Transaction I/O: $TRANS_COUNT operations
- Define OpenAPI specifications
- Map CICS SEND/RECEIVE to HTTP request/response

## Phase 3: Data Migration (4-6 weeks)
- Embedded SQL: $SQL_STMTS statements
- WORKING-STORAGE sections: $WORKING_STORAGE
- Map COBOL data types to Java/modern equivalents
- Design relational database schema

## Phase 4: Microservice Implementation (8-12 weeks)
- Implement Spring Boot microservices
- Side-by-side testing with mainframe
- Gradual traffic migration

## Control Flow Complexity
- PERFORM statements: $PERFORM_COUNT (structured)
- GOTO statements: $GOTO_COUNT (unstructured - HIGH RISK)

## Estimated Effort: 6-9 months
EOF

echo "=== Analysis complete ==="
