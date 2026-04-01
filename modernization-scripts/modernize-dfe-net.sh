#!/bin/bash
# modernize-dfe-net.sh
# Modernization script for DFe.NET (C# 5K LOC Invoicing)
# Strategy: dotnet-modernization
set -euo pipefail

SYSTEM_DIR="${1:-modernization-corpus-aggregate/dfe-net}"
RESULT_DIR="${2:-modernization-results/dfe-net}"
mkdir -p "$RESULT_DIR"

echo "=== DFe.NET Modernization Analysis ==="
echo "Strategy: .NET 8+ migration + XML API modernization"

# 1. .NET version
echo "[1/5] Checking .NET target framework..."
grep -r "TargetFramework\|TargetFrameworkVersion" "$SYSTEM_DIR" --include="*.csproj" 2>/dev/null > "$RESULT_DIR/dotnet-version.txt" || true
FW_COUNT=$(wc -l < "$RESULT_DIR/dotnet-version.txt")
echo "  Target framework declarations: $FW_COUNT"

# 2. XML handling (core domain)
echo "[2/5] Analyzing XML handling patterns..."
XML_PATTERNS=$(grep -r "XmlDocument\|XDocument\|XmlSerializer\|XmlReader\|XmlWriter" "$SYSTEM_DIR" --include="*.cs" 2>/dev/null | wc -l)
echo "  XML handling patterns: $XML_PATTERNS"

# 3. NuGet packages
echo "[3/5] NuGet audit..."
grep -r "PackageReference\|packages.config" "$SYSTEM_DIR" --include="*.csproj" --include="packages.config" 2>/dev/null > "$RESULT_DIR/nuget-packages.txt" || true

# 4. Test files
echo "[4/5] Test baseline..."
TEST_FILES=$(find "$SYSTEM_DIR" -type f -name "*Test*.cs" 2>/dev/null | wc -l)
echo "  Test files: $TEST_FILES"

# 5. Project structure
echo "[5/5] Project structure..."
CSPROJ_COUNT=$(find "$SYSTEM_DIR" -name "*.csproj" 2>/dev/null | wc -l)
echo "  C# projects: $CSPROJ_COUNT"

cat > "$RESULT_DIR/migration-plan.md" << EOF
# DFe.NET Migration Plan

## Phase 1: .NET 8 Migration
- Projects: $CSPROJ_COUNT
- Migrate from .NET Framework to .NET 8
## Phase 2: XML API Modernization
- XML patterns: $XML_PATTERNS
- Migrate to System.Text.Json where applicable
- Use XDocument for remaining XML needs
## Phase 3: Testing
- Current test files: $TEST_FILES
- Add comprehensive unit tests
## Estimated Effort: 4-6 weeks
EOF

echo "=== Analysis complete ==="
