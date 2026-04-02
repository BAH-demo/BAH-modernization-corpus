"""
Finite element stiffness matrices - replacing NASTRAN-95 element routines.

Original Fortran element subroutines:
    SUBROUTINE KBAR(EK, ...) - Bar element
    SUBROUTINE KTRIA(EK, ...) - Triangular element
    SUBROUTINE KQUAD(EK, ...) - Quadrilateral element

Each computed element stiffness matrices using COMMON blocks for material
properties and geometric data.
"""

import numpy as np
from numpy.typing import NDArray


class BarElement:
    """1D bar/truss element - replacing NASTRAN CBAR/CROD.

    Original Fortran:
        SUBROUTINE KBAR(EK, E, A, L)
        COMMON /BARPRM/ E, A, L, IZ, IY
    """

    def __init__(
        self,
        youngs_modulus: float,
        area: float,
        length: float,
        moment_of_inertia_z: float = 0.0,
        moment_of_inertia_y: float = 0.0,
    ) -> None:
        self.E = youngs_modulus
        self.A = area
        self.L = length
        self.Iz = moment_of_inertia_z
        self.Iy = moment_of_inertia_y

    def stiffness_matrix_axial(self) -> NDArray[np.float64]:
        """Axial stiffness matrix for bar element (2x2).

        Replaces:
            EK(1,1) = E*A/L
            EK(1,2) = -E*A/L
            EK(2,1) = -E*A/L
            EK(2,2) = E*A/L
        """
        k = self.E * self.A / self.L
        return np.array([[k, -k], [-k, k]], dtype=np.float64)

    def stiffness_matrix_beam(self) -> NDArray[np.float64]:
        """Full beam stiffness matrix (4x4) including bending.

        Replaces Fortran KBEAM subroutine with Euler-Bernoulli beam theory.
        DOFs: [v1, theta1, v2, theta2]
        """
        L = self.L
        EI = self.E * self.Iz

        k = EI / (L ** 3)
        return np.array(
            [
                [12 * k, 6 * k * L, -12 * k, 6 * k * L],
                [6 * k * L, 4 * k * L ** 2, -6 * k * L, 2 * k * L ** 2],
                [-12 * k, -6 * k * L, 12 * k, -6 * k * L],
                [6 * k * L, 2 * k * L ** 2, -6 * k * L, 4 * k * L ** 2],
            ],
            dtype=np.float64,
        )

    def mass_matrix_consistent(self) -> NDArray[np.float64]:
        """Consistent mass matrix for bar element.

        Replaces:
            SUBROUTINE MBAR(EM, RHO, A, L)
        """
        rho_A_L = self.A * self.L  # Assume unit density for now
        return (rho_A_L / 6.0) * np.array(
            [[2, 1], [1, 2]], dtype=np.float64
        )


class TriangularElement:
    """2D triangular (CST) element - replacing NASTRAN CTRIA3.

    Original Fortran:
        SUBROUTINE KTRIA(EK, XY, T, E, NU, NTYPE)
        COMMON /TRIPRM/ T, E, NU
    """

    def __init__(
        self,
        nodes: NDArray[np.float64],
        thickness: float,
        youngs_modulus: float,
        poissons_ratio: float,
        plane_stress: bool = True,
    ) -> None:
        """
        Args:
            nodes: 3x2 array of nodal coordinates [[x1,y1], [x2,y2], [x3,y3]]
            thickness: Element thickness
            youngs_modulus: Young's modulus E
            poissons_ratio: Poisson's ratio nu
            plane_stress: True for plane stress, False for plane strain
        """
        self.nodes = np.asarray(nodes, dtype=np.float64)
        self.t = thickness
        self.E = youngs_modulus
        self.nu = poissons_ratio
        self.plane_stress = plane_stress

    def area(self) -> float:
        """Calculate element area using cross product formula.

        Replaces Fortran:
            AREA = 0.5D0 * ABS((X2-X1)*(Y3-Y1) - (X3-X1)*(Y2-Y1))
        """
        x1, y1 = self.nodes[0]
        x2, y2 = self.nodes[1]
        x3, y3 = self.nodes[2]
        return 0.5 * abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1))

    def b_matrix(self) -> NDArray[np.float64]:
        """Strain-displacement matrix B (3x6).

        Replaces Fortran computation of shape function derivatives.
        """
        x1, y1 = self.nodes[0]
        x2, y2 = self.nodes[1]
        x3, y3 = self.nodes[2]
        A = self.area()
        inv2A = 1.0 / (2.0 * A)

        b1 = (y2 - y3) * inv2A
        b2 = (y3 - y1) * inv2A
        b3 = (y1 - y2) * inv2A
        c1 = (x3 - x2) * inv2A
        c2 = (x1 - x3) * inv2A
        c3 = (x2 - x1) * inv2A

        return np.array(
            [
                [b1, 0, b2, 0, b3, 0],
                [0, c1, 0, c2, 0, c3],
                [c1, b1, c2, b2, c3, b3],
            ],
            dtype=np.float64,
        )

    def d_matrix(self) -> NDArray[np.float64]:
        """Material constitutive matrix D (3x3).

        Replaces Fortran:
            IF (NTYPE .EQ. 1) THEN  ! Plane stress
                D(1,1) = E/(1-NU**2)
            ELSE                     ! Plane strain
                D(1,1) = E*(1-NU)/((1+NU)*(1-2*NU))
        """
        E = self.E
        nu = self.nu

        if self.plane_stress:
            factor = E / (1.0 - nu ** 2)
            return factor * np.array(
                [[1, nu, 0], [nu, 1, 0], [0, 0, (1 - nu) / 2]],
                dtype=np.float64,
            )
        else:
            factor = E / ((1 + nu) * (1 - 2 * nu))
            return factor * np.array(
                [
                    [1 - nu, nu, 0],
                    [nu, 1 - nu, 0],
                    [0, 0, (1 - 2 * nu) / 2],
                ],
                dtype=np.float64,
            )

    def stiffness_matrix(self) -> NDArray[np.float64]:
        """Element stiffness matrix K = t * A * B^T * D * B (6x6).

        Replaces:
            SUBROUTINE KTRIA(EK, ...)
            EK = T * AREA * MATMUL(TRANSPOSE(B), MATMUL(D, B))
        """
        B = self.b_matrix()
        D = self.d_matrix()
        A = self.area()
        return self.t * A * (B.T @ D @ B)


class SpringElement:
    """Simple spring element for testing."""

    def __init__(self, stiffness: float) -> None:
        self.k = stiffness

    def stiffness_matrix(self) -> NDArray[np.float64]:
        return np.array([[self.k, -self.k], [-self.k, self.k]], dtype=np.float64)
