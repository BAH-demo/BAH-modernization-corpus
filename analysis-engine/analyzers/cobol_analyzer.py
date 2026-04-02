"""COBOL code analyzer for paragraph detection, COPY/CALL mapping, and CICS commands."""

import re
from pathlib import Path

from analysis_engine.analyzers.base_analyzer import BaseAnalyzer


class CobolAnalyzer(BaseAnalyzer):
    """Analyzer for COBOL codebases."""

    LANGUAGE = "COBOL"
    FILE_EXTENSIONS = (".cbl", ".cob", ".CBL", ".COB", ".cobol", ".cpy", ".CPY")

    def _is_comment(self, line: str) -> bool:
        if len(line) >= 7:
            return line[6] == "*" or line[6] == "/"
        return line.startswith("*")

    def analyze_structure(self) -> dict:
        """Extract COBOL program structure: divisions, sections, paragraphs."""
        divisions = set()
        sections = set()
        paragraphs = []
        copybooks = set()
        call_targets = set()
        cics_commands = set()
        data_items = []
        file_controls = []

        division_pattern = re.compile(r"^\s{6}\s+(\w+)\s+DIVISION", re.IGNORECASE)
        section_pattern = re.compile(r"^\s{6}\s+(\w[\w-]+)\s+SECTION", re.IGNORECASE)
        paragraph_pattern = re.compile(r"^(\s{7}\s?)(\w[\w-]+)\.\s*$", re.IGNORECASE)
        copy_pattern = re.compile(r"\bCOPY\s+([\w-]+)", re.IGNORECASE)
        call_pattern = re.compile(r"\bCALL\s+['\"]?([\w-]+)['\"]?", re.IGNORECASE)
        cics_pattern = re.compile(r"\bEXEC\s+CICS\s+(\w+)", re.IGNORECASE)
        data_pattern = re.compile(
            r"^\s+(\d{2})\s+([\w-]+)", re.IGNORECASE
        )
        file_pattern = re.compile(r"\bSELECT\s+([\w-]+)", re.IGNORECASE)

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        match = division_pattern.match(line)
                        if match:
                            divisions.add(match.group(1).upper())

                        match = section_pattern.match(line)
                        if match:
                            sections.add(match.group(1).upper())

                        match = paragraph_pattern.match(line)
                        if match:
                            paragraphs.append(match.group(2))

                        for match in copy_pattern.finditer(line):
                            copybooks.add(match.group(1))

                        for match in call_pattern.finditer(line):
                            call_targets.add(match.group(1))

                        for match in cics_pattern.finditer(line):
                            cics_commands.add(match.group(1).upper())

                        match = data_pattern.match(line)
                        if match:
                            level = match.group(1)
                            name = match.group(2)
                            if level in ("01", "05", "77", "88"):
                                data_items.append(f"{level} {name}")

                        for match in file_pattern.finditer(line):
                            file_controls.append(match.group(1))
            except (OSError, UnicodeDecodeError):
                continue

        return {
            "divisions": sorted(divisions),
            "sections": len(sections),
            "paragraphs": len(paragraphs),
            "copybooks": sorted(copybooks),
            "call_targets": sorted(call_targets),
            "cics_commands": sorted(cics_commands),
            "data_items_01_level": len([d for d in data_items if d.startswith("01")]),
            "file_controls": len(file_controls),
        }

    def detect_patterns(self) -> list[str]:
        """Detect COBOL-specific architectural patterns."""
        patterns = []
        has_cics = False
        has_vsam = False
        has_db2 = False
        has_batch = False
        has_copybook = False

        for filepath in self.files[:100]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read().upper()

                if "EXEC CICS" in content:
                    has_cics = True
                if "VSAM" in content or "KSDS" in content or "ESDS" in content:
                    has_vsam = True
                if "EXEC SQL" in content or "DB2" in content:
                    has_db2 = True
                if "JCL" in filepath.upper() or "JOB" in content[:200]:
                    has_batch = True
            except (OSError, UnicodeDecodeError):
                continue

        if any(f.endswith((".cpy", ".CPY")) for f in self.files):
            has_copybook = True

        if has_cics:
            patterns.append("CICS Online Transaction Processing")
        if has_vsam:
            patterns.append("VSAM File I/O")
        if has_db2:
            patterns.append("DB2 SQL Embedded")
        if has_batch:
            patterns.append("Batch JCL Processing")
        if has_copybook:
            patterns.append("COPYBOOK Data Structures")
        if len(self.files) > 10:
            patterns.append("Multi-Program System")

        self.architectural_patterns = patterns
        return patterns

    def find_dependencies(self) -> list[str]:
        """Find COBOL dependencies: COPY and CALL statements."""
        deps = set()

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        for match in re.finditer(r"\bCOPY\s+([\w-]+)", line, re.IGNORECASE):
                            deps.add(f"COPY:{match.group(1)}")
                        for match in re.finditer(r"\bCALL\s+['\"]?([\w-]+)", line, re.IGNORECASE):
                            deps.add(f"CALL:{match.group(1)}")
            except (OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)
        return self.dependencies
