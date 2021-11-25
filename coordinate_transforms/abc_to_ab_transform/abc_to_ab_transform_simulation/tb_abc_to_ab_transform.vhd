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

------------------------------------------------------------------------
    -- simulation specific signals ----
------------------------------------------------------------------------

    type abc is (phase_a, phase_b, phase_c);

    type sincos_array is array (abc range abc'left to abc'right) of sincos_record;
    signal sincos : sincos_array := (init_sincos, init_sincos, init_sincos);
    signal angle_rad16 : unsigned(15 downto 0) := (others => '0');

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (init_multiplier, init_multiplier, init_multiplier);

    signal ab_transform_multiplier : multiplier_record := init_multiplier;
    signal abc_to_ab_transform : abc_to_ab_transform_record := init_abc_to_ab_transform;
------------------------------------------------------------------------

------------------------------------------------------------------------
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
                request_abc_to_ab_transform(abc_to_ab_transform);
            end if;

            create_multiplier(ab_transform_multiplier);
            create_abc_to_ab_transformer(ab_transform_multiplier, abc_to_ab_transform, get_sine(sincos(phase_a)), get_sine(sincos(phase_c)), get_sine(sincos(phase_b)));

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
