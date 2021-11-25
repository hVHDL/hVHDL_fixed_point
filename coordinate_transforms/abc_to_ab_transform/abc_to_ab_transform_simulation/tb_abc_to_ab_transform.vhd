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
    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    constant init_abc_multiplier : multiplier_array := (init_multiplier, init_multiplier, init_multiplier);
    signal multiplier : multiplier_array := init_abc_multiplier;

    signal abc_multiplier_process_counter : natural range 0 to 15 := 15;
    signal abc_transform_process_counter : natural range 0 to 15 := 15;

    type int_array is array (integer range 0 to 2) of integer;
    type int2d_array is array (integer range 0 to 2) of int_array;
    constant alpha_beta_to_abc_gains : int2d_array := 
    (
        (43691 , -21845 , -21845) ,
        (0     , 37837  , -37837) ,
        (21845 , 21845  , 21845)
    );
        

    signal sincos_multiplier : multiplier_record := init_multiplier;

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos);
    signal angle_rad16 : unsigned(15 downto 0) := (others => '0');

    signal test : integer := 0;

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

            create_multiplier(sincos_multiplier);
            create_sincos(multiplier(phase_a) , sincos(phase_a));
            create_sincos(multiplier(phase_b) , sincos(phase_b));
            create_sincos(multiplier(phase_c) , sincos(phase_c));

            test <= get_sine(sincos(phase_a)) + get_sine(sincos(phase_b)) + get_sine(sincos(phase_c));

            if simulation_counter = 10 or sincos_is_ready(sincos(phase_a)) then
                angle_rad16 <= angle_rad16 + 511;
                request_sincos(sincos(phase_a), angle_rad16);
                request_sincos(sincos(phase_b), angle_rad16 + 21845);
                request_sincos(sincos(phase_c), angle_rad16 + 21845*2);
            end if; 

            if sincos_is_ready(sincos(phase_a)) then
                CASE abc_multiplier_process_counter is
                    WHEN 0 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN 1 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN 2 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN 3 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN 4 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN 5 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN 6 =>
                        multiply(multiplier(phase_a), get_sine(sincos(phase_a)), 32768);
                        abc_multiplier_process_counter <= abc_multiplier_process_counter + 1;
                    WHEN others =>
                end CASE;

                CASE abc_transform_process_counter is
                    WHEN 0 =>
                        if multiplier_is_ready(multiplier(phase_a)) then
                            -- get_multiplier_result(multiplier(phase_a));
                            abc_transform_process_counter <= abc_transform_process_counter + 1;
                        end if;
                    WHEN 1 =>
                    WHEN 2 =>
                    WHEN 3 =>
                    WHEN 4 =>
                    WHEN 5 =>
                    WHEN 6 =>
                    WHEN others => -- wait for restart
                end CASE;
            end if; -- sincos(phase_a)_is_ready(sincos(phase_a))



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
