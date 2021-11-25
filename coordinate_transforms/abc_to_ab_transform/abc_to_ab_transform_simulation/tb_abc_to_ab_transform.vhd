LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.sincos_pkg.all;
    use math_library.abc_to_ab_transform_pkg.all;

entity tb_abc_to_ab_transform is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_abc_to_ab_transform is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 10000;

    signal simulation_counter : natural := 0;

    -----------------------------------
    -- simulation specific signals ----

    type abc is (phase_a, phase_b, phase_c);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos);
    signal angle_rad16 : unsigned(15 downto 0) := (others => '0');

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier, init_multiplier, init_multiplier);

    signal abc_multiplier_process_counter : natural range 0 to 15 := 15;
    signal abc_transform_process_counter : natural range 0 to 15 := 15;

    signal ab_transform_multiplier : multiplier_record := init_multiplier;

    signal abc_to_ab_transform : abc_to_ab_transform_record := init_abc_to_ab_transform;

    alias alpha is abc_to_ab_transform.alpha;
    alias beta  is abc_to_ab_transform.beta;
    alias gamma is abc_to_ab_transform.gamma;

    alias alpha_sum is abc_to_ab_transform.alpha_sum;
    alias beta_sum  is abc_to_ab_transform.beta_sum;
    alias gamma_sum is abc_to_ab_transform.gamma_sum;

    procedure abc_to_ab_transformer
    (
        signal hw_multiplier : inout multiplier_record
    ) is
    begin
        
    end abc_to_ab_transformer;

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

            if simulation_counter = 10 or sincos_is_ready(sincos(phase_a)) then
                angle_rad16 <= angle_rad16 + 511;
                request_sincos(sincos(phase_a),angle_rad16);
                request_sincos(sincos(phase_b),angle_rad16 + 21845);
                request_sincos(sincos(phase_c),angle_rad16 + 21845*2);
            end if; 

            if sincos_is_ready(sincos(phase_a)) then
                abc_multiplier_process_counter <= 0;
                abc_transform_process_counter <= 0;
            end if;

            create_multiplier(ab_transform_multiplier);
            CASE abc_multiplier_process_counter is
                WHEN 0 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_a)), 43691 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN 1 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_b)), -21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN 2 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_c)), -21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;

                WHEN 3 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_a)), 0 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN 4 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_b)), 37837 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN 5 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_c)), -37837 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;

                WHEN 6 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_a)), 21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN 7 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_b)), 21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN 8 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_c)), 21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                WHEN others =>
            end CASE;

            CASE abc_transform_process_counter is
                WHEN 0 =>
                    if multiplier_is_ready(ab_transform_multiplier) then
                        alpha_sum <= get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                    end if;
                WHEN 1 =>
                        alpha_sum <= alpha_sum + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 2 =>
                        alpha <= alpha_sum + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 3 =>
                        beta_sum <= get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 4 =>
                        beta_sum <= beta_sum + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 5 =>
                        beta <= beta_sum + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 6 =>
                        gamma_sum <= get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 7 =>
                        gamma_sum <= gamma_sum + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 8 =>
                        gamma <= gamma_sum + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN others => -- wait for restart
            end CASE;



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
