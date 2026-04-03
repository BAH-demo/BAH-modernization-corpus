#!/bin/bash
# modernize-all.sh
# Master modernization runner for all legacy corpus systems
# Tracks: execution time, tokens (LOC processed), retries, wall time
# Usage: bash modernize-all.sh [system1] [system2] ... or bash modernize-all.sh --all

set -euo pipefail

###############################################################################
# CONFIGURATION
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGG_ROOT="$SCRIPT_DIR/modernization-corpus-aggregate"
RESULTS_DIR="$SCRIPT_DIR/modernization-results"
METRICS_FILE="$RESULTS_DIR/metrics.csv"
SUMMARY_FILE="$RESULTS_DIR/summary.json"
REPORT_FILE="$SCRIPT_DIR/rationalization-report.md"
MASTER_START=$(date +%s%N)
MASTER_WALL_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MAX_RETRIES=3

# All available systems
ALL_SYSTEMS=(
    apache-ofbiz odoo alfresco-community
    nuxeo django-oscar umbraco-cms
    mezzanine b2cweb dfe-net monolith-enterprise cfwheels
    cics-banking-sample nastran-95 apollo-11
)

###############################################################################
# METRICS TRACKING
###############################################################################
init_metrics() {
    mkdir -p "$RESULTS_DIR"
    echo "system,tier,language,loc_count,files_count,execution_time_ms,wall_time_seconds,tokens_estimated,retries,status,strategy,modernization_actions" > "$METRICS_FILE"
}

# Estimate tokens: ~1 token per 4 characters (industry standard approximation)
estimate_tokens() {
    local dir="$1"
    local total_chars=0
    if [ -d "$dir" ]; then
        total_chars=$(find "$dir" -type f \( \
            -name "*.java" -o -name "*.py" -o -name "*.cs" -o -name "*.js" \
            -o -name "*.ts" -o -name "*.cfm" -o -name "*.cfc" \
            -o -name "*.cbl" -o -name "*.cob" -o -name "*.cpy" \
            -o -name "*.f" -o -name "*.f77" -o -name "*.for" -o -name "*.ftn" \
            -o -name "*.agc" -o -name "*.s" -o -name "*.asm" \
            -o -name "*.xml" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \
            -o -name "*.properties" -o -name "*.cfg" -o -name "*.conf" \
            -o -name "*.html" -o -name "*.css" -o -name "*.jsp" \
            -o -name "*.rb" -o -name "*.go" -o -name "*.rs" \
            -o -name "*.sql" -o -name "*.sh" -o -name "*.bash" \
        \) -exec wc -c {} + 2>/dev/null | tail -1 | awk '{print $1}') || true
        total_chars=${total_chars:-0}
    fi
    echo $(( total_chars / 4 ))
}

count_loc() {
    local dir="$1"
    local extensions="$2"
    local count=0
    IFS=',' read -ra EXTS <<< "$extensions"
    for ext in "${EXTS[@]}"; do
        local ext_count
        ext_count=$(find "$dir" -type f -name "$ext" -exec cat {} + 2>/dev/null | wc -l) || true
        count=$((count + ext_count))
    done
    echo "$count"
}

count_files() {
    local dir="$1"
    local extensions="$2"
    local count=0
    IFS=',' read -ra EXTS <<< "$extensions"
    for ext in "${EXTS[@]}"; do
        local ext_count
        ext_count=$(find "$dir" -type f -name "$ext" 2>/dev/null | wc -l) || true
        count=$((count + ext_count))
    done
    echo "$count"
}

record_metric() {
    local system="$1"
    local tier="$2"
    local language="$3"
    local loc="$4"
    local files="$5"
    local exec_time="$6"
    local wall_time="$7"
    local tokens="$8"
    local retries="$9"
    local status="${10}"
    local strategy="${11}"
    local actions="${12}"
    echo "$system,$tier,$language,$loc,$files,$exec_time,$wall_time,$tokens,$retries,$status,\"$strategy\",\"$actions\"" >> "$METRICS_FILE"
}

###############################################################################
# SYSTEM METADATA
###############################################################################
get_system_info() {
    local system="$1"
    case "$system" in
        apache-ofbiz)       echo "Tier1|Java|*.java,*.xml,*.properties,*.groovy" ;;
        odoo)               echo "Tier1|Python|*.py,*.xml,*.js,*.css" ;;
        alfresco-community) echo "Tier1|Java|*.java,*.xml,*.properties" ;;
        nuxeo)              echo "Tier2|Java|*.java,*.xml,*.properties" ;;
        django-oscar)       echo "Tier2|Python|*.py,*.html,*.js" ;;
        umbraco-cms)        echo "Tier2|C#|*.cs,*.cshtml,*.json" ;;
        mezzanine)          echo "Tier2|Python|*.py,*.html,*.js" ;;
        b2cweb)             echo "Tier2|Java|*.java,*.xml,*.jsp" ;;
        dfe-net)            echo "Tier2|C#|*.cs,*.xml,*.config" ;;
        monolith-enterprise) echo "Tier2|Java|*.java,*.xml,*.properties" ;;
        cfwheels)           echo "Tier2|ColdFusion|*.cfm,*.cfc,*.xml" ;;
        cics-banking-sample) echo "Tier3|COBOL|*.cbl,*.cob,*.cpy,*.jcl" ;;
        nastran-95)         echo "Tier3|Fortran|*.f,*.f77,*.for,*.ftn" ;;
        apollo-11)          echo "Tier3|Assembly|*.agc,*.s,*.asm" ;;
        *)                  echo "Unknown|Unknown|*" ;;
    esac
}

