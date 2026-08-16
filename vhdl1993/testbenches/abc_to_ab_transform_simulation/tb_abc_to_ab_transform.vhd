LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.sincos_pkg.all;
    use work.abc_to_ab_transform_pkg.all;
    use work.ab_to_abc_transform_pkg.all;

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
    signal sincos : sincos_array := (others => init_sincos);
    signal angle_rad16 : unsigned(15 downto 0) := (others => '0');

    type multiplier_array is array (abc range abc'left to abc'right) of multiplier_record;
    signal multiplier : multiplier_array := (others => init_multiplier);

    signal ab_transform_multiplier : multiplier_record := init_multiplier;
    signal abc_to_ab_transform : abc_to_ab_transform_record := init_abc_to_ab_transform;
    signal ab_to_abc_transform : alpha_beta_to_abc_transform_record := init_alpha_beta_to_abc_transform;
------------------------------------------------------------------------
    signal phase_a_difference : integer := 0;
    signal phase_b_difference : integer := 0;
    signal phase_c_difference : integer := 0;

------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    simulator_clock <= not simulator_clock after clock_per/2.0;
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

            if simulation_counter = 10 or ab_to_abc_transform_is_ready(ab_to_abc_transform) then
                angle_rad16 <= angle_rad16 + 511;
                request_sincos(sincos(phase_a),angle_rad16);
                request_sincos(sincos(phase_b),angle_rad16 + 21845);
                request_sincos(sincos(phase_c),angle_rad16 + 21845*2);
            end if; 
        ------------------------------------------------------------------------
            create_multiplier(ab_transform_multiplier);
            create_abc_to_ab_transformer(ab_transform_multiplier, abc_to_ab_transform, get_sine(sincos(phase_a)), get_sine(sincos(phase_b)), get_sine(sincos(phase_c)));

            create_alpha_beta_to_abc_transformer( ab_transform_multiplier, ab_to_abc_transform,
                get_alpha(abc_to_ab_transform) ,
                get_beta(abc_to_ab_transform)  ,
                get_gamma(abc_to_ab_transform) );
        ------------------------------------------------------------------------

            if sincos_is_ready(sincos(phase_a)) then
                request_abc_to_ab_transform(abc_to_ab_transform);
            end if;

            if abc_to_ab_transform_is_ready(abc_to_ab_transform) then
                request_alpha_beta_to_abc_transform(ab_to_abc_transform);
            end if;

            if ab_to_abc_transform_is_ready(ab_to_abc_transform) then
                assert abs(get_sine(sincos(phase_a)) - get_phase_a(ab_to_abc_transform)) < 5 report"phase a error higher than 5" severity error;
                assert abs(get_sine(sincos(phase_b)) - get_phase_b(ab_to_abc_transform)) < 5 report"phase b error higher than 5" severity error;
                assert abs(get_sine(sincos(phase_c)) - get_phase_c(ab_to_abc_transform)) < 5 report"phase c error higher than 5" severity error;
                phase_a_difference <= get_sine(sincos(phase_a)) - get_phase_a(ab_to_abc_transform);
                phase_b_difference <= get_sine(sincos(phase_b)) - get_phase_b(ab_to_abc_transform);
                phase_c_difference <= get_sine(sincos(phase_c)) - get_phase_c(ab_to_abc_transform);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
