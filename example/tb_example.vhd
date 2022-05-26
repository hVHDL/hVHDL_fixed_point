LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

    use work.multiplier_pkg.all;

entity tb_example is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_example is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 5000;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type filter_object_record is record
        multiplier       : multiplier_record ;
        counter          : natural           ;
        process_counter  : natural           ;
        process_counter2 : natural           ;
        y                : int18             ;
        mem              : int18             ;
    end record;

    constant init_filter : filter_object_record := (
        init_multiplier , 0 , 0 , 0 , 0 , 0) ;

    procedure create_filter
    (
        signal filter_object : inout filter_object_record
    ) is
        alias multiplier       is filter_object.multiplier       ;
        alias counter          is filter_object.counter          ;
        alias process_counter  is filter_object.process_counter  ;
        alias process_counter2 is filter_object.process_counter2 ;
        alias y                is filter_object.y                ;
        alias mem              is filter_object.mem              ;
        constant b0 : integer := 1500;
        constant b1 : integer := 150;
        constant a0 : integer := 2**16-b0-b1;
    begin
            create_multiplier(multiplier);

            Case process_counter is
                WHEN 0 =>
                    multiply(multiplier, counter, b0);
                    increment(process_counter);
                WHEN 1 =>
                    multiply(multiplier, counter, b1);
                    increment(process_counter);
                WHEN others => -- wait
            end case;

            Case process_counter2 is
                WHEN 0 =>
                    if multiplier_is_ready(multiplier) then
                        increment(process_counter2);
                        y <= mem + get_multiplier_result(multiplier, 16);
                    end if;
                WHEN 1 =>
                    if multiplier_is_ready(multiplier) then
                        increment(process_counter2);
                        mem <= get_multiplier_result(multiplier, 16);
                        multiply(multiplier, y, a0);
                    end if;
                When 2 =>
                    if multiplier_is_ready(multiplier) then
                        increment(process_counter2);
                        mem <= mem + get_multiplier_result(multiplier, 16);
                    end if;
                When 3 =>
                    process_counter <= 0;
                    process_counter2 <= 0;

                    counter <= counter + 1e3;
                    if counter = 10e3 then
                        counter <= 0;
                    end if;
                WHEN others => -- wait
            end case;

        
    end create_filter;
------------------------------------------------------------------------
    signal filter : filter_object_record := init_filter; 
    signal filter2 : filter_object_record := init_filter; 
------------------------------------------------------------------------
    type resolver_model_record is record
        sine             : real ;
        angle_slow       : real ;
        sine_slow        : real ;
        cosine_slow      : real ;
        modulated_sine   : real ;
        modulated_cosine : real ;
    end record;

    constant init_resolver_model : resolver_model_record := (0.0,0.0,0.0,0.0,0.0,0.0);

    signal resolver_model : resolver_model_record := init_resolver_model;

------------------------------------------------------------------------
    procedure create_resolver_model
    (
        signal resolver_model_object : inout resolver_model_record;
        sine : real
    ) is
        alias angle_slow       is resolver_model_object.angle_slow      ;
        alias sine_slow        is resolver_model_object.sine_slow       ;
        alias cosine_slow      is resolver_model_object.cosine_slow     ;
        alias modulated_sine   is resolver_model_object.modulated_sine  ;
        alias modulated_cosine is resolver_model_object.modulated_cosine;
    begin
        angle_slow       <= (angle_slow + math_pi/500.0) mod (2.0*math_pi);
        sine_slow        <= sin(angle_slow);
        cosine_slow      <= cos(angle_slow);
        modulated_sine   <= sine_slow * sine;
        modulated_cosine <= cosine_slow * sine;

    end create_resolver_model;

------------------------------------------------------------------------
    type resolver_demodulator_record is record
        sin_out : real;
        estimated_position : real;
        estimated_angle : real;
        angle : real;
    end record;

    constant init_resolver_demodulator : resolver_demodulator_record := (0.0, 0.0, 0.0, 0.0);

------------------------------------------------------------------------
    procedure create_resolver_demodulator
    (
        signal resolver_demodulator_object : inout resolver_demodulator_record;
        modulated_sine : in real;
        modulated_cosine : in real
    ) is
        alias m is resolver_demodulator_object;
    begin
        m.angle <= (m.angle + math_pi/50.0) mod (2.0*math_pi);
        m.sin_out <= sin(m.angle);

        m.estimated_position <= m.estimated_position + 0.1*(-sin(m.estimated_angle) * modulated_cosine + cos((m.estimated_angle)*modulated_sine))*sin(m.angle);
        m.estimated_angle <= (m.estimated_angle + m.estimated_position) mod (math_pi*2.0)*0.01;
        
    end create_resolver_demodulator;

------------------------------------------------------------------------
    function get_modulator_sine
    (
        resolver_demodulator_object : resolver_demodulator_record
    )
    return real
    is
    begin
        return resolver_demodulator_object.sin_out;
    end get_modulator_sine;

    signal resolver_demodulator : resolver_demodulator_record := init_resolver_demodulator;
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
            create_filter(filter);
            create_filter(filter2);

            create_resolver_model(resolver_model, get_modulator_sine(resolver_demodulator));
            create_resolver_demodulator(resolver_demodulator, resolver_model.modulated_sine, resolver_model.modulated_cosine);
            -- stimulus
            if simulation_counter > 500 and simulation_counter < 900 then
                resolver_model.angle_slow <= math_pi/2.0;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