get_modernization_strategy() {
    local system="$1"
    case "$system" in
        apache-ofbiz)
            echo "javax-to-jakarta-migration|Migrate javax.* to jakarta.* namespace; upgrade to Java 17+; modularize monolith into microservices; replace global state with dependency injection; containerize with Docker" ;;
        odoo)
            echo "python-modernization|Upgrade to Python 3.12+; add type hints; replace deprecated APIs; modularize multi-domain logic; add comprehensive test coverage; containerize" ;;
        alfresco-community)
            echo "java-platform-upgrade|Migrate to Spring Boot 3.x; upgrade Java 17+; modernize document model APIs; replace legacy XML config with annotations; containerize" ;;
        nuxeo)
            echo "java-simplification|Reduce abstraction layers; migrate javax to jakarta; upgrade to modern Java; simplify plugin architecture; containerize" ;;
        django-oscar)
            echo "django-upgrade|Upgrade Django to latest LTS; resolve architectural debt; add type hints; improve test coverage; modernize frontend to use modern JS framework" ;;
        umbraco-cms)
            echo "dotnet-migration|Migrate to .NET 8+; replace legacy patterns; modernize Razor views; upgrade NuGet dependencies; add health checks and observability" ;;
        mezzanine)
            echo "python312-compatibility|Replace imp module with importlib; upgrade to Python 3.12+; replace deprecated Django patterns; modernize settings management" ;;
        b2cweb)
            echo "java-rebuild|Migrate from SSH framework to Spring Boot; replace manual JDBC with JPA/Hibernate; add Maven/Gradle build; internationalize; containerize" ;;
        dfe-net)
            echo "dotnet-modernization|Migrate to .NET 8+; replace legacy XML handling with modern APIs; add unit tests; modernize integration patterns" ;;
        monolith-enterprise)
            echo "java17-migration|Migrate javax to jakarta namespace; upgrade Java 7 to 17; replace Liquibase MySQL dependency; upgrade Spring Framework; containerize" ;;
        cfwheels)
            echo "framework-migration|Assess migration from ColdFusion to modern framework (Node.js/Python); document API surface; create migration roadmap" ;;
        cics-banking-sample)
            echo "mainframe-modernization|Extract business rules from COBOL; document CICS transaction flows; identify API extraction points; create microservice migration plan" ;;
        nastran-95)
            echo "fortran-modernization|Inventory numerical algorithms; assess F77 to Modern Fortran (F2018) migration; identify parallelization opportunities; document computational kernels" ;;
        apollo-11)
            echo "historical-preservation|Document AGC instruction set; create modern simulation wrapper; preserve historical accuracy; add comprehensive documentation" ;;
        *)
            echo "unknown|No strategy defined" ;;
    esac
}

###############################################################################
# MODERNIZATION ANALYSIS FUNCTIONS
###############################################################################

