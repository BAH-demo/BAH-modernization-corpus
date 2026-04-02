# Language-specific analyzers
from analyzers.java_analyzer import JavaAnalyzer
from analyzers.python_analyzer import PythonAnalyzer
from analyzers.csharp_analyzer import CSharpAnalyzer
from analyzers.cobol_analyzer import CobolAnalyzer
from analyzers.fortran_analyzer import FortranAnalyzer
from analyzers.assembly_analyzer import AssemblyAnalyzer
from analyzers.coldfusion_analyzer import ColdFusionAnalyzer

ANALYZERS = {
    "Java": JavaAnalyzer,
    "Python": PythonAnalyzer,
    "C#": CSharpAnalyzer,
    "COBOL": CobolAnalyzer,
    "Fortran": FortranAnalyzer,
    "Assembly": AssemblyAnalyzer,
    "ColdFusion": ColdFusionAnalyzer,
}

__all__ = [
    "JavaAnalyzer",
    "PythonAnalyzer",
    "CSharpAnalyzer",
    "CobolAnalyzer",
    "FortranAnalyzer",
    "AssemblyAnalyzer",
    "ColdFusionAnalyzer",
    "ANALYZERS",
]
