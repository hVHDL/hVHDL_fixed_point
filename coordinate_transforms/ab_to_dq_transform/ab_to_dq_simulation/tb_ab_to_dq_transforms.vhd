LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.sincos_pkg.all;
    use math_library.dq_to_ab_transform_pkg.all;
    use math_library.ab_to_dq_transform_pkg.all;

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

    signal d : int18 := -10e3;
    signal q : int18 := -500;

    signal dq_to_ab_transform : dq_to_ab_record := init_dq_to_ab_transform;
    signal ab_to_dq_transform : ab_to_dq_record := init_ab_to_dq_transform;


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

            --------------------------------------------------
            create_dq_to_ab_transform(multiplier(phase_b), dq_to_ab_transform);
            create_ab_to_dq_transform(multiplier(phase_c), ab_to_dq_transform);
            --------------------------------------------------
            if sincos_is_ready(sincos(phase_a)) then
                angle_rad16 <= angle_rad16 + 511;
                request_sincos(sincos(phase_a), angle_rad16);

                request_dq_to_ab_transform(
                    dq_to_ab_transform          ,
                    get_sine(sincos(phase_a))   ,
                    get_cosine(sincos(phase_a)) ,
                    -10e3                       , -500);

                request_ab_to_dq_transform(
                    ab_to_dq_transform          ,
                    get_sine(sincos(phase_a))   ,
                    get_cosine(sincos(phase_a)) ,
                    dq_to_ab_transform.alpha    , dq_to_ab_transform.beta);
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