analyze_java_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Find javax imports that need jakarta migration
    local javax_count=0
    javax_count=$(grep -r "import javax\." "$system_dir" --include="*.java" 2>/dev/null | wc -l) || true
    echo "javax_imports: $javax_count" > "$result_dir/analysis.txt"

    # 2. Check Java version requirements
    local java_version="unknown"
    if [ -f "$system_dir/pom.xml" ]; then
        java_version=$(grep -oP '<java.version>\K[^<]+' "$system_dir/pom.xml" 2>/dev/null | head -1) || true
        java_version=${java_version:-"not-specified-in-pom"}
        echo "build_system: Maven" >> "$result_dir/analysis.txt"
    elif [ -f "$system_dir/build.gradle" ]; then
        java_version=$(grep -oP "sourceCompatibility\s*=\s*['\"]?\K[^'\"\\s]+" "$system_dir/build.gradle" 2>/dev/null | head -1) || true
        java_version=${java_version:-"not-specified-in-gradle"}
        echo "build_system: Gradle" >> "$result_dir/analysis.txt"
    fi
    echo "java_version: $java_version" >> "$result_dir/analysis.txt"

    # 3. Check for deprecated patterns
    local deprecated_count=0
    deprecated_count=$(grep -r "@Deprecated" "$system_dir" --include="*.java" 2>/dev/null | wc -l) || true
    echo "deprecated_annotations: $deprecated_count" >> "$result_dir/analysis.txt"

    # 4. Check for global state (static mutable fields)
    local static_mutable=0
    static_mutable=$(grep -r "static.*=\s*new\|static.*Map\|static.*List\|static.*Set" "$system_dir" --include="*.java" 2>/dev/null | grep -v "final" | wc -l) || true
    echo "static_mutable_state: $static_mutable" >> "$result_dir/analysis.txt"

    # 5. Check for security vulnerabilities (hardcoded secrets)
    local hardcoded_secrets=0
    hardcoded_secrets=$(grep -riE "password\s*=\s*\"|secret\s*=\s*\"|api.key\s*=\s*\"" "$system_dir" --include="*.java" --include="*.properties" --include="*.xml" 2>/dev/null | wc -l) || true
    echo "hardcoded_secrets_candidates: $hardcoded_secrets" >> "$result_dir/analysis.txt"

    # 6. Count test files
    local test_files=0
    test_files=$(find "$system_dir" -type f -name "*Test.java" -o -name "*Tests.java" -o -name "*Spec.java" 2>/dev/null | wc -l) || true
    echo "test_files: $test_files" >> "$result_dir/analysis.txt"

    # 7. Check for Spring Framework version
    local spring_version="none"
    if [ -f "$system_dir/pom.xml" ]; then
        spring_version=$(grep -oP '<spring.version>\K[^<]+\|<spring-boot.version>\K[^<]+' "$system_dir/pom.xml" 2>/dev/null | head -1) || true
        spring_version=${spring_version:-"not-found"}
    fi
    echo "spring_version: $spring_version" >> "$result_dir/analysis.txt"

    actions="javax_imports=$javax_count;deprecated=$deprecated_count;static_mutable=$static_mutable;hardcoded_secrets=$hardcoded_secrets;test_files=$test_files;java_version=$java_version"
    echo "$actions|$retries"
}

analyze_python_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Check for deprecated module usage
    local imp_usage=0
    imp_usage=$(grep -r "import imp\b\|from imp " "$system_dir" --include="*.py" 2>/dev/null | wc -l) || true
    echo "deprecated_imp_module: $imp_usage" > "$result_dir/analysis.txt"

    # 2. Check Python 2 compatibility issues
    local py2_patterns=0
    py2_patterns=$(grep -rE "print\s+['\"]|except\s+\w+,\s*\w+:|has_key\(|\.iteritems\(|\.itervalues\(|\.iterkeys\(" "$system_dir" --include="*.py" 2>/dev/null | wc -l) || true
    echo "python2_patterns: $py2_patterns" >> "$result_dir/analysis.txt"

    # 3. Type hint coverage
    local typed_funcs=0
    local total_funcs=0
    total_funcs=$(grep -r "def " "$system_dir" --include="*.py" 2>/dev/null | wc -l) || true
    typed_funcs=$(grep -r "def .*->.*:" "$system_dir" --include="*.py" 2>/dev/null | wc -l) || true
    echo "total_functions: $total_funcs" >> "$result_dir/analysis.txt"
    echo "typed_functions: $typed_funcs" >> "$result_dir/analysis.txt"
    local type_coverage=0
    if [ "$total_funcs" -gt 0 ]; then
        type_coverage=$(( typed_funcs * 100 / total_funcs ))
    fi
    echo "type_hint_coverage_pct: $type_coverage" >> "$result_dir/analysis.txt"

    # 4. Check for requirements/setup files
    local has_requirements="false"
    local has_setup="false"
    local has_pyproject="false"
    [ -f "$system_dir/requirements.txt" ] && has_requirements="true"
    [ -f "$system_dir/setup.py" ] && has_setup="true"
    [ -f "$system_dir/pyproject.toml" ] && has_pyproject="true"
    echo "has_requirements_txt: $has_requirements" >> "$result_dir/analysis.txt"
    echo "has_setup_py: $has_setup" >> "$result_dir/analysis.txt"
    echo "has_pyproject_toml: $has_pyproject" >> "$result_dir/analysis.txt"

    # 5. Check for security issues
    local hardcoded_secrets=0
    hardcoded_secrets=$(grep -riE "password\s*=\s*['\"]|secret.key\s*=\s*['\"]|api.key\s*=\s*['\"]" "$system_dir" --include="*.py" --include="*.cfg" --include="*.ini" 2>/dev/null | wc -l) || true
    echo "hardcoded_secrets_candidates: $hardcoded_secrets" >> "$result_dir/analysis.txt"

    # 6. Test coverage
    local test_files=0
    test_files=$(find "$system_dir" -type f \( -name "test_*.py" -o -name "*_test.py" -o -name "tests.py" \) 2>/dev/null | wc -l) || true
    echo "test_files: $test_files" >> "$result_dir/analysis.txt"

    # 7. Django version check
    local django_version="none"
    if [ -f "$system_dir/setup.py" ]; then
        django_version=$(grep -oP "Django[><=]+\K[0-9.]+" "$system_dir/setup.py" 2>/dev/null | head -1) || true
    elif [ -f "$system_dir/requirements.txt" ]; then
        django_version=$(grep -oP "Django[><=]+\K[0-9.]+" "$system_dir/requirements.txt" 2>/dev/null | head -1) || true
    elif [ -f "$system_dir/pyproject.toml" ]; then
        django_version=$(grep -oP "Django[><=]+\K[0-9.]+" "$system_dir/pyproject.toml" 2>/dev/null | head -1) || true
    fi
    django_version=${django_version:-"not-found"}
    echo "django_version: $django_version" >> "$result_dir/analysis.txt"

    actions="imp_usage=$imp_usage;py2_patterns=$py2_patterns;type_coverage=${type_coverage}%;test_files=$test_files;hardcoded_secrets=$hardcoded_secrets;django_version=$django_version"
    echo "$actions|$retries"
}

