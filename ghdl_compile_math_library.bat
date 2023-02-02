echo off

ghdl -a --ieee=synopsys --std=08 hVHDL_memory_library/fpga_ram/ram_configuration/ram_configuration_16x1024_pkg.vhd
ghdl -a --ieee=synopsys --std=08 hVHDL_memory_library/fpga_ram/ram_read_port_pkg.vhd

ghdl -a --ieee=synopsys --std=08 multiplier/multiplier_base_types_18bit_pkg.vhd
ghdl -a --ieee=synopsys --std=08 real_to_fixed/real_to_fixed_pkg.vhd

ghdl -a --ieee=synopsys --std=08 multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --std=08 sincos/sincos_pkg.vhd

ghdl -a --ieee=synopsys --std=08 sincos/lut_generator_functions/sine_lut_generator_pkg.vhd
ghdl -a --ieee=synopsys --std=08 sincos/lut_sine_pkg.vhd

ghdl -a --ieee=synopsys --std=08 division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --std=08 division/division_pkg.vhd
ghdl -a --ieee=synopsys --std=08 first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 pi_controller/pi_controller_pkg.vhd

ghdl -a --ieee=synopsys --std=08 coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 coordinate_transforms/abc_to_ab_transform/ab_to_abc_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 coordinate_transforms/ab_to_dq_transform/dq_to_ab_transform_pkg.vhd
ghdl -a --ieee=synopsys --std=08 coordinate_transforms/ab_to_dq_transform/ab_to_dq_transform_pkg.vhd

ghdl -a --ieee=synopsys --std=08 sos_filter/sos_filter_pkg.vhd
ghdl -a --ieee=synopsys --std=08 testbenches/multiply_add/fixed_point_dsp_pkg.vhd
ghdl -a --ieee=synopsys --std=08 sos_filter/dsp_sos_filter_pkg.vhd
