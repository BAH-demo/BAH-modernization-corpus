#!/usr/bin/env python3
"""
analyze-schema.py — SQL Schema Complexity Analyzer

Parses a SQL schema file and produces a complexity assessment including:
  - Table, column, index, foreign key, stored procedure, and trigger counts
  - Complexity score based on weighted heuristics
  - Modernization complexity rating (Low / Medium / High / Very High)
  - Estimated disposition recommendation (Refactor / API-Wrap / Retire / Retain)

Usage:
    python analyze-schema.py <path-to-schema.sql>
    python analyze-schema.py <path-to-schema.sql> --json
    python analyze-schema.py <path-to-schema.sql> --verbose

Examples:
    python analyze-schema.py ../../db-schema-corpus/erp/northwind-postgresql.sql
    python analyze-schema.py schema.sql --json > report.json

Supported SQL dialects: PostgreSQL, MySQL, Oracle (DDL subset), SQL Server (DDL subset)

Note: This is a heuristic-based static analyzer. It parses SQL text using regex
patterns, not a full SQL parser. Results are approximate and should be validated
by a database engineer before making disposition decisions.
"""

import argparse
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path


@dataclass
class SchemaMetrics:
    """Collected metrics from schema analysis."""

    file_path: str = ""
    file_size_bytes: int = 0
    total_lines: int = 0
    non_empty_lines: int = 0

    tables: list = field(default_factory=list)
    columns_per_table: dict = field(default_factory=dict)
    indexes: list = field(default_factory=list)
    foreign_keys: list = field(default_factory=list)
    stored_procedures: list = field(default_factory=list)
    triggers: list = field(default_factory=list)
    views: list = field(default_factory=list)
    sequences: list = field(default_factory=list)

    deprecated_features: list = field(default_factory=list)

    @property
    def table_count(self) -> int:
        return len(self.tables)

    @property
    def total_columns(self) -> int:
        return sum(self.columns_per_table.values())

    @property
    def index_count(self) -> int:
        return len(self.indexes)

    @property
    def fk_count(self) -> int:
        return len(self.foreign_keys)

    @property
    def sp_count(self) -> int:
        return len(self.stored_procedures)

    @property
    def trigger_count(self) -> int:
        return len(self.triggers)

    @property
    def view_count(self) -> int:
        return len(self.views)