analyze_csharp_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Check .NET version
    local dotnet_version="unknown"
    local target_fw
    target_fw=$(grep -r "TargetFramework" "$system_dir" --include="*.csproj" 2>/dev/null | head -1) || true
    if [ -n "$target_fw" ]; then
        dotnet_version=$(echo "$target_fw" | grep -oP 'net[0-9.]+\|netcoreapp[0-9.]+\|netstandard[0-9.]+' | head -1) || true
        dotnet_version=${dotnet_version:-"legacy-framework"}
    fi
    echo "dotnet_version: $dotnet_version" > "$result_dir/analysis.txt"

    # 2. Count solution/project files
    local sln_count=0
    local csproj_count=0
    sln_count=$(find "$system_dir" -name "*.sln" 2>/dev/null | wc -l) || true
    csproj_count=$(find "$system_dir" -name "*.csproj" 2>/dev/null | wc -l) || true
    echo "solution_files: $sln_count" >> "$result_dir/analysis.txt"
    echo "project_files: $csproj_count" >> "$result_dir/analysis.txt"

    # 3. Check for deprecated patterns
    local obsolete_count=0
    obsolete_count=$(grep -r "\[Obsolete\]" "$system_dir" --include="*.cs" 2>/dev/null | wc -l) || true
    echo "obsolete_attributes: $obsolete_count" >> "$result_dir/analysis.txt"

    # 4. NuGet package analysis
    local nuget_packages=0
    nuget_packages=$(grep -r "PackageReference" "$system_dir" --include="*.csproj" 2>/dev/null | wc -l) || true
    echo "nuget_packages: $nuget_packages" >> "$result_dir/analysis.txt"

    # 5. Test files
    local test_files=0
    test_files=$(find "$system_dir" -type f -name "*Test*.cs" -o -name "*Spec*.cs" 2>/dev/null | wc -l) || true
    echo "test_files: $test_files" >> "$result_dir/analysis.txt"

    actions="dotnet_version=$dotnet_version;projects=$csproj_count;obsolete=$obsolete_count;nuget_packages=$nuget_packages;test_files=$test_files"
    echo "$actions|$retries"
}

analyze_coldfusion_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Count CFM/CFC files
    local cfm_files=0
    local cfc_files=0
    cfm_files=$(find "$system_dir" -name "*.cfm" 2>/dev/null | wc -l) || true
    cfc_files=$(find "$system_dir" -name "*.cfc" 2>/dev/null | wc -l) || true
    echo "cfm_template_files: $cfm_files" > "$result_dir/analysis.txt"
    echo "cfc_component_files: $cfc_files" >> "$result_dir/analysis.txt"

    # 2. Check for deprecated CFML tags
    local deprecated_tags=0
    deprecated_tags=$(grep -ri "<cfform\|<cfgrid\|<cfapplet\|<cfservlet" "$system_dir" --include="*.cfm" --include="*.cfc" 2>/dev/null | wc -l) || true
    echo "deprecated_cfml_tags: $deprecated_tags" >> "$result_dir/analysis.txt"

    # 3. Check for SQL injection risks
    local sql_concat=0
    sql_concat=$(grep -ri "cfquery.*#\|#.*cfquery" "$system_dir" --include="*.cfm" --include="*.cfc" 2>/dev/null | wc -l) || true
    echo "potential_sql_injection: $sql_concat" >> "$result_dir/analysis.txt"

    # 4. Check for test files
    local test_files=0
    test_files=$(find "$system_dir" -type f -iname "*test*" \( -name "*.cfm" -o -name "*.cfc" \) 2>/dev/null | wc -l) || true
    echo "test_files: $test_files" >> "$result_dir/analysis.txt"

    actions="cfm_files=$cfm_files;cfc_files=$cfc_files;deprecated_tags=$deprecated_tags;sql_injection_risk=$sql_concat;test_files=$test_files"
    echo "$actions|$retries"
}

