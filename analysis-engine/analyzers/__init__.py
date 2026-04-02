# Language-specific analyzers
from analysis_engine.analyzers.java_analyzer import JavaAnalyzer
from analysis_engine.analyzers.python_analyzer import PythonAnalyzer
from analysis_engine.analyzers.csharp_analyzer import CSharpAnalyzer
from analysis_engine.analyzers.cobol_analyzer import CobolAnalyzer
from analysis_engine.analyzers.fortran_analyzer import FortranAnalyzer
from analysis_engine.analyzers.assembly_analyzer import AssemblyAnalyzer
from analysis_engine.analyzers.coldfusion_analyzer import ColdFusionAnalyzer

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
