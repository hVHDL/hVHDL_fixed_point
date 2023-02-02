LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.fixed_point_dsp_pkg.all;

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
                WHEN 0 => multiply_add(fixed_point_dsp, 2**16, 9999, 1);
                WHEN others =>
            end CASE;
            if fixed_point_dsp_is_ready(fixed_point_dsp) then
                check(get_dsp_result(fixed_point_dsp) = 10e3, "expected 10e3 got " & integer'image(get_dsp_result(fixed_point_dsp)));
            end if;



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
