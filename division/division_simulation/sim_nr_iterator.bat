echo off
rem simulate tb_nr_iterator.vhd

FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/

ghdl -a --ieee=synopsys --work=math_library %source%/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/division/division_internal_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/division/division_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/division/division_pkg_body.vhd
ghdl -a --ieee=synopsys tb_nr_iterator.vhd
ghdl -e --ieee=synopsys tb_nr_iterator
ghdl -r --ieee=synopsys tb_nr_iterator --wave=tb_nr_iterator.ghw


IF %1 EQU 1 start "" gtkwave tb_nr_iterator.vcd