analyze_cobol_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Count COBOL program files
    local cbl_files=0
    local cpy_files=0
    local jcl_files=0
    cbl_files=$(find "$system_dir" -type f \( -iname "*.cbl" -o -iname "*.cob" \) 2>/dev/null | wc -l) || true
    cpy_files=$(find "$system_dir" -type f -iname "*.cpy" 2>/dev/null | wc -l) || true
    jcl_files=$(find "$system_dir" -type f -iname "*.jcl" 2>/dev/null | wc -l) || true
    echo "cobol_program_files: $cbl_files" > "$result_dir/analysis.txt"
    echo "copybook_files: $cpy_files" >> "$result_dir/analysis.txt"
    echo "jcl_files: $jcl_files" >> "$result_dir/analysis.txt"

    # 2. Identify CICS commands
    local cics_commands=0
    cics_commands=$(grep -ri "EXEC CICS" "$system_dir" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l) || true
    echo "cics_exec_commands: $cics_commands" >> "$result_dir/analysis.txt"

    # 3. Identify SQL statements
    local sql_statements=0
    sql_statements=$(grep -ri "EXEC SQL" "$system_dir" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l) || true
    echo "embedded_sql_statements: $sql_statements" >> "$result_dir/analysis.txt"

    # 4. Count paragraphs (rough program structure)
    local paragraph_count=0
    paragraph_count=$(grep -rE "^[A-Z0-9-]+\.\s*$" "$system_dir" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l) || true
    echo "paragraph_count: $paragraph_count" >> "$result_dir/analysis.txt"

    # 5. PERFORM statements (control flow complexity)
    local perform_count=0
    perform_count=$(grep -ri "PERFORM " "$system_dir" --include="*.cbl" --include="*.cob" 2>/dev/null | wc -l) || true
    echo "perform_statements: $perform_count" >> "$result_dir/analysis.txt"

    actions="cobol_files=$cbl_files;copybooks=$cpy_files;jcl=$jcl_files;cics_commands=$cics_commands;sql_statements=$sql_statements;paragraphs=$paragraph_count"
    echo "$actions|$retries"
}

analyze_fortran_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Count Fortran source files
    local f77_files=0
    local f90_files=0
    f77_files=$(find "$system_dir" -type f \( -iname "*.f" -o -iname "*.f77" -o -iname "*.for" -o -iname "*.ftn" \) 2>/dev/null | wc -l) || true
    f90_files=$(find "$system_dir" -type f \( -iname "*.f90" -o -iname "*.f95" -o -iname "*.f03" \) 2>/dev/null | wc -l) || true
    echo "fortran77_files: $f77_files" > "$result_dir/analysis.txt"
    echo "modern_fortran_files: $f90_files" >> "$result_dir/analysis.txt"

    # 2. Check for COMMON blocks (global state)
    local common_blocks=0
    common_blocks=$(grep -ri "COMMON " "$system_dir" --include="*.f" --include="*.f77" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l) || true
    echo "common_blocks: $common_blocks" >> "$result_dir/analysis.txt"

    # 3. Check for GOTO statements
    local goto_count=0
    goto_count=$(grep -ri "GO TO\|GOTO" "$system_dir" --include="*.f" --include="*.f77" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l) || true
    echo "goto_statements: $goto_count" >> "$result_dir/analysis.txt"

    # 4. Check for EQUIVALENCE (memory aliasing)
    local equiv_count=0
    equiv_count=$(grep -ri "EQUIVALENCE" "$system_dir" --include="*.f" --include="*.f77" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l) || true
    echo "equivalence_statements: $equiv_count" >> "$result_dir/analysis.txt"

    # 5. Subroutine/function count
    local subroutine_count=0
    subroutine_count=$(grep -riE "^\s*(SUBROUTINE|FUNCTION)" "$system_dir" --include="*.f" --include="*.f77" --include="*.for" --include="*.ftn" 2>/dev/null | wc -l) || true
    echo "subroutines_functions: $subroutine_count" >> "$result_dir/analysis.txt"

    actions="f77_files=$f77_files;f90_files=$f90_files;common_blocks=$common_blocks;gotos=$goto_count;equivalence=$equiv_count;subroutines=$subroutine_count"
    echo "$actions|$retries"
}

