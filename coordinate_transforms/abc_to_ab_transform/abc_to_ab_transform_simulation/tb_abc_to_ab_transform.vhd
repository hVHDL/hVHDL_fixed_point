LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.sincos_pkg.all;

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

    type int_array is array (abc range abc'left to abc'right) of integer;
    type int2d_array is array (integer range 0 to 2) of int_array;
    constant alpha_beta_to_abc_gains : int2d_array := 
    (
        (43691 , -21845 , -21845) ,
        (0     , 37837  , -37837) ,
        (21845 , 21845  , 21845)
    );
        
    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier, init_multiplier, init_multiplier);

    signal abc_multiplier_process_counter : natural range 0 to 15 := 15;
    signal abc_transform_process_counter : natural range 0 to 15 := 15;

    signal ab_transform_multiplier : multiplier_record := init_multiplier;

    signal alpha : int18 := 0;
    signal beta  : int18 := 0;
    signal gamma : int18 := 0;

    signal alpha_jee : int18 :=0;
    signal beta_jee : int18 :=0;
    signal gamma_jee : int18 :=0;

    signal testi : integer :=0;
    signal nolla : integer := 0;

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
                    testi <= get_sine(sincos(phase_a));
                WHEN 7 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_b)), 21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    testi <= testi + get_sine(sincos(phase_b));
                WHEN 8 =>
                    multiply(ab_transform_multiplier, get_sine(sincos(phase_c)), 21845 );
                    abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    nolla <= testi + get_sine(sincos(phase_c));
                WHEN others =>
            end CASE;

            CASE abc_transform_process_counter is
                WHEN 0 =>
                    if multiplier_is_ready(ab_transform_multiplier) then
                        alpha_jee <= get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                    end if;
                WHEN 1 =>
                        alpha_jee <= alpha_jee + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 2 =>
                        alpha <= alpha_jee + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 3 =>
                        beta_jee <= get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 4 =>
                        beta_jee <= beta_jee + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 5 =>
                        beta <= beta_jee + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 6 =>
                        gamma_jee <= get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 7 =>
                        gamma_jee <= gamma_jee + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 8 =>
                        gamma <= gamma_jee + get_multiplier_result(ab_transform_multiplier,15);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN others => -- wait for restart
            end CASE;



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
