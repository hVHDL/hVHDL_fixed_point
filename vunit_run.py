#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit

# ROOT
ROOT = Path(__file__).resolve().parent
VU = VUnit.from_argv()

sqrt_lib = VU.add_library("sqrt_lib")
sqrt_lib.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")
sqrt_lib.add_source_files(ROOT / "multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd")
sqrt_lib.add_source_files(ROOT / "multiplier/multiplier_base_types_for_sqrt_pkg.vhd")
sqrt_lib.add_source_files(ROOT / "multiplier/multiplier_pkg.vhd") 

sqrt_lib.add_source_files(ROOT / "fixed_point_scaling/fixed_point_scaling_pkg.vhd")

sqrt_lib.add_source_files(ROOT / "square_root/fixed_isqrt_pkg.vhd")
sqrt_lib.add_source_files(ROOT / "square_root/fixed_sqrt_pkg.vhd")

sqrt_lib.add_source_files(ROOT / "testbenches/fixed_point_scaling/fixed_point_scaling_tb.vhd")
sqrt_lib.add_source_files(ROOT / "testbenches/square_root/isqrt_scaling_tb.vhd")

sqrt_lib.add_source_files(ROOT / "testbenches/square_root/initia_values_tb.vhd")
sqrt_lib.add_source_files(ROOT / "testbenches/square_root/isqrt_tb.vhd")
sqrt_lib.add_source_files(ROOT / "testbenches/square_root/test_square_root_radix_tb.vhd")

vhdl2008 = VU.add_library("vhdl2008")
vhdl2008.add_source_files(ROOT / "multiplier/multiplier_generic_pkg.vhd")
vhdl2008.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")

vhdl2008.add_source_files(ROOT / "division/division_generic_pkg.vhd")
vhdl2008.add_source_files(ROOT / "division/division_generic_pkg_body.vhd")

vhdl2008.add_source_files(ROOT / "pi_controller/pi_controller_generic_pkg.vhd")

vhdl2008.add_source_files(ROOT / "testbenches/multiplier_simulation/multiplier_generic_tb.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/division_simulation/division_generic_tb.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/division_simulation/tb_integer_division_generic.vhd")

vhdl2008.add_source_files(ROOT / "testbenches/division_simulation/reciproc_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/division_simulation/zero_shifter_tb.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/division_simulation/sequential_zero_shift_tb.vhd")

vhdl2008.add_source_files(ROOT / "submodules/hVHDL_memory_library/vhdl2008/dp_ram_w_configurable_recrods.vhd")
vhdl2008.add_source_files(ROOT / "submodules/hVHDL_memory_library/vhdl2008/arch_sim_dp_ram_w_configurable_records.vhd")

vhdl2008.add_source_files(ROOT / "adc_scaler/adc_scaler.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/adc_scaler/adc_scaler_tb.vhd")

vhdl2008.add_source_files(ROOT / "lut_interpolation/lut_interpolation_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/lut_interpolation/lut_interpolation_tb.vhd")

# these use initial values of signals as initial values of other signals, fix them
# mathlib.add_source_files(ROOT / "testbenches/adder/adder_tb.vhd")
# mathlib26.add_source_files(ROOT / "testbenches/division_simulation/division_tb.vhd")
# mathlib.add_source_files(ROOT / "testbenches/division_simulation/tb_divider_internal_pkg.vhd")
# mathlib.add_source_files(ROOT / "testbenches/real_to_fixed/real_to_fixed_tb.vhd")
# mathlib22.add_source_files(ROOT / "testbenches/real_to_fixed/real_to_fixed_tb.vhd")
# mathlib26.add_source_files(ROOT / "testbenches/real_to_fixed/real_to_fixed_tb.vhd")
# sqrt_lib.add_source_files(ROOT / "testbenches/square_root/fixed_inv_square_root_tb.vhd")
# sqrt_lib.add_source_files(ROOT / "testbenches/division_simulation/goldsmith_tb.vhd")
 
# VU.set_sim_option("nvc.sim_flags", ["-w"])
VU.main()
