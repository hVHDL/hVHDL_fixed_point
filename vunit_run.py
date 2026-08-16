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

vhdl2008.add_source_files(ROOT / "lut_interpolation/lut_reciprocal_pkg.vhd")
vhdl2008.add_source_files(ROOT / "testbenches/lut_interpolation/lut_reciprocal_tb.vhd")

# VU.set_sim_option("nvc.sim_flags", ["-w"])

if args.dump_arrays is not None:
    dump_arrays_flag = "--dump-arrays" + (f"={args.dump_arrays}" if args.dump_arrays else "")
    VU.set_sim_option("nvc.sim_flags", ["-w", dump_arrays_flag])

VU.main()
