#!/usr/bin/env python3
"""
connect-and-extract.py — Live Database Schema Extractor

Connects to a live database instance and extracts schema metadata including
tables, columns, indexes, foreign keys, views, stored procedures, and triggers.
Outputs a structured schema summary report.

Supported databases:
  - PostgreSQL (via psycopg2)
  - MySQL (via mysql-connector-python)
  - Oracle (via oracledb)

Usage:
    python connect-and-extract.py --dbtype postgresql --host localhost --port 5432 \\
        --database mydb --user myuser --password mypass

    python connect-and-extract.py --dbtype mysql --host localhost --port 3306 \\
        --database mydb --user root --password secret

    python connect-and-extract.py --dbtype oracle --host dbhost --port 1521 \\
        --database ORCL --user system --password oracle

    python connect-and-extract.py --dbtype postgresql --host localhost --port 5432 \\
        --database mydb --user myuser --password mypass --json > report.json

Security Notes:
    - Do NOT pass credentials via command line in production. Use environment
      variables or a credentials file instead.
    - This script supports reading credentials from environment variables:
        DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_TYPE
    - For Oracle connections, ensure the Oracle Instant Client is installed
      or use oracledb thin mode.
    - All connections use the database driver's default security settings.
      For production use, configure SSL/TLS certificates explicitly.

Dependencies:
    pip install psycopg2-binary    # PostgreSQL
    pip install mysql-connector-python  # MySQL
    pip install oracledb           # Oracle

Alternative: SchemaCrawler
    For more comprehensive schema extraction (including ER diagrams), consider
    SchemaCrawler: https://www.schemacrawler.com/
    java -cp schemacrawler.jar schemacrawler.tools.main.Main \\
        --server=postgresql --host=localhost --port=5432 --database=mydb \\
        --user=myuser --password=mypass --info-level=standard --command=schema
"""

import argparse
import json
import os
import sys
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class ColumnInfo:
    """Metadata for a database column."""
    name: str
    data_type: str
    is_nullable: bool
    column_default: str = ""
    character_maximum_length: int = 0
    numeric_precision: int = 0

    def to_dict(self) -> dict:
        result = {"name": self.name, "data_type": self.data_type, "is_nullable": self.is_nullable}
        if self.column_default:
            result["default"] = self.column_default
        if self.character_maximum_length:
            result["max_length"] = self.character_maximum_length
        return result


@dataclass
class TableInfo:
    """Metadata for a database table."""
    schema_name: str
    table_name: str
    table_type: str = "BASE TABLE"
    columns: list = field(default_factory=list)
    row_count: int = 0

    def to_dict(self) -> dict:
        return {
            "schema": self.schema_name,
            "table": self.table_name,
            "type": self.table_type,
            "columns": [c.to_dict() for c in self.columns],
            "column_count": len(self.columns),
            "row_count": self.row_count,
        }


@dataclass
class IndexInfo:
    """Metadata for a database index."""
    name: str
    table_name: str
    columns: str
    is_unique: bool = False

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "table": self.table_name,
            "columns": self.columns,
            "is_unique": self.is_unique,
        }


@dataclass
class ForeignKeyInfo:
    """Metadata for a foreign key relationship."""
    constraint_name: str
    source_table: str
    source_columns: str
    target_table: str
    target_columns: str

    def to_dict(self) -> dict:
        return {
            "constraint": self.constraint_name,
            "source_table": self.source_table,
            "source_columns": self.source_columns,
            "target_table": self.target_table,
            "target_columns": self.target_columns,
        }


