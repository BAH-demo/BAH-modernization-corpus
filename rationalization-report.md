# Modernization Rationalization Report

**Generated:** 2026-04-01T21:57:19Z
**Corpus:** Legacy Rationalization Corpus (14 Systems)
**Objective:** Execute modernization strategy across all legacy systems with full metrics tracking

---

## Executive Summary

| Metric | Value |
|--------|-------|
| **Total Systems** | 14 |
| **Systems Analyzed** | 13 |
| **Systems Skipped** | 1 |
| **Systems Failed** | 0 |
| **Total LOC Processed** | 8735764 |
| **Total Files Analyzed** | 55535 |
| **Total Tokens Estimated** | 15916044 |
| **Total Retries** | 0 |
| **Total Wall Time** | 13s |
| **Total Execution Time** | 13200ms |
| **Start Time** | 2026-04-01T21:57:06Z |
| **End Time** | 2026-04-01T21:57:19Z |

---

## Per-System Metrics

| System | Tier | Language | LOC | Files | Exec Time (ms) | Wall Time (s) | Tokens Est. | Retries | Status |
|--------|------|----------|-----|-------|----------------|---------------|-------------|---------|--------|
| apache-ofbiz | Tier1 | Java | 885211 | 2742 | 824 | 1 | 2013198 | 0 | COMPLETED |
| odoo | Tier1 | Python | 3007247 | 19575 | 4362 | 4 | 1597250 | 0 | COMPLETED |
| alfresco-community | Tier1 | Java | 1883473 | 10549 | 1714 | 2 | 1764967 | 0 | COMPLETED |
| nuxeo | Tier2 | Java | 1197472 | 9647 | 2696 | 3 | 416725 | 0 | COMPLETED |
| django-oscar | Tier2 | Python | 85673 | 1074 | 282 | 0 | 87726 | 0 | COMPLETED |
| umbraco-cms | Tier2 | C# | 761123 | 7055 | 1509 | 1 | 597528 | 0 | COMPLETED |
| mezzanine | Tier2 | Python | 64453 | 372 | 302 | 1 | 761682 | 0 | COMPLETED |
| b2cweb | Tier2 | Java | 6507 | 79 | 77 | 0 | 37653 | 0 | COMPLETED |
| dfe-net | Tier2 | C# | 112701 | 1199 | 253 | 0 | 214374 | 0 | COMPLETED |
| monolith-enterprise | Tier2 | Java | 5897 | 119 | 88 | 0 | 48159 | 0 | COMPLETED |
| cfwheels | Tier2 | ColdFusion | 178321 | 1101 | 370 | 1 | 6564898 | 0 | COMPLETED |
| cics-banking-sample | Tier3 | COBOL | 0 | 0 | 0 | 0 | 0 | 0 | SKIPPED |
| nastran-95 | Tier3 | Fortran | 417500 | 1848 | 392 | 0 | 1023854 | 0 | COMPLETED |
| apollo-11 | Tier3 | Assembly | 130186 | 175 | 244 | 0 | 788030 | 0 | COMPLETED |

---

## Modernization Strategies by System

### apache-ofbiz (Java - Tier1)

**Strategy:** `javax-to-jakarta-migration`
**Description:** Migrate javax.* to jakarta.* namespace; upgrade to Java 17+; modularize monolith into microservices; replace global state with dependency injection; containerize with Docker

**Metrics:**
- LOC: 885211 | Files: 2742
- Execution Time: 824ms | Wall Time: 1s
- Tokens Estimated: 2013198 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
javax_imports: 413
build_system: Gradle
java_version: not-specified-in-gradle
deprecated_annotations: 130
static_mutable_state: 2063
hardcoded_secrets_candidates: 90
test_files: 65
spring_version: none
```

**Key Findings:** `javax_imports=413;deprecated=130;static_mutable=2063;hardcoded_secrets=90;test_files=65;java_version=not-specified-in-gradle`

---

### odoo (Python - Tier1)

**Strategy:** `python-modernization`
**Description:** Upgrade to Python 3.12+; add type hints; replace deprecated APIs; modularize multi-domain logic; add comprehensive test coverage; containerize

**Metrics:**
- LOC: 3007247 | Files: 19575
- Execution Time: 4362ms | Wall Time: 4s
- Tokens Estimated: 1597250 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
deprecated_imp_module: 0
python2_patterns: 3
total_functions: 46980
typed_functions: 1065
type_hint_coverage_pct: 2
has_requirements_txt: true
has_setup_py: true
has_pyproject_toml: false
hardcoded_secrets_candidates: 55
test_files: 1729
django_version: not-found
```

