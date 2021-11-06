rem simulate integer_division.vhd
echo off

FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source


ghdl -a --ieee=synopsys --work=math_library %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/division/division_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/division/division_pkg_body.vhd
ghdl -a --ieee=synopsys tb_integer_division.vhd
ghdl -e --ieee=synopsys tb_integer_division
ghdl -r --ieee=synopsys tb_integer_division --vcd=tb_integer_division.vcd


IF %1 EQU 1 start "" gtkwave tb_integer_division.vcd
IF %2 EQU 1 EXIT
