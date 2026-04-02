"""Tests for element stiffness matrices - verify against analytical solutions."""

import numpy as np
import pytest

from nastran_modern.element_library import BarElement, TriangularElement, SpringElement


class TestBarElement:
    """Test bar/truss element stiffness matrices."""

    def test_axial_stiffness_basic(self):
        """Verify axial stiffness matrix for known E, A, L."""
        bar = BarElement(youngs_modulus=200e9, area=0.01, length=1.0)
        K = bar.stiffness_matrix_axial()

        # k = EA/L = 200e9 * 0.01 / 1.0 = 2e9
        expected_k = 2e9
        expected = np.array(
            [[expected_k, -expected_k], [-expected_k, expected_k]],
            dtype=np.float64,
        )
        np.testing.assert_allclose(K, expected, rtol=1e-10)

    def test_axial_stiffness_symmetry(self):
        """Stiffness matrix must be symmetric."""
        bar = BarElement(youngs_modulus=70e9, area=0.005, length=2.0)
        K = bar.stiffness_matrix_axial()
        np.testing.assert_allclose(K, K.T, atol=1e-10)

    def test_axial_stiffness_singular(self):
        """Global stiffness matrix for single element should be singular."""
        bar = BarElement(youngs_modulus=200e9, area=0.01, length=1.0)
        K = bar.stiffness_matrix_axial()
        det = np.linalg.det(K)
        assert abs(det) < 1e-10  # Singular (rigid body mode)

    def test_axial_row_sum_zero(self):
        """Row sums should be zero (equilibrium condition)."""
        bar = BarElement(youngs_modulus=200e9, area=0.01, length=1.0)
        K = bar.stiffness_matrix_axial()
        row_sums = np.sum(K, axis=1)
        np.testing.assert_allclose(row_sums, np.zeros(2), atol=1e-10)

    def test_beam_stiffness_symmetry(self):
        """Beam stiffness matrix must be symmetric."""
        bar = BarElement(
            youngs_modulus=200e9,
            area=0.01,
            length=2.0,
            moment_of_inertia_z=1e-4,
        )
        K = bar.stiffness_matrix_beam()
        np.testing.assert_allclose(K, K.T, atol=1e-5)

    def test_beam_stiffness_size(self):
        """Beam stiffness matrix should be 4x4."""
        bar = BarElement(
            youngs_modulus=200e9,
            area=0.01,
            length=1.0,
            moment_of_inertia_z=1e-4,
        )
        K = bar.stiffness_matrix_beam()
        assert K.shape == (4, 4)

    def test_beam_stiffness_known_values(self):
        """Verify specific entries of beam stiffness matrix.

        For EI=1, L=1:
        K[0,0] = 12*EI/L^3 = 12
        K[1,1] = 4*EI/L = 4
        """
        bar = BarElement(
            youngs_modulus=1.0,
            area=1.0,
            length=1.0,
            moment_of_inertia_z=1.0,
        )
        K = bar.stiffness_matrix_beam()
        assert abs(K[0, 0] - 12.0) < 1e-10
        assert abs(K[1, 1] - 4.0) < 1e-10
        assert abs(K[0, 1] - 6.0) < 1e-10

    def test_mass_matrix_consistent(self):
        """Test consistent mass matrix."""
        bar = BarElement(youngs_modulus=200e9, area=0.01, length=1.0)
        M = bar.mass_matrix_consistent()
        assert M.shape == (2, 2)
        # Mass matrix should be symmetric
        np.testing.assert_allclose(M, M.T, atol=1e-15)
        # All entries should be positive
        assert np.all(M > 0)


class TestTriangularElement:
    """Test CST (Constant Strain Triangle) element."""

    def setup_method(self):
        """Set up a standard test triangle."""
        self.nodes = np.array(
            [[0, 0], [1, 0], [0, 1]], dtype=np.float64
        )
        self.element = TriangularElement(
            nodes=self.nodes,
            thickness=0.1,
            youngs_modulus=200e9,
            poissons_ratio=0.3,
        )

    def test_area_right_triangle(self):
        """Area of unit right triangle should be 0.5."""
        area = self.element.area()
        assert abs(area - 0.5) < 1e-10

    def test_area_equilateral(self):
        """Area of equilateral triangle with side 2."""
        nodes = np.array(
            [[0, 0], [2, 0], [1, np.sqrt(3)]], dtype=np.float64
        )
        element = TriangularElement(nodes, 0.1, 200e9, 0.3)
        expected_area = np.sqrt(3)  # side^2 * sqrt(3)/4 = 4*sqrt(3)/4
        assert abs(element.area() - expected_area) < 1e-10

    def test_b_matrix_shape(self):
        """B matrix should be 3x6 for CST element."""
        B = self.element.b_matrix()
        assert B.shape == (3, 6)

    def test_d_matrix_symmetry(self):
        """D matrix must be symmetric."""
        D = self.element.d_matrix()
        np.testing.assert_allclose(D, D.T, atol=1e-5)

    def test_d_matrix_positive_definite(self):
        """D matrix must be positive definite."""
        D = self.element.d_matrix()
        eigenvalues = np.linalg.eigvalsh(D)
        assert np.all(eigenvalues > 0)

    def test_stiffness_matrix_size(self):
        """Stiffness matrix should be 6x6 for CST."""
        K = self.element.stiffness_matrix()
        assert K.shape == (6, 6)

    def test_stiffness_matrix_symmetry(self):
        """Element stiffness matrix must be symmetric."""
        K = self.element.stiffness_matrix()
        np.testing.assert_allclose(K, K.T, atol=1e-5)

    def test_stiffness_matrix_positive_semidefinite(self):
        """Element stiffness matrix must be positive semi-definite."""
        K = self.element.stiffness_matrix()
        eigenvalues = np.linalg.eigvalsh(K)
        # Allow small negative eigenvalues due to numerical errors
        assert np.all(eigenvalues >= -1e-5 * np.max(np.abs(eigenvalues)))

    def test_plane_stress_vs_strain(self):
        """Plane stress and plane strain should give different results."""
        nodes = np.array([[0, 0], [1, 0], [0, 1]], dtype=np.float64)
        stress_elem = TriangularElement(nodes, 0.1, 200e9, 0.3, plane_stress=True)
        strain_elem = TriangularElement(nodes, 0.1, 200e9, 0.3, plane_stress=False)

        K_stress = stress_elem.stiffness_matrix()
        K_strain = strain_elem.stiffness_matrix()

        # They should be different
        assert not np.allclose(K_stress, K_strain)


class TestSpringElement:
    """Test simple spring element."""

    def test_spring_stiffness(self):
        spring = SpringElement(stiffness=1000.0)
        K = spring.stiffness_matrix()
        expected = np.array([[1000, -1000], [-1000, 1000]], dtype=np.float64)
        np.testing.assert_allclose(K, expected, atol=1e-10)

    def test_spring_symmetry(self):
        spring = SpringElement(stiffness=500.0)
        K = spring.stiffness_matrix()
        np.testing.assert_allclose(K, K.T, atol=1e-15)
