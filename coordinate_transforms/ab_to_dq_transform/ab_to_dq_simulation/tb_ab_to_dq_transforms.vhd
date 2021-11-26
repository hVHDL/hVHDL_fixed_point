LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.sincos_pkg.all;

entity tb_ab_to_dq_transforms is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_ab_to_dq_transforms is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 10e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type abc is (phase_a, phase_b, phase_c);

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier, init_multiplier, init_multiplier);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos);

    signal angle_rad16 : unsigned(15 downto 0) := (others => '0');

    signal alpha : int18 := 0;
    signal alpha_sum : int18 := 0;
    signal beta : int18 := 0;
    signal beta_sum : int18 := 0;

    signal d : int18 := -10e3;
    signal q : int18 := -500;

    signal dq_to_ab_multiplier_counter : natural range 0 to 15 := 15;
    signal dq_to_ab_calculation_counter : natural range 0 to 15 := 15;

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
            create_multiplier(multiplier(phase_a));
            create_multiplier(multiplier(phase_b));
            create_multiplier(multiplier(phase_c));

            create_sincos(multiplier(phase_a) , sincos(phase_a));
            create_sincos(multiplier(phase_b) , sincos(phase_b));
            create_sincos(multiplier(phase_c) , sincos(phase_c));
            ---
            if simulation_counter = 10 then
                request_sincos(sincos(phase_a), angle_rad16);
            end if;

            if sincos_is_ready(sincos(phase_a)) then
                angle_rad16 <= angle_rad16 + 511;
                request_sincos(sincos(phase_a), angle_rad16);
                dq_to_ab_calculation_counter <= 0;
                dq_to_ab_multiplier_counter <= 0;
            end if;

            CASE dq_to_ab_multiplier_counter is
                WHEN 0 =>
                    multiply_and_increment_counter(multiplier(phase_b), dq_to_ab_multiplier_counter, get_cosine(sincos(phase_a)), d);
                WHEN 1 =>
                    multiply_and_increment_counter(multiplier(phase_b), dq_to_ab_multiplier_counter, get_sine(sincos(phase_a)), q);
                WHEN 2 =>
                    multiply_and_increment_counter(multiplier(phase_b), dq_to_ab_multiplier_counter, -get_sine(sincos(phase_a)), d);
                WHEN 3 =>
                    multiply_and_increment_counter(multiplier(phase_b), dq_to_ab_multiplier_counter, get_cosine(sincos(phase_a)), q);
                WHEN others =>
            end CASE;

            CASE dq_to_ab_calculation_counter is
                WHEN 0 =>
                    if multiplier_is_ready(multiplier(phase_b)) then
                        alpha_sum <= get_multiplier_result(multiplier(phase_b),15);
                        increment(dq_to_ab_calculation_counter);
                    end if;
                WHEN 1 =>
                    alpha <= get_multiplier_result(multiplier(phase_b),15);
                    increment(dq_to_ab_calculation_counter);
                WHEN 2 =>
                    beta_sum <= alpha_sum + get_multiplier_result(multiplier(phase_b),15);
                    increment(dq_to_ab_calculation_counter);
                WHEN 3 =>
                    beta <= beta_sum + get_multiplier_result(multiplier(phase_b),15);
                    increment(dq_to_ab_calculation_counter);
                WHEN others => -- hang and wait for start
            end CASE;



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
