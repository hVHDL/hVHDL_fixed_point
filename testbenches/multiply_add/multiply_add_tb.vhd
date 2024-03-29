LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.fixed_point_dsp_pkg.all;

    --todo clean up this dependency
    use work.sos_filter_pkg.number_of_fractional_bits;

entity multiply_add_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of multiply_add_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal fixed_point_dsp : fixed_point_dsp_record := init_fixed_point_dsp;
    signal result_counter : integer := 0;

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

            create_fixed_point_dsp(fixed_point_dsp);

            CASE simulation_counter is 
                WHEN 0 => multiply_add(fixed_point_dsp  , 2**number_of_fractional_bits     , 9999   , 1);
                WHEN 6 => multiply_add(fixed_point_dsp  , 2**number_of_fractional_bits     , 15e3   , 15e3);
                WHEN 7 => multiply_add(fixed_point_dsp  , 2**(number_of_fractional_bits+1) , 9999   , 2);
                WHEN 8 => multiply_add(fixed_point_dsp  , 2**(number_of_fractional_bits-1) , -10000 , 1);
                WHEN 17 => multiply_add(fixed_point_dsp , 2**(number_of_fractional_bits-1) , 10000  , 1);
                WHEN others =>
            end CASE;
            if fixed_point_dsp_is_ready(fixed_point_dsp) then
                
                result_counter <= result_counter + 1;
                CASE result_counter is
                    WHEN 0 => check(get_dsp_result(fixed_point_dsp) = 10e3  , "expected 10e3 got " & integer'image(get_dsp_result(fixed_point_dsp)));
                    WHEN 1 => check(get_dsp_result(fixed_point_dsp) = 30e3  , "expected 30e3 got " & integer'image(get_dsp_result(fixed_point_dsp)));
                    WHEN 2 => check(get_dsp_result(fixed_point_dsp) = 20e3  , "expected 20e3 got " & integer'image(get_dsp_result(fixed_point_dsp)));
                    WHEN 3 => check(get_dsp_result(fixed_point_dsp) = -4999 , "expected -4999 got " & integer'image(get_dsp_result(fixed_point_dsp)));
                    WHEN 4 => check(get_dsp_result(fixed_point_dsp) = 5001  , "expected 5001 got " & integer'image(get_dsp_result(fixed_point_dsp)));
                    WHEN others =>
                end CASE;
                        
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
