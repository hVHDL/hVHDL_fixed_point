LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity tb_square_root is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_square_root is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
    function nr_iteration
    (
        number_to_invert, guess : real
    )
    return real
    is
        variable x : real := 0.0;
    begin
        x := guess;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;

        return x;
        
    end nr_iteration;

------------------------------------------------------------------------
    signal test_0 : real := nr_iteration(0.25     / 2.0**0, 1.0) / 2.0**0 - 1.0 / sqrt(0.25);
    signal test_1 : real := nr_iteration(0.5     / 2.0**0, 1.0) / 2.0**0 - 1.0 / sqrt(0.5);
    signal test_2 : real := nr_iteration(0.99    / 2.0**0, 1.0) / 2.0**0 - 1.0 / sqrt(0.99);

    signal test_3 : real := nr_iteration(3.0     / 2.0**(2*1), 1.0) / 2.0**1 - 1.0 / sqrt(3.0);
    signal test_4 : real := nr_iteration(5.0     / 2.0**(2*2), 1.0) / 2.0**2 - 1.0 / sqrt(5.0);
    signal test_5 : real := nr_iteration(16.0    / 2.0**(2*3), 1.0) / 2.0**3 - 1.0 / sqrt(16.0);
    signal test_6 : real := nr_iteration(155.7   / 2.0**(2*4), 1.0) / 2.0**4 - 1.0 / sqrt(155.7);
    signal test_7 : real := nr_iteration(588.543 / 2.0**(2*5), 1.0) / 2.0**5 - 1.0 / sqrt(588.543);
    signal test_8 : real := nr_iteration(1588.543 / 2.0**(2*6), 1.0) / 2.0**6 - 1.0 / sqrt(1588.543);
    signal test_9 : real := nr_iteration(4588.543 / 2.0**(2*7), 1.0) / 2.0**7 - 1.0 / sqrt(4588.543);
------------------------------------------------------------------------

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            -- check(abs(1.0 - test_1 / (1.0/sqrt(2200.0))) < 0.01, "fail");
            -- check(abs(1.0 - test_2 / (1.0/sqrt(2800.0))) < 0.01, "fail");


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