def parse_schema(file_path: str) -> SchemaMetrics:
    """Parse a SQL schema file and extract structural metrics."""
    path = Path(file_path)
    if not path.exists():
        print(f"Error: File not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    content = path.read_text(encoding="utf-8", errors="replace")
    lines = content.splitlines()

    metrics = SchemaMetrics(
        file_path=str(path.resolve()),
        file_size_bytes=path.stat().st_size,
        total_lines=len(lines),
        non_empty_lines=sum(1 for line in lines if line.strip()),
    )

    # Normalize content for pattern matching (collapse whitespace, keep newlines)
    normalized = content

    # --- Tables ---
    table_pattern = re.compile(
        r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:`|\"|)(\w[\w.]*?)(?:`|\"|)\s*\(",
        re.IGNORECASE,
    )
    for match in table_pattern.finditer(normalized):
        table_name = match.group(1).split(".")[-1]  # strip schema prefix
        metrics.tables.append(table_name)

    # --- Columns per table ---
    # For each CREATE TABLE block, count column definitions
    table_block_pattern = re.compile(
        r"CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:`|\"|)(\w[\w.]*?)(?:`|\"|)\s*\((.*?)\);",
        re.IGNORECASE | re.DOTALL,
    )
    for match in table_block_pattern.finditer(normalized):
        table_name = match.group(1).split(".")[-1]
        block = match.group(2)
        # Count lines that look like column definitions (start with a name and type)
        col_count = 0
        for line in block.split(","):
            line = line.strip()
            if not line:
                continue
            # Skip constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, CONSTRAINT, INDEX)
            first_word = line.split()[0].upper().strip("`\"") if line.split() else ""
            constraint_keywords = {
                "PRIMARY", "FOREIGN", "UNIQUE", "CHECK", "CONSTRAINT",
                "INDEX", "KEY", "EXCLUDE", "LIKE",
            }
            if first_word not in constraint_keywords:
                col_count += 1
        metrics.columns_per_table[table_name] = col_count

    # --- Indexes ---
    index_pattern = re.compile(
        r"CREATE\s+(?:UNIQUE\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:CONCURRENTLY\s+)?(?:`|\"|)(\w[\w.]*?)(?:`|\"|)",
        re.IGNORECASE,
    )
    for match in index_pattern.finditer(normalized):
        metrics.indexes.append(match.group(1))

    # --- Foreign Keys ---
    fk_pattern = re.compile(
        r"(?:CONSTRAINT\s+(?:`|\"|)?(\w+)(?:`|\"|)?\s+)?FOREIGN\s+KEY\s*\(([^)]+)\)\s*REFERENCES\s+(?:`|\"|)?(\w[\w.]*?)(?:`|\"|)?",
        re.IGNORECASE,
    )
    for match in fk_pattern.finditer(normalized):
        constraint_name = match.group(1) or "unnamed"
        columns = match.group(2).strip()
        ref_table = match.group(3).split(".")[-1]
        metrics.foreign_keys.append({
            "constraint": constraint_name,
            "columns": columns,
            "references": ref_table,
        })

    # Also catch inline REFERENCES (column-level FK)
    inline_fk_pattern = re.compile(
        r"(\w+)\s+\w+.*?\bREFERENCES\s+(?:`|\"|)?(\w[\w.]*?)(?:`|\"|)?\s*\(",
        re.IGNORECASE,
    )
    for match in inline_fk_pattern.finditer(normalized):
        col_name = match.group(1)
        ref_table = match.group(2).split(".")[-1]
        # Avoid duplicates with the constraint-level FK pattern
        if not any(
            fk["columns"].strip().strip("`\"") == col_name and fk["references"] == ref_table
            for fk in metrics.foreign_keys
        ):
            metrics.foreign_keys.append({
                "constraint": "inline",
                "columns": col_name,
                "references": ref_table,
            })

    # --- Stored Procedures / Functions / Packages ---
    sp_pattern = re.compile(
        r"CREATE\s+(?:OR\s+REPLACE\s+)?(?:PROCEDURE|FUNCTION|PACKAGE(?:\s+BODY)?)\s+(?:`|\"|)?(\w[\w.]+)(?:`|\"|)?(?:\s|;|\()",
        re.IGNORECASE,
    )
    for match in sp_pattern.finditer(normalized):
        name = match.group(1)
        if name.upper() not in {"BODY"}:
            metrics.stored_procedures.append(name)
    # Deduplicate (PACKAGE + PACKAGE BODY = one logical unit)
    metrics.stored_procedures = list(dict.fromkeys(metrics.stored_procedures))

    # --- Triggers ---
    trigger_pattern = re.compile(
        r"CREATE\s+(?:OR\s+REPLACE\s+)?TRIGGER\s+(?:`|\"|)?(\w[\w.]+)(?:`|\"|)?(?:\s|;)",
        re.IGNORECASE,
    )
    for match in trigger_pattern.finditer(normalized):
        metrics.triggers.append(match.group(1))

    # --- Views ---
    view_pattern = re.compile(
        r"CREATE\s+(?:OR\s+REPLACE\s+)?(?:MATERIALIZED\s+)?VIEW\s+(?:`|\"|)?(\w[\w.]+)(?:`|\"|)?(?:\s|;|\()",
        re.IGNORECASE,
    )
    for match in view_pattern.finditer(normalized):
        metrics.views.append(match.group(1))

    # --- Sequences ---
    seq_pattern = re.compile(
        r"CREATE\s+SEQUENCE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:`|\"|)?(\w[\w.]*?)(?:`|\"|)?",
        re.IGNORECASE,
    )
    for match in seq_pattern.finditer(normalized):
        metrics.sequences.append(match.group(1))

    # --- Deprecated / Legacy Features ---
    deprecated_patterns = [
        (r"\bDBMS_OUTPUT\b", "DBMS_OUTPUT (Oracle-specific debug output)"),
        (r"\bUTL_FILE\b", "UTL_FILE (Oracle file I/O from PL/SQL)"),
        (r"\bDBMS_JOB\b", "DBMS_JOB (deprecated Oracle job scheduler)"),
        (r"\bDBMS_PIPE\b", "DBMS_PIPE (Oracle inter-session messaging)"),
        (r"\bCONNECT\s+BY\s+PRIOR\b", "CONNECT BY PRIOR (Oracle hierarchical query)"),
        (r"\bROWNUM\b", "ROWNUM (Oracle-specific row limiting)"),
        (r"\bDECODE\s*\(", "DECODE (Oracle-specific conditional)"),
        (r"\bNVL\s*\(", "NVL (Oracle-specific null handling)"),
        (r"\bVARCHAR2\b", "VARCHAR2 (Oracle-specific type)"),
        (r"\bNUMBER\s*\(", "NUMBER (Oracle-specific numeric type)"),
        (r"\bSYSDATE\b", "SYSDATE (Oracle-specific date function)"),
        (r"\bdefault_with_oids\b", "default_with_oids (PostgreSQL deprecated setting)"),
        (r"\bWITH\s+OIDS\b", "WITH OIDS (PostgreSQL deprecated feature)"),
        (r"EXCEPTION\s+WHEN\s+OTHERS\s+THEN", "Catch-all exception handler (anti-pattern)"),
    ]

    for pattern, description in deprecated_patterns:
        if re.search(pattern, normalized, re.IGNORECASE):
            metrics.deprecated_features.append(description)

    return metrics


def compute_complexity_score(metrics: SchemaMetrics) -> float:
    """
    Compute a weighted complexity score from 0.0 to 10.0.

    Weights:
      - Table count: 25%
      - Total columns: 15%
      - Foreign key complexity: 20%
      - Stored procedure count: 15%
      - Trigger count: 10%
      - Lines of code: 10%
      - Deprecated features: 5%
    """
    # Normalize each dimension to 0–10 scale
    table_score = min(metrics.table_count / 20.0, 1.0) * 10
    column_score = min(metrics.total_columns / 200.0, 1.0) * 10
    fk_score = min(metrics.fk_count / 30.0, 1.0) * 10
    sp_score = min(metrics.sp_count / 10.0, 1.0) * 10
    trigger_score = min(metrics.trigger_count / 10.0, 1.0) * 10
    loc_score = min(metrics.non_empty_lines / 5000.0, 1.0) * 10
    deprecated_score = min(len(metrics.deprecated_features) / 5.0, 1.0) * 10

    weighted = (
        table_score * 0.25
        + column_score * 0.15
        + fk_score * 0.20
        + sp_score * 0.15
        + trigger_score * 0.10
        + loc_score * 0.10
        + deprecated_score * 0.05
    )

    return round(weighted, 2)


def get_complexity_rating(score: float) -> str:
    """Map complexity score to a human-readable rating."""
    if score < 2.5:
        return "Low"
    elif score < 5.0:
        return "Medium"
    elif score < 7.5:
        return "High"
    else:
        return "Very High"


def get_estimated_disposition(metrics: SchemaMetrics, score: float) -> str:
    """
    Estimate a disposition based on schema metrics and complexity score.

    This is a heuristic recommendation — final disposition requires
    human judgment and stakeholder input.
    """
    # If very small and no stored procedures/triggers, likely Retire or Retain candidate
    if metrics.table_count < 5 and metrics.sp_count == 0 and metrics.trigger_count == 0:
        return "Retire (or Retain if actively used)"

    # If heavy stored procedure / trigger usage, API-Wrap first
    if metrics.sp_count > 5 or metrics.trigger_count > 5:
        return "API-Wrap (heavy procedural logic — decouple before migrating)"

    # High complexity with many FKs = coordinated Refactor
    if score >= 5.0 and metrics.fk_count > 15:
        return "Refactor (complex but structured — phased migration recommended)"

    # Moderate complexity = straightforward Refactor
    if score >= 2.5:
        return "Refactor (moderate complexity — standard migration path)"

    # Low complexity
    return "Retain (low complexity — migrate only if platform EOL)"


def print_report(metrics: SchemaMetrics, score: float, verbose: bool = False) -> None:
    """Print a human-readable analysis report."""
    rating = get_complexity_rating(score)
    disposition = get_estimated_disposition(metrics, score)

    print("=" * 70)
    print("DATABASE SCHEMA ANALYSIS REPORT")
    print("=" * 70)
    print()
    print(f"  File:                 {metrics.file_path}")
    print(f"  File Size:            {metrics.file_size_bytes:,} bytes")
    print(f"  Total Lines:          {metrics.total_lines:,}")
    print(f"  Non-Empty Lines:      {metrics.non_empty_lines:,}")
    print()
    print("-" * 70)
    print("SCHEMA OBJECTS")
    print("-" * 70)
    print(f"  Tables:               {metrics.table_count}")
    print(f"  Total Columns:        {metrics.total_columns}")
    print(f"  Indexes:              {metrics.index_count}")
    print(f"  Foreign Keys:         {metrics.fk_count}")
    print(f"  Stored Procedures:    {metrics.sp_count}")
    print(f"  Triggers:             {metrics.trigger_count}")
    print(f"  Views:                {metrics.view_count}")
    print(f"  Sequences:            {len(metrics.sequences)}")
    print()
    print("-" * 70)
    print("ASSESSMENT")
    print("-" * 70)
    print(f"  Complexity Score:     {score} / 10.0")
    print(f"  Complexity Rating:    {rating}")
    print(f"  Est. Disposition:     {disposition}")
    print()

    if metrics.deprecated_features:
        print("-" * 70)
        print("DEPRECATED / LEGACY FEATURES DETECTED")
        print("-" * 70)
        for feature in metrics.deprecated_features:
            print(f"  - {feature}")
        print()

    if verbose:
        print("-" * 70)
        print("TABLE DETAILS")
        print("-" * 70)
        for table in sorted(metrics.tables):
            col_count = metrics.columns_per_table.get(table, 0)
            fk_refs = [fk for fk in metrics.foreign_keys if fk["references"] == table]
            fk_from = [
                fk for fk in metrics.foreign_keys
                if table in str(metrics.columns_per_table)
            ]
            print(f"  {table}: {col_count} columns, referenced by {len(fk_refs)} FKs")
        print()

        if metrics.stored_procedures:
            print("-" * 70)
            print("STORED PROCEDURES / FUNCTIONS")
            print("-" * 70)
            for sp in metrics.stored_procedures:
                print(f"  - {sp}")
            print()

        if metrics.triggers:
            print("-" * 70)
            print("TRIGGERS")
            print("-" * 70)
            for trigger in metrics.triggers:
                print(f"  - {trigger}")
            print()

        if metrics.views:
            print("-" * 70)
            print("VIEWS")
            print("-" * 70)
            for view in metrics.views:
                print(f"  - {view}")
            print()

    print("=" * 70)
    print("NOTE: This is a heuristic-based assessment. Final disposition")
    print("decisions require human review, stakeholder input, and alignment")
    print("with the broader modernization wave plan.")
    print("=" * 70)


def print_json_report(metrics: SchemaMetrics, score: float) -> None:
    """Print the analysis report in JSON format."""
    report = {
        "file": metrics.file_path,
        "file_size_bytes": metrics.file_size_bytes,
        "total_lines": metrics.total_lines,
        "non_empty_lines": metrics.non_empty_lines,
        "schema_objects": {
            "tables": metrics.table_count,
            "total_columns": metrics.total_columns,
            "indexes": metrics.index_count,
            "foreign_keys": metrics.fk_count,
            "stored_procedures": metrics.sp_count,
            "triggers": metrics.trigger_count,
            "views": metrics.view_count,
            "sequences": len(metrics.sequences),
        },
        "assessment": {
            "complexity_score": score,
            "complexity_rating": get_complexity_rating(score),
            "estimated_disposition": get_estimated_disposition(metrics, score),
        },
        "deprecated_features": metrics.deprecated_features,
        "tables": metrics.tables,
        "columns_per_table": metrics.columns_per_table,
        "foreign_keys": metrics.foreign_keys,
        "stored_procedures": metrics.stored_procedures,
        "triggers": metrics.triggers,
        "views": metrics.views,
    }
    print(json.dumps(report, indent=2))


def main():
    parser = argparse.ArgumentParser(
        description="Analyze a SQL schema file for modernization complexity assessment.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python analyze-schema.py schema.sql
  python analyze-schema.py schema.sql --json
  python analyze-schema.py schema.sql --verbose
        """,
    )
    parser.add_argument("schema_file", help="Path to the SQL schema file to analyze")
    parser.add_argument(
        "--json", action="store_true", help="Output report in JSON format"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true", help="Include detailed table and object listings"
    )

    args = parser.parse_args()

    metrics = parse_schema(args.schema_file)
    score = compute_complexity_score(metrics)

    if args.json:
        print_json_report(metrics, score)
    else:
        print_report(metrics, score, verbose=args.verbose)


if __name__ == "__main__":
    main()
