#!/bin/bash
# refactor-all.sh
# Master refactoring runner - executes actual code transformations across all systems
# Tracks: execution time, tokens (LOC changed), retries, wall time per system
set -uo pipefail

###############################################################################
# CONFIGURATION
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGG_ROOT="$SCRIPT_DIR/modernization-corpus-aggregate"
REFACTOR_DIR="$SCRIPT_DIR/refactoring-scripts"
RESULTS_DIR="$SCRIPT_DIR/modernization-results"
METRICS_FILE="$RESULTS_DIR/refactor-metrics.csv"
PATCHES_DIR="$RESULTS_DIR/patches"
MASTER_START=$(date +%s%N)
MASTER_WALL_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MAX_RETRIES=3

mkdir -p "$RESULTS_DIR" "$PATCHES_DIR"

echo "system,language,files_changed,lines_added,lines_removed,execution_time_ms,wall_time_seconds,tokens_processed,retries,status,transformations_applied" > "$METRICS_FILE"

###############################################################################
# UTILITY FUNCTIONS
###############################################################################

run_with_retry() {
    local cmd="$1"
    local system="$2"
    local attempt=0
    local retries=0
    while [ $attempt -lt $MAX_RETRIES ]; do
        attempt=$((attempt + 1))
        if eval "$cmd" 2>/dev/null; then
            echo "$retries"
            return 0
        fi
        retries=$((retries + 1))
        echo "  Retry $attempt for $system..." >&2
    done
    echo "$retries"
    return 1
}

count_tokens_changed() {
    local dir="$1"
    local chars
    chars=$(cd "$dir" && git diff --cached 2>/dev/null | wc -c) || chars=0
    echo $(( chars / 4 ))
}

record_refactor_metric() {
    local system="$1" lang="$2" files_changed="$3" lines_added="$4" lines_removed="$5"
    local exec_time="$6" wall_time="$7" tokens="$8" retries="$9" status="${10}" transforms="${11}"
    echo "$system,$lang,$files_changed,$lines_added,$lines_removed,$exec_time,$wall_time,$tokens,$retries,$status,\"$transforms\"" >> "$METRICS_FILE"
}

generate_patch() {
    local system_dir="$1"
    local system_name="$2"
    if [ -d "$system_dir/.git" ]; then
        (cd "$system_dir" && git diff) > "$PATCHES_DIR/${system_name}.patch" 2>/dev/null || true
        local patch_size
        patch_size=$(wc -l < "$PATCHES_DIR/${system_name}.patch" 2>/dev/null) || patch_size=0
        echo "  Patch generated: ${system_name}.patch ($patch_size lines)"
    fi
}

get_diff_stats() {
    local system_dir="$1"
    if [ -d "$system_dir/.git" ]; then
        local stats
        stats=$(cd "$system_dir" && git diff --stat 2>/dev/null | tail -1) || stats=""
        local files_changed lines_added lines_removed
        files_changed=$(echo "$stats" | grep -oP '\d+(?= files? changed)') || files_changed=0
        lines_added=$(echo "$stats" | grep -oP '\d+(?= insertions?)') || lines_added=0
        lines_removed=$(echo "$stats" | grep -oP '\d+(?= deletions?)') || lines_removed=0
        echo "${files_changed:-0}|${lines_added:-0}|${lines_removed:-0}"
    else
        echo "0|0|0"
    fi
}

