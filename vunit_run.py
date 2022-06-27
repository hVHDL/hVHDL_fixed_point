#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

mathlib = VU.add_library("math_library_18x18")
mathlib.add_source_files(ROOT / "hVHDL_memory_library/fpga_ram" / "*.vhd") 

mathlib.add_source_files(ROOT / "multiplier" /"multiplier_base_types_18bit_pkg.vhd") 
mathlib.add_source_files(ROOT / "multiplier" /"multiplier_pkg.vhd") 

mathlib.add_source_files(ROOT / "division" / "*.vhd") 
mathlib.add_source_files(ROOT / "division/division_simulation/tb_integer_division.vhd") 

mathlib.add_source_files(ROOT / "sincos/sincos_pkg.vhd") 
mathlib.add_source_files(ROOT / "sincos/lut_generator_functions/sine_lut_generator_pkg.vhd") 
mathlib.add_source_files(ROOT / "sincos/lut_sine_pkg.vhd") 
mathlib.add_source_files(ROOT / "sincos/sincos_simulation/tb_sincos.vhd")
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 

mathlib.add_source_files(ROOT / "multiplier/simulation/tb_multiplier.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_simulation/tb_abc_to_ab_transform.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/ab_to_dq_transform/ab_to_dq_simulation/tb_ab_to_dq_transforms.vhd")

mathlib22 = VU.add_library("math_library_22x22")
mathlib22.add_source_files(ROOT / "multiplier" /"multiplier_base_types_22bit_pkg.vhd") 
mathlib22.add_source_files(ROOT / "multiplier" /"multiplier_pkg.vhd") 
mathlib22.add_source_files(ROOT / "multiplier/simulation/tb_multiplier.vhd") 

mathlib26 = VU.add_library("math_library_26x26")
mathlib26.add_source_files(ROOT / "multiplier" /"multiplier_base_types_26bit_pkg.vhd") 
mathlib26.add_source_files(ROOT / "multiplier" /"multiplier_pkg.vhd") 
mathlib26.add_source_files(ROOT / "multiplier/simulation/tb_multiplier.vhd") 
mathlib26.add_source_files(ROOT / "first_order_filter/first_order_filter_pkg.vhd")
mathlib26.add_source_files(ROOT / "first_order_filter/first_order_filter_simulation" / "*.vhd")

mathlib26.add_source_files(ROOT / "example" / "*.vhd")

mathlib.add_source_files(ROOT / "fixed_point_interface_tests" / "*.vhd") 

VU.main()