**Key Findings:** `imp_usage=0;py2_patterns=3;type_coverage=2%;test_files=1729;hardcoded_secrets=55;django_version=not-found`

---

### alfresco-community (Java - Tier1)

**Strategy:** `java-platform-upgrade`
**Description:** Migrate to Spring Boot 3.x; upgrade Java 17+; modernize document model APIs; replace legacy XML config with annotations; containerize

**Metrics:**
- LOC: 1883473 | Files: 10549
- Execution Time: 1714ms | Wall Time: 2s
- Tokens Estimated: 1764967 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
javax_imports: 302
build_system: Maven
java_version: 21
deprecated_annotations: 412
static_mutable_state: 786
hardcoded_secrets_candidates: 74
test_files: 1447
spring_version: not-found
```

**Key Findings:** `javax_imports=302;deprecated=412;static_mutable=786;hardcoded_secrets=74;test_files=1447;java_version=21`

---

### nuxeo (Java - Tier2)

**Strategy:** `java-simplification`
**Description:** Reduce abstraction layers; migrate javax to jakarta; upgrade to modern Java; simplify plugin architecture; containerize

**Metrics:**
- LOC: 1197472 | Files: 9647
- Execution Time: 2696ms | Wall Time: 3s
- Tokens Estimated: 416725 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
javax_imports: 527
build_system: Maven
java_version: not-specified-in-pom
deprecated_annotations: 894
static_mutable_state: 761
hardcoded_secrets_candidates: 62
test_files: 501
spring_version: not-found
```

**Key Findings:** `javax_imports=527;deprecated=894;static_mutable=761;hardcoded_secrets=62;test_files=501;java_version=not-specified-in-pom`

---

### django-oscar (Python - Tier2)

**Strategy:** `django-upgrade`
**Description:** Upgrade Django to latest LTS; resolve architectural debt; add type hints; improve test coverage; modernize frontend to use modern JS framework

**Metrics:**
- LOC: 85673 | Files: 1074
- Execution Time: 282ms | Wall Time: 0s
- Tokens Estimated: 87726 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
deprecated_imp_module: 0
python2_patterns: 0
total_functions: 4181
typed_functions: 4
type_hint_coverage_pct: 0
has_requirements_txt: false
has_setup_py: true
has_pyproject_toml: true
hardcoded_secrets_candidates: 33
test_files: 180
django_version: not-found
```

**Key Findings:** `imp_usage=0;py2_patterns=0;type_coverage=0%;test_files=180;hardcoded_secrets=33;django_version=not-found`

---

### umbraco-cms (C# - Tier2)

**Strategy:** `dotnet-migration`
**Description:** Migrate to .NET 8+; replace legacy patterns; modernize Razor views; upgrade NuGet dependencies; add health checks and observability

**Metrics:**
- LOC: 761123 | Files: 7055
- Execution Time: 1509ms | Wall Time: 1s
- Tokens Estimated: 597528 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
dotnet_version: legacy-framework
solution_files: 1
project_files: 31
obsolete_attributes: 2
nuget_packages: 113
test_files: 1089
```

**Key Findings:** `dotnet_version=legacy-framework;projects=31;obsolete=2;nuget_packages=113;test_files=1089`

---

### mezzanine (Python - Tier2)

**Strategy:** `python312-compatibility`
**Description:** Replace imp module with importlib; upgrade to Python 3.12+; replace deprecated Django patterns; modernize settings management

**Metrics:**
- LOC: 64453 | Files: 372
- Execution Time: 302ms | Wall Time: 1s
- Tokens Estimated: 761682 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
deprecated_imp_module: 1
python2_patterns: 0
total_functions: 665
typed_functions: 0
type_hint_coverage_pct: 0
has_requirements_txt: false
has_setup_py: true
has_pyproject_toml: true
hardcoded_secrets_candidates: 3
test_files: 9
django_version: not-found
```

**Key Findings:** `imp_usage=1;py2_patterns=0;type_coverage=0%;test_files=9;hardcoded_secrets=3;django_version=not-found`

---

### b2cweb (Java - Tier2)

**Strategy:** `java-rebuild`
**Description:** Migrate from SSH framework to Spring Boot; replace manual JDBC with JPA/Hibernate; add Maven/Gradle build; internationalize; containerize

**Metrics:**
- LOC: 6507 | Files: 79
- Execution Time: 77ms | Wall Time: 0s
- Tokens Estimated: 37653 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
javax_imports: 52
java_version: unknown
deprecated_annotations: 0
static_mutable_state: 4
hardcoded_secrets_candidates: 2
test_files: 3
spring_version: none
```

