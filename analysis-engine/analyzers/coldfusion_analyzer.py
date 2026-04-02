"""ColdFusion code analyzer for tag-based component detection."""

import re
from pathlib import Path

from analysis_engine.analyzers.base_analyzer import BaseAnalyzer


class ColdFusionAnalyzer(BaseAnalyzer):
    """Analyzer for ColdFusion codebases."""

    LANGUAGE = "ColdFusion"
    FILE_EXTENSIONS = (".cfm", ".cfc", ".cfml")

    def _is_comment(self, line: str) -> bool:
        return line.strip().startswith("<!---") or line.strip().startswith("//")

    def analyze_structure(self) -> dict:
        """Extract ColdFusion components, functions, and tag usage."""
        components = []
        functions = []
        cfqueries = 0
        cfincludes = set()
        custom_tags = set()
        scopes_used = set()

        component_pattern = re.compile(r"<cfcomponent\b", re.IGNORECASE)
        function_pattern = re.compile(
            r"<cffunction\s+name=['\"](\w+)['\"]", re.IGNORECASE
        )
        query_pattern = re.compile(r"<cfquery\b", re.IGNORECASE)
        include_pattern = re.compile(
            r"<cfinclude\s+template=['\"]([^'\"]+)['\"]", re.IGNORECASE
        )
        custom_tag_pattern = re.compile(r"<cf_(\w+)", re.IGNORECASE)
        scope_pattern = re.compile(
            r"\b(APPLICATION|SESSION|REQUEST|SERVER|VARIABLES|FORM|URL|CGI)\.", re.IGNORECASE
        )
        script_function_pattern = re.compile(
            r"(?:public|private|remote)?\s*(?:\w+\s+)?function\s+(\w+)\s*\(", re.IGNORECASE
        )

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                if component_pattern.search(content):
                    components.append(filepath)

                for match in function_pattern.finditer(content):
                    functions.append(match.group(1))

                for match in script_function_pattern.finditer(content):
                    functions.append(match.group(1))

                cfqueries += len(query_pattern.findall(content))

                for match in include_pattern.finditer(content):
                    cfincludes.add(match.group(1))

                for match in custom_tag_pattern.finditer(content):
                    custom_tags.add(match.group(1))

                for match in scope_pattern.finditer(content):
                    scopes_used.add(match.group(1).upper())
            except (OSError, UnicodeDecodeError):
                continue

        return {
            "components": len(components),
            "functions": len(set(functions)),
            "queries": cfqueries,
            "includes": len(cfincludes),
            "custom_tags": sorted(custom_tags),
            "scopes_used": sorted(scopes_used),
        }

    def detect_patterns(self) -> list[str]:
        """Detect ColdFusion architectural patterns."""
        patterns = []
        has_orm = False
        has_mvc = False
        has_ajax = False
        has_web_services = False

        for filepath in self.files[:100]:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()

                if re.search(r"<cfcomponent\s+.*persistent", content, re.IGNORECASE):
                    has_orm = True
                if re.search(r"controller|model|view", filepath, re.IGNORECASE):
                    has_mvc = True
                if re.search(r"<cfajaxproxy|cfsprydataset", content, re.IGNORECASE):
                    has_ajax = True
                if re.search(r"<cffunction.*access=['\"]remote['\"]", content, re.IGNORECASE):
                    has_web_services = True
            except (OSError, UnicodeDecodeError):
                continue

        if has_orm:
            patterns.append("ColdFusion ORM")
        if has_mvc:
            patterns.append("MVC Architecture")
        if has_ajax:
            patterns.append("AJAX Integration")
        if has_web_services:
            patterns.append("Remote Web Services")
        if any(f.endswith(".cfc") for f in self.files):
            patterns.append("ColdFusion Components (CFC)")
        if any(f.endswith(".cfm") for f in self.files):
            patterns.append("Tag-Based Templates (CFM)")

        self.architectural_patterns = patterns
        return patterns

    def find_dependencies(self) -> list[str]:
        """Find ColdFusion dependencies: includes, custom tags, component calls."""
        deps = set()

        for filepath in self.files:
            try:
                with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        for match in re.finditer(
                            r"<cfinclude\s+template=['\"]([^'\"]+)['\"]",
                            line,
                            re.IGNORECASE,
                        ):
                            deps.add(f"INCLUDE:{match.group(1)}")
                        for match in re.finditer(
                            r"createObject\(['\"]component['\"],\s*['\"](\w+)['\"]",
                            line,
                            re.IGNORECASE,
                        ):
                            deps.add(f"COMPONENT:{match.group(1)}")
                        for match in re.finditer(r"<cf_(\w+)", line, re.IGNORECASE):
                            deps.add(f"CUSTOMTAG:{match.group(1)}")
            except (OSError, UnicodeDecodeError):
                continue

        self.dependencies = sorted(deps)[:100]
        return self.dependencies