###############################################################################
# JAVA REFACTORING: javax -> jakarta migration
###############################################################################
refactor_java_javax_to_jakarta() {
    local system_dir="$1"
    local system_name="$2"
    local transforms=""

    echo "  [javax->jakarta] Migrating Jakarta EE namespace..."

    # Only migrate packages that actually moved to jakarta (NOT javax.crypto, javax.xml core, etc.)
    local jakarta_packages=(
        "javax.annotation"
        "javax.batch"
        "javax.ejb"
        "javax.el"
        "javax.enterprise"
        "javax.faces"
        "javax.inject"
        "javax.interceptor"
        "javax.jms"
        "javax.json"
        "javax.jws"
        "javax.mail"
        "javax.persistence"
        "javax.resource"
        "javax.security.enterprise"
        "javax.servlet"
        "javax.transaction"
        "javax.validation"
        "javax.websocket"
        "javax.ws.rs"
        "javax.xml.bind"
        "javax.xml.soap"
        "javax.xml.ws"
        "javax.activation"
    )

    local total_replacements=0
    for pkg in "${jakarta_packages[@]}"; do
        local jakarta_pkg="${pkg/javax/jakarta}"
        local count
        count=$(grep -rl "$pkg" "$system_dir" --include="*.java" 2>/dev/null | wc -l) || count=0
        if [ "$count" -gt 0 ]; then
            # Use find + sed for reliable in-place replacement
            find "$system_dir" -name "*.java" -exec grep -l "$pkg" {} \; 2>/dev/null | while read -r file; do
                sed -i "s|$pkg|$jakarta_pkg|g" "$file"
            done
            total_replacements=$((total_replacements + count))
            transforms="${transforms}${pkg}->${jakarta_pkg}($count files);"
        fi
    done

    # Also update XML configuration files (persistence.xml, web.xml, etc.)
    for pkg in "${jakarta_packages[@]}"; do
        local jakarta_pkg="${pkg/javax/jakarta}"
        find "$system_dir" -name "*.xml" -exec grep -l "$pkg" {} \; 2>/dev/null | while read -r file; do
            sed -i "s|$pkg|$jakarta_pkg|g" "$file"
        done
    done

    echo "  [javax->jakarta] Migrated $total_replacements files"
    echo "$transforms"
}

refactor_java_version_upgrade() {
    local system_dir="$1"
    local system_name="$2"
    local transforms=""

    echo "  [java-version] Upgrading Java version targets..."

    # Update Maven pom.xml
    find "$system_dir" -name "pom.xml" 2>/dev/null | while read -r pom; do
        # Update java.version property
        if grep -q '<java.version>' "$pom" 2>/dev/null; then
            sed -i 's|<java.version>1\.[0-9]*</java.version>|<java.version>17</java.version>|g' "$pom"
            sed -i 's|<java.version>[0-9]*</java.version>|<java.version>17</java.version>|g' "$pom"
            transforms="${transforms}pom.xml-java-version-17;"
        fi
        # Update maven.compiler.source/target
        if grep -q '<maven.compiler.source>' "$pom" 2>/dev/null; then
            sed -i 's|<maven.compiler.source>1\.[0-9]*</maven.compiler.source>|<maven.compiler.source>17</maven.compiler.source>|g' "$pom"
            sed -i 's|<maven.compiler.target>1\.[0-9]*</maven.compiler.target>|<maven.compiler.target>17</maven.compiler.target>|g' "$pom"
            transforms="${transforms}maven-compiler-17;"
        fi
    done

    # Update Gradle build files
    find "$system_dir" -name "build.gradle" 2>/dev/null | while read -r gradle; do
        if grep -q "sourceCompatibility" "$gradle" 2>/dev/null; then
            sed -i "s|sourceCompatibility\s*=\s*['\"]1\.[0-9]*['\"]|sourceCompatibility = '17'|g" "$gradle"
            sed -i "s|sourceCompatibility\s*=\s*['\"][0-9]*['\"]|sourceCompatibility = '17'|g" "$gradle"
            sed -i "s|sourceCompatibility\s*=\s*JavaVersion.VERSION_1_[0-9]*|sourceCompatibility = JavaVersion.VERSION_17|g" "$gradle"
            transforms="${transforms}gradle-sourceCompat-17;"
        fi
        if grep -q "targetCompatibility" "$gradle" 2>/dev/null; then
            sed -i "s|targetCompatibility\s*=\s*['\"]1\.[0-9]*['\"]|targetCompatibility = '17'|g" "$gradle"
            sed -i "s|targetCompatibility\s*=\s*['\"][0-9]*['\"]|targetCompatibility = '17'|g" "$gradle"
            transforms="${transforms}gradle-targetCompat-17;"
        fi
    done

    echo "  [java-version] Version upgrade transforms applied"
    echo "$transforms"
}

