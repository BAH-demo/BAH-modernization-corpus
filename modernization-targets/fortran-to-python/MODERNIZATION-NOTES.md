# Fortran → Python/NumPy Modernization Notes

## Source System
- **Name**: NASTRAN-95 (NASA Structural Analysis System)
- **Language**: Fortran 77 (fixed-format)
- **Source**: NASA nastran-95
- **LOC**: ~750K+ lines of Fortran

## Scope of Modernization

This modernization covers the core numerical kernel of NASTRAN, specifically:
- Matrix operations (assembly, manipulation, decomposition)
- Finite element formulations (bar, triangular elements)
- Linear system solvers (direct, iterative)
- Input deck parsing (bulk data format)

## COMMON Block → Class Mapping

| Fortran COMMON Block | Python Class | Purpose |
|---------------------|-------------|---------|
| COMMON /MATDAT/ | MatrixOperations | Matrix storage and operations |
| COMMON /MATPRM/ | MatrixOperations attributes | Matrix dimensions and parameters |
| COMMON /BARPRM/ | BarElement.__init__ | Bar element properties (E, A, L, I) |
| COMMON /TRIPRM/ | TriangularElement.__init__ | Triangle element properties (t, E, nu) |
| COMMON /SOLVER/ | LinearSolver.__init__ | Solver state and configuration |

### COMMON Block Issues Resolved

1. **Shared mutable state**: Fortran COMMON blocks create implicit coupling between subroutines.
   → Python classes encapsulate state, making data flow explicit.

2. **Naming collisions**: COMMON blocks share the same memory locations globally.
   → Python namespaces prevent name collisions.

3. **Size limitations**: COMMON block arrays had fixed compile-time sizes (MAXSIZ).
   → NumPy arrays are dynamically sized.

## EQUIVALENCE Handling

Fortran EQUIVALENCE statements alias memory locations, creating multiple views of the same data:

```fortran
REAL A(100), B(50,2)
EQUIVALENCE (A, B)
```

This was used in NASTRAN for memory efficiency. In Python:
- Replaced with explicit array views using `np.reshape()` or `np.ndarray.view()`
- Where EQUIVALENCE was used for type punning, replaced with explicit type conversion
- Where used for memory optimization, simply allocated separate arrays (memory is cheap now)

## Implicit Typing Resolution

Fortran 77 implicit typing (I-N integers, A-H/O-Z reals) was eliminated:

| Fortran Convention | Resolution |
|-------------------|------------|
| Variables I-N default INTEGER | Explicit `int` type annotations |
| Variables A-H, O-Z default REAL | Explicit `float` or `np.float64` type annotations |
| No IMPLICIT NONE in many routines | All Python variables explicitly typed |
| DOUBLE PRECISION declarations | `np.float64` consistently used |

## Subroutine → Method Mapping

| Fortran Subroutine | Python Method | Notes |
|-------------------|---------------|-------|
| GMMATS | MatrixOperations.multiply() | Uses np.matmul |
| TRANSP | MatrixOperations.transpose() | Uses np.transpose |
| DET | MatrixOperations.determinant() | Uses np.linalg.det |
| INVERS | MatrixOperations.inverse() | Uses np.linalg.inv |
| EIGVAL | MatrixOperations.eigenvalues() | Uses np.linalg.eigh |
| DECOMP | LinearSolver.lu_decompose() | Uses scipy.linalg.lu |
| SOLVE | LinearSolver.solve() | Uses np.linalg.solve |
| CHOLES | LinearSolver.cholesky() | Uses np.linalg.cholesky |
| KBAR | BarElement.stiffness_matrix_axial() | Direct formula |
| KBEAM | BarElement.stiffness_matrix_beam() | Euler-Bernoulli |
| KTRIA | TriangularElement.stiffness_matrix() | B^T * D * B formulation |

## Numerical Precision

- All floating-point operations use `np.float64` (64-bit IEEE 754)
- Matches Fortran DOUBLE PRECISION behavior
- Tests verify accuracy to 1e-10 tolerance
- Condition number tracking added for numerical stability monitoring

## What Was Simplified

1. **FORMAT statements**: Replaced with Python string formatting and standard I/O
2. **GO TO control flow**: Replaced with structured if/else, loops, and function calls
3. **DATA statements**: Replaced with Python default arguments and class attributes
4. **BLOCK DATA subprograms**: Replaced with module-level constants
5. **Fixed-format source**: Free-format Python eliminates column-sensitivity issues
6. **Manual memory management**: NumPy handles array allocation/deallocation

## Running the Tests

```bash
cd modernization-targets/fortran-to-python
pip install -e ".[test]"
pytest tests/ -v
```
