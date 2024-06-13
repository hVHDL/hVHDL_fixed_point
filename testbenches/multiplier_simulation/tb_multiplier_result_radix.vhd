LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_multiplier_result_radix is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_multiplier_result_radix is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal multiplier : multiplier_record := init_multiplier;
    signal result_counter : natural;

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
            create_multiplier(multiplier);
            CASE simulation_counter is
                WHEN 0 => multiply(multiplier , to_fixed(5.0  , 6)  , to_fixed(3.0  , 12));
                WHEN 1 => multiply(multiplier , to_fixed(-5.0 , 11) , to_fixed(3.0  , 17));
                WHEN 2 => multiply(multiplier , to_fixed(0.7  , 14) , to_fixed(33.0 , 12));
                WHEN 3 => multiply(multiplier , to_fixed(-5.0 , 20) , to_fixed(-3.0 , 20));
                WHEN others => --do nothing
            end CASE;

            if multiplier_is_ready(multiplier) then
                result_counter <= result_counter + 1;
                CASE result_counter is
                    WHEN 0 => check_equal(5.0*3.0   , to_real(get_multiplier_result(self => multiplier , input_a_radix => 6, input_b_radix => 12, target_radix => 11) , 11) , max_diff => 0.001);
                    WHEN 1 => check_equal(-5.0*3.0  , to_real(get_multiplier_result(multiplier , 11,17,21) , 21) , max_diff => 0.001);
                    WHEN 2 => check_equal(0.7*33.0  , to_real(get_multiplier_result(multiplier , 14,12,11) , 11) , max_diff => 0.001);
                    WHEN 3 => check_equal(-5.0*(-3.0) , to_real(get_multiplier_result(multiplier , 20,20,20) , 20) , max_diff => 0.001);
                    WHEN others => --do nothing
                end CASE; --result_counter
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
