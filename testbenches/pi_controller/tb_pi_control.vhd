LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.pi_controller_pkg.all;
    use work.real_to_fixed_pkg.all;

entity pi_control_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of pi_control_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 1000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal multiplier : multiplier_record       := init_multiplier;
    signal pi_controller : pi_controller_record := pi_controller_init;

    signal model_multiplier : multiplier_record := init_multiplier;

    signal model_counter : integer := 0;
    signal state : real := 0.0;

    signal reference : integer := 0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(abs(state - 10.0e3/32768.0) < 0.01, real'image(state));
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        function to_fixed (real_input : real) return integer is
        begin
            return to_fixed(real_input, int_word_length-6);
        end to_fixed;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_multiplier(multiplier);
            create_pi_controller(multiplier, pi_controller, to_fixed(2.50,12), to_fixed(0.15, 12));

            if pi_control_calculation_is_ready(pi_controller) then
                state <= state + (state * 0.0 + real(get_pi_control_output(pi_controller))/32768.0)*0.1;
            end if;

            if simulation_counter = 0 or pi_control_calculation_is_ready(pi_controller) then
                calculate_pi_control(pi_controller, reference - integer(state*32768.0));
            end if;

            CASE simulation_counter is
                WHEN 0      => reference <= 0;
                WHEN 50     => reference <= 500;
                WHEN 100    => reference <= -8500;
                WHEN 200    => reference <= -25e3;
                WHEN 300    => reference <= 25e3;
                WHEN 700    => reference <= 10e3;
                WHEN others => -- do nothgin
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
