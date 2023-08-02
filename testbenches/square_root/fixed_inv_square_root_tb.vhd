LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.square_root_pkg.all;
    use work.multiplier_pkg.all;

entity fixed_inv_square_root_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fixed_inv_square_root_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 60;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
    signal testi : boolean := true;

    signal input_value : real := 1.0;
    signal output_value : real := 0.0;

    signal inv_sqrt_is_ready : boolean := false;
    signal request_isqrt : boolean := false;


    signal sign_input_value : signed(16 downto 0) := to_fixed(1.0,17,14);

    signal square_root_was_requested : boolean := false;

    signal multiplier : multiplier_record := init_multiplier;

    signal state_counter : integer := 0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        if run("square root was requested") then
            check(square_root_was_requested);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
        variable inv_sqrt_error : real;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            request_isqrt <= false;
            if inv_sqrt_is_ready then
                if input_value < 2.0 then
                    input_value <= input_value + 0.02;
                    request_isqrt <= true;
                end if;
            end if;

            inv_sqrt_is_ready <= false;
            if request_isqrt then
                inv_sqrt_is_ready <= true;
                sign_input_value <= to_fixed(input_value,sign_input_value'length, sign_input_value'high-2);
                square_root_was_requested <= true;
            end if;

            CASE simulation_counter is
                WHEN 10 =>
                    inv_sqrt_is_ready <= true;
                WHEN others => --do nothing
            end CASE;

            CASE state_counter is
                WHEN 0 => multiply_and_increment_counter(multiplier,state_counter, to_integer(sign_input_value), to_integer(sign_input_value));
                WHEN others => --do nothign
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