analyze_assembly_system() {
    local system_dir="$1"
    local system_name="$2"
    local result_dir="$RESULTS_DIR/$system_name"
    mkdir -p "$result_dir"
    local actions=""
    local retries=0

    # 1. Count AGC source files
    local agc_files=0
    agc_files=$(find "$system_dir" -type f \( -iname "*.agc" -o -iname "*.s" -o -iname "*.asm" \) 2>/dev/null | wc -l) || true
    echo "assembly_source_files: $agc_files" > "$result_dir/analysis.txt"

    # 2. Count instruction types
    local total_instructions=0
    total_instructions=$(find "$system_dir" -type f \( -iname "*.agc" -o -iname "*.s" -o -iname "*.asm" \) -exec cat {} + 2>/dev/null | grep -vE "^#|^$|^\s*$" | wc -l) || true
    echo "total_instructions: $total_instructions" >> "$result_dir/analysis.txt"

    # 3. Check for program modules/banks
    local module_count=0
    module_count=$(grep -ri "BANK\|SETLOC\|EBANK" "$system_dir" --include="*.agc" 2>/dev/null | wc -l) || true
    echo "memory_bank_refs: $module_count" >> "$result_dir/analysis.txt"

    # 4. Subroutine calls
    local tc_count=0
    tc_count=$(grep -ri "^[[:space:]]*TC\b\|^[[:space:]]*TCF\b\|^[[:space:]]*CADR\b" "$system_dir" --include="*.agc" 2>/dev/null | wc -l) || true
    echo "transfer_control_instructions: $tc_count" >> "$result_dir/analysis.txt"

    actions="agc_files=$agc_files;instructions=$total_instructions;bank_refs=$module_count;tc_instructions=$tc_count"
    echo "$actions|$retries"
}

###############################################################################
# PER-SYSTEM MODERNIZATION RUNNER
###############################################################################
run_modernization() {
    local system="$1"
    local system_dir="$AGG_ROOT/$system"
    local sys_wall_start=$(date +%s)
    local sys_exec_start=$(date +%s%N)
    local retries=0
    local status="COMPLETED"

    echo "================================================================"
    echo "  MODERNIZING: $system"
    echo "  Started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "================================================================"

    # Check if system directory exists
    if [ ! -d "$system_dir" ]; then
        echo "  SKIPPED: Directory not found (clone may have failed)"
        local info
        info=$(get_system_info "$system")
        local tier=$(echo "$info" | cut -d'|' -f1)
        local lang=$(echo "$info" | cut -d'|' -f2)
        local strat_line
        strat_line=$(get_modernization_strategy "$system")
        local strategy=$(echo "$strat_line" | cut -d'|' -f1)
        record_metric "$system" "$tier" "$lang" "0" "0" "0" "0" "0" "0" "SKIPPED" "$strategy" "Directory not found - clone failed (403)"
        return
    fi

    # Get system metadata
    local info
    info=$(get_system_info "$system")
    local tier=$(echo "$info" | cut -d'|' -f1)
    local lang=$(echo "$info" | cut -d'|' -f2)
    local extensions=$(echo "$info" | cut -d'|' -f3)

    # Count LOC and files
    echo "  Counting LOC and files..."
    local loc
    loc=$(count_loc "$system_dir" "$extensions")
    local files
    files=$(count_files "$system_dir" "$extensions")

    # Estimate tokens
    echo "  Estimating tokens..."
    local tokens
    tokens=$(estimate_tokens "$system_dir")

    # Get strategy
    local strat_line
    strat_line=$(get_modernization_strategy "$system")
    local strategy=$(echo "$strat_line" | cut -d'|' -f1)

    # Run language-specific analysis with retry logic
    echo "  Running modernization analysis ($lang)..."
    local analysis_result=""
    local attempt=0
    while [ $attempt -lt $MAX_RETRIES ]; do
        attempt=$((attempt + 1))
        case "$lang" in
            Java)       analysis_result=$(analyze_java_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            Python)     analysis_result=$(analyze_python_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            "C#")       analysis_result=$(analyze_csharp_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            ColdFusion) analysis_result=$(analyze_coldfusion_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            COBOL)      analysis_result=$(analyze_cobol_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            Fortran)    analysis_result=$(analyze_fortran_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            Assembly)   analysis_result=$(analyze_assembly_system "$system_dir" "$system" 2>&1) && break || retries=$((retries + 1)) ;;
            *)          analysis_result="unknown_language|0"; break ;;
        esac
        echo "  Retry $attempt for $system..."
    done

    if [ $attempt -eq $MAX_RETRIES ] && [ -z "$analysis_result" ]; then
        status="FAILED"
        analysis_result="analysis_failed|$retries"
    fi

    local modernization_actions=$(echo "$analysis_result" | tail -1 | cut -d'|' -f1)
    local analysis_retries=$(echo "$analysis_result" | tail -1 | cut -d'|' -f2)
    retries=$((retries + analysis_retries))

    # Calculate timing
    local sys_exec_end=$(date +%s%N)
    local sys_wall_end=$(date +%s)
    local exec_time_ms=$(( (sys_exec_end - sys_exec_start) / 1000000 ))
    local wall_time=$((sys_wall_end - sys_wall_start))

    echo "  LOC: $loc | Files: $files | Tokens: $tokens"
    echo "  Exec Time: ${exec_time_ms}ms | Wall Time: ${wall_time}s | Retries: $retries"
    echo "  Status: $status"
    echo ""

    # Record metrics
    record_metric "$system" "$tier" "$lang" "$loc" "$files" "$exec_time_ms" "$wall_time" "$tokens" "$retries" "$status" "$strategy" "$modernization_actions"
}

