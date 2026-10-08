#!/usr/bin/env python3

from pathlib import Path
from vunit import VUnit, VUnitCLI

# ROOT
ROOT = Path(__file__).resolve().parent

cli = VUnitCLI()
cli.parser.add_argument(
    "--dump-arrays",
    nargs="?",
    const="",
    default=None,
    metavar="N",
    help="Enable waveform dump and pass --dump-arrays[=N] to nvc to include array signals in it",
)
args = cli.parse_args()

VU = VUnit.from_args(args)

# the fixed_dsp based math functions, the older vhdl2008 and vhdl1993 sources
# are in legacy/ with their own run scripts
vhdl2008 = VU.add_library("vhdl2008")
vhdl2008.add_source_files(ROOT / "real_to_fixed/real_to_fixed_pkg.vhd")

vhdl2008.add_source_files(ROOT / "submodules/hVHDL_memory_library/vhdl2008/dp_ram_w_configurable_recrods.vhd")
vhdl2008.add_source_files(ROOT / "submodules/hVHDL_memory_library/vhdl2008/arch_sim_dp_ram_w_configurable_records.vhd")

vhdl2008.add_source_files(ROOT / "lut_interpolation/lut_sine_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/lut_interpolation/lut_interpolation_tb.vhd")

vhdl2008.add_source_files(ROOT / "lut_interpolation/lut_reciprocal_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/lut_interpolation/lut_reciprocal_tb.vhd")

vhdl2008.add_source_files(ROOT / "lut_interpolation/lut_sqrt_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/lut_interpolation/lut_sqrt_tb.vhd")

vhdl2008.add_source_files(ROOT / "fixed_dsp/fixed_dsp.vhd")
vhdl2008.add_source_files(ROOT / "fixed_dsp/arch_rtl_fixed_dsp.vhd")

# mpy_32x32_sim.vhd stands in for the ECP5 sysDSP hard IP so arch_ecp5_fixed_dsp
# can be elaborated by a generic simulator (the real vendor netlist depends on
# the ECP5U primitive library and is only usable by Diamond)
vhdl2008.add_source_files(ROOT / "fixed_dsp/mpy_32x32_sim.vhd")
vhdl2008.add_source_files(ROOT / "fixed_dsp/arch_ecp5_fixed_dsp.vhd")

vhdl2008.add_source_files(ROOT / "testbenches/fixed_dsp/fixed_dsp_tb.vhd")
fixed_dsp_tb = vhdl2008.test_bench("fixed_dsp_tb")
fixed_dsp_tb.add_config(name="rtl", generics=dict(use_ecp5=False))
fixed_dsp_tb.add_config(name="rtl_pre_add_register", generics=dict(use_ecp5=False, use_pre_add_register=True))
fixed_dsp_tb.add_config(name="rtl_product_register", generics=dict(use_ecp5=False, use_product_register=True))
fixed_dsp_tb.add_config(name="rtl_pre_add_and_product_registers", generics=dict(use_ecp5=False, use_pre_add_register=True, use_product_register=True))
fixed_dsp_tb.add_config(name="ecp5", generics=dict(use_ecp5=True))

vhdl2008.add_source_files(ROOT / "testbenches/fixed_dsp/fixed_dsp_combine_tb.vhd")

vhdl2008.add_source_files(ROOT / "sine_calculator/sine_calculator.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/fixed_dsp/sine_lut_dsp_tb.vhd")
sine_lut_dsp_tb = vhdl2008.test_bench("sine_lut_dsp_tb")
sine_lut_dsp_tb.add_config(name="continuous", generics=dict(use_gaps=False))
sine_lut_dsp_tb.add_config(name="gapped", generics=dict(use_gaps=True))
sine_lut_dsp_tb.add_config(name="continuous_no_ram_output_register", generics=dict(use_gaps=False, use_ram_output_register=False))
sine_lut_dsp_tb.add_config(name="gapped_no_ram_output_register", generics=dict(use_gaps=True, use_ram_output_register=False))
sine_lut_dsp_tb.add_config(name="continuous_no_dsp_request_register", generics=dict(use_gaps=False, use_dsp_request_register=False))
sine_lut_dsp_tb.add_config(name="gapped_no_registers", generics=dict(use_gaps=True, use_ram_output_register=False, use_dsp_request_register=False))
sine_lut_dsp_tb.add_config(name="continuous_no_registers", generics=dict(use_gaps=False, use_ram_output_register=False, use_dsp_request_register=False))

