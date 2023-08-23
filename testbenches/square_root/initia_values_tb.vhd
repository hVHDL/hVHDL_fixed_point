LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;

entity initial_values_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of initial_values_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal testaa_arrayta : testarray := get_table;

    signal test_input   : real := 1.0;
    signal input_number : signed(int_word_length-1 downto 0);
    signal guess        : signed(int_word_length-1 downto 0);
    signal real_guess   : real := 0.0;
    signal number       : natural := 99;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        constant stepsize : real := 0.5/16.0;
        variable v_input : signed(guess'range);
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if test_input < 2.0 then
                test_input <= test_input + stepsize;
            end if;
            v_input := to_fixed(test_input, input_number'length, isqrt_radix);
            input_number <= v_input;
            guess        <= get_initial_guess(v_input);
            real_guess   <= to_real(get_initial_guess(v_input),isqrt_radix);
            number       <= to_integer('0' & v_input(v_input'high-1 downto v_input'high-table_pow2));


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
