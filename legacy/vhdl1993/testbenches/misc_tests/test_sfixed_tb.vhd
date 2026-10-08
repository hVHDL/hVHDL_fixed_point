LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use std.textio.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity test_sfixed_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of test_sfixed_tb is
    constant clock_period : time := 1 ns;
    
    signal simulator_clock    : std_logic := '0';
    signal simulation_counter : natural   := 0;

    use ieee.fixed_pkg.all;

    constant d1   : sfixed(4 downto -15) := to_sfixed(1.35, 4, -15);
    constant d3   : sfixed(6 downto -15) := to_sfixed(1.35, 6, -15);
    constant d2   : sfixed               := d1*d1;
    constant d4   : sfixed               := d1*d3;
    constant d5   : sfixed               := d1+d3;
    signal testi  : sfixed(d2'range)     := d2;
    signal testi2 : sfixed(d1'range)     := resize(d2,d1);
    signal testi3 : sfixed(d1'range)     := resize(d4,d1);
    signal testi4 : sfixed(d1'range)     := resize(d5,d1);
    signal testi5 : sfixed(d5'range)     := d5;

    constant a : sfixed := to_sfixed(1.5, 4, -3);
    constant b : sfixed := to_sfixed(3.165, 3,-6);
    constant adivb : sfixed := a/b;
    signal testi6 : sfixed(d1'range) := resize(adivb,d1);
    signal testi7 : natural := d1'length;
    constant c : STD_LOGIC_VECTOR(a'length-1 downto 0) := to_slv(a);
    constant d : sfixed(a'range) := sfixed(c);

begin

------------------------------------------------------------------------
    process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until simulation_counter >= 100;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
    begin
        simulation_counter <= simulation_counter + 1;
    end process;

end vunit_simulation;
