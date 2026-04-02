"""
Input deck parsing - replacing Fortran FORMAT statements and card-image I/O.

Original Fortran I/O used fixed-format card images:
    READ(5, 100) CARD
    100 FORMAT(A80)
    READ(CARD, 200) ID, TYPE, VAL1, VAL2
    200 FORMAT(I8, A8, 2F16.0)

This module provides a modern parser for NASTRAN-style bulk data.
"""

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import TextIO, Union


@dataclass
class GridPoint:
    """Grid point (node) definition - replaces GRID bulk data card."""

    grid_id: int
    x: float
    y: float
    z: float
    cp: int = 0  # Coordinate system ID
    cd: int = 0  # Displacement coordinate system

    def __str__(self) -> str:
        return f"GRID({self.grid_id}): ({self.x}, {self.y}, {self.z})"


@dataclass
class MaterialProperty:
    """Material property - replaces MAT1 bulk data card."""

    mid: int
    youngs_modulus: float
    poissons_ratio: float = 0.3
    density: float = 0.0
    thermal_expansion: float = 0.0
    shear_modulus: float = 0.0

    def __post_init__(self) -> None:
        if self.shear_modulus == 0.0 and self.poissons_ratio > 0:
            self.shear_modulus = self.youngs_modulus / (
                2.0 * (1.0 + self.poissons_ratio)
            )


@dataclass
class ElementDefinition:
    """Element connectivity - replaces CBAR/CTRIA3/etc cards."""

    eid: int
    element_type: str
    pid: int
    nodes: list[int] = field(default_factory=list)


@dataclass
class LoadCase:
    """Load definition - replaces FORCE/MOMENT cards."""

    sid: int
    grid_id: int
    direction: list[float] = field(default_factory=list)
    magnitude: float = 0.0


@dataclass
class NastranModel:
    """Complete NASTRAN model parsed from input deck."""

    title: str = ""
    grid_points: dict[int, GridPoint] = field(default_factory=dict)
    materials: dict[int, MaterialProperty] = field(default_factory=dict)
    elements: dict[int, ElementDefinition] = field(default_factory=dict)
    loads: list[LoadCase] = field(default_factory=list)
    constraints: dict[int, list[int]] = field(default_factory=dict)


class NastranInputParser:
    """Parser for NASTRAN-style input decks.

    Replaces Fortran FORMAT-based card reading:
        Original Fortran:
            SUBROUTINE XREAD(IUNIT, CARD, NCARD)
            READ(IUNIT, '(A80)', END=999) CARD
            CALL XFIELD(CARD, 1, FIELD1)
            CALL XFIELD(CARD, 2, FIELD2)
    """

    def __init__(self) -> None:
        self.model = NastranModel()

    def parse_file(self, filepath: Union[str, Path]) -> NastranModel:
        """Parse a NASTRAN bulk data file."""
        filepath = Path(filepath)
        with open(filepath, "r") as f:
            return self.parse_stream(f)

    def parse_stream(self, stream: TextIO) -> NastranModel:
        """Parse NASTRAN input from a text stream."""
        self.model = NastranModel()

        for line in stream:
            line = line.rstrip()
            if not line or line.startswith("$"):
                continue

            fields = self._parse_free_field(line)
            if not fields:
                continue

            card_type = fields[0].upper().strip()

            if card_type == "GRID":
                self._parse_grid(fields)
            elif card_type == "MAT1":
                self._parse_mat1(fields)
            elif card_type in ("CBAR", "CROD", "CTRIA3", "CQUAD4"):
                self._parse_element(fields, card_type)
            elif card_type == "FORCE":
                self._parse_force(fields)
            elif card_type == "SPC":
                self._parse_spc(fields)
            elif card_type == "TITLE":
                self.model.title = " ".join(fields[1:])

        return self.model

    def _parse_free_field(self, line: str) -> list[str]:
        """Parse free-field format (comma or space separated).

        Replaces Fortran fixed-field parsing:
            FIELD1 = CARD(1:8)
            FIELD2 = CARD(9:16)
            ...
        """
        if "," in line:
            return [f.strip() for f in line.split(",")]
        else:
            # Fixed field: 8-character fields
            fields = []
            # First field might be the card name
            parts = line.split()
            if parts:
                return parts
            return fields

    def _safe_float(self, s: str, default: float = 0.0) -> float:
        """Safely parse float, handling Fortran-style notation."""
        s = s.strip()
        if not s:
            return default
        # Handle Fortran-style D exponent: 1.0D+03 -> 1.0E+03
        s = s.replace("D", "E").replace("d", "e")
        try:
            return float(s)
        except ValueError:
            return default

    def _safe_int(self, s: str, default: int = 0) -> int:
        """Safely parse integer."""
        s = s.strip()
        if not s:
            return default
        try:
            return int(float(s))
        except ValueError:
            return default

    def _parse_grid(self, fields: list[str]) -> None:
        """Parse GRID card: GRID, ID, CP, X, Y, Z, CD"""
        if len(fields) < 5:
            return
        gid = self._safe_int(fields[1])
        cp = self._safe_int(fields[2])
        x = self._safe_float(fields[3])
        y = self._safe_float(fields[4])
        z = self._safe_float(fields[5]) if len(fields) > 5 else 0.0
        cd = self._safe_int(fields[6]) if len(fields) > 6 else 0
        self.model.grid_points[gid] = GridPoint(gid, x, y, z, cp, cd)

    def _parse_mat1(self, fields: list[str]) -> None:
        """Parse MAT1 card: MAT1, MID, E, G, NU, RHO"""
        if len(fields) < 3:
            return
        mid = self._safe_int(fields[1])
        e = self._safe_float(fields[2])
        g = self._safe_float(fields[3]) if len(fields) > 3 else 0.0
        nu = self._safe_float(fields[4]) if len(fields) > 4 else 0.3
        rho = self._safe_float(fields[5]) if len(fields) > 5 else 0.0
        self.model.materials[mid] = MaterialProperty(mid, e, nu, rho, shear_modulus=g)

    def _parse_element(self, fields: list[str], etype: str) -> None:
        """Parse element connectivity card."""
        if len(fields) < 4:
            return
        eid = self._safe_int(fields[1])
        pid = self._safe_int(fields[2])
        nodes = [self._safe_int(f) for f in fields[3:] if f.strip()]
        self.model.elements[eid] = ElementDefinition(eid, etype, pid, nodes)

    def _parse_force(self, fields: list[str]) -> None:
        """Parse FORCE card: FORCE, SID, G, CID, F, N1, N2, N3"""
        if len(fields) < 6:
            return
        sid = self._safe_int(fields[1])
        gid = self._safe_int(fields[2])
        mag = self._safe_float(fields[4])
        direction = [
            self._safe_float(fields[i]) if len(fields) > i else 0.0
            for i in range(5, 8)
        ]
        self.model.loads.append(LoadCase(sid, gid, direction, mag))

    def _parse_spc(self, fields: list[str]) -> None:
        """Parse SPC card: SPC, SID, G, C, D"""
        if len(fields) < 4:
            return
        gid = self._safe_int(fields[2])
        components = [int(c) for c in fields[3].strip() if c.isdigit()]
        self.model.constraints[gid] = components
