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

entity fixed_inv_square_root_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fixed_inv_square_root_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 20e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
    constant start_value : real := 0.5;
    signal input_value : real := start_value;
    signal output_value : real := 0.0;

    signal inv_isqrt_is_ready : boolean := false;
    subtype sig is signed(int_word_length-1 downto 0);

    signal sign_input_value : sig := to_fixed(start_value , int_word_length , isqrt_radix);
    signal fixed_result     : sig := to_fixed(1.0         , int_word_length , isqrt_radix);

    signal square_root_was_requested : boolean := false;

    signal multiplier : multiplier_record := init_multiplier;

    signal isqrt : isqrt_record := init_isqrt;
    signal result_error : real := 0.0;
    signal result : real := 1.0;

    signal max_result_error : real := 0.0;
    signal min_error : real := 1.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        if run("square root was requested") then
            check(square_root_was_requested);
        elsif run("max error was less than 0.05") then
            check(max_result_error < 0.05, "error was " & real'image(max_result_error));
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
        variable hihii : sig;
        constant stepsize : real := 1.5/512.0;

        constant number_of_nr_iterations : natural := 1;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_isqrt(isqrt, multiplier);

            CASE simulation_counter is
                WHEN 10 =>

                    request_isqrt(self            => isqrt,
                    input_number                  => to_fixed(input_value, sign_input_value'length, isqrt_radix),
                                  guess           => get_initial_guess(to_fixed(input_value, sign_input_value'length, isqrt_radix)),
                                  number_of_loops => number_of_nr_iterations);

                WHEN others => --do nothing
            end CASE;

            if isqrt_is_ready(isqrt) then
                if input_value < 2.0 then
                    input_value <= input_value + stepsize;
                    hihii := to_fixed(input_value + stepsize, sign_input_value'length, isqrt_radix);

                    request_isqrt(self            => isqrt,
                    input_number                  => to_fixed(input_value + stepsize, sign_input_value'length, isqrt_radix),
                                  guess           => get_initial_guess(hihii),
                                  number_of_loops => number_of_nr_iterations);

                    square_root_was_requested <= true;
                end if;
            end if;

            if isqrt_is_ready(isqrt) then
                result_error <= abs(1.0/sqrt(input_value) - to_real(get_isqrt_result(isqrt), isqrt_radix));
                result       <= 1.0/sqrt(input_value)*2.0**(isqrt_radix);
                fixed_result <= get_isqrt_result(isqrt);
            end if;

            if max_result_error < abs(result_error) then
                max_result_error <= abs(result_error);
            end if;

            if min_error > result_error and result_error > 0.0 then
                min_error <= result_error;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