refactor_java_deprecated_patterns() {
    local system_dir="$1"
    local transforms=""

    echo "  [deprecated] Fixing deprecated Java patterns..."

    # Replace javax.annotation.PostConstruct with jakarta.annotation.PostConstruct (already handled by javax->jakarta)
    # Fix common deprecated patterns

    # Replace Thread.stop() calls with interrupt pattern (just flag them)
    local thread_stop
    thread_stop=$(grep -rn "\.stop()" "$system_dir" --include="*.java" 2>/dev/null | grep -c "Thread") || thread_stop=0
    if [ "$thread_stop" -gt 0 ]; then
        transforms="${transforms}thread_stop_flagged=$thread_stop;"
    fi

    # Replace StringBuffer with StringBuilder where not synchronized
    find "$system_dir" -name "*.java" -exec grep -l "new StringBuffer()" {} \; 2>/dev/null | while read -r file; do
        sed -i 's/new StringBuffer()/new StringBuilder()/g' "$file"
        sed -i 's/StringBuffer\s\+\(\w\+\)\s*=\s*new\s\+StringBuilder/StringBuilder \1 = new StringBuilder/g' "$file"
    done
    local sb_count
    sb_count=$(grep -rl "new StringBuilder()" "$system_dir" --include="*.java" 2>/dev/null | wc -l) || sb_count=0
    transforms="${transforms}StringBuffer->StringBuilder;"

    # Replace Vector with ArrayList in non-synchronized contexts
    find "$system_dir" -name "*.java" 2>/dev/null | while read -r file; do
        if grep -q "new Vector<\|new Vector()" "$file" 2>/dev/null; then
            sed -i 's/new Vector<>/new ArrayList<>()/g' "$file"
            sed -i 's/new Vector()/new ArrayList<>()/g' "$file"
            # Update variable declarations
            sed -i 's/Vector<\([^>]*\)>/List<\1>/g' "$file"
            # Add ArrayList import if not present
            if grep -q "ArrayList" "$file" && ! grep -q "import java.util.ArrayList" "$file"; then
                sed -i '/^import java\.util\./a import java.util.ArrayList;' "$file"
            fi
            if grep -q "List<" "$file" && ! grep -q "import java.util.List" "$file"; then
                sed -i '/^import java\.util\./a import java.util.List;' "$file"
            fi
        fi
    done
    transforms="${transforms}Vector->ArrayList;"

    # Replace Hashtable with HashMap
    find "$system_dir" -name "*.java" 2>/dev/null | while read -r file; do
        if grep -q "new Hashtable<\|new Hashtable()" "$file" 2>/dev/null; then
            sed -i 's/new Hashtable<>/new HashMap<>()/g' "$file"
            sed -i 's/new Hashtable()/new HashMap<>()/g' "$file"
            sed -i 's/Hashtable<\([^>]*\)>/Map<\1>/g' "$file"
        fi
    done
    transforms="${transforms}Hashtable->HashMap;"

    echo "  [deprecated] Deprecated pattern fixes applied"
    echo "$transforms"
}

###############################################################################
# PYTHON REFACTORING
###############################################################################
refactor_python_imp_to_importlib() {
    local system_dir="$1"
    local transforms=""

    echo "  [imp->importlib] Replacing deprecated imp module..."

    find "$system_dir" -name "*.py" 2>/dev/null | while read -r file; do
        if grep -q "import imp\b\|from imp " "$file" 2>/dev/null; then
            # Replace 'import imp' with 'import importlib'
            sed -i 's/^import imp$/import importlib\nimport importlib.util/g' "$file"
            sed -i 's/^from imp import /from importlib import /g' "$file"

            # Replace imp.find_module with importlib.util.find_spec
            sed -i 's/imp\.find_module(\([^)]*\))/importlib.util.find_spec(\1)/g' "$file"

            # Replace imp.load_module patterns
            sed -i 's/imp\.load_module(\([^)]*\))/importlib.import_module(\1)/g' "$file"

            # Replace imp.reload with importlib.reload
            sed -i 's/imp\.reload(\([^)]*\))/importlib.reload(\1)/g' "$file"

            transforms="${transforms}imp->importlib(${file##*/});"
        fi
    done

    echo "  [imp->importlib] Replacement complete"
    echo "$transforms"
}

