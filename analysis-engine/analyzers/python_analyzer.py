"""Python code analyzer using the ast module for complexity and import graph analysis."""

import ast
import re
from pathlib import Path

from analyzers.base_analyzer import BaseAnalyzer


class PythonAnalyzer(BaseAnalyzer):
    """Analyzer for Python codebases."""

    LANGUAGE = "Python"
    FILE_EXTENSIONS = (".py",)

    def _is_comment(self, line: str) -> bool:
        return line.startswith("#")

    def analyze_structure(self) -> dict:
        """Extract classes, functions, and imports using AST."""
        classes = []
        functions = []
        imports = set()
        decorators = set()

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    source = f.read()

                tree = ast.parse(source, filename=filepath)

                for node in ast.walk(tree):
                    if isinstance(node, ast.ClassDef):
                        classes.append(node.name)
                    elif isinstance(node, ast.FunctionDef):
                        functions.append(node.name)
                        for dec in node.decorator_list:
                            if isinstance(dec, ast.Name):
                                decorators.add(dec.id)
                            elif isinstance(dec, ast.Attribute):
                                decorators.add(dec.attr)
                    elif isinstance(node, ast.Import):
                        for alias in node.names:
                            imports.add(alias.name.split(".")[0])
                    elif isinstance(node, ast.ImportFrom):
                        if node.module:
                            imports.add(node.module.split(".")[0])
            except (SyntaxError, OSError, UnicodeDecodeError):
                continue

        return {
            "classes": len(classes),
            "functions": len(functions),
            "unique_imports": len(imports),
            "decorators_used": sorted(decorators),
        }

    def detect_patterns(self) -> list[str]:
        """Detect Python architectural patterns."""
        patterns = []
        all_imports = set()
        has_decorators = set()

        for filepath in self.files[:200]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                if "django" in content.lower():
                    all_imports.add("django")
                if "flask" in content.lower():
                    all_imports.add("flask")
                if "fastapi" in content.lower():
                    all_imports.add("fastapi")

                if re.search(r"class\s+\w+\(models\.Model\)", content):
                    patterns.append("Django ORM")
                if re.search(r"@app\.route|@blueprint\.route", content):
                    has_decorators.add("flask_routes")
                if re.search(r"class\s+\w+Admin", content):
                    has_decorators.add("django_admin")
            except (OSError, UnicodeDecodeError):
                continue

        if "django" in all_imports:
            patterns.append("Django Framework")
        if "flask" in all_imports:
            patterns.append("Flask Framework")
        if "fastapi" in all_imports:
            patterns.append("FastAPI Framework")
        if "flask_routes" in has_decorators:
            patterns.append("Flask Routing")
        if "django_admin" in has_decorators:
            patterns.append("Django Admin")

        # Check for setup files
        if (self.system_path / "setup.py").exists():
            patterns.append("setuptools packaging")
        if (self.system_path / "pyproject.toml").exists():
            patterns.append("PEP 517 packaging")
        if (self.system_path / "requirements.txt").exists():
            patterns.append("pip requirements")

        self.architectural_patterns = list(set(patterns))
        return self.architectural_patterns

    def find_dependencies(self) -> list[str]:
        """Find Python dependencies from imports and requirements files."""
        deps = set()

        # Check requirements.txt
        req_files = list(self.system_path.rglob("requirements*.txt"))
        for req_file in req_files:
            try:
                with open(req_file, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and not line.startswith("-"):
                            pkg = re.split(r"[>=<!\[]", line)[0].strip()
                            if pkg:
                                deps.add(pkg)
            except (OSError, UnicodeDecodeError):
                continue

        # Check setup.py / pyproject.toml
        setup_py = self.system_path / "setup.py"
        if setup_py.exists():
            try:
                with open(setup_py, "r", encoding="utf-8") as f:
                    content = f.read()
                for match in re.finditer(r"['\"]([a-zA-Z][\w-]+)['\"]", content):
                    deps.add(match.group(1))
            except (OSError, UnicodeDecodeError):
                pass

        # Also collect from import statements
        for filepath in self.files[:200]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    source = f.read()
                tree = ast.parse(source)
                for node in ast.walk(tree):
                    if isinstance(node, ast.Import):
                        for alias in node.names:
                            top = alias.name.split(".")[0]
                            if top not in ("os", "sys", "re", "json", "math", "datetime", "collections", "typing", "pathlib", "io", "abc", "functools", "itertools", "copy", "logging", "unittest", "subprocess", "shutil", "tempfile", "hashlib", "base64", "urllib", "http"):
                                deps.add(top)
                    elif isinstance(node, ast.ImportFrom):
                        if node.module:
                            top = node.module.split(".")[0]
                            if top not in ("os", "sys", "re", "json", "math", "datetime", "collections", "typing", "pathlib", "io", "abc", "functools", "itertools", "copy", "logging", "unittest", "subprocess", "shutil", "tempfile", "hashlib", "base64", "urllib", "http"):
                                deps.add(top)
            except (SyntaxError, OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)[:100]
        return self.dependencies