@dataclass
class SchemaReport:
    """Complete schema extraction report."""
    dbtype: str = ""
    host: str = ""
    port: int = 0
    database: str = ""
    extracted_at: str = ""
    tables: list = field(default_factory=list)
    indexes: list = field(default_factory=list)
    foreign_keys: list = field(default_factory=list)
    views: list = field(default_factory=list)
    stored_procedures: list = field(default_factory=list)
    triggers: list = field(default_factory=list)

    def to_dict(self) -> dict:
        return {
            "connection": {
                "dbtype": self.dbtype,
                "host": self.host,
                "port": self.port,
                "database": self.database,
            },
            "extracted_at": self.extracted_at,
            "summary": {
                "table_count": len(self.tables),
                "total_columns": sum(len(t.columns) for t in self.tables),
                "index_count": len(self.indexes),
                "foreign_key_count": len(self.foreign_keys),
                "view_count": len(self.views),
                "stored_procedure_count": len(self.stored_procedures),
                "trigger_count": len(self.triggers),
            },
            "tables": [t.to_dict() for t in self.tables],
            "indexes": [i.to_dict() for i in self.indexes],
            "foreign_keys": [fk.to_dict() for fk in self.foreign_keys],
            "views": self.views,
            "stored_procedures": self.stored_procedures,
            "triggers": self.triggers,
        }


# ---------------------------------------------------------------------------
# PostgreSQL Extractor
# ---------------------------------------------------------------------------

def extract_postgresql(host: str, port: int, database: str, user: str, password: str) -> SchemaReport:
    """Extract schema metadata from a PostgreSQL database."""
    try:
        import psycopg2
    except ImportError:
        print("Error: psycopg2 is not installed.", file=sys.stderr)
        print("Install it with: pip install psycopg2-binary", file=sys.stderr)
        sys.exit(1)

    report = SchemaReport(
        dbtype="postgresql",
        host=host,
        port=port,
        database=database,
        extracted_at=datetime.utcnow().isoformat() + "Z",
    )

    conn = psycopg2.connect(host=host, port=port, dbname=database, user=user, password=password)
    cur = conn.cursor()

    try:
        # Tables
        cur.execute("""
            SELECT table_schema, table_name, table_type
            FROM information_schema.tables
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY table_schema, table_name
        """)
        for schema_name, table_name, table_type in cur.fetchall():
            table = TableInfo(schema_name=schema_name, table_name=table_name, table_type=table_type)

            # Columns for this table
            cur.execute("""
                SELECT column_name, data_type, is_nullable, column_default,
                       character_maximum_length, numeric_precision
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                ORDER BY ordinal_position
            """, (schema_name, table_name))
            for col_name, data_type, nullable, default, max_len, precision in cur.fetchall():
                table.columns.append(ColumnInfo(
                    name=col_name,
                    data_type=data_type,
                    is_nullable=(nullable == "YES"),
                    column_default=default or "",
                    character_maximum_length=max_len or 0,
                    numeric_precision=precision or 0,
                ))

            # Row count (approximate via pg_stat)
            cur.execute("""
                SELECT n_live_tup FROM pg_stat_user_tables
                WHERE schemaname = %s AND relname = %s
            """, (schema_name, table_name))
            row = cur.fetchone()
            if row:
                table.row_count = row[0]

            if table_type == "BASE TABLE":
                report.tables.append(table)
            else:
                report.views.append(table_name)

        # Indexes
        cur.execute("""
            SELECT indexname, tablename, indexdef
            FROM pg_indexes
            WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
            ORDER BY tablename, indexname
        """)
        for idx_name, tbl_name, idx_def in cur.fetchall():
            is_unique = "UNIQUE" in (idx_def or "").upper()
            report.indexes.append(IndexInfo(
                name=idx_name, table_name=tbl_name, columns=idx_def or "", is_unique=is_unique
            ))

        # Foreign Keys
        cur.execute("""
            SELECT
                tc.constraint_name,
                tc.table_name AS source_table,
                kcu.column_name AS source_column,
                ccu.table_name AS target_table,
                ccu.column_name AS target_column
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.constraint_name
                AND tc.table_schema = ccu.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
                AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY tc.table_name, tc.constraint_name
        """)
        for constraint, src_table, src_col, tgt_table, tgt_col in cur.fetchall():
            report.foreign_keys.append(ForeignKeyInfo(
                constraint_name=constraint,
                source_table=src_table,
                source_columns=src_col,
                target_table=tgt_table,
                target_columns=tgt_col,
            ))

        # Stored Procedures / Functions
        cur.execute("""
            SELECT routine_name, routine_type
            FROM information_schema.routines
            WHERE routine_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY routine_name
        """)
        for routine_name, routine_type in cur.fetchall():
            report.stored_procedures.append(f"{routine_name} ({routine_type})")

        # Triggers
        cur.execute("""
            SELECT trigger_name, event_object_table, action_timing, event_manipulation
            FROM information_schema.triggers
            WHERE trigger_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY event_object_table, trigger_name
        """)
        for trig_name, tbl_name, timing, event in cur.fetchall():
            report.triggers.append(f"{trig_name} ON {tbl_name} ({timing} {event})")

        # Views (explicit query)
        cur.execute("""
            SELECT table_name
            FROM information_schema.views
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY table_name
        """)
        for (view_name,) in cur.fetchall():
            if view_name not in report.views:
                report.views.append(view_name)

    finally:
        cur.close()
        conn.close()

    return report