**Key Findings:** `javax_imports=52;deprecated=0;static_mutable=4;hardcoded_secrets=2;test_files=3;java_version=unknown`

---

### dfe-net (C# - Tier2)

**Strategy:** `dotnet-modernization`
**Description:** Migrate to .NET 8+; replace legacy XML handling with modern APIs; add unit tests; modernize integration patterns

**Metrics:**
- LOC: 112701 | Files: 1199
- Execution Time: 253ms | Wall Time: 0s
- Tokens Estimated: 214374 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
dotnet_version: legacy-framework
solution_files: 1
project_files: 51
obsolete_attributes: 0
nuget_packages: 43
test_files: 20
```

**Key Findings:** `dotnet_version=legacy-framework;projects=51;obsolete=0;nuget_packages=43;test_files=20`

---

### monolith-enterprise (Java - Tier2)

**Strategy:** `java17-migration`
**Description:** Migrate javax to jakarta namespace; upgrade Java 7 to 17; replace Liquibase MySQL dependency; upgrade Spring Framework; containerize

**Metrics:**
- LOC: 5897 | Files: 119
- Execution Time: 88ms | Wall Time: 0s
- Tokens Estimated: 48159 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
javax_imports: 54
build_system: Maven
java_version: 1.7
deprecated_annotations: 0
static_mutable_state: 4
hardcoded_secrets_candidates: 3
test_files: 16
spring_version: not-found
```

**Key Findings:** `javax_imports=54;deprecated=0;static_mutable=4;hardcoded_secrets=3;test_files=16;java_version=1.7`

---

### cfwheels (ColdFusion - Tier2)

**Strategy:** `framework-migration`
**Description:** Assess migration from ColdFusion to modern framework (Node.js/Python); document API surface; create migration roadmap

**Metrics:**
- LOC: 178321 | Files: 1101
- Execution Time: 370ms | Wall Time: 1s
- Tokens Estimated: 6564898 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
cfm_template_files: 335
cfc_component_files: 761
deprecated_cfml_tags: 0
potential_sql_injection: 46
test_files: 81
```

**Key Findings:** `cfm_files=335;cfc_files=761;deprecated_tags=0;sql_injection_risk=46;test_files=81`

---

### cics-banking-sample (COBOL - Tier3)

**Strategy:** `mainframe-modernization`
**Description:** Extract business rules from COBOL; document CICS transaction flows; identify API extraction points; create microservice migration plan

**Metrics:**
- LOC: 0 | Files: 0
- Execution Time: 0ms | Wall Time: 0s
- Tokens Estimated: 0 | Retries: 0
- Status: **SKIPPED**

**Key Findings:** `Directory not found - clone failed (403)`

---

### nastran-95 (Fortran - Tier3)

**Strategy:** `fortran-modernization`
**Description:** Inventory numerical algorithms; assess F77 to Modern Fortran (F2018) migration; identify parallelization opportunities; document computational kernels

**Metrics:**
- LOC: 417500 | Files: 1848
- Execution Time: 392ms | Wall Time: 0s
- Tokens Estimated: 1023854 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
fortran77_files: 1848
modern_fortran_files: 0
common_blocks: 7572
goto_statements: 40417
equivalence_statements: 1740
subroutines_functions: 1786
```

**Key Findings:** `f77_files=1848;f90_files=0;common_blocks=7572;gotos=40417;equivalence=1740;subroutines=1786`

---

### apollo-11 (Assembly - Tier3)

**Strategy:** `historical-preservation`
**Description:** Document AGC instruction set; create modern simulation wrapper; preserve historical accuracy; add comprehensive documentation

**Metrics:**
- LOC: 130186 | Files: 175
- Execution Time: 244ms | Wall Time: 0s
- Tokens Estimated: 788030 | Retries: 0
- Status: **COMPLETED**

**Analysis Results:**
```
assembly_source_files: 175
total_instructions: 81520
memory_bank_refs: 4517
transfer_control_instructions: 10653
```

**Key Findings:** `agc_files=175;instructions=81520;bank_refs=4517;tc_instructions=10653`

---


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


---

## Methodology

### Metrics Definitions
- **Execution Time (ms):** CPU time spent on modernization analysis for each system
- **Wall Time (s):** Total elapsed clock time including I/O waits
- **Tokens Estimated:** Approximate LLM token count based on source code character count (1 token per 4 characters)
- **Retries:** Number of retry attempts for failed analysis operations (max 3 per system)
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
- **Timing:** nanosecond-precision via `date +%s%N`
- **Retry Policy:** Up to 3 retries per system analysis

---

*Report generated by modernize-all.sh | Legacy Rationalization Corpus*
*Raw metrics available in: modernization-results/metrics.csv*