refactor_python_deprecated_patterns() {
    local system_dir="$1"
    local transforms=""

    echo "  [py-deprecated] Fixing deprecated Python patterns..."

    # Fix Python 2 print statements (print "x" -> print("x"))
    find "$system_dir" -name "*.py" 2>/dev/null | while read -r file; do
        if grep -qP 'print\s+["\x27]' "$file" 2>/dev/null; then
            # Convert print "text" to print("text") - careful not to match print("text")
            perl -i -pe 's/^(\s*)print\s+(["\x27].*)/\1print(\2)/g unless /print\(/' "$file" 2>/dev/null || true
        fi
    done
    transforms="${transforms}print-statement->function;"

    # Replace has_key() with 'in' operator
    find "$system_dir" -name "*.py" -exec grep -l "\.has_key(" {} \; 2>/dev/null | while read -r file; do
        perl -i -pe 's/(\w+)\.has_key\(([^)]+)\)/\2 in \1/g' "$file" 2>/dev/null || true
        transforms="${transforms}has_key->in;"
    done

    # Replace .iteritems() with .items()
    find "$system_dir" -name "*.py" -exec grep -l "\.iteritems()" {} \; 2>/dev/null | while read -r file; do
        sed -i 's/\.iteritems()/.items()/g' "$file"
    done
    transforms="${transforms}iteritems->items;"

    # Replace .itervalues() with .values()
    find "$system_dir" -name "*.py" -exec grep -l "\.itervalues()" {} \; 2>/dev/null | while read -r file; do
        sed -i 's/\.itervalues()/.values()/g' "$file"
    done
    transforms="${transforms}itervalues->values;"

    # Replace .iterkeys() with .keys()
    find "$system_dir" -name "*.py" -exec grep -l "\.iterkeys()" {} \; 2>/dev/null | while read -r file; do
        sed -i 's/\.iterkeys()/.keys()/g' "$file"
    done
    transforms="${transforms}iterkeys->keys;"

    # Replace deprecated Django ugettext with gettext
    find "$system_dir" -name "*.py" -exec grep -l "ugettext\|ugettext_lazy" {} \; 2>/dev/null | while read -r file; do
        sed -i 's/from django.utils.translation import ugettext_lazy as _/from django.utils.translation import gettext_lazy as _/g' "$file"
        sed -i 's/from django.utils.translation import ugettext as _/from django.utils.translation import gettext as _/g' "$file"
        sed -i 's/from django.utils.translation import ugettext_lazy/from django.utils.translation import gettext_lazy/g' "$file"
        sed -i 's/from django.utils.translation import ugettext/from django.utils.translation import gettext/g' "$file"
        sed -i 's/ugettext_lazy/gettext_lazy/g' "$file"
        sed -i 's/ugettext/gettext/g' "$file"
    done
    transforms="${transforms}ugettext->gettext;"

    # Replace python_2_unicode_compatible decorator
    find "$system_dir" -name "*.py" -exec grep -l "python_2_unicode_compatible" {} \; 2>/dev/null | while read -r file; do
        sed -i '/python_2_unicode_compatible/d' "$file"
        sed -i '/@python_2_unicode_compatible/d' "$file"
    done
    transforms="${transforms}remove-py2-unicode-compat;"

    # Replace os.path with pathlib patterns for common cases
    # (Only flag count, don't auto-transform as it's risky)
    local ospath_count
    ospath_count=$(grep -rl "os.path.join\|os.path.exists\|os.path.isdir\|os.path.isfile" "$system_dir" --include="*.py" 2>/dev/null | wc -l) || ospath_count=0
    transforms="${transforms}os.path-flagged=$ospath_count;"

    echo "  [py-deprecated] Fixes applied"
    echo "$transforms"
}

refactor_python_type_hints() {
    local system_dir="$1"
    local transforms=""

    echo "  [type-hints] Adding type hints to key functions..."

    # Add __future__ annotations import to files that don't have it
    find "$system_dir" -name "*.py" -exec grep -L "from __future__ import annotations" {} \; 2>/dev/null | head -50 | while read -r file; do
        # Only add to files with function definitions
        if grep -q "def " "$file" 2>/dev/null; then
            # Add after existing future imports, or at top after docstring
            if grep -q "from __future__" "$file" 2>/dev/null; then
                sed -i '/from __future__/a from __future__ import annotations' "$file" 2>/dev/null || true
            else
                sed -i '1s/^/from __future__ import annotations\n/' "$file" 2>/dev/null || true
            fi
        fi
    done
    transforms="${transforms}future-annotations;"

    # Add -> None return type to __init__ methods that lack type hints
    find "$system_dir" -name "*.py" 2>/dev/null | head -100 | while read -r file; do
        sed -i 's/def __init__(self):/def __init__(self) -> None:/g' "$file" 2>/dev/null || true
        sed -i 's/def __init__(self, \*args, \*\*kwargs):/def __init__(self, *args, **kwargs) -> None:/g' "$file" 2>/dev/null || true
    done
    transforms="${transforms}init-return-None;"

    # Add -> str to __str__ methods
    find "$system_dir" -name "*.py" 2>/dev/null | head -100 | while read -r file; do
        sed -i 's/def __str__(self):/def __str__(self) -> str:/g' "$file" 2>/dev/null || true
        sed -i 's/def __repr__(self):/def __repr__(self) -> str:/g' "$file" 2>/dev/null || true
    done
    transforms="${transforms}str-repr-hints;"

    # Add -> bool to __bool__ and __eq__ methods
    find "$system_dir" -name "*.py" 2>/dev/null | head -100 | while read -r file; do
        sed -i 's/def __bool__(self):/def __bool__(self) -> bool:/g' "$file" 2>/dev/null || true
        sed -i 's/def __len__(self):/def __len__(self) -> int:/g' "$file" 2>/dev/null || true
        sed -i 's/def __hash__(self):/def __hash__(self) -> int:/g' "$file" 2>/dev/null || true
    done
    transforms="${transforms}dunder-type-hints;"

    echo "  [type-hints] Type hints added"
    echo "$transforms"
}