# ---------------------------------------------------------------------------
# MySQL Extractor
# ---------------------------------------------------------------------------

def extract_mysql(host: str, port: int, database: str, user: str, password: str) -> SchemaReport:
    """Extract schema metadata from a MySQL database."""
    try:
        import mysql.connector
    except ImportError:
        print("Error: mysql-connector-python is not installed.", file=sys.stderr)
        print("Install it with: pip install mysql-connector-python", file=sys.stderr)
        sys.exit(1)

    report = SchemaReport(
        dbtype="mysql",
        host=host,
        port=port,
        database=database,
        extracted_at=datetime.utcnow().isoformat() + "Z",
    )

    conn = mysql.connector.connect(host=host, port=port, database=database, user=user, password=password)
    cur = conn.cursor()

    try:
        # Tables
        cur.execute("""
            SELECT table_schema, table_name, table_type, table_rows
            FROM information_schema.tables
            WHERE table_schema = %s
            ORDER BY table_name
        """, (database,))
        for schema_name, table_name, table_type, row_count in cur.fetchall():
            table = TableInfo(
                schema_name=schema_name,
                table_name=table_name,
                table_type=table_type,
                row_count=row_count or 0,
            )

            # Columns
            cur.execute("""
                SELECT column_name, data_type, is_nullable, column_default,
                       character_maximum_length, numeric_precision
                FROM information_schema.columns
                WHERE table_schema = %s AND table_name = %s
                ORDER BY ordinal_position
            """, (database, table_name))
            for col_name, data_type, nullable, default, max_len, precision in cur.fetchall():
                table.columns.append(ColumnInfo(
                    name=col_name,
                    data_type=data_type,
                    is_nullable=(nullable == "YES"),
                    column_default=default or "",
                    character_maximum_length=max_len or 0,
                    numeric_precision=precision or 0,
                ))

            if "VIEW" in table_type.upper():
                report.views.append(table_name)
            else:
                report.tables.append(table)

        # Indexes
        cur.execute("""
            SELECT index_name, table_name, column_name, non_unique
            FROM information_schema.statistics
            WHERE table_schema = %s
            ORDER BY table_name, index_name, seq_in_index
        """, (database,))
        seen_indexes = {}
        for idx_name, tbl_name, col_name, non_unique in cur.fetchall():
            key = f"{tbl_name}.{idx_name}"
            if key not in seen_indexes:
                seen_indexes[key] = IndexInfo(
                    name=idx_name, table_name=tbl_name, columns=col_name, is_unique=(non_unique == 0)
                )
            else:
                seen_indexes[key].columns += f", {col_name}"
        report.indexes = list(seen_indexes.values())

        # Foreign Keys
        cur.execute("""
            SELECT constraint_name, table_name, column_name,
                   referenced_table_name, referenced_column_name
            FROM information_schema.key_column_usage
            WHERE table_schema = %s AND referenced_table_name IS NOT NULL
            ORDER BY table_name, constraint_name
        """, (database,))
        for constraint, src_table, src_col, tgt_table, tgt_col in cur.fetchall():
            report.foreign_keys.append(ForeignKeyInfo(
                constraint_name=constraint,
                source_table=src_table,
                source_columns=src_col,
                target_table=tgt_table,
                target_columns=tgt_col,
            ))

        # Stored Procedures
        cur.execute("""
            SELECT routine_name, routine_type
            FROM information_schema.routines
            WHERE routine_schema = %s
            ORDER BY routine_name
        """, (database,))
        for routine_name, routine_type in cur.fetchall():
            report.stored_procedures.append(f"{routine_name} ({routine_type})")

        # Triggers
        cur.execute("""
            SELECT trigger_name, event_object_table, action_timing, event_manipulation
            FROM information_schema.triggers
            WHERE trigger_schema = %s
            ORDER BY event_object_table, trigger_name
        """, (database,))
        for trig_name, tbl_name, timing, event in cur.fetchall():
            report.triggers.append(f"{trig_name} ON {tbl_name} ({timing} {event})")

    finally:
        cur.close()
        conn.close()

    return report


