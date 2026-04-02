"""Assembly code analyzer for label/instruction counting and subroutine detection."""

import re
from pathlib import Path

from analysis_engine.analyzers.base_analyzer import BaseAnalyzer


class AssemblyAnalyzer(BaseAnalyzer):
    """Analyzer for Assembly codebases (focused on AGC assembly)."""

    LANGUAGE = "Assembly"
    FILE_EXTENSIONS = (".agc", ".s", ".asm", ".S")

    def _is_comment(self, line: str) -> bool:
        return (
            line.startswith("#")
            or line.startswith(";")
            or line.startswith("##")
        )

    def analyze_structure(self) -> dict:
        """Extract assembly structure: labels, instructions, subroutines."""
        labels = []
        instructions = set()
        subroutines = []
        macros = []
        data_defs = 0
        total_instructions = 0

        # AGC-specific patterns
        agc_label_pattern = re.compile(r"^(\w+)\s+", re.MULTILINE)
        agc_instruction_pattern = re.compile(
            r"^\w*\s+(TC|TCF|CA|CS|AD|MASK|DCA|DCS|INDEX|EXTEND|INHINT|RELINT|"
            r"TS|XCH|LXCH|DXCH|INCR|ADS|SU|MSU|MP|DV|QXCH|CCS|BZF|BZMF|"
            r"CAF|CAE|DDOUBL|ZL|ZQ|COM|DOUBLE|OVSK|NOOP|RESUME|DTCB|DTCF|"
            r"STCALL|STODL|STORE|EXIT|SETPD|PUSH|PDDL|PDVL|MXV|VXM|VXSC|"
            r"V/SC|SLOAD|DLOAD|TLOAD|VLOAD|SSP|DAD|DSU|DMP|DDV|DMPR|BDSU|"
            r"BDDV|SIGN|SIN|COS|ASIN|ACOS|SQRT|DSQ|ROUND|COMP|VDEF|UNIT|"
            r"DOT|CROSS|VXV|VSQ|ABVAL|VCOMP|VPROJ|V/SC|NORM|BVSU|VAD|VSU|"
            r"GOTO|CALL|RTB|BHIZ|BMN|BOV|BPL)\b",
            re.IGNORECASE,
        )
        # Generic assembly patterns
        generic_label_pattern = re.compile(r"^(\w+):", re.MULTILINE)
        generic_subroutine_pattern = re.compile(
            r"^(\w+):\s*$|^\s+(PROC|FUNCTION|SUBROUTINE)\b", re.IGNORECASE
        )

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                    lines = content.split("\n")

                # Determine if AGC or generic assembly
                is_agc = filepath.endswith(".agc")

                if is_agc:
                    for line in lines:
                        stripped = line.strip()
                        if not stripped or stripped.startswith("#"):
                            continue

                        # Labels in column 1 (no leading whitespace)
                        if line and not line[0].isspace() and not line.startswith("#"):
                            word = line.split()[0] if line.split() else ""
                            if word and word.isalnum():
                                labels.append(word)

                        match = agc_instruction_pattern.match(stripped)
                        if match:
                            instructions.add(match.group(1).upper())
                            total_instructions += 1

                        if re.match(r"^\w+\s+TC\s+", line):
                            parts = line.split()
                            if len(parts) >= 3:
                                subroutines.append(parts[0])
                else:
                    for match in generic_label_pattern.finditer(content):
                        labels.append(match.group(1))
                    for match in generic_subroutine_pattern.finditer(content):
                        if match.group(1):
                            subroutines.append(match.group(1))

                # Count data definitions
                data_defs += len(re.findall(r"\b(DEC|OCT|2DEC|2OCT|ERASE|EQUALS|=)\b", content, re.IGNORECASE))

            except (OSError, UnicodeDecodeError):
                continue

        return {
            "labels": len(labels),
            "unique_instructions": len(instructions),
            "total_instructions": total_instructions,
            "subroutines": len(subroutines),
            "data_definitions": data_defs,
            "instruction_set": sorted(instructions)[:30],
        }

    def detect_patterns(self) -> list[str]:
        """Detect assembly-specific patterns."""
        patterns = []
        is_agc = any(f.endswith(".agc") for f in self.files)
        has_interrupts = False
        has_fixed_point = False

        for filepath in self.files[:50]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read().upper()

                if "INHINT" in content or "RELINT" in content or "INTERRUPT" in content:
                    has_interrupts = True
                if "DEC" in content or "2DEC" in content or "COMP-3" in content:
                    has_fixed_point = True
            except (OSError, UnicodeDecodeError):
                continue

        if is_agc:
            patterns.append("Apollo Guidance Computer (AGC)")
            patterns.append("15-bit Word + Sign Bit Architecture")
        if has_interrupts:
            patterns.append("Interrupt-Driven Execution")
        if has_fixed_point:
            patterns.append("Fixed-Point Arithmetic")
        if len(self.files) > 5:
            patterns.append("Multi-Module Assembly")

        self.architectural_patterns = patterns
        return patterns

    def find_dependencies(self) -> list[str]:
        """Find assembly dependencies: external calls and includes."""
        deps = set()

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        # TC (Transfer Control) = subroutine calls in AGC
                        for match in re.finditer(r"\bTC\s+(\w+)", line, re.IGNORECASE):
                            deps.add(f"TC:{match.group(1)}")
                        # Include/copy
                        for match in re.finditer(r"\bINCLUDE\s+['\"]?(\w+)", line, re.IGNORECASE):
                            deps.add(f"INCLUDE:{match.group(1)}")
            except (OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)[:100]
        return self.dependencies