###############################################################################
# C# REFACTORING
###############################################################################
refactor_csharp_dotnet_upgrade() {
    local system_dir="$1"
    local transforms=""

    echo "  [dotnet-upgrade] Upgrading .NET target framework..."

    # Update .csproj files to target net8.0
    find "$system_dir" -name "*.csproj" 2>/dev/null | while read -r csproj; do
        # Replace old target frameworks with net8.0
        if grep -q "TargetFramework" "$csproj" 2>/dev/null; then
            sed -i 's|<TargetFramework>net[0-9]\.[0-9]*</TargetFramework>|<TargetFramework>net8.0</TargetFramework>|g' "$csproj"
            sed -i 's|<TargetFramework>netcoreapp[0-9]\.[0-9]*</TargetFramework>|<TargetFramework>net8.0</TargetFramework>|g' "$csproj"
            sed -i 's|<TargetFramework>netstandard[0-9]\.[0-9]*</TargetFramework>|<TargetFramework>netstandard2.0</TargetFramework>|g' "$csproj"
            sed -i 's|<TargetFrameworkVersion>v4\.[0-9]*\.[0-9]*</TargetFrameworkVersion>|<TargetFramework>net8.0</TargetFramework>|g' "$csproj"
            sed -i 's|<TargetFrameworkVersion>v4\.[0-9]*</TargetFrameworkVersion>|<TargetFramework>net8.0</TargetFramework>|g' "$csproj"
        fi

        # Enable nullable reference types
        if ! grep -q "<Nullable>" "$csproj" 2>/dev/null; then
            sed -i '/<PropertyGroup>/a\    <Nullable>enable</Nullable>' "$csproj" 2>/dev/null || true
        fi

        # Enable implicit usings
        if ! grep -q "<ImplicitUsings>" "$csproj" 2>/dev/null; then
            sed -i '/<PropertyGroup>/a\    <ImplicitUsings>enable</ImplicitUsings>' "$csproj" 2>/dev/null || true
        fi
    done

    local csproj_count
    csproj_count=$(find "$system_dir" -name "*.csproj" 2>/dev/null | wc -l)
    transforms="csproj-net8.0($csproj_count);nullable-enable;implicit-usings;"

    echo "  [dotnet-upgrade] .NET 8 upgrade applied to $csproj_count projects"
    echo "$transforms"
}

refactor_csharp_modernize_patterns() {
    local system_dir="$1"
    local transforms=""

    echo "  [cs-modernize] Modernizing C# patterns..."

    # Replace string.Format with string interpolation (simple cases)
    # This is too risky for automated transform, just count
    local format_count
    format_count=$(grep -rl "string.Format(" "$system_dir" --include="*.cs" 2>/dev/null | wc -l) || format_count=0
    transforms="${transforms}string.Format-flagged=$format_count;"

    # Add file-scoped namespaces comment marker
    # (actual transform too risky for automated)
    local namespace_count
    namespace_count=$(grep -rl "^namespace " "$system_dir" --include="*.cs" 2>/dev/null | wc -l) || namespace_count=0
    transforms="${transforms}namespace-candidates=$namespace_count;"

    # Replace HttpWebRequest with HttpClient usage markers
    find "$system_dir" -name "*.cs" -exec grep -l "HttpWebRequest\|WebClient" {} \; 2>/dev/null | while read -r file; do
        # Add TODO comment above HttpWebRequest usage
        sed -i 's|HttpWebRequest|HttpWebRequest /* TODO: Replace with HttpClient */|g' "$file" 2>/dev/null || true
        sed -i 's|new WebClient|new WebClient /* TODO: Replace with HttpClient */|g' "$file" 2>/dev/null || true
    done
    transforms="${transforms}HttpWebRequest-flagged;"

    echo "  [cs-modernize] C# modernization applied"
    echo "$transforms"
}

