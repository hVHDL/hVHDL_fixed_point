LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use ieee.fixed_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity multiplier_generic_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of multiplier_generic_tb is

    package multiplier_pkg is new work.multiplier_generic_pkg generic map(37, 2, 2);
    use multiplier_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal multiplier : multiplier_record := init_multiplier;

    constant integer_bits : natural := 4;
    constant word_length  : natural := 18;
    constant zero         : sfixed(integer_bits downto integer_bits-word_length) := (others => '0');
    constant result_type  : mpy_signed := (others => '0');

    signal test_sfixed : sfixed(zero'range) := to_sfixed(3.135, zero);


    constant test1 : signed(multiplier_word_length -1 downto 0) := (others => '0');
    signal multiplier_was_called : boolean := false;

    signal multiplier_result : test1'subtype := (others => '0');
    signal sfixed_multiplier_result : sfixed(integer_bits downto -16) := (others => '0');
    signal multiplier_test_result : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(multiplier_was_called, "multiplier did not complete");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        constant a : sfixed(integer_bits downto integer_bits-word_length) := to_sfixed(3.135, integer_bits, integer_bits-word_length);
        constant b : sfixed(integer_bits downto integer_bits-word_length) := to_sfixed(3.135, integer_bits, integer_bits-word_length);

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_multiplier(multiplier);

            CASE simulation_counter is
                WHEN 0 => multiply(multiplier, to_signed(a), to_signed(b));
                WHEN others => -- do nothing
            end CASE;

            if multiplier_is_ready(multiplier) then
                /* multiplier_result <= get_multiplier_result(multiplier, abs(integer_bits-word_length), abs(integer_bits-word_length), 16); */
                multiplier_result <= get_multiplier_result(multiplier , a , b , sfixed_multiplier_result);

                multiplier_test_result <= 3.135 * 3.135;
                multiplier_was_called  <= true;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
