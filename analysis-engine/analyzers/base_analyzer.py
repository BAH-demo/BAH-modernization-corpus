"""Base analyzer class for all language-specific analyzers."""

import json
import os
import re
import subprocess
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional


class BaseAnalyzer(ABC):
    """Base class for language-specific code analyzers."""

    LANGUAGE: str = ""
    FILE_EXTENSIONS: tuple[str, ...] = ()

    def __init__(self, system_path: str, system_name: str):
        self.system_path = Path(system_path)
        self.system_name = system_name
        self.files: list[str] = []
        self.loc: int = 0
        self.complexity_scores: list[float] = []
        self.dependencies: list[str] = []
        self.dead_code_candidates: list[str] = []
        self.architectural_patterns: list[str] = []

    def discover_files(self) -> list[str]:
        """Find all files matching the language extensions."""
        self.files = []
        for ext in self.FILE_EXTENSIONS:
            for path in self.system_path.rglob(f"*{ext}"):
                if not any(
                    part.startswith(".")
                    for part in path.relative_to(self.system_path).parts
                ):
                    self.files.append(str(path))
        return self.files

    def count_loc(self) -> int:
        """Count lines of code (excluding blank lines and comments)."""
        total = 0
        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        stripped = line.strip()
                        if stripped and not self._is_comment(stripped):
                            total += 1
            except (OSError, UnicodeDecodeError):
                continue
        self.loc = total
        return total

    def _is_comment(self, line: str) -> bool:
        """Check if a line is a comment. Override per language."""
        return line.startswith("//") or line.startswith("#") or line.startswith("*")

    def run_lizard(self) -> list[dict]:
        """Run lizard complexity analysis if available."""
        results = []
        try:
            import lizard

            for filepath in self.files:
                try:
                    analysis = lizard.analyze_file(filepath)
                    for func in analysis.function_list:
                        results.append(
                            {
                                "name": func.name,
                                "file": filepath,
                                "complexity": func.cyclomatic_complexity,
                                "nloc": func.nloc,
                                "parameters": func.length,
                            }
                        )
                        self.complexity_scores.append(func.cyclomatic_complexity)
                except Exception:
                    continue
        except ImportError:
            pass
        return results

    @abstractmethod
    def analyze_structure(self) -> dict:
        """Analyze language-specific structure. Returns structured data."""
        ...

    @abstractmethod
    def detect_patterns(self) -> list[str]:
        """Detect architectural patterns in the codebase."""
        ...

    @abstractmethod
    def find_dependencies(self) -> list[str]:
        """Find external dependencies."""
        ...

    def find_dead_code_candidates(self) -> list[str]:
        """Basic dead code detection - functions/methods defined but never referenced."""
        return self.dead_code_candidates

    def analyze(self) -> dict:
        """Run full analysis and return JSON-serializable result."""
        self.discover_files()
        self.count_loc()
        self.run_lizard()
        self.analyze_structure()
        self.detect_patterns()
        self.find_dependencies()
        self.find_dead_code_candidates()

        complexity_avg = (
            sum(self.complexity_scores) / len(self.complexity_scores)
            if self.complexity_scores
            else 0.0
        )
        complexity_max = (
            max(self.complexity_scores) if self.complexity_scores else 0.0
        )

        return {
            "system": self.system_name,
            "language": self.LANGUAGE,
            "loc": self.loc,
            "files": len(self.files),
            "complexity_avg": round(complexity_avg, 2),
            "complexity_max": round(complexity_max, 2),
            "dependencies": self.dependencies,
            "dead_code_candidates": self.dead_code_candidates[:50],
            "architectural_patterns": self.architectural_patterns,
        }
