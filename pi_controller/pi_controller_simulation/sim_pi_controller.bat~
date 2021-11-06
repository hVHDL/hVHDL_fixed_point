rem simulate tb_pi_controller.vhd
echo off

echo %project_root%
FOR /F "tokens=* USEBACKQ" %%F IN (`git rev-parse --show-toplevel`) DO (
SET project_root=%%F
)
SET source=%project_root%/source
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/multiplier/multiplier_pkg.vhd
ghdl -a --ieee=synopsys --work=math_library %source%/math_library/state_variable/state_variable_pkg.vhd 

    ghdl -a --ieee=synopsys tb_pi_controller.vhd
    ghdl -e --ieee=synopsys tb_pi_controller
    ghdl -r --ieee=synopsys tb_pi_controller --vcd=tb_pi_controller.vcd


IF %1 EQU 1 start "" gtkwave tb_pi_controller.vcd
