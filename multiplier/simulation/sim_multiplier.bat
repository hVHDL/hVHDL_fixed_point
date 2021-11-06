rem simulate multiplier.vhd
echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
ghdl -a --ieee=synopsys --work=math_library ..\multiplier_pkg.vhd
ghdl -a --ieee=synopsys tb_multiplier.vhd
ghdl -e --ieee=synopsys tb_multiplier
ghdl -r --ieee=synopsys tb_multiplier --vcd=tb_multiplier.vcd 

IF %1 EQU 1 start "" gtkwave tb_multiplier.vcd