vhdl2008.add_source_files(ROOT / "reciprocal_calculator/reciprocal_calculator.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/fixed_dsp/reciprocal_lut_dsp_tb.vhd")
reciprocal_lut_dsp_tb = vhdl2008.test_bench("reciprocal_lut_dsp_tb")
reciprocal_lut_dsp_tb.add_config(name="continuous", generics=dict(use_gaps=False))
reciprocal_lut_dsp_tb.add_config(name="gapped", generics=dict(use_gaps=True))
reciprocal_lut_dsp_tb.add_config(name="continuous_no_ram_output_register", generics=dict(use_gaps=False, use_ram_output_register=False))
reciprocal_lut_dsp_tb.add_config(name="gapped_no_ram_output_register", generics=dict(use_gaps=True, use_ram_output_register=False))
reciprocal_lut_dsp_tb.add_config(name="continuous_no_dsp_request_register", generics=dict(use_gaps=False, use_dsp_request_register=False))
reciprocal_lut_dsp_tb.add_config(name="gapped_no_registers", generics=dict(use_gaps=True, use_ram_output_register=False, use_dsp_request_register=False))
reciprocal_lut_dsp_tb.add_config(name="continuous_no_registers", generics=dict(use_gaps=False, use_ram_output_register=False, use_dsp_request_register=False))

vhdl2008.add_source_files(ROOT / "sqrt_calculator/sqrt_calculator.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/fixed_dsp/sqrt_lut_dsp_tb.vhd")
sqrt_lut_dsp_tb = vhdl2008.test_bench("sqrt_lut_dsp_tb")
sqrt_lut_dsp_tb.add_config(name="continuous", generics=dict(use_gaps=False))
sqrt_lut_dsp_tb.add_config(name="gapped", generics=dict(use_gaps=True))
sqrt_lut_dsp_tb.add_config(name="continuous_no_ram_output_register", generics=dict(use_gaps=False, use_ram_output_register=False))
sqrt_lut_dsp_tb.add_config(name="gapped_no_ram_output_register", generics=dict(use_gaps=True, use_ram_output_register=False))
sqrt_lut_dsp_tb.add_config(name="continuous_no_dsp_request_register", generics=dict(use_gaps=False, use_dsp_request_register=False))
sqrt_lut_dsp_tb.add_config(name="gapped_no_registers", generics=dict(use_gaps=True, use_ram_output_register=False, use_dsp_request_register=False))
sqrt_lut_dsp_tb.add_config(name="continuous_no_registers", generics=dict(use_gaps=False, use_ram_output_register=False, use_dsp_request_register=False))

