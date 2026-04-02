"""C# code analyzer using regex-based class/namespace extraction."""

import re
from pathlib import Path

from analysis_engine.analyzers.base_analyzer import BaseAnalyzer


class CSharpAnalyzer(BaseAnalyzer):
    """Analyzer for C# codebases."""

    LANGUAGE = "C#"
    FILE_EXTENSIONS = (".cs",)

    def _is_comment(self, line: str) -> bool:
        return line.startswith("//") or line.startswith("*") or line.startswith("///")

    def analyze_structure(self) -> dict:
        """Extract namespaces, classes, interfaces, and methods."""
        namespaces = set()
        classes = []
        interfaces = []
        methods = []
        properties = []

        namespace_pattern = re.compile(r"namespace\s+([\w.]+)")
        class_pattern = re.compile(
            r"(?:public|private|internal|protected)?\s*(?:abstract|sealed|static|partial)?\s*class\s+(\w+)"
        )
        interface_pattern = re.compile(
            r"(?:public|internal)?\s*interface\s+(I\w+)"
        )
        method_pattern = re.compile(
            r"(?:public|private|protected|internal)\s+(?:static\s+)?(?:virtual\s+)?(?:override\s+)?(?:async\s+)?"
            r"(?:Task<?)?(\w+>?)\s+(\w+)\s*\("
        )
        property_pattern = re.compile(
            r"(?:public|private|protected)\s+\w+\s+(\w+)\s*\{\s*get"
        )

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                for match in namespace_pattern.finditer(content):
                    namespaces.add(match.group(1))
                for match in class_pattern.finditer(content):
                    classes.append(match.group(1))
                for match in interface_pattern.finditer(content):
                    interfaces.append(match.group(1))
                for match in method_pattern.finditer(content):
                    methods.append(match.group(2))
                for match in property_pattern.finditer(content):
                    properties.append(match.group(1))
            except (OSError, UnicodeDecodeError):
                continue

        return {
            "namespaces": len(namespaces),
            "classes": len(classes),
            "interfaces": len(interfaces),
            "methods": len(methods),
            "properties": len(properties),
        }

    def detect_patterns(self) -> list[str]:
        """Detect C#/.NET architectural patterns."""
        patterns = []
        all_content = ""

        for filepath in self.files[:100]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    all_content += f.read() + "\n"
            except (OSError, UnicodeDecodeError):
                continue

        if re.search(r"using\s+Microsoft\.AspNetCore", all_content):
            patterns.append("ASP.NET Core")
        if re.search(r"using\s+System\.Web\.Mvc", all_content):
            patterns.append("ASP.NET MVC")
        if re.search(r"DbContext|DbSet", all_content):
            patterns.append("Entity Framework")
        if re.search(r"\[ApiController\]|\[HttpGet\]|\[HttpPost\]", all_content):
            patterns.append("Web API Controllers")
        if re.search(r"IServiceCollection|AddScoped|AddTransient|AddSingleton", all_content):
            patterns.append("Dependency Injection Container")
        if re.search(r"IRepository|Repository<", all_content):
            patterns.append("Repository Pattern")
        if re.search(r"LINQ|\.Where\(|\.Select\(|\.OrderBy\(", all_content):
            patterns.append("LINQ Queries")

        # Check for project files
        if list(self.system_path.rglob("*.csproj")):
            patterns.append("MSBuild/csproj")
        if list(self.system_path.rglob("*.sln")):
            patterns.append("Visual Studio Solution")

        self.architectural_patterns = patterns
        return patterns

    def find_dependencies(self) -> list[str]:
        """Find C# dependencies from using statements and csproj files."""
        deps = set()

        # Check using statements
        for filepath in self.files[:200]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        match = re.match(r"using\s+([\w.]+);", line.strip())
                        if match:
                            ns = match.group(1)
                            top = ns.split(".")[0]
                            if top not in ("System", "Microsoft"):
                                deps.add(ns.split(".")[0] + "." + ns.split(".")[1] if "." in ns else ns)
            except (OSError, UnicodeDecodeError):
                continue

        # Check csproj files for PackageReference
        for csproj in self.system_path.rglob("*.csproj"):
            try:
                with open(csproj, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                for match in re.finditer(
                    r'<PackageReference\s+Include="([\w.]+)"', content
                ):
                    deps.add(match.group(1))
            except (OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)[:100]
        return self.dependencies
