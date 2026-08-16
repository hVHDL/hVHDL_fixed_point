LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.division_pkg.all;
    use work.real_to_fixed_pkg.all;

entity division_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of division_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal radix : integer := int_word_length - 3;

    signal test1 : int := to_fixed(0.5  , radix);
    signal test2 : int := to_fixed(0.25 , radix);
    signal result : int := to_fixed(0.0 , radix);
    signal real_result : real := 0.0;

    signal multiplier : multiplier_record := init_multiplier;
    signal divider : division_record := init_division;

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

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_divider_and_multiplier(divider, multiplier);

            if division_is_ready(multiplier, divider) or simulation_counter <= 0 then
                request_division(divider, test1, test2);
                result      <= get_division_result(multiplier, divider, radix);
                real_result <= to_real(get_division_result(multiplier, divider, radix), radix);
            end if;
            if division_is_ready(multiplier, divider) then
                check_equal(0.5/0.25, to_real(get_division_result(multiplier, divider, radix), radix), max_diff => 0.001);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