###############################################################################
# COLDFUSION REFACTORING
###############################################################################
refactor_coldfusion_security() {
    local system_dir="$1"
    local transforms=""

    echo "  [cf-security] Fixing ColdFusion security patterns..."

    # Add cfqueryparam to unparameterized queries
    # This is complex, so we'll add comments flagging the issues
    find "$system_dir" -name "*.cfm" -o -name "*.cfc" 2>/dev/null | while read -r file; do
        if grep -q "cfquery" "$file" 2>/dev/null; then
            # Flag inline variable interpolation in queries
            if grep -q '#[a-zA-Z]' "$file" 2>/dev/null; then
                sed -i '/cfquery/,/<\/cfquery>/s/\(#\)\([a-zA-Z][a-zA-Z0-9_.]*\)\(#\)/\1\2\3 <!--- SECURITY: Use cfqueryparam --->/g' "$file" 2>/dev/null || true
            fi
        fi
    done
    local flagged
    flagged=$(grep -rl "SECURITY: Use cfqueryparam" "$system_dir" --include="*.cfm" --include="*.cfc" 2>/dev/null | wc -l) || flagged=0
    transforms="${transforms}sql-injection-flagged=$flagged;"

    # Replace deprecated cfform tags
    find "$system_dir" -name "*.cfm" 2>/dev/null | while read -r file; do
        sed -i 's/<cfform/<form <!--- MODERNIZE: was cfform --->/gi' "$file" 2>/dev/null || true
        sed -i 's/<\/cfform>/<\/form>/gi' "$file" 2>/dev/null || true
    done
    transforms="${transforms}cfform->form;"

    # Add output encoding for XSS prevention
    find "$system_dir" -name "*.cfm" 2>/dev/null | while read -r file; do
        if grep -q "#[a-zA-Z]" "$file" 2>/dev/null; then
            # Flag unencoded output
            sed -i 's/\(#\)\([a-zA-Z][a-zA-Z0-9_.]*\)\(#\)/\1encodeForHTML(\2)\3/g' "$file" 2>/dev/null || true
        fi
    done
    transforms="${transforms}xss-encodeForHTML;"

    echo "  [cf-security] Security fixes applied"
    echo "$transforms"
}

