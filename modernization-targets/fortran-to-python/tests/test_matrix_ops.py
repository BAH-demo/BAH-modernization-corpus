"""Tests for matrix operations - validate against known matrix results."""

import numpy as np
import pytest

from nastran_modern.matrix_ops import MatrixOperations


class TestMatrixMultiply:
    """Test matrix multiplication against known results."""

    def test_identity_multiply(self):
        """Multiplying by identity should return the original matrix."""
        ops = MatrixOperations()
        a = np.array([[1, 2], [3, 4]], dtype=np.float64)
        identity = np.eye(2, dtype=np.float64)
        result = ops.multiply(a, identity)
        np.testing.assert_allclose(result, a, atol=1e-15)

    def test_3x3_multiply(self):
        """Test 3x3 matrix multiplication with known result."""
        a = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]], dtype=np.float64)
        b = np.array([[9, 8, 7], [6, 5, 4], [3, 2, 1]], dtype=np.float64)
        expected = np.array(
            [[30, 24, 18], [84, 69, 54], [138, 114, 90]], dtype=np.float64
        )
        result = MatrixOperations.multiply(a, b)
        np.testing.assert_allclose(result, expected, atol=1e-10)

    def test_rectangular_multiply(self):
        """Test multiplication of non-square matrices."""
        a = np.array([[1, 2, 3], [4, 5, 6]], dtype=np.float64)  # 2x3
        b = np.array([[7, 8], [9, 10], [11, 12]], dtype=np.float64)  # 3x2
        expected = np.array([[58, 64], [139, 154]], dtype=np.float64)  # 2x2
        result = MatrixOperations.multiply(a, b)
        np.testing.assert_allclose(result, expected, atol=1e-10)

    def test_large_matrix_multiply(self):
        """Test multiplication of larger matrices."""
        n = 50
        np.random.seed(42)
        a = np.random.randn(n, n)
        b = np.random.randn(n, n)
        result = MatrixOperations.multiply(a, b)
        expected = a @ b
        np.testing.assert_allclose(result, expected, atol=1e-10)


class TestTranspose:
    """Test matrix transpose."""

    def test_square_transpose(self):
        a = np.array([[1, 2], [3, 4]], dtype=np.float64)
        expected = np.array([[1, 3], [2, 4]], dtype=np.float64)
        result = MatrixOperations.transpose(a)
        np.testing.assert_allclose(result, expected, atol=1e-15)

    def test_rectangular_transpose(self):
        a = np.array([[1, 2, 3], [4, 5, 6]], dtype=np.float64)
        result = MatrixOperations.transpose(a)
        assert result.shape == (3, 2)
        np.testing.assert_allclose(result[0, 1], 4.0, atol=1e-15)

    def test_double_transpose_identity(self):
        """Transposing twice should return original."""
        a = np.array([[1, 2, 3], [4, 5, 6]], dtype=np.float64)
        result = MatrixOperations.transpose(MatrixOperations.transpose(a))
        np.testing.assert_allclose(result, a, atol=1e-15)


class TestDeterminant:
    """Test matrix determinant."""

    def test_2x2_determinant(self):
        a = np.array([[3, 8], [4, 6]], dtype=np.float64)
        result = MatrixOperations.determinant(a)
        assert abs(result - (-14.0)) < 1e-10

    def test_3x3_determinant(self):
        a = np.array([[6, 1, 1], [4, -2, 5], [2, 8, 7]], dtype=np.float64)
        result = MatrixOperations.determinant(a)
        assert abs(result - (-306.0)) < 1e-10

    def test_identity_determinant(self):
        result = MatrixOperations.determinant(np.eye(5))
        assert abs(result - 1.0) < 1e-10

    def test_singular_determinant(self):
        a = np.array([[1, 2], [2, 4]], dtype=np.float64)
        result = MatrixOperations.determinant(a)
        assert abs(result) < 1e-10