# leading zero count for the divider's and the square root's shifters
vhdl2008.add_source_files(ROOT / "fixed_point_scaling/fixed_point_scaling_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/fixed_point_scaling/fixed_point_scaling_tb.vhd")
vhdl2008.add_source_files(ROOT / "lut_divider/lut_divider.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/lut_divider/lut_divider_tb.vhd")
lut_divider_tb = vhdl2008.test_bench("lut_divider_tb")
lut_divider_tb.add_config(name="w32_radix16", generics=dict(word_length=32, quotient_radix=16))
lut_divider_tb.add_config(name="w32_radix16_gapped", generics=dict(word_length=32, quotient_radix=16, use_gaps=True))
lut_divider_tb.add_config(name="w32_radix16_pre_add_register", generics=dict(word_length=32, quotient_radix=16, use_pre_add_register=True))
lut_divider_tb.add_config(name="w32_radix16_product_register", generics=dict(word_length=32, quotient_radix=16, use_product_register=True))
lut_divider_tb.add_config(name="w32_radix16_pre_add_and_product_registers_gapped", generics=dict(word_length=32, quotient_radix=16, use_pre_add_register=True, use_product_register=True, use_gaps=True))
lut_divider_tb.add_config(name="w32_radix10", generics=dict(word_length=32, quotient_radix=10))
lut_divider_tb.add_config(name="w32_radix0", generics=dict(word_length=32, quotient_radix=0))
lut_divider_tb.add_config(name="w24_radix8", generics=dict(word_length=24, quotient_radix=8))
lut_divider_tb.add_config(name="w17_radix12", generics=dict(word_length=17, quotient_radix=12))
lut_divider_tb.add_config(name="w32_radix16_1_shifter_stage", generics=dict(word_length=32, quotient_radix=16, shifter_stages=1))
lut_divider_tb.add_config(name="w32_radix0_3_shifter_stages", generics=dict(word_length=32, quotient_radix=0, shifter_stages=3))
lut_divider_tb.add_config(name="w32_radix16_5_shifter_stages", generics=dict(word_length=32, quotient_radix=16, shifter_stages=5))
lut_divider_tb.add_config(name="w24_radix8_1_shifter_stage", generics=dict(word_length=24, quotient_radix=8, shifter_stages=1))
lut_divider_tb.add_config(name="w17_radix12_7_shifter_stages", generics=dict(word_length=17, quotient_radix=12, shifter_stages=7))
lut_divider_tb.add_config(name="w32_radix16_no_ram_output_register", generics=dict(word_length=32, quotient_radix=16, use_ram_output_register=False))
lut_divider_tb.add_config(name="w32_radix16_gapped_no_ram_output_register", generics=dict(word_length=32, quotient_radix=16, use_gaps=True, use_ram_output_register=False))
lut_divider_tb.add_config(name="w32_radix0_1_shifter_stage_no_ram_output_register", generics=dict(word_length=32, quotient_radix=0, shifter_stages=1, use_ram_output_register=False, use_pre_add_register=True))
lut_divider_tb.add_config(name="w32_radix16_no_dsp_request_register", generics=dict(word_length=32, quotient_radix=16, use_dsp_request_register=False))
lut_divider_tb.add_config(name="w32_radix16_gapped_no_registers", generics=dict(word_length=32, quotient_radix=16, use_gaps=True, use_ram_output_register=False, use_dsp_request_register=False))
lut_divider_tb.add_config(name="w24_radix8_1_shifter_stage_no_registers_pre_add", generics=dict(word_length=24, quotient_radix=8, shifter_stages=1, use_ram_output_register=False, use_dsp_request_register=False, use_pre_add_register=True))
lut_divider_tb.add_config(name="w32_radix16_512x18_r16", generics=dict(word_length=32, quotient_radix=16, index_width=9, table_word_length=18, table_radix=16, x_frac_width=18))
lut_divider_tb.add_config(name="w32_radix16_512x18_r16_no_registers", generics=dict(word_length=32, quotient_radix=16, index_width=9, table_word_length=18, table_radix=16, x_frac_width=18, use_ram_output_register=False, use_dsp_request_register=False, use_gaps=True))
lut_divider_tb.add_config(name="w32_radix20_1024x20_r18_x24", generics=dict(word_length=32, quotient_radix=20, index_width=10, table_word_length=20, table_radix=18, x_frac_width=24))
lut_divider_tb.add_config(name="w32_radix0_512x18_r16_x30", generics=dict(word_length=32, quotient_radix=0, index_width=9, table_word_length=18, table_radix=16, x_frac_width=30))
lut_divider_tb.add_config(name="w24_radix8_128x14_r12_x12", generics=dict(word_length=24, quotient_radix=8, index_width=7, table_word_length=14, table_radix=12, x_frac_width=12, shifter_stages=1))
# 36 bit, the microprogram processor's wider data
lut_divider_tb.add_config(name="w36_radix16", generics=dict(word_length=36, quotient_radix=16))
lut_divider_tb.add_config(name="w36_radix20", generics=dict(word_length=36, quotient_radix=20))
lut_divider_tb.add_config(name="w36_radix24", generics=dict(word_length=36, quotient_radix=24))
lut_divider_tb.add_config(name="w36_radix24_gapped", generics=dict(word_length=36, quotient_radix=24, use_gaps=True))
lut_divider_tb.add_config(name="w36_radix0", generics=dict(word_length=36, quotient_radix=0))
lut_divider_tb.add_config(name="w36_radix24_512x18_table", generics=dict(word_length=36, quotient_radix=24, index_width=9, table_word_length=18, table_radix=16, x_frac_width=18))
lut_divider_tb.add_config(name="w36_radix24_512x18_table_pre_add_and_product_registers", generics=dict(word_length=36, quotient_radix=24, index_width=9, table_word_length=18, table_radix=16, x_frac_width=18, use_pre_add_register=True, use_product_register=True))
lut_divider_tb.add_config(name="w36_radix24_512x18_table_no_registers", generics=dict(word_length=36, quotient_radix=24, index_width=9, table_word_length=18, table_radix=16, x_frac_width=18, use_ram_output_register=False, use_dsp_request_register=False))

