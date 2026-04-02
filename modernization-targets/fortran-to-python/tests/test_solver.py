"""Tests for linear system solvers - verify to 1e-10 tolerance."""

import numpy as np
import pytest

from nastran_modern.solver import LinearSolver


class TestLinearSolve:
    """Test general linear system solving."""

    def test_simple_2x2(self):
        """Solve simple 2x2 system."""
        solver = LinearSolver()
        A = np.array([[2, 1], [5, 7]], dtype=np.float64)
        b = np.array([11, 13], dtype=np.float64)
        x = solver.solve(A, b)
        expected = np.array([7.111111111, -3.222222222], dtype=np.float64)
        np.testing.assert_allclose(x, expected, atol=1e-8)

    def test_3x3_known_solution(self):
        """Solve 3x3 system with known exact solution [2, 3, -1]."""
        solver = LinearSolver()
        A = np.array(
            [[2, 1, -1], [-3, -1, 2], [-2, 1, 2]], dtype=np.float64
        )
        b = np.array([8, -11, -3], dtype=np.float64)
        x = solver.solve(A, b)
        expected = np.array([2.0, 3.0, -1.0])
        np.testing.assert_allclose(x, expected, atol=1e-10)

    def test_identity_system(self):
        """Solving with identity matrix should return RHS."""
        solver = LinearSolver()
        n = 10
        A = np.eye(n, dtype=np.float64)
        b = np.arange(1, n + 1, dtype=np.float64)
        x = solver.solve(A, b)
        np.testing.assert_allclose(x, b, atol=1e-10)

    def test_large_system(self):
        """Solve larger system and verify residual."""
        solver = LinearSolver()
        np.random.seed(42)
        n = 100
        A = np.random.randn(n, n)
        A = A + A.T + n * np.eye(n)  # Make diagonally dominant
        b = np.random.randn(n)
        x = solver.solve(A, b)

        # Verify Ax = b to high precision
        residual = np.linalg.norm(A @ x - b)
        assert residual < 1e-10

    def test_residual_tracking(self):
        """Solver should track residual."""
        solver = LinearSolver()
        A = np.array([[1, 0], [0, 1]], dtype=np.float64)
        b = np.array([3, 4], dtype=np.float64)
        solver.solve(A, b)
        assert solver.last_residual < 1e-10

    def test_condition_number_tracking(self):
        """Solver should track condition number."""
        solver = LinearSolver()
        A = np.array([[1, 0], [0, 1]], dtype=np.float64)
        b = np.array([1, 1], dtype=np.float64)
        solver.solve(A, b)
        assert abs(solver.last_condition_number - 1.0) < 1e-10

    def test_singular_matrix_raises(self):
        """Singular matrix should raise LinAlgError."""
        solver = LinearSolver()
        A = np.array([[1, 2], [2, 4]], dtype=np.float64)
        b = np.array([3, 6], dtype=np.float64)
        with pytest.raises(np.linalg.LinAlgError):
            solver.solve(A, b)

    def test_multiple_rhs(self):
        """Solve with multiple right-hand sides."""
        solver = LinearSolver()
        A = np.array([[2, 1], [1, 3]], dtype=np.float64)
        B = np.array([[5, 7], [7, 11]], dtype=np.float64)
        X = solver.solve(A, B)
        np.testing.assert_allclose(A @ X, B, atol=1e-10)


class TestSymmetricSolve:
    """Test Cholesky-based symmetric solver."""

    def test_spd_system(self):
        """Solve symmetric positive definite system."""
        solver = LinearSolver()
        A = np.array([[4, 2], [2, 3]], dtype=np.float64)
        b = np.array([1, 2], dtype=np.float64)
        x = solver.solve_symmetric(A, b)
        np.testing.assert_allclose(A @ x, b, atol=1e-10)

    def test_structural_system(self):
        """Solve a typical structural stiffness system K*u = F.

        A simple 2-spring system:
        k1=100, k2=200
        K = [100, -100; -100, 300]
        F = [10; 0]
        """
        solver = LinearSolver()
        K = np.array([[100, -100], [-100, 300]], dtype=np.float64)
        F = np.array([10, 0], dtype=np.float64)
        u = solver.solve_symmetric(K, F)

        # Verify
        np.testing.assert_allclose(K @ u, F, atol=1e-10)
        # Expected: u1 = 0.15, u2 = 0.05
        np.testing.assert_allclose(u, [0.15, 0.05], atol=1e-10)

    def test_large_spd_system(self):
        """Solve larger SPD system."""
        solver = LinearSolver()
        np.random.seed(42)
        n = 50
        L = np.random.randn(n, n)
        A = L @ L.T + n * np.eye(n)  # Guaranteed SPD
        b = np.random.randn(n)
        x = solver.solve_symmetric(A, b)
        np.testing.assert_allclose(A @ x, b, atol=1e-8)


class TestEigensolve:
    """Test generalized eigenvalue solver."""

    def test_simple_eigenvalue(self):
        """Test with known eigenvalues."""
        solver = LinearSolver()
        K = np.array([[2, -1], [-1, 2]], dtype=np.float64)
        M = np.eye(2, dtype=np.float64)
        eigenvalues, eigenvectors = solver.eigensolve(K, M, num_modes=2)
        np.testing.assert_allclose(
            np.sort(eigenvalues), [1.0, 3.0], atol=1e-10
        )

    def test_generalized_eigenvalue(self):
        """Test generalized eigenvalue K*phi = lambda*M*phi."""
        solver = LinearSolver()
        K = np.array([[6, -2], [-2, 4]], dtype=np.float64)
        M = np.array([[2, 0], [0, 1]], dtype=np.float64)
        eigenvalues, eigenvectors = solver.eigensolve(K, M, num_modes=2)

        # Verify K*phi = lambda*M*phi for each mode
        for i in range(len(eigenvalues)):
            lhs = K @ eigenvectors[:, i]
            rhs = eigenvalues[i] * M @ eigenvectors[:, i]
            np.testing.assert_allclose(lhs, rhs, atol=1e-10)


class TestLUDecomposition:
    """Test LU decomposition."""

    def test_lu_reconstruction(self):
        """A = P @ L @ U should hold."""
        A = np.array(
            [[2, 5, 8, 7], [5, 2, 2, 8], [7, 5, 6, 6], [5, 4, 4, 8]],
            dtype=np.float64,
        )
        P, L, U = LinearSolver.lu_decompose(A)
        reconstructed = P @ L @ U
        np.testing.assert_allclose(reconstructed, A, atol=1e-10)


class TestCholesky:
    """Test Cholesky decomposition."""

    def test_cholesky_reconstruction(self):
        """A = L @ L^T should hold for SPD matrix."""
        A = np.array([[4, 2], [2, 3]], dtype=np.float64)
        L = LinearSolver.cholesky(A)
        np.testing.assert_allclose(L @ L.T, A, atol=1e-10)

    def test_cholesky_lower_triangular(self):
        """Cholesky factor should be lower triangular."""
        A = np.array(
            [[4, 2, 1], [2, 5, 3], [1, 3, 6]], dtype=np.float64
        )
        L = LinearSolver.cholesky(A)
        # Upper triangle (excluding diagonal) should be zero
        assert np.allclose(L, np.tril(L))

    def test_non_spd_raises(self):
        """Non-SPD matrix should raise error."""
        A = np.array([[-1, 0], [0, -1]], dtype=np.float64)
        with pytest.raises(np.linalg.LinAlgError):
            LinearSolver.cholesky(A)
