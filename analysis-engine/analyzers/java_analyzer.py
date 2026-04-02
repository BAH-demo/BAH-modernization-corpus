"""Java code analyzer using regex-based parsing for class/method extraction."""

import re
from pathlib import Path

from analyzers.base_analyzer import BaseAnalyzer


class JavaAnalyzer(BaseAnalyzer):
    """Analyzer for Java codebases."""

    LANGUAGE = "Java"
    FILE_EXTENSIONS = (".java",)

    def _is_comment(self, line: str) -> bool:
        return (
            line.startswith("//")
            or line.startswith("*")
            or line.startswith("/*")
        )

    def analyze_structure(self) -> dict:
        """Extract classes, interfaces, methods, and inheritance."""
        classes = []
        interfaces = []
        methods = []
        imports_set = set()

        class_pattern = re.compile(
            r"(?:public|private|protected)?\s*(?:abstract|final)?\s*class\s+(\w+)"
        )
        interface_pattern = re.compile(
            r"(?:public)?\s*interface\s+(\w+)"
        )
        method_pattern = re.compile(
            r"(?:public|private|protected)\s+(?:static\s+)?(?:final\s+)?"
            r"(?:synchronized\s+)?(?:\w+(?:<[^>]+>)?)\s+(\w+)\s*\("
        )
        import_pattern = re.compile(r"import\s+([\w.]+);")
        extends_pattern = re.compile(r"class\s+\w+\s+extends\s+(\w+)")
        implements_pattern = re.compile(r"implements\s+([\w,\s]+)")

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                for match in class_pattern.finditer(content):
                    classes.append(match.group(1))
                for match in interface_pattern.finditer(content):
                    interfaces.append(match.group(1))
                for match in method_pattern.finditer(content):
                    methods.append(match.group(1))
                for match in import_pattern.finditer(content):
                    imports_set.add(match.group(1))
            except (OSError, UnicodeDecodeError):
                continue

        return {
            "classes": len(classes),
            "interfaces": len(interfaces),
            "methods": len(methods),
            "unique_imports": len(imports_set),
        }

    def detect_patterns(self) -> list[str]:
        """Detect Java architectural patterns."""
        patterns = []
        all_content = ""

        for filepath in self.files[:100]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    all_content += f.read() + "\n"
            except (OSError, UnicodeDecodeError):
                continue

        if re.search(r"@(Controller|RestController|RequestMapping)", all_content):
            patterns.append("Spring MVC/REST")
        if re.search(r"@(Entity|Table|Column)", all_content):
            patterns.append("JPA/Hibernate ORM")
        if re.search(r"@(Service|Component|Autowired|Inject)", all_content):
            patterns.append("Dependency Injection")
        if re.search(r"@(EJB|Stateless|Stateful)", all_content):
            patterns.append("EJB")
        if re.search(r"extends\s+HttpServlet", all_content):
            patterns.append("Servlet")
        if re.search(r"(Factory|Builder|Singleton|Observer)Pattern", all_content, re.IGNORECASE):
            patterns.append("GoF Design Patterns")
        if re.search(r"implements\s+\w*(DAO|Repository)", all_content):
            patterns.append("DAO/Repository Pattern")
        if re.search(r"@(Transactional|Transaction)", all_content):
            patterns.append("Transaction Management")
        if re.search(r"(pom\.xml|build\.gradle)", " ".join(self.files)):
            patterns.append("Maven/Gradle Build")

        self.architectural_patterns = patterns
        return patterns

    def find_dependencies(self) -> list[str]:
        """Find Java dependencies from import statements and build files."""
        deps = set()

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        match = re.match(r"import\s+([\w.]+);", line.strip())
                        if match:
                            parts = match.group(1).split(".")
                            if len(parts) >= 2 and parts[0] != "java":
                                deps.add(".".join(parts[:3]))
            except (OSError, UnicodeDecodeError):
                continue

        # Check pom.xml for dependencies
        pom_files = list(self.system_path.rglob("pom.xml"))
        for pom in pom_files[:5]:
            try:
                with open(pom, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                for match in re.finditer(
                    r"<groupId>([\w.]+)</groupId>\s*<artifactId>([\w.-]+)</artifactId>",
                    content,
                ):
                    deps.add(f"{match.group(1)}:{match.group(2)}")
            except (OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)[:100]
        return self.dependencies

    def find_dead_code_candidates(self) -> list[str]:
        """Find potentially unused private methods."""
        private_methods = {}
        method_refs = set()

        private_pattern = re.compile(r"private\s+\w+\s+(\w+)\s*\(")

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                for match in private_pattern.finditer(content):
                    method_name = match.group(1)
                    if method_name not in ("main", "toString", "hashCode", "equals"):
                        private_methods[method_name] = filepath
            except (OSError, UnicodeDecodeError):
                continue

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                for method_name in private_methods:
                    if content.count(method_name) > 1:
                        method_refs.add(method_name)
            except (OSError, UnicodeDecodeError):
                continue

        self.dead_code_candidates = [
            f"{name} in {path}"
            for name, path in private_methods.items()
            if name not in method_refs
        ][:50]
        return self.dead_code_candidates
