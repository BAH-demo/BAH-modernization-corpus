"""
Linear system solvers - replacing NASTRAN-95 equation solvers.

Original Fortran solvers:
    SUBROUTINE DECOMP(A, N, IPVT, INFO) - LU decomposition
    SUBROUTINE SOLVE(A, N, IPVT, B) - Forward/back substitution
    SUBROUTINE BAND(A, N, ML, MU, B) - Banded solver

NASTRAN-95 used custom Fortran routines with COMMON blocks for solver state.
This module uses scipy.linalg for robust, well-tested implementations.
"""

import numpy as np
import scipy.linalg
from numpy.typing import NDArray


class LinearSolver:
    """Linear system solver replacing NASTRAN-95 Fortran solver subroutines.

    Replaces COMMON /SOLVER/ shared state with instance attributes.
    """

    def __init__(self) -> None:
        self.last_condition_number: float = 0.0
        self.last_residual: float = 0.0

    def solve(
        self,
        a: NDArray[np.float64],
        b: NDArray[np.float64],
    ) -> NDArray[np.float64]:
        """Solve Ax = b using LU decomposition.

        Replaces Fortran:
            CALL DECOMP(A, N, IPVT, INFO)
            IF (INFO .NE. 0) GO TO 999
            CALL SOLVE(A, N, IPVT, B)

        Args:
            a: Coefficient matrix (n x n)
            b: Right-hand side vector (n,) or matrix (n x m)

        Returns:
            Solution vector x

        Raises:
            np.linalg.LinAlgError: If matrix is singular
        """
        a = np.asarray(a, dtype=np.float64)
        b = np.asarray(b, dtype=np.float64)

        self.last_condition_number = float(np.linalg.cond(a))
        x = np.linalg.solve(a, b)
        self.last_residual = float(np.linalg.norm(a @ x - b))
        return x

    def solve_symmetric(
        self,
        a: NDArray[np.float64],
        b: NDArray[np.float64],
    ) -> NDArray[np.float64]:
        """Solve symmetric positive definite system using Cholesky decomposition.

        Replaces Fortran:
            SUBROUTINE CHOLES(A, N, B, X)
            - Used for stiffness matrix systems where K is SPD

        More efficient than general LU for structural analysis.
        """
        a = np.asarray(a, dtype=np.float64)
        b = np.asarray(b, dtype=np.float64)

        cho = scipy.linalg.cho_factor(a)
        x = scipy.linalg.cho_solve(cho, b)
        self.last_residual = float(np.linalg.norm(a @ x - b))
        return x

    def solve_banded(
        self,
        a_banded: NDArray[np.float64],
        b: NDArray[np.float64],
        lower_bandwidth: int,
        upper_bandwidth: int,
    ) -> NDArray[np.float64]:
        """Solve banded system - replacing NASTRAN BAND subroutine.

        NASTRAN stored matrices in banded format to save memory.
        Original Fortran:
            SUBROUTINE BAND(A, N, ML, MU, B)
            DO I=1,N
              ...bandwidth-limited elimination...
        """
        ab = np.asarray(a_banded, dtype=np.float64)
        b = np.asarray(b, dtype=np.float64)

        return scipy.linalg.solve_banded(
            (lower_bandwidth, upper_bandwidth), ab, b
        )

    def eigensolve(
        self,
        k: NDArray[np.float64],
        m: NDArray[np.float64],
        num_modes: int = 6,
    ) -> tuple[NDArray[np.float64], NDArray[np.float64]]:
        """Solve generalized eigenvalue problem K*phi = lambda*M*phi.

        Replaces Fortran:
            SUBROUTINE EIGVAL(K, M, N, NMOD, EVAL, EVEC)
            - Used for natural frequency / mode shape analysis

        Args:
            k: Stiffness matrix
            m: Mass matrix
            num_modes: Number of eigenvalues/vectors to compute

        Returns:
            (eigenvalues, eigenvectors) tuple
        """
        k = np.asarray(k, dtype=np.float64)
        m = np.asarray(m, dtype=np.float64)

        eigenvalues, eigenvectors = scipy.linalg.eigh(
            k, m, subset_by_index=[0, min(num_modes - 1, k.shape[0] - 1)]
        )
        return eigenvalues, eigenvectors

    @staticmethod
    def lu_decompose(
        a: NDArray[np.float64],
    ) -> tuple[NDArray[np.float64], NDArray[np.float64], NDArray[np.float64]]:
        """LU decomposition replacing Fortran DECOMP.

        Returns (P, L, U) such that A = P @ L @ U
        """
        return scipy.linalg.lu(np.asarray(a, dtype=np.float64))

    @staticmethod
    def cholesky(a: NDArray[np.float64]) -> NDArray[np.float64]:
        """Cholesky decomposition for SPD matrices.

        Replaces:
            SUBROUTINE CHOLES(A, N, L)
            DO I=1,N
              L(I,I) = SQRT(A(I,I) - SUM)
        """
        return np.linalg.cholesky(np.asarray(a, dtype=np.float64))