class TestInverse:
    """Test matrix inverse."""

    def test_2x2_inverse(self):
        a = np.array([[4, 7], [2, 6]], dtype=np.float64)
        a_inv = MatrixOperations.inverse(a)
        product = MatrixOperations.multiply(a, a_inv)
        np.testing.assert_allclose(product, np.eye(2), atol=1e-10)

    def test_3x3_inverse(self):
        a = np.array([[1, 2, 3], [0, 1, 4], [5, 6, 0]], dtype=np.float64)
        a_inv = MatrixOperations.inverse(a)
        product = MatrixOperations.multiply(a, a_inv)
        np.testing.assert_allclose(product, np.eye(3), atol=1e-10)

    def test_singular_raises(self):
        a = np.array([[1, 2], [2, 4]], dtype=np.float64)
        with pytest.raises(np.linalg.LinAlgError):
            MatrixOperations.inverse(a)


class TestEigenvalues:
    """Test eigenvalue computation."""

    def test_symmetric_eigenvalues(self):
        """Test eigenvalues of a known symmetric matrix."""
        a = np.array([[2, -1], [-1, 2]], dtype=np.float64)
        eigenvalues, eigenvectors = MatrixOperations.eigenvalues(a)
        expected_eigenvalues = np.array([1.0, 3.0])
        np.testing.assert_allclose(
            np.sort(eigenvalues), expected_eigenvalues, atol=1e-10
        )

    def test_identity_eigenvalues(self):
        eigenvalues, _ = MatrixOperations.eigenvalues(np.eye(3))
        np.testing.assert_allclose(eigenvalues, np.ones(3), atol=1e-10)

    def test_eigenvector_orthogonality(self):
        """Eigenvectors of symmetric matrix should be orthogonal."""
        a = np.array([[4, 1], [1, 3]], dtype=np.float64)
        _, eigenvectors = MatrixOperations.eigenvalues(a)
        product = eigenvectors.T @ eigenvectors
        np.testing.assert_allclose(product, np.eye(2), atol=1e-10)


class TestMatrixProperties:
    """Test matrix property checks."""

    def test_symmetric_true(self):
        a = np.array([[1, 2, 3], [2, 5, 6], [3, 6, 9]], dtype=np.float64)
        assert MatrixOperations.symmetric_check(a)

    def test_symmetric_false(self):
        a = np.array([[1, 2], [3, 4]], dtype=np.float64)
        assert not MatrixOperations.symmetric_check(a)

    def test_positive_definite_true(self):
        a = np.array([[2, -1], [-1, 2]], dtype=np.float64)
        assert MatrixOperations.positive_definite_check(a)

    def test_positive_definite_false(self):
        a = np.array([[-1, 0], [0, -1]], dtype=np.float64)
        assert not MatrixOperations.positive_definite_check(a)


class TestAddSubtract:
    """Test matrix addition and subtraction."""

    def test_add(self):
        a = np.array([[1, 2], [3, 4]], dtype=np.float64)
        b = np.array([[5, 6], [7, 8]], dtype=np.float64)
        expected = np.array([[6, 8], [10, 12]], dtype=np.float64)
        result = MatrixOperations.add(a, b)
        np.testing.assert_allclose(result, expected, atol=1e-15)

    def test_subtract(self):
        a = np.array([[5, 6], [7, 8]], dtype=np.float64)
        b = np.array([[1, 2], [3, 4]], dtype=np.float64)
        expected = np.array([[4, 4], [4, 4]], dtype=np.float64)
        result = MatrixOperations.subtract(a, b)
        np.testing.assert_allclose(result, expected, atol=1e-15)

    def test_dimension_mismatch(self):
        a = np.array([[1, 2], [3, 4]], dtype=np.float64)
        b = np.array([[1, 2, 3]], dtype=np.float64)
        with pytest.raises(ValueError):
            MatrixOperations.add(a, b)