vhdl2008.add_source_files(ROOT / "full_range_sqrt/full_range_sqrt.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/full_range_sqrt/full_range_sqrt_tb.vhd")
full_range_sqrt_tb = vhdl2008.test_bench("full_range_sqrt_tb")
full_range_sqrt_tb.add_config(name="w32_radix16", generics=dict(word_length=32, radix=16))
full_range_sqrt_tb.add_config(name="w32_radix16_gapped", generics=dict(word_length=32, radix=16, use_gaps=True))
full_range_sqrt_tb.add_config(name="w32_radix16_pre_add_register", generics=dict(word_length=32, radix=16, use_pre_add_register=True))
full_range_sqrt_tb.add_config(name="w32_radix16_product_register", generics=dict(word_length=32, radix=16, use_product_register=True))
full_range_sqrt_tb.add_config(name="w32_radix16_pre_add_and_product_registers", generics=dict(word_length=32, radix=16, use_pre_add_register=True, use_product_register=True))
full_range_sqrt_tb.add_config(name="w32_radix15", generics=dict(word_length=32, radix=15))
full_range_sqrt_tb.add_config(name="w32_radix0", generics=dict(word_length=32, radix=0))
full_range_sqrt_tb.add_config(name="w32_radix31", generics=dict(word_length=32, radix=31))
full_range_sqrt_tb.add_config(name="w24_radix8", generics=dict(word_length=24, radix=8))
full_range_sqrt_tb.add_config(name="w17_radix12", generics=dict(word_length=17, radix=12))
full_range_sqrt_tb.add_config(name="w32_radix16_1_shifter_stage", generics=dict(word_length=32, radix=16, shifter_stages=1))
full_range_sqrt_tb.add_config(name="w32_radix31_3_shifter_stages", generics=dict(word_length=32, radix=31, shifter_stages=3))
full_range_sqrt_tb.add_config(name="w32_radix15_5_shifter_stages", generics=dict(word_length=32, radix=15, shifter_stages=5))
full_range_sqrt_tb.add_config(name="w24_radix8_1_shifter_stage", generics=dict(word_length=24, radix=8, shifter_stages=1))
full_range_sqrt_tb.add_config(name="w17_radix12_7_shifter_stages", generics=dict(word_length=17, radix=12, shifter_stages=7))
full_range_sqrt_tb.add_config(name="w32_radix16_no_ram_output_register", generics=dict(word_length=32, radix=16, use_ram_output_register=False))
full_range_sqrt_tb.add_config(name="w32_radix16_gapped_no_ram_output_register", generics=dict(word_length=32, radix=16, use_gaps=True, use_ram_output_register=False))
full_range_sqrt_tb.add_config(name="w32_radix31_1_shifter_stage_no_ram_output_register", generics=dict(word_length=32, radix=31, shifter_stages=1, use_ram_output_register=False, use_pre_add_register=True))
full_range_sqrt_tb.add_config(name="w32_radix16_no_dsp_request_register", generics=dict(word_length=32, radix=16, use_dsp_request_register=False))
full_range_sqrt_tb.add_config(name="w32_radix16_gapped_no_registers", generics=dict(word_length=32, radix=16, use_gaps=True, use_ram_output_register=False, use_dsp_request_register=False))
full_range_sqrt_tb.add_config(name="w24_radix8_1_shifter_stage_no_registers_pre_add", generics=dict(word_length=24, radix=8, shifter_stages=1, use_ram_output_register=False, use_dsp_request_register=False, use_pre_add_register=True))
full_range_sqrt_tb.add_config(name="w32_radix16_512x18_r17", generics=dict(word_length=32, radix=16, index_width=9, table_word_length=18, table_radix=17, x_frac_width=18))
full_range_sqrt_tb.add_config(name="w32_radix16_512x18_r17_no_registers", generics=dict(word_length=32, radix=16, index_width=9, table_word_length=18, table_radix=17, x_frac_width=18, use_ram_output_register=False, use_dsp_request_register=False, use_gaps=True))
full_range_sqrt_tb.add_config(name="w32_radix31_1024x20_r19_x24", generics=dict(word_length=32, radix=31, index_width=10, table_word_length=20, table_radix=19, x_frac_width=24))
full_range_sqrt_tb.add_config(name="w32_radix0_512x18_r17_x30", generics=dict(word_length=32, radix=0, index_width=9, table_word_length=18, table_radix=17, x_frac_width=30))
full_range_sqrt_tb.add_config(name="w24_radix8_128x14_r13_x12", generics=dict(word_length=24, radix=8, index_width=7, table_word_length=14, table_radix=13, x_frac_width=12, shifter_stages=1))
# 36 bit, the microprogram processor's wider data
full_range_sqrt_tb.add_config(name="w36_radix16", generics=dict(word_length=36, radix=16))
full_range_sqrt_tb.add_config(name="w36_radix20", generics=dict(word_length=36, radix=20))
full_range_sqrt_tb.add_config(name="w36_radix24", generics=dict(word_length=36, radix=24))
full_range_sqrt_tb.add_config(name="w36_radix24_gapped", generics=dict(word_length=36, radix=24, use_gaps=True))
full_range_sqrt_tb.add_config(name="w36_radix35", generics=dict(word_length=36, radix=35))
full_range_sqrt_tb.add_config(name="w36_radix24_512x18_table", generics=dict(word_length=36, radix=24, index_width=9, table_word_length=18, table_radix=17, x_frac_width=18))
full_range_sqrt_tb.add_config(name="w36_radix24_512x18_table_pre_add_and_product_registers", generics=dict(word_length=36, radix=24, index_width=9, table_word_length=18, table_radix=17, x_frac_width=18, use_pre_add_register=True, use_product_register=True))
full_range_sqrt_tb.add_config(name="w36_radix24_512x18_table_no_registers", generics=dict(word_length=36, radix=24, index_width=9, table_word_length=18, table_radix=17, x_frac_width=18, use_ram_output_register=False, use_dsp_request_register=False))

# VU.set_sim_option("nvc.sim_flags", ["-w"])

if args.dump_arrays is not None:
    dump_arrays_flag = "--dump-arrays" + (f"={args.dump_arrays}" if args.dump_arrays else "")
    VU.set_sim_option("nvc.sim_flags", ["-w", dump_arrays_flag])

VU.main()
