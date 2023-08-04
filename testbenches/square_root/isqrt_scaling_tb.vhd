LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.square_root_pkg.all;
    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;

entity isqrt_scaling_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of isqrt_scaling_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    type real_array is array (integer range 0 to 7) of real;
    type sign_array is array (integer range 0 to 7) of signed(int_word_length-1 downto 0);

    function to_fixed
    (
        number : real_array
    )
    return sign_array
    is
        variable return_value : sign_array := (others => (others => '0'));
    begin

        for i in real_array'range loop
            return_value(i) := to_fixed(number(i), int_word_length, int_word_length-8);
        end loop;

        return return_value;
        
    end to_fixed;

    function to_fixed
    (
        number : real
    )
    return signed
    is
    begin
        return to_fixed(number, int_word_length, int_word_length-2);
        
    end to_fixed;

    constant input_values : real_array := (1.5, 1.0, 15.35689, 17.1359, 32.153, 33.315, 0.4865513, 25.00);
    constant fixed_input_values : sign_array := to_fixed(input_values);

    signal multiplier : multiplier_record := init_multiplier;
    signal isqrt : isqrt_record := init_isqrt;

    signal sqrt_was_calculated : boolean := false;
    signal result : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        if run("sqrt was calculated") then
            check(sqrt_was_calculated);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_isqrt(isqrt, multiplier);


            CASE simulation_counter is
                WHEN 10 => request_isqrt(isqrt,shift_left(fixed_input_values(2), 3), to_fixed(0.826), 3);
                WHEN others => --do nothing
            end CASE;

            if isqrt_is_ready(isqrt) then
                sqrt_was_calculated <= true;
                result <= to_real(get_isqrt_result(isqrt),int_word_length-2);
                -- check(abs(to_real(shift_left(get_isqrt_result(isqrt),5), int_word_length-2) - 1.0/sqrt(input_values(2))) < 1.0e-12);
            end if;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
