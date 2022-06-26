echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/../

ghdl -a --ieee=synopsys --std=08 %source%/math_library/hVHDL_memory_library/fpga_ram/ram_read_port_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/math_library/multiplier/multiplier_base_types_18bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/sincos/sincos_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/math_library/sincos/lut_generator_functions/sine_lut_generator_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/sincos/lut_sine_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/math_library/division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/division/division_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/pi_controller/pi_controller_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %source%/math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %source%/math_library/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd

