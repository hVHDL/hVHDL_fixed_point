#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

sos_filter_library = VU.add_library("sos_filter_library")
sos_filter_library.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")
sos_filter_library.add_source_files(ROOT / "multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
sos_filter_library.add_source_files(ROOT / "multiplier/multiplier_base_types_18bit_pkg.vhd") 
sos_filter_library.add_source_files(ROOT / "multiplier/multiplier_pkg.vhd") 
sos_filter_library.add_source_files(ROOT / "sos_filter/sos_filter_pkg.vhd")
sos_filter_library.add_source_files(ROOT / "sos_filter/dsp_sos_filter_pkg.vhd")

sos_filter_library.add_source_files(ROOT / "testbenches/multiply_add/fixed_point_dsp_pkg.vhd")
sos_filter_library.add_source_files(ROOT / "testbenches/sos_filter/sos_filter_tb.vhd")
sos_filter_library.add_source_files(ROOT / "testbenches/sos_filter/serial_sos_tb.vhd")
sos_filter_library.add_source_files(ROOT / "testbenches/sos_filter/ram_sos_tb.vhd")

fixed_point_library = VU.add_library("fixed_point_library")
fixed_point_library.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")
fixed_point_library.add_source_files(ROOT / "multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
fixed_point_library.add_source_files(ROOT / "multiplier/multiplier_base_types_18bit_pkg.vhd") 
fixed_point_library.add_source_files(ROOT / "multiplier/multiplier_pkg.vhd") 
fixed_point_library.add_source_files(ROOT / "sos_filter/sos_filter_pkg.vhd")
fixed_point_library.add_source_files(ROOT / "testbenches/multiply_add/fixed_point_dsp_pkg.vhd")
fixed_point_library.add_source_files(ROOT / "testbenches/multiply_add/multiply_add_tb.vhd")

mathlib = VU.add_library("math_library_18x18")

mathlib.add_source_files(ROOT / "multiplier/configuration/multiply_with_2_input_and_output_registers_pkg.vhd")
mathlib.add_source_files(ROOT / "multiplier" /"multiplier_base_types_18bit_pkg.vhd") 
mathlib.add_source_files(ROOT / "multiplier" /"multiplier_pkg.vhd") 

mathlib.add_source_files(ROOT / "pi_controller/pi_controller_pkg.vhd")

mathlib.add_source_files(ROOT / "division" / "division_pkg.vhd") 
mathlib.add_source_files(ROOT / "division" / "division_pkg_body.vhd") 
mathlib.add_source_files(ROOT / "division" / "division_internal_pkg.vhd") 

mathlib.add_source_files(ROOT / "sincos/sincos_pkg.vhd")
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd")
mathlib.add_source_files(ROOT / "coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd") 
mathlib.add_source_files(ROOT / "coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd") 


mathlib22 = VU.add_library("math_library_22x22")
mathlib22.add_source_files(ROOT / "multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
mathlib22.add_source_files(ROOT / "multiplier" /"multiplier_base_types_22bit_pkg.vhd") 
mathlib22.add_source_files(ROOT / "multiplier" /"multiplier_pkg.vhd") 
mathlib22.add_source_files(ROOT / "division" / "division_pkg.vhd") 
mathlib22.add_source_files(ROOT / "division" / "division_pkg_body.vhd") 
mathlib22.add_source_files(ROOT / "division" / "division_internal_pkg.vhd") 

mathlib26 = VU.add_library("math_library_26x26")
mathlib26.add_source_files(ROOT / "multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
mathlib26.add_source_files(ROOT / "multiplier" /"multiplier_base_types_26bit_pkg.vhd") 
mathlib26.add_source_files(ROOT / "multiplier" /"multiplier_pkg.vhd") 
mathlib26.add_source_files(ROOT / "division" / "division_pkg.vhd") 
mathlib26.add_source_files(ROOT / "division" / "division_pkg_body.vhd") 
mathlib26.add_source_files(ROOT / "division" / "division_internal_pkg.vhd") 


mathlib26.add_source_files(ROOT / "first_order_filter/first_order_filter_pkg.vhd")

mathlib.add_source_files(ROOT / "testbenches/pi_controller/tb_pi_control.vhd")
mathlib.add_source_files(ROOT / "testbenches/pi_controller/pi_with_feedforward_tb.vhd")

mathlib.add_source_files(ROOT / "testbenches/sincos_simulation/tb_sincos.vhd")
mathlib.add_source_files(ROOT / "testbenches/multiplier_simulation/tb_multiplier.vhd")
mathlib.add_source_files(ROOT / "testbenches/abc_to_ab_transform_simulation/tb_abc_to_ab_transform.vhd")
mathlib.add_source_files(ROOT / "testbenches/ab_to_dq_simulation/tb_ab_to_dq_transforms.vhd")
mathlib.add_source_files(ROOT / "testbenches/division_simulation/tb_integer_division.vhd")

mathlib.add_source_files(ROOT / "fixed_point_scaling/fixed_point_scaling_pkg.vhd")
mathlib.add_source_files(ROOT / "square_root/fixed_isqrt_pkg.vhd")
mathlib.add_source_files(ROOT / "square_root/fixed_sqrt_pkg.vhd")
mathlib.add_source_files(ROOT / "testbenches/square_root/test_square_root_radix_tb.vhd")

mathlib22.add_source_files(ROOT / "testbenches/multiplier_simulation/tb_multiplier.vhd")
mathlib22.add_source_files(ROOT / "testbenches/division_simulation/tb_integer_division.vhd")

mathlib26.add_source_files(ROOT / "testbenches/multiplier_simulation/tb_multiplier.vhd")
mathlib26.add_source_files(ROOT / "testbenches/division_simulation/tb_integer_division.vhd")
mathlib26.add_source_files(ROOT / "testbenches/first_order_filter_simulation/tb_first_order_filter.vhd")

mathlib.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")

mathlib22.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")

mathlib26.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")

mathlib26.add_source_files(ROOT / "square_root/fixed_isqrt_pkg.vhd")
mathlib26.add_source_files(ROOT / "testbenches/square_root/fixed_inv_square_root_tb.vhd")

mathlib26.add_source_files(ROOT / "testbenches/multiplier_simulation/tb_multiplier_result_radix.vhd")

# VU.set_sim_option("nvc.sim_flags", ["-w"])
VU.main()
