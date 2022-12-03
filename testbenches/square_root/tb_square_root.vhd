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

        return x;
        
    end nr_iteration;
------------------------------------------------------------------------
    function get_reduction_factor
    (
        input : real range 0.0 to 2.0**64
    )
    return real
    is
    begin
        return 2.0**12;
    end get_reduction_factor;
------------------------------------------------------------------------
    function reduce_input
    (
        input : real range 0.0 to 2.0**64
    )
    return real
    is
    begin
        return input/2.0**12;
    end reduce_input;

    signal test_1 : real := nr_iteration(reduce_input(2200.0), 1.1)/get_reduction_factor(2200.0);
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
            check(test_1 / sqrt(2200.0) < 2.0, "fail");


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
