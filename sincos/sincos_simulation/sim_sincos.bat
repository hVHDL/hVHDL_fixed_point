echo off
rem simulate sincos.vhd

FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source

ghdl -a --ieee=synopsys --work=math_library %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/sincos/sincos_pkg.vhd
ghdl -a --ieee=synopsys tb_sincos.vhd
ghdl -e --ieee=synopsys tb_sincos
ghdl -r --ieee=synopsys tb_sincos --vcd=tb_sincos.vcd


IF %1 EQU 1 start "" gtkwave tb_sincos.vcd
IF %2 EQU 1 EXIT
