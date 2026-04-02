"""Fortran code analyzer for COMMON block detection, subroutine mapping."""

import re
from pathlib import Path

from analyzers.base_analyzer import BaseAnalyzer


class FortranAnalyzer(BaseAnalyzer):
    """Analyzer for Fortran codebases."""

    LANGUAGE = "Fortran"
    FILE_EXTENSIONS = (".f", ".f90", ".f77", ".for", ".F", ".F90", ".ftn")

    def _is_comment(self, line: str) -> bool:
        if not line:
            return False
        first = line[0].upper()
        return first in ("C", "!", "*") or line.strip().startswith("!")

    def analyze_structure(self) -> dict:
        """Extract Fortran program structure: subroutines, functions, COMMON blocks."""
        subroutines = []
        functions = []
        common_blocks = set()
        modules = []
        programs = []
        equivalences = []
        data_statements = 0
        format_statements = 0
        goto_count = 0

        subroutine_pattern = re.compile(r"^\s+SUBROUTINE\s+(\w+)", re.IGNORECASE)
        function_pattern = re.compile(
            r"^\s+(?:\w+\s+)?FUNCTION\s+(\w+)", re.IGNORECASE
        )
        common_pattern = re.compile(r"\bCOMMON\s*/(\w+)/", re.IGNORECASE)
        common_blank_pattern = re.compile(r"\bCOMMON\s+\w", re.IGNORECASE)
        module_pattern = re.compile(r"^\s*MODULE\s+(\w+)", re.IGNORECASE)
        program_pattern = re.compile(r"^\s*PROGRAM\s+(\w+)", re.IGNORECASE)
        equivalence_pattern = re.compile(r"\bEQUIVALENCE\s*\(", re.IGNORECASE)

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        match = subroutine_pattern.match(line)
                        if match:
                            subroutines.append(match.group(1))

                        match = function_pattern.match(line)
                        if match:
                            functions.append(match.group(1))

                        for match in common_pattern.finditer(line):
                            common_blocks.add(match.group(1))

                        if common_blank_pattern.search(line) and "/" not in line:
                            common_blocks.add("BLANK_COMMON")

                        match = module_pattern.match(line)
                        if match:
                            modules.append(match.group(1))

                        match = program_pattern.match(line)
                        if match:
                            programs.append(match.group(1))

                        if equivalence_pattern.search(line):
                            equivalences.append(filepath)

                        if re.search(r"\bFORMAT\s*\(", line, re.IGNORECASE):
                            format_statements += 1

                        if re.search(r"\bDATA\s+\w", line, re.IGNORECASE):
                            data_statements += 1

                        if re.search(r"\bGO\s*TO\b", line, re.IGNORECASE):
                            goto_count += 1
            except (OSError, UnicodeDecodeError):
                continue

        return {
            "subroutines": len(subroutines),
            "functions": len(functions),
            "common_blocks": len(common_blocks),
            "common_block_names": sorted(common_blocks),
            "modules": len(modules),
            "programs": len(programs),
            "equivalences": len(set(equivalences)),
            "format_statements": format_statements,
            "data_statements": data_statements,
            "goto_count": goto_count,
        }

    def detect_patterns(self) -> list[str]:
        """Detect Fortran-specific patterns."""
        patterns = []
        has_common = False
        has_equivalence = False
        has_implicit = False
        has_f90_features = False
        has_goto = False

        for filepath in self.files[:100]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read().upper()

                if "COMMON" in content:
                    has_common = True
                if "EQUIVALENCE" in content:
                    has_equivalence = True
                if "IMPLICIT NONE" in content:
                    has_implicit = True
                if "MODULE" in content or "USE " in content:
                    has_f90_features = True
                if "GO TO" in content or "GOTO" in content:
                    has_goto = True
            except (OSError, UnicodeDecodeError):
                continue

        if has_common:
            patterns.append("COMMON Block Shared State")
        if has_equivalence:
            patterns.append("EQUIVALENCE Memory Aliasing")
        if not has_implicit:
            patterns.append("Implicit Typing (no IMPLICIT NONE)")
        if has_f90_features:
            patterns.append("Fortran 90+ Module System")
        if has_goto:
            patterns.append("GO TO Control Flow")
        if any(f.endswith((".f", ".f77", ".ftn", ".F")) for f in self.files):
            patterns.append("Fixed-Format Source (F77)")
        if any(f.endswith((".f90", ".F90")) for f in self.files):
            patterns.append("Free-Format Source (F90+)")

        self.architectural_patterns = patterns
        return patterns

    def find_dependencies(self) -> list[str]:
        """Find Fortran dependencies: CALL targets, INCLUDE files, USE modules."""
        deps = set()

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        for match in re.finditer(r"\bCALL\s+(\w+)", line, re.IGNORECASE):
                            deps.add(f"CALL:{match.group(1)}")
                        for match in re.finditer(r"\bINCLUDE\s+['\"](\w+)", line, re.IGNORECASE):
                            deps.add(f"INCLUDE:{match.group(1)}")
                        for match in re.finditer(r"\bUSE\s+(\w+)", line, re.IGNORECASE):
                            deps.add(f"USE:{match.group(1)}")
            except (OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)[:100]
        return self.dependencies