# ---------------------------------------------------------------------------
# Oracle Extractor
# ---------------------------------------------------------------------------

def extract_oracle(host: str, port: int, database: str, user: str, password: str) -> SchemaReport:
    """Extract schema metadata from an Oracle database."""
    try:
        import oracledb
    except ImportError:
        print("Error: oracledb is not installed.", file=sys.stderr)
        print("Install it with: pip install oracledb", file=sys.stderr)
        sys.exit(1)

    report = SchemaReport(
        dbtype="oracle",
        host=host,
        port=port,
        database=database,
        extracted_at=datetime.utcnow().isoformat() + "Z",
    )

    dsn = f"{host}:{port}/{database}"
    conn = oracledb.connect(user=user, password=password, dsn=dsn)
    cur = conn.cursor()

    try:
        # Tables
        cur.execute("""
            SELECT owner, table_name, num_rows
            FROM all_tables
            WHERE owner = UPPER(:owner)
            ORDER BY table_name
        """, {"owner": user})
        for owner, table_name, num_rows in cur.fetchall():
            table = TableInfo(
                schema_name=owner,
                table_name=table_name,
                row_count=num_rows or 0,
            )

            # Columns
            cur.execute("""
                SELECT column_name, data_type, nullable, data_default,
                       char_length, data_precision
                FROM all_tab_columns
                WHERE owner = UPPER(:owner) AND table_name = :table_name
                ORDER BY column_id
            """, {"owner": user, "table_name": table_name})
            for col_name, data_type, nullable, default, max_len, precision in cur.fetchall():
                table.columns.append(ColumnInfo(
                    name=col_name,
                    data_type=data_type,
                    is_nullable=(nullable == "Y"),
                    column_default=str(default).strip() if default else "",
                    character_maximum_length=max_len or 0,
                    numeric_precision=precision or 0,
                ))

            report.tables.append(table)

        # Indexes
        cur.execute("""
            SELECT index_name, table_name, uniqueness
            FROM all_indexes
            WHERE owner = UPPER(:owner)
            ORDER BY table_name, index_name
        """, {"owner": user})
        for idx_name, tbl_name, uniqueness in cur.fetchall():
            report.indexes.append(IndexInfo(
                name=idx_name, table_name=tbl_name, columns="", is_unique=(uniqueness == "UNIQUE")
            ))

        # Foreign Keys
        cur.execute("""
            SELECT a.constraint_name, a.table_name,
                   a_col.column_name AS source_column,
                   c_r.table_name AS target_table,
                   b_col.column_name AS target_column
            FROM all_constraints a
            JOIN all_cons_columns a_col ON a.constraint_name = a_col.constraint_name AND a.owner = a_col.owner
            JOIN all_constraints c_r ON a.r_constraint_name = c_r.constraint_name AND a.r_owner = c_r.owner
            JOIN all_cons_columns b_col ON c_r.constraint_name = b_col.constraint_name AND c_r.owner = b_col.owner
            WHERE a.constraint_type = 'R' AND a.owner = UPPER(:owner)
            ORDER BY a.table_name, a.constraint_name
        """, {"owner": user})
        for constraint, src_table, src_col, tgt_table, tgt_col in cur.fetchall():
            report.foreign_keys.append(ForeignKeyInfo(
                constraint_name=constraint,
                source_table=src_table,
                source_columns=src_col,
                target_table=tgt_table,
                target_columns=tgt_col,
            ))

        # Stored Procedures / Functions / Packages
        cur.execute("""
            SELECT object_name, object_type
            FROM all_objects
            WHERE owner = UPPER(:owner)
                AND object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')
            ORDER BY object_name
        """, {"owner": user})
        for obj_name, obj_type in cur.fetchall():
            report.stored_procedures.append(f"{obj_name} ({obj_type})")

        # Triggers
        cur.execute("""
            SELECT trigger_name, table_name, triggering_event, trigger_type
            FROM all_triggers
            WHERE owner = UPPER(:owner)
            ORDER BY table_name, trigger_name
        """, {"owner": user})
        for trig_name, tbl_name, event, trig_type in cur.fetchall():
            report.triggers.append(f"{trig_name} ON {tbl_name} ({trig_type} {event})")

        # Views
        cur.execute("""
            SELECT view_name FROM all_views
            WHERE owner = UPPER(:owner)
            ORDER BY view_name
        """, {"owner": user})
        for (view_name,) in cur.fetchall():
            report.views.append(view_name)

    finally:
        cur.close()
        conn.close()

    return report


