#!/usr/bin/env python3
"""
Report generator that produces per-system markdown reports from analysis JSON.
"""

import json
import os
import sys
from pathlib import Path


def generate_system_report(result: dict) -> str:
    """Generate a markdown report for a single system."""
    system = result.get("system", "Unknown")
    language = result.get("language", "Unknown")
    loc = result.get("loc", 0)
    files = result.get("files", 0)
    complexity_avg = result.get("complexity_avg", 0)
    complexity_max = result.get("complexity_max", 0)
    dependencies = result.get("dependencies", [])
    dead_code = result.get("dead_code_candidates", [])
    patterns = result.get("architectural_patterns", [])

    lines = []
    lines.append(f"# Analysis Report: {system}")
    lines.append("")
    lines.append("## Overview")
    lines.append("")
    lines.append(f"| Metric | Value |")
    lines.append(f"|--------|-------|")
    lines.append(f"| **System** | {system} |")
    lines.append(f"| **Primary Language** | {language} |")
    lines.append(f"| **Lines of Code** | {loc:,} |")
    lines.append(f"| **Source Files** | {files:,} |")
    lines.append(f"| **Avg Cyclomatic Complexity** | {complexity_avg:.1f} |")
    lines.append(f"| **Max Cyclomatic Complexity** | {complexity_max:.1f} |")
    lines.append("")

    # Complexity assessment
    lines.append("## Complexity Assessment")
    lines.append("")
    if complexity_avg <= 5:
        lines.append("**Low complexity** - Code is generally well-structured with simple control flow.")
    elif complexity_avg <= 10:
        lines.append("**Moderate complexity** - Some methods have complex control flow that may benefit from refactoring.")
    elif complexity_avg <= 20:
        lines.append("**High complexity** - Significant portions of code have complex control flow. Refactoring recommended.")
    else:
        lines.append("**Very high complexity** - Code has extensive branching and nested logic. Major refactoring needed.")
    lines.append("")

    # Architectural patterns
    if patterns:
        lines.append("## Architectural Patterns Detected")
        lines.append("")
        for pattern in patterns:
            lines.append(f"- {pattern}")
        lines.append("")

    # Dependencies
    if dependencies:
        lines.append("## Dependencies")
        lines.append("")
        lines.append(f"Total external dependencies: {len(dependencies)}")
        lines.append("")
        for dep in dependencies[:30]:
            lines.append(f"- `{dep}`")
        if len(dependencies) > 30:
            lines.append(f"- ... and {len(dependencies) - 30} more")
        lines.append("")

    # Dead code candidates
    if dead_code:
        lines.append("## Potential Dead Code")
        lines.append("")
        lines.append(f"Found {len(dead_code)} potential dead code candidates:")
        lines.append("")
        for item in dead_code[:20]:
            lines.append(f"- `{item}`")
        if len(dead_code) > 20:
            lines.append(f"- ... and {len(dead_code) - 20} more")
        lines.append("")

    # Modernization recommendations
    lines.append("## Modernization Recommendations")
    lines.append("")
    lines.append(f"Based on the analysis of {system}:")
    lines.append("")

    if language == "COBOL":
        lines.append("1. **Transaction Processing**: Map CICS transactions to REST API endpoints")
        lines.append("2. **Data Access**: Replace VSAM file I/O with relational database (JPA/JDBC)")
        lines.append("3. **Business Logic**: Extract COBOL paragraphs into service methods")
        lines.append("4. **Data Types**: Handle COMP-3/packed decimal to Java BigDecimal conversion")
        lines.append("5. **Copybooks**: Convert to shared data transfer objects (DTOs)")
    elif language == "Fortran":
        lines.append("1. **COMMON Blocks**: Replace with class/module attributes")
        lines.append("2. **EQUIVALENCE**: Eliminate memory aliasing with proper data structures")
        lines.append("3. **Implicit Typing**: Add explicit type declarations")
        lines.append("4. **GO TO**: Replace with structured control flow")
        lines.append("5. **FORMAT Statements**: Replace with modern I/O libraries")
    elif language == "Assembly":
        lines.append("1. **Fixed-Point Math**: Implement as a library with proper type system")
        lines.append("2. **Register Model**: Map to local variables and function parameters")
        lines.append("3. **Interrupt Handling**: Convert to event-driven architecture")
        lines.append("4. **Memory Layout**: Use structs and typed arrays")
        lines.append("5. **Control Flow**: Map labels and branches to functions and if/else")
    elif language == "Java":
        lines.append("1. **Decouple Monolith**: Identify bounded contexts for microservice extraction")
        lines.append("2. **Modernize Framework**: Migrate from legacy Java EE to Spring Boot")
        lines.append("3. **Database Layer**: Standardize on JPA with connection pooling")
        lines.append("4. **Testing**: Add comprehensive unit and integration tests")
        lines.append("5. **API Layer**: Expose REST APIs for all business operations")
    elif language == "Python":
        lines.append("1. **Framework Updates**: Upgrade to latest Django/Flask with async support")
        lines.append("2. **Type Hints**: Add type annotations throughout the codebase")
        lines.append("3. **Database**: Optimize ORM queries and add indexes")
        lines.append("4. **Testing**: Increase test coverage with pytest")
        lines.append("5. **Packaging**: Migrate to pyproject.toml and modern tooling")
    elif language == "C#":
        lines.append("1. **Framework Migration**: Upgrade to .NET 8+ and ASP.NET Core")
        lines.append("2. **Dependency Injection**: Use built-in DI container consistently")
        lines.append("3. **Async/Await**: Convert synchronous I/O to async patterns")
        lines.append("4. **Testing**: Add xUnit tests with mocking")
        lines.append("5. **API**: Migrate to minimal APIs or controllers with OpenAPI")
    else:
        lines.append("1. **Code Analysis**: Perform deeper structural analysis")
        lines.append("2. **Documentation**: Document existing architecture and dependencies")
        lines.append("3. **Testing**: Establish baseline test coverage")
        lines.append("4. **Refactoring**: Address high-complexity areas first")
        lines.append("5. **Migration Plan**: Create phased modernization roadmap")

    lines.append("")
    lines.append("---")
    lines.append(f"*Generated by Legacy Modernization Corpus Analysis Engine*")
    lines.append("")

    return "\n".join(lines)