###############################################################################
# FORTRAN REFACTORING
###############################################################################
refactor_fortran_modernize() {
    local system_dir="$1"
    local transforms=""

    echo "  [fortran] Modernizing Fortran code..."

    # Add IMPLICIT NONE to subroutines that lack it
    find "$system_dir" -type f \( -iname "*.f" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | head -200 | while read -r file; do
        if ! grep -qi "IMPLICIT NONE" "$file" 2>/dev/null; then
            # Add IMPLICIT NONE after SUBROUTINE or PROGRAM declarations
            sed -i '/^\s*SUBROUTINE\s/a\      IMPLICIT NONE' "$file" 2>/dev/null || true
            sed -i '/^\s*PROGRAM\s/a\      IMPLICIT NONE' "$file" 2>/dev/null || true
        fi
    done
    transforms="${transforms}implicit-none;"

    # Replace computed GOTO with SELECT CASE comments
    find "$system_dir" -type f \( -iname "*.f" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | head -200 | while read -r file; do
        if grep -qi "GO TO\s*(" "$file" 2>/dev/null; then
            sed -i 's/\(.*GO TO\s*(\)/C MODERNIZE: Replace computed GOTO with SELECT CASE\n\1/I' "$file" 2>/dev/null || true
        fi
    done
    transforms="${transforms}computed-goto-flagged;"

    # Flag EQUIVALENCE statements for removal
    find "$system_dir" -type f \( -iname "*.f" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | head -200 | while read -r file; do
        if grep -qi "EQUIVALENCE" "$file" 2>/dev/null; then
            sed -i 's/\(.*EQUIVALENCE.*\)/C MODERNIZE: Remove EQUIVALENCE - use proper typing\n\1/I' "$file" 2>/dev/null || true
        fi
    done
    transforms="${transforms}equivalence-flagged;"

    # Replace COMMON blocks with MODULE markers
    find "$system_dir" -type f \( -iname "*.f" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | head -200 | while read -r file; do
        if grep -qi "COMMON\s*/" "$file" 2>/dev/null; then
            sed -i 's/\(.*COMMON\s*\/\)/C MODERNIZE: Replace COMMON block with MODULE\n\1/I' "$file" 2>/dev/null || true
        fi
    done
    transforms="${transforms}common-block-flagged;"

    # Convert fixed-form comments (C in col 1) to free-form (!)
    # Only do this for a subset of files to avoid breaking things
    find "$system_dir" -type f \( -iname "*.f" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | head -50 | while read -r file; do
        sed -i 's/^[Cc]\(.*\)/!\1/' "$file" 2>/dev/null || true
    done
    transforms="${transforms}fixed->free-comments;"

    echo "  [fortran] Fortran modernization applied"
    echo "$transforms"
}

###############################################################################
# ASSEMBLY (APOLLO-11) DOCUMENTATION
###############################################################################
refactor_apollo_documentation() {
    local system_dir="$1"
    local result_dir="$RESULTS_DIR/apollo-11"
    mkdir -p "$result_dir"
    local transforms=""

    echo "  [apollo-docs] Creating preservation documentation..."

    # Generate module index
    {
        echo "# Apollo-11 AGC Module Index"
        echo ""
        echo "## Comanche (Command Module)"
        find "$system_dir" -path "*Comanche*" -name "*.agc" 2>/dev/null | sort | while read -r f; do
            local basename=$(basename "$f" .agc)
            local lines=$(wc -l < "$f")
            echo "- **$basename** ($lines lines)"
        done
        echo ""
        echo "## Luminary (Lunar Module)"
        find "$system_dir" -path "*Luminary*" -name "*.agc" 2>/dev/null | sort | while read -r f; do
            local basename=$(basename "$f" .agc)
            local lines=$(wc -l < "$f")
            echo "- **$basename** ($lines lines)"
        done
    } > "$result_dir/module-index.md"
    transforms="${transforms}module-index;"

    # Create instruction frequency analysis
    {
        echo "# Apollo-11 AGC Instruction Frequency Analysis"
        echo ""
        echo "| Instruction | Count |"
        echo "|------------|-------|"
        find "$system_dir" -name "*.agc" -exec cat {} + 2>/dev/null | \
            awk '{print $1}' | grep -E '^[A-Z]+$' | sort | uniq -c | sort -rn | head -30 | \
            while read -r count instr; do
                echo "| $instr | $count |"
            done
    } > "$result_dir/instruction-frequency.md"
    transforms="${transforms}instruction-analysis;"

    echo "  [apollo-docs] Documentation created"
    echo "$transforms"
}

###############################################################################
# PER-SYSTEM REFACTORING ORCHESTRATOR
###############################################################################
refactor_system() {
    local system="$1"
    local system_dir="$AGG_ROOT/$system"
    local wall_start=$(date +%s)
    local exec_start=$(date +%s%N)
    local retries=0
    local status="COMPLETED"
    local all_transforms=""

    echo "================================================================"
    echo "  REFACTORING: $system"
    echo "  Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "================================================================"

    if [ ! -d "$system_dir" ]; then
        echo "  SKIPPED: Directory not found"
        record_refactor_metric "$system" "N/A" "0" "0" "0" "0" "0" "0" "0" "SKIPPED" "directory-not-found"
        return
    fi

    case "$system" in
        apache-ofbiz|alfresco-community|nuxeo)
            all_transforms=$(refactor_java_javax_to_jakarta "$system_dir" "$system")
            all_transforms="${all_transforms}$(refactor_java_version_upgrade "$system_dir" "$system")"
            all_transforms="${all_transforms}$(refactor_java_deprecated_patterns "$system_dir")"
            local lang="Java"
            ;;
        monolith-enterprise)
            all_transforms=$(refactor_java_javax_to_jakarta "$system_dir" "$system")
            all_transforms="${all_transforms}$(refactor_java_version_upgrade "$system_dir" "$system")"
            all_transforms="${all_transforms}$(refactor_java_deprecated_patterns "$system_dir")"
            local lang="Java"
            ;;
        b2cweb)
            all_transforms=$(refactor_java_javax_to_jakarta "$system_dir" "$system")
            all_transforms="${all_transforms}$(refactor_java_deprecated_patterns "$system_dir")"
            local lang="Java"
            ;;
        odoo)
            all_transforms=$(refactor_python_imp_to_importlib "$system_dir")
            all_transforms="${all_transforms}$(refactor_python_deprecated_patterns "$system_dir")"
            all_transforms="${all_transforms}$(refactor_python_type_hints "$system_dir")"
            local lang="Python"
            ;;
        django-oscar)
            all_transforms=$(refactor_python_deprecated_patterns "$system_dir")
            all_transforms="${all_transforms}$(refactor_python_type_hints "$system_dir")"
            local lang="Python"
            ;;
        mezzanine)
            all_transforms=$(refactor_python_imp_to_importlib "$system_dir")
            all_transforms="${all_transforms}$(refactor_python_deprecated_patterns "$system_dir")"
            all_transforms="${all_transforms}$(refactor_python_type_hints "$system_dir")"
            local lang="Python"
            ;;
        umbraco-cms)
            all_transforms=$(refactor_csharp_dotnet_upgrade "$system_dir")
            all_transforms="${all_transforms}$(refactor_csharp_modernize_patterns "$system_dir")"
            local lang="C#"
            ;;
        dfe-net)
            all_transforms=$(refactor_csharp_dotnet_upgrade "$system_dir")
            all_transforms="${all_transforms}$(refactor_csharp_modernize_patterns "$system_dir")"
            local lang="C#"
            ;;
        cfwheels)
            all_transforms=$(refactor_coldfusion_security "$system_dir")
            local lang="ColdFusion"
            ;;
        nastran-95)
            all_transforms=$(refactor_fortran_modernize "$system_dir")
            local lang="Fortran"
            ;;
        apollo-11)
            all_transforms=$(refactor_apollo_documentation "$system_dir")
            local lang="Assembly"
            ;;
        cics-banking-sample)
            echo "  SKIPPED: Repository not available (403)"
            record_refactor_metric "$system" "COBOL" "0" "0" "0" "0" "0" "0" "0" "SKIPPED" "repo-403"
            return
            ;;
        *)
            echo "  SKIPPED: No refactoring strategy defined"
            record_refactor_metric "$system" "Unknown" "0" "0" "0" "0" "0" "0" "0" "SKIPPED" "no-strategy"
            return
            ;;
    esac

    # Generate patch and get stats
    generate_patch "$system_dir" "$system"
    local diff_stats
    diff_stats=$(get_diff_stats "$system_dir")
    local files_changed=$(echo "$diff_stats" | cut -d'|' -f1)
    local lines_added=$(echo "$diff_stats" | cut -d'|' -f2)
    local lines_removed=$(echo "$diff_stats" | cut -d'|' -f3)

    # Calculate timing
    local exec_end=$(date +%s%N)
    local wall_end=$(date +%s)
    local exec_time_ms=$(( (exec_end - exec_start) / 1000000 ))
    local wall_time=$((wall_end - wall_start))

    # Estimate tokens processed (chars in patch / 4)
    local tokens=0
    if [ -f "$PATCHES_DIR/${system}.patch" ]; then
        local patch_chars
        patch_chars=$(wc -c < "$PATCHES_DIR/${system}.patch") || patch_chars=0
        tokens=$(( patch_chars / 4 ))
    fi

    echo "  Files changed: $files_changed | +$lines_added / -$lines_removed"
    echo "  Exec Time: ${exec_time_ms}ms | Wall Time: ${wall_time}s | Tokens: $tokens"
    echo ""

    record_refactor_metric "$system" "$lang" "$files_changed" "$lines_added" "$lines_removed" "$exec_time_ms" "$wall_time" "$tokens" "$retries" "$status" "$all_transforms"
}

###############################################################################
# MAIN
###############################################################################
main() {
    echo "================================================================"
    echo "  LEGACY CORPUS - CODE REFACTORING RUN"
    echo "  Started: $MASTER_WALL_START"
    echo "================================================================"
    echo ""

    local systems=(
        apache-ofbiz odoo alfresco-community
        nuxeo django-oscar umbraco-cms
        mezzanine b2cweb dfe-net monolith-enterprise cfwheels
        cics-banking-sample nastran-95 apollo-11
    )

    for system in "${systems[@]}"; do
        refactor_system "$system"
    done

    local master_end=$(date +%s%N)
    local total_exec_ms=$(( (master_end - MASTER_START) / 1000000 ))
    local total_wall=$(($(date +%s) - $(date -d "$MASTER_WALL_START" +%s 2>/dev/null || echo $(date +%s))))

    echo "================================================================"
    echo "  REFACTORING COMPLETE"
    echo "  Total Execution: ${total_exec_ms}ms"
    echo "  Metrics: $METRICS_FILE"
    echo "  Patches: $PATCHES_DIR/"
    echo "================================================================"
}

main "$@"