# ---------------------------------------------------------------------------
# Report Output
# ---------------------------------------------------------------------------

def print_text_report(report: SchemaReport) -> None:
    """Print a human-readable schema summary report."""
    data = report.to_dict()

    print("=" * 70)
    print("DATABASE SCHEMA EXTRACTION REPORT")
    print("=" * 70)
    print()
    print(f"  Database Type:        {data['connection']['dbtype']}")
    print(f"  Host:                 {data['connection']['host']}:{data['connection']['port']}")
    print(f"  Database:             {data['connection']['database']}")
    print(f"  Extracted At:         {data['extracted_at']}")
    print()
    print("-" * 70)
    print("SUMMARY")
    print("-" * 70)
    summary = data["summary"]
    print(f"  Tables:               {summary['table_count']}")
    print(f"  Total Columns:        {summary['total_columns']}")
    print(f"  Indexes:              {summary['index_count']}")
    print(f"  Foreign Keys:         {summary['foreign_key_count']}")
    print(f"  Views:                {summary['view_count']}")
    print(f"  Stored Procedures:    {summary['stored_procedure_count']}")
    print(f"  Triggers:             {summary['trigger_count']}")
    print()

    print("-" * 70)
    print("TABLES")
    print("-" * 70)
    for table in report.tables:
        row_info = f", ~{table.row_count:,} rows" if table.row_count else ""
        print(f"  {table.schema_name}.{table.table_name} ({len(table.columns)} columns{row_info})")
    print()

    if report.foreign_keys:
        print("-" * 70)
        print("FOREIGN KEY RELATIONSHIPS")
        print("-" * 70)
        for fk in report.foreign_keys:
            print(f"  {fk.source_table}.{fk.source_columns} -> {fk.target_table}.{fk.target_columns}")
        print()

    if report.views:
        print("-" * 70)
        print("VIEWS")
        print("-" * 70)
        for view in report.views:
            print(f"  {view}")
        print()

    if report.stored_procedures:
        print("-" * 70)
        print("STORED PROCEDURES / FUNCTIONS")
        print("-" * 70)
        for sp in report.stored_procedures:
            print(f"  {sp}")
        print()

    if report.triggers:
        print("-" * 70)
        print("TRIGGERS")
        print("-" * 70)
        for trigger in report.triggers:
            print(f"  {trigger}")
        print()

    print("=" * 70)
    print("TIP: Use --json flag for machine-readable output.")
    print("     Pipe to analyze-schema.py for complexity assessment.")
    print("=" * 70)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

