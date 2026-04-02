"""
Core matrix operations - replacing NASTRAN-95 Fortran COMMON block shared state.

Original Fortran used COMMON blocks to share matrix data between subroutines:
    COMMON /MATDAT/ A(MAXSIZ,MAXSIZ), B(MAXSIZ,MAXSIZ), C(MAXSIZ,MAXSIZ)
    COMMON /MATPRM/ NROWS, NCOLS, NBAND

This module uses a MatrixOperations class with instance attributes instead.
"""

import numpy as np
from numpy.typing import NDArray


class MatrixOperations:
    """Core matrix operations replacing NASTRAN-95 matrix manipulation subroutines.

    Replaces Fortran COMMON /MATDAT/ shared state with class attributes.
    """

    def __init__(self) -> None:
        self._cache: dict[str, NDArray[np.float64]] = {}

    @staticmethod
    def multiply(
        a: NDArray[np.float64], b: NDArray[np.float64]
    ) -> NDArray[np.float64]:
        """Matrix multiplication replacing Fortran GMMATS subroutine.

        Original Fortran:
            SUBROUTINE GMMATS(A, AR, AC, AT, B, BR, BC, BT, C)
            DO 30 I=1,AR
              DO 20 J=1,BC
                SUM = 0.0D0
                DO 10 K=1,AC
                  SUM = SUM + A(I,K)*B(K,J)
            10  CONTINUE
                C(I,J) = SUM
            20 CONTINUE
            30 CONTINUE
        """
        return np.matmul(a, b)

    @staticmethod
    def transpose(a: NDArray[np.float64]) -> NDArray[np.float64]:
        """Matrix transpose replacing Fortran TRANSP subroutine.

        Original Fortran:
            SUBROUTINE TRANSP(A, AT, NR, NC)
            DO 20 I=1,NR
              DO 10 J=1,NC
                AT(J,I) = A(I,J)
            10 CONTINUE
            20 CONTINUE
        """
        return np.transpose(a)

    @staticmethod
    def add(
        a: NDArray[np.float64], b: NDArray[np.float64]
    ) -> NDArray[np.float64]:
        """Matrix addition replacing Fortran MATADD subroutine."""
        if a.shape != b.shape:
            raise ValueError(
                f"Matrix dimensions must match: {a.shape} vs {b.shape}"
            )
        return a + b

    @staticmethod
    def subtract(
        a: NDArray[np.float64], b: NDArray[np.float64]
    ) -> NDArray[np.float64]:
        """Matrix subtraction."""
        if a.shape != b.shape:
            raise ValueError(
                f"Matrix dimensions must match: {a.shape} vs {b.shape}"
            )
        return a - b

    @staticmethod
    def scale(
        a: NDArray[np.float64], scalar: float
    ) -> NDArray[np.float64]:
        """Scalar-matrix multiplication."""
        return scalar * a

    @staticmethod
    def determinant(a: NDArray[np.float64]) -> float:
        """Matrix determinant replacing Fortran DET subroutine.

        Original Fortran used LU decomposition manually:
            SUBROUTINE DET(A, N, DETER)
            CALL DECOMP(A, N, ...)
            DETER = 1.0D0
            DO 10 I=1,N
              DETER = DETER * A(I,I)
            10 CONTINUE
        """
        return float(np.linalg.det(a))

    @staticmethod
    def inverse(a: NDArray[np.float64]) -> NDArray[np.float64]:
        """Matrix inverse replacing Fortran INVERS subroutine.

        Original Fortran used Gauss-Jordan elimination:
            SUBROUTINE INVERS(A, AINV, N, DET)
        """
        return np.linalg.inv(a)

    @staticmethod
    def eigenvalues(
        a: NDArray[np.float64],
    ) -> tuple[NDArray[np.float64], NDArray[np.float64]]:
        """Eigenvalue computation replacing Fortran EIGVAL subroutine.

        Returns (eigenvalues, eigenvectors).

        Original Fortran used Householder tridiagonalization + QR iteration:
            SUBROUTINE EIGVAL(A, N, EVAL, EVEC)
        """
        eigenvalues, eigenvectors = np.linalg.eigh(a)
        return eigenvalues, eigenvectors

    @staticmethod
    def norm(a: NDArray[np.float64], order: int = 2) -> float:
        """Matrix or vector norm."""
        return float(np.linalg.norm(a, ord=order))

    @staticmethod
    def identity(n: int) -> NDArray[np.float64]:
        """Create identity matrix."""
        return np.eye(n, dtype=np.float64)

    @staticmethod
    def zeros(rows: int, cols: int) -> NDArray[np.float64]:
        """Create zero matrix."""
        return np.zeros((rows, cols), dtype=np.float64)

    @staticmethod
    def symmetric_check(a: NDArray[np.float64], tol: float = 1e-10) -> bool:
        """Check if matrix is symmetric within tolerance."""
        return bool(np.allclose(a, a.T, atol=tol))

    @staticmethod
    def positive_definite_check(a: NDArray[np.float64]) -> bool:
        """Check if matrix is positive definite (required for stiffness matrices)."""
        try:
            np.linalg.cholesky(a)
            return True
        except np.linalg.LinAlgError:
            return False