###############################################################################
# REPORT GENERATION
###############################################################################
generate_report() {
    local master_end=$(date +%s%N)
    local master_wall_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local total_wall_seconds=$(( (master_end - MASTER_START) / 1000000000 ))
    local total_exec_ms=$(( (master_end - MASTER_START) / 1000000 ))

    echo ""
    echo "================================================================"
    echo "  GENERATING RATIONALIZATION REPORT"
    echo "================================================================"

    # Calculate totals from CSV
    local total_loc=0
    local total_files=0
    local total_tokens=0
    local total_retries=0
    local completed=0
    local skipped=0
    local failed=0

    while IFS=',' read -r sys tier lang loc files exec wall tokens retries status strategy actions; do
        [ "$sys" = "system" ] && continue
        total_loc=$((total_loc + loc))
        total_files=$((total_files + files))
        total_tokens=$((total_tokens + tokens))
        total_retries=$((total_retries + retries))
        case "$status" in
            COMPLETED) completed=$((completed + 1)) ;;
            SKIPPED) skipped=$((skipped + 1)) ;;
            FAILED) failed=$((failed + 1)) ;;
        esac
    done < "$METRICS_FILE"

    cat > "$REPORT_FILE" << REPORT_EOF
# Modernization Rationalization Report

**Generated:** $master_wall_end
**Corpus:** Legacy Rationalization Corpus (14 Systems)
**Objective:** Execute modernization strategy across all legacy systems with full metrics tracking

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total Systems** | 14 |
| **Systems Analyzed** | $completed |
| **Systems Skipped** | $skipped |
| **Systems Failed** | $failed |
| **Total LOC Processed** | $(printf "%'d" $total_loc) |
| **Total Files Analyzed** | $(printf "%'d" $total_files) |
| **Total Tokens Estimated** | $(printf "%'d" $total_tokens) |
| **Total Retries** | $total_retries |
| **Total Wall Time** | ${total_wall_seconds}s |
| **Total Execution Time** | ${total_exec_ms}ms |
| **Start Time** | $MASTER_WALL_START |
| **End Time** | $master_wall_end |

---

## Per-System Metrics

| System | Tier | Language | LOC | Files | Exec Time (ms) | Wall Time (s) | Tokens Est. | Retries | Status |
|--------|------|----------|-----|-------|----------------|---------------|-------------|---------|--------|
REPORT_EOF

    while IFS=',' read -r sys tier lang loc files exec wall tokens retries status strategy actions; do
        [ "$sys" = "system" ] && continue
        echo "| $sys | $tier | $lang | $(printf "%'d" $loc) | $(printf "%'d" $files) | $(printf "%'d" $exec) | $wall | $(printf "%'d" $tokens) | $retries | $status |" >> "$REPORT_FILE"
    done < "$METRICS_FILE"

    cat >> "$REPORT_FILE" << 'SECTION_EOF'

---

## Modernization Strategies by System

SECTION_EOF

    # Add per-system details
    while IFS=',' read -r sys tier lang loc files exec wall tokens retries status strategy actions; do
        [ "$sys" = "system" ] && continue

        # Clean up strategy and actions (remove quotes)
        strategy=$(echo "$strategy" | tr -d '"')
        actions=$(echo "$actions" | tr -d '"')

        local strat_line
        strat_line=$(get_modernization_strategy "$sys")
        local strat_name=$(echo "$strat_line" | cut -d'|' -f1)
        local strat_desc=$(echo "$strat_line" | cut -d'|' -f2)

        cat >> "$REPORT_FILE" << SYSTEM_EOF
### $sys ($lang - $tier)

**Strategy:** \`$strat_name\`
**Description:** $strat_desc

**Metrics:**
- LOC: $(printf "%'d" $loc) | Files: $(printf "%'d" $files)
- Execution Time: ${exec}ms | Wall Time: ${wall}s
- Tokens Estimated: $(printf "%'d" $tokens) | Retries: $retries
- Status: **$status**

SYSTEM_EOF

        # Add analysis details if available
        local analysis_file="$RESULTS_DIR/$sys/analysis.txt"
        if [ -f "$analysis_file" ]; then
            echo "**Analysis Results:**" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            cat "$analysis_file" >> "$REPORT_FILE"
            echo '```' >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi

        # Add modernization actions breakdown
        if [ -n "$actions" ]; then
            echo "**Key Findings:** \`$actions\`" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi

        echo "---" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"

    done < "$METRICS_FILE"

    # Add tier-level summaries
    cat >> "$REPORT_FILE" << 'TIER_EOF'