EXTRACTORS = {
    "postgresql": extract_postgresql,
    "mysql": extract_mysql,
    "oracle": extract_oracle,
}

DEFAULT_PORTS = {
    "postgresql": 5432,
    "mysql": 3306,
    "oracle": 1521,
}


def main():
    parser = argparse.ArgumentParser(
        description="Connect to a live database and extract schema metadata.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Connection Templates:

  PostgreSQL:
    python connect-and-extract.py --dbtype postgresql --host localhost \\
        --port 5432 --database mydb --user myuser --password mypass

  MySQL:
    python connect-and-extract.py --dbtype mysql --host localhost \\
        --port 3306 --database mydb --user root --password secret

  Oracle:
    python connect-and-extract.py --dbtype oracle --host dbhost \\
        --port 1521 --database ORCL --user system --password oracle

Environment Variables (override command-line args):
    DB_TYPE, DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
        """,
    )
    parser.add_argument(
        "--dbtype", choices=list(EXTRACTORS.keys()),
        default=os.environ.get("DB_TYPE", "postgresql"),
        help="Database type (default: postgresql)"
    )
    parser.add_argument(
        "--host", default=os.environ.get("DB_HOST", "localhost"),
        help="Database host (default: localhost)"
    )
    parser.add_argument(
        "--port", type=int, default=None,
        help="Database port (default: depends on dbtype)"
    )
    parser.add_argument(
        "--database", default=os.environ.get("DB_NAME", ""),
        help="Database name"
    )
    parser.add_argument(
        "--user", default=os.environ.get("DB_USER", ""),
        help="Database user"
    )
    parser.add_argument(
        "--password", default=os.environ.get("DB_PASSWORD", ""),
        help="Database password (prefer env var DB_PASSWORD for security)"
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Output report in JSON format"
    )

    args = parser.parse_args()

    # Resolve port default based on dbtype
    if args.port is None:
        port_env = os.environ.get("DB_PORT")
        if port_env:
            args.port = int(port_env)
        else:
            args.port = DEFAULT_PORTS.get(args.dbtype, 5432)

    # Validate required arguments
    if not args.database:
        print("Error: --database is required (or set DB_NAME env var)", file=sys.stderr)
        sys.exit(1)
    if not args.user:
        print("Error: --user is required (or set DB_USER env var)", file=sys.stderr)
        sys.exit(1)

    # Extract schema
    extractor = EXTRACTORS[args.dbtype]
    try:
        report = extractor(
            host=args.host,
            port=args.port,
            database=args.database,
            user=args.user,
            password=args.password,
        )
    except Exception as e:
        print(f"Error connecting to {args.dbtype} at {args.host}:{args.port}/{args.database}",
              file=sys.stderr)
        print(f"  {type(e).__name__}: {e}", file=sys.stderr)
        print("\nTroubleshooting:", file=sys.stderr)
        print("  1. Verify the database is running and accessible", file=sys.stderr)
        print("  2. Check credentials (user/password)", file=sys.stderr)
        print("  3. Ensure the required driver is installed:", file=sys.stderr)
        print("     - PostgreSQL: pip install psycopg2-binary", file=sys.stderr)
        print("     - MySQL:      pip install mysql-connector-python", file=sys.stderr)
        print("     - Oracle:     pip install oracledb", file=sys.stderr)
        sys.exit(1)

    # Output report
    if args.json:
        print(json.dumps(report.to_dict(), indent=2))
    else:
        print_text_report(report)


if __name__ == "__main__":
    main()
