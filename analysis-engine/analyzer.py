#!/usr/bin/env python3
"""
Main entry point for the Legacy Modernization Corpus Analysis Engine.

Discovers all systems in modernization-corpus-aggregate/ and runs
language-specific analyzers to produce JSON profiles.
"""

import json
import os
import sys
from pathlib import Path

# Add this directory to path for imports when run as a script
sys.path.insert(0, str(Path(__file__).parent))

from analyzers.base_analyzer import BaseAnalyzer
from analyzers.java_analyzer import JavaAnalyzer
from analyzers.python_analyzer import PythonAnalyzer
from analyzers.csharp_analyzer import CSharpAnalyzer
from analyzers.cobol_analyzer import CobolAnalyzer
from analyzers.fortran_analyzer import FortranAnalyzer
from analyzers.assembly_analyzer import AssemblyAnalyzer
from analyzers.coldfusion_analyzer import ColdFusionAnalyzer

LANGUAGE_ANALYZERS: dict[str, type[BaseAnalyzer]] = {
    "Java": JavaAnalyzer,
    "Python": PythonAnalyzer,
    "C#": CSharpAnalyzer,
    "COBOL": CobolAnalyzer,
    "Fortran": FortranAnalyzer,
    "Assembly": AssemblyAnalyzer,
    "ColdFusion": ColdFusionAnalyzer,
}


def load_manifest(repo_root: Path) -> dict:
    """Load corpus-manifest.json to determine system languages."""
    manifest_path = repo_root / "corpus-manifest.json"
    if not manifest_path.exists():
        print(f"Warning: corpus-manifest.json not found at {manifest_path}")
        return {}
    with open(manifest_path, "r") as f:
        return json.load(f)


def discover_systems(aggregate_dir: Path) -> list[str]:
    """Discover all cloned systems in the aggregate directory."""
    if not aggregate_dir.exists():
        return []
    systems = []
    for entry in sorted(aggregate_dir.iterdir()):
        if entry.is_dir() and (entry / ".git").exists():
            systems.append(entry.name)
    return systems


def analyze_system(
    system_name: str,
    system_path: Path,
    language: str,
) -> dict:
    """Run analysis on a single system."""
    analyzer_class = LANGUAGE_ANALYZERS.get(language)
    if not analyzer_class:
        print(f"  No analyzer available for language: {language}")
        return {
            "system": system_name,
            "language": language,
            "error": f"No analyzer for {language}",
        }

    print(f"  Running {language} analyzer...")
    analyzer = analyzer_class(str(system_path), system_name)
    return analyzer.analyze()


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Legacy Modernization Corpus Analysis Engine"
    )
    parser.add_argument(
        "--corpus-dir",
        type=str,
        default=None,
        help="Path to modernization-corpus-aggregate directory",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default=None,
        help="Output directory for analysis results (default: corpus-analysis-results/)",
    )
    parser.add_argument(
        "--systems",
        nargs="+",
        help="Specific systems to analyze (default: all discovered)",
    )
    parser.add_argument(
        "--format",
        choices=["json", "summary"],
        default="json",
        help="Output format",
    )

    args = parser.parse_args()

    # Determine paths
    repo_root = Path(__file__).parent.parent
    aggregate_dir = (
        Path(args.corpus_dir)
        if args.corpus_dir
        else repo_root / "modernization-corpus-aggregate"
    )
    output_dir = (
        Path(args.output_dir)
        if args.output_dir
        else repo_root / "corpus-analysis-results"
    )

    print("=" * 60)
    print("Legacy Modernization Corpus - Analysis Engine")
    print("=" * 60)
    print(f"Corpus directory: {aggregate_dir}")
    print(f"Output directory: {output_dir}")
    print()

    # Load manifest
    manifest = load_manifest(repo_root)
    systems_config = manifest.get("systems", {})

    # Discover systems
    discovered = discover_systems(aggregate_dir)
    if not discovered:
        print(f"No systems found in {aggregate_dir}")
        print("Run CORPUS-AGGREGATION-SETUP.sh first to clone systems.")
        sys.exit(1)

    # Filter to requested systems
    if args.systems:
        systems_to_analyze = [s for s in args.systems if s in discovered]
        missing = set(args.systems) - set(discovered)
        if missing:
            print(f"Warning: Systems not found: {', '.join(missing)}")
    else:
        systems_to_analyze = discovered

    print(f"Systems to analyze: {len(systems_to_analyze)}")
    print()

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Analyze each system
    all_results = []
    for system_name in systems_to_analyze:
        system_path = aggregate_dir / system_name
        config = systems_config.get(system_name, {})
        language = config.get("language", "Unknown")

        print(f"Analyzing: {system_name} ({language})")

        result = analyze_system(system_name, system_path, language)
        all_results.append(result)

        # Write individual result
        result_file = output_dir / f"{system_name}.json"
        with open(result_file, "w") as f:
            json.dump(result, f, indent=2)
        print(f"  Result saved: {result_file}")
        print()

    # Write combined results
    combined_file = output_dir / "all-systems.json"
    with open(combined_file, "w") as f:
        json.dump(
            {
                "analyzed_at": __import__("datetime").datetime.utcnow().isoformat() + "Z",
                "systems_analyzed": len(all_results),
                "results": all_results,
            },
            f,
            indent=2,
        )
    print(f"Combined results: {combined_file}")

    # Print summary
    if args.format == "summary" or True:
        print()
        print("=" * 60)
        print("Analysis Summary")
        print("=" * 60)
        print(f"{'System':<25} {'Language':<12} {'LOC':>8} {'Files':>6} {'Avg CC':>7} {'Max CC':>7}")
        print("-" * 75)
        for r in all_results:
            if "error" not in r:
                print(
                    f"{r['system']:<25} {r['language']:<12} {r['loc']:>8,} "
                    f"{r['files']:>6} {r['complexity_avg']:>7.1f} {r['complexity_max']:>7.1f}"
                )
            else:
                print(f"{r['system']:<25} {r.get('language', 'N/A'):<12} {'ERROR':>8}")
        print()

    print("Analysis complete!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