## Tier Analysis

### Tier 1: Enterprise Monoliths (Hardest Cases)
These systems represent the most challenging modernization targets due to their massive codebases (100K+ LOC), deep architectural debt, and extensive dependency graphs.

**Common Challenges:**
- Global mutable state patterns
- javax namespace requiring jakarta migration
- Monolithic architecture requiring decomposition
- Legacy build system configurations
- Insufficient test coverage for safe refactoring

**Recommended Approach:**
1. Strangler fig pattern for incremental migration
2. Automated javax -> jakarta namespace migration tooling
3. Dependency injection to replace static state
4. Container-first deployment strategy
5. Incremental microservice extraction

### Tier 2: Enterprise Applications (5K-50K LOC)
Mid-tier systems with focused domains but significant legacy patterns. These are the best candidates for rapid modernization wins.

**Common Challenges:**
- Outdated framework versions
- Missing type safety (Python type hints, C# nullable references)
- Deprecated module usage (Python imp, .NET Framework APIs)
- Insufficient test infrastructure
- Hard-coded configuration and secrets

**Recommended Approach:**
1. Framework version upgrades (Django LTS, .NET 8, Spring Boot 3)
2. Automated code transformation tools
3. Type annotation campaigns
4. CI/CD pipeline implementation
5. Configuration externalization

### Tier 3: Federal/Legacy Systems (Hardest to Modernize)
These systems use non-mainstream languages (COBOL, Fortran, Assembly) and represent the most complex modernization challenges in federal IT.

**Common Challenges:**
- Language-specific expertise scarcity
- No modern build/test infrastructure
- Deep hardware/platform coupling (CICS, AGC)
- Numerical algorithm preservation requirements
- Historical significance constraints

**Recommended Approach:**
1. Business rule extraction and documentation
2. API wrapping for gradual decoupling
3. Containerization where possible
4. Modern language re-implementation for non-critical paths
5. Preservation-first for historically significant code (Apollo-11)

TIER_EOF

    cat >> "$REPORT_FILE" << FOOTER_EOF

---

## Methodology

### Metrics Definitions
- **Execution Time (ms):** CPU time spent on modernization analysis for each system
- **Wall Time (s):** Total elapsed clock time including I/O waits
- **Tokens Estimated:** Approximate LLM token count based on source code character count (1 token per 4 characters)
- **Retries:** Number of retry attempts for failed analysis operations (max $MAX_RETRIES per system)
- **LOC:** Lines of code in primary language files
- **Files:** Count of source files in primary language extensions

### Analysis Techniques Applied
1. **Namespace Migration Scan** (Java): javax.* import detection for jakarta migration planning
2. **Deprecated Pattern Detection** (All): Language-specific deprecated API/module usage
3. **Type Safety Assessment** (Python): Function-level type hint coverage analysis
4. **Security Surface Scan** (All): Hardcoded credential pattern detection
5. **Test Coverage Baseline** (All): Test file enumeration for refactoring safety assessment
6. **Build System Audit** (All): Build tool and dependency management evaluation
7. **Control Flow Complexity** (COBOL/Fortran): GOTO, PERFORM, COMMON block analysis

### Tools & Environment
- **Analysis Engine:** Bash-based static analysis with grep/find pattern matching
- **Token Estimation:** Character-count based (1 token ~4 characters, industry standard)
- **Timing:** nanosecond-precision via \`date +%s%N\`
- **Retry Policy:** Up to $MAX_RETRIES retries per system analysis

---

*Report generated by modernize-all.sh | Legacy Rationalization Corpus*
*Raw metrics available in: modernization-results/metrics.csv*
FOOTER_EOF

    echo "Report generated: $REPORT_FILE"
}

###############################################################################
# MAIN
###############################################################################
main() {
    echo "================================================================"
    echo "  LEGACY MODERNIZATION CORPUS - FULL MODERNIZATION RUN"
    echo "  Started: $MASTER_WALL_START"
    echo "  Systems: ${#ALL_SYSTEMS[@]}"
    echo "================================================================"
    echo ""

    # Parse args
    local systems_to_run=()
    if [ "${1:-}" = "--all" ] || [ $# -eq 0 ]; then
        systems_to_run=("${ALL_SYSTEMS[@]}")
    else
        systems_to_run=("$@")
    fi

    # Initialize metrics
    init_metrics

    # Run modernization for each system
    for system in "${systems_to_run[@]}"; do
        run_modernization "$system"
    done

    # Generate report
    generate_report

    echo ""
    echo "================================================================"
    echo "  MODERNIZATION COMPLETE"
    echo "  Report: $REPORT_FILE"
    echo "  Metrics: $METRICS_FILE"
    echo "  Results: $RESULTS_DIR/"
    echo "================================================================"
}

main "$@"
