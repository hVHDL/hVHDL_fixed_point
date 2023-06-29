echo off

ghdl -a --ieee=synopsys --std=08 %1/hVHDL_memory_library/fpga_ram/ram_configuration/ram_configuration_16x1024_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/hVHDL_memory_library/fpga_ram/ram_read_port_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %1/multiplier/configuration/multiply_with_1_input_and_output_registers_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/multiplier/multiplier_base_types_18bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/real_to_fixed/real_to_fixed_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %1/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/sincos/sincos_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %1/sincos/lut_generator_functions/sine_lut_generator_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/sincos/lut_sine_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %1/division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/division/division_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/pi_controller/pi_controller_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %1/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd

ghdl -a --ieee=synopsys --std=08 %1/sos_filter/sos_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/testbenches/multiply_add/fixed_point_dsp_pkg.vhd
ghdl -a --ieee=synopsys --std=08 %1/sos_filter/dsp_sos_filter_pkg.vhd
