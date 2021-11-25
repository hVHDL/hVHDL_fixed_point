echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/../

ghdl -a --ieee=synopsys --work=math_library %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/sincos/sincos_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/division/division_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/first_order_filter/first_order_filter_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/pi_controller/pi_controller_pkg.vhd

ghdl -a --ieee=synopsys --work=math_library %source%/math_library/coordinate_transforms/abc_to_ab_transform/abc_to_ab_transform_pkg.vhd