def main():
    """Generate markdown reports from analysis JSON files."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate markdown reports from analysis results"
    )
    parser.add_argument(
        "--input-dir",
        type=str,
        default=None,
        help="Directory containing analysis JSON files",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Directory for markdown reports",
    )

    args = parser.parse_args()

    repo_root = Path(__file__).parent.parent
    input_dir = Path(args.input_dir) if args.input_dir else repo_root / "corpus-analysis-results"
    output_dir = Path(args.output_dir) if args.output_dir else input_dir / "reports"

    if not input_dir.exists():
        print(f"Error: Input directory not found: {input_dir}")
        print("Run the analyzer first: python -m analysis_engine.analyzer")
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    print("Generating markdown reports...")
    print(f"Input:  {input_dir}")
    print(f"Output: {output_dir}")
    print()

    report_count = 0
    for json_file in sorted(input_dir.glob("*.json")):
        if json_file.name == "all-systems.json":
            continue

        try:
            with open(json_file, "r") as f:
                result = json.load(f)

            if "error" in result:
                print(f"  Skipping {json_file.name} (has errors)")
                continue

            report = generate_system_report(result)
            report_file = output_dir / f"{json_file.stem}-report.md"
            with open(report_file, "w") as f:
                f.write(report)
            print(f"  Generated: {report_file.name}")
            report_count += 1

        except (json.JSONDecodeError, KeyError) as e:
            print(f"  Error processing {json_file.name}: {e}")

    print(f"\nGenerated {report_count} reports in {output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
