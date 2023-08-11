LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity goldsmith_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of goldsmith_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal test1 : real := 1.0;

    signal n : real := 0.5;
    signal d : real := 2.1353686/2.0;

    -- initial condition for f is taken from simulation
    signal f : real := 0.9323157;

    signal test_result : real := n/d;
    signal div_error : real := 0.0;

    signal count : natural := 0;


    signal x : real := 0.5;
    signal div_error2 : real := 0.0;
begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable vd : real;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            vd := f*d;
            d <= vd;
            n <= f*n;
            f <= 2.0-vd;
            div_error <= n-test_result;
            count <= 0;

            x <= x*(2.0-2.1353686*x);
            div_error2 <= x-test_result;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
