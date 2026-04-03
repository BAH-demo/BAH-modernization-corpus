#!/bin/bash
# modernize-umbraco-cms.sh
# Modernization script for Umbraco CMS (C# 50K+ LOC CMS)
# Strategy: dotnet-migration
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/umbraco-cms}"
RESULT_DIR="${2:-modernization-results/umbraco-cms}"
mkdir -p "$RESULT_DIR"

echo "=== Umbraco CMS Modernization Analysis ==="
echo "Strategy: .NET 8+ migration + NuGet audit + observability"

# 1. .NET version check
echo "[1/6] Checking .NET target framework..."
grep -r "TargetFramework" "$SYSTEM_DIR" --include="*.csproj" 2>/dev/null | head -20 > "$RESULT_DIR/dotnet-version.txt" || true
echo "  Found $(wc -l < "$RESULT_DIR/dotnet-version.txt") project target frameworks"

# 2. Project structure
echo "[2/6] Analyzing project structure..."
SLN_COUNT=$(find "$SYSTEM_DIR" -name "*.sln" 2>/dev/null | wc -l)
CSPROJ_COUNT=$(find "$SYSTEM_DIR" -name "*.csproj" 2>/dev/null | wc -l)
echo "  Solutions: $SLN_COUNT | Projects: $CSPROJ_COUNT"

# 3. NuGet packages
echo "[3/6] NuGet dependency audit..."
grep -r "PackageReference" "$SYSTEM_DIR" --include="*.csproj" 2>/dev/null | grep -oP 'Include="\K[^"]+' | sort | uniq > "$RESULT_DIR/nuget-packages.txt" || true
NUGET_COUNT=$(wc -l < "$RESULT_DIR/nuget-packages.txt")
echo "  Unique NuGet packages: $NUGET_COUNT"

# 4. Obsolete patterns
echo "[4/6] Scanning obsolete patterns..."
OBSOLETE=$(grep -r "\[Obsolete\]" "$SYSTEM_DIR" --include="*.cs" 2>/dev/null | wc -l)
echo "  [Obsolete] attributes: $OBSOLETE"

# 5. Test files
echo "[5/6] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -name "*Test*.cs" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 6. Razor views
echo "[6/6] Razor view assessment..."
RAZOR_FILES=$(find "$SYSTEM_DIR" -type f -name "*.cshtml" 2>/dev/null | wc -l)
echo "  Razor view files: $RAZOR_FILES"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# Umbraco CMS Migration Plan

## Phase 1: .NET 8 Migration
- Projects: $CSPROJ_COUNT | Solutions: $SLN_COUNT
- Target: .NET 8 LTS
## Phase 2: NuGet Audit
- Packages: $NUGET_COUNT unique dependencies
- Update to latest compatible versions
## Phase 3: View Modernization
- Razor files: $RAZOR_FILES
- Add Blazor components where beneficial
## Estimated Effort: 6-10 months
EOF

echo "=== Analysis complete ==="
