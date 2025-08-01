LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity division_generic_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of division_generic_tb is
    constant int_word_length : integer := 31;

    use work.real_to_fixed_pkg.all;

    package multiplier_pkg is new work.multiplier_generic_pkg generic map(int_word_length, 1, 1);
    use multiplier_pkg.all;

    package division_pkg is new work.division_generic_pkg generic map(multiplier_pkg);
    use division_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal radix : integer := int_word_length-4;

    constant left : real := 0.5;
    constant right : real := 0.25;

    signal test1  : int := to_fixed(left, radix);
    signal test2  : int := to_fixed(right, radix);
    signal result : int := to_fixed(0.0  , radix);

    signal real_result : real := 0.0;

    signal multiplier : multiplier_record := init_multiplier;
    signal divider    : division_record   := init_division;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        log("divider only works up to 31 bit word length", info);
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

                check_equal(
                left/right
                , to_real(get_division_result(multiplier, divider, radix), radix)
                , max_diff => 0.001);

            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
