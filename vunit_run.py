#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()
VU = VUnit.from_argv(vhdl_standard="93")

mathlib = VU.add_library("math_library")
mathlib.add_source_files(ROOT / "multiplier/multiplier_pkg.vhd") 
mathlib.add_source_files(ROOT / "sincos/sincos_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 

mathlib.add_source_files(ROOT / "multiplier/simulation/tb_multiplier.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_simulation/tb_abc_to_ab_transform.vhd") 

VU.main()
