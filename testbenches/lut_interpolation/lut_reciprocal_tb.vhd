LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.lut_reciprocal_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity lut_reciprocal_tb is
  generic (runner_cfg : string);
end;

architecture sim of lut_reciprocal_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 2**recip_word_length + 2;
------------------------------------------------------------------------
    signal simulation_counter : natural := 0;

    signal x_frac      : unsigned(recip_word_length-1 downto 0) := (others => '0');
    signal x_frac_of_y : unsigned(recip_word_length-1 downto 0) := (others => '0');
    signal y           : unsigned(recip_word_length-1 downto 0) := (others => '0');

    -- exposed only so the lut lookup can be seen in the waveform dump
    signal reciprocal_index : natural range 0 to recip_number_of_entries-1 := 0;
    signal point_value      : signed(recip_word_length-1 downto 0) := (others => '0');
    signal slope_value      : signed(recip_word_length-1 downto 0) := (others => '0');
------------------------------------------------------------------------
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

    stimulus_and_check : process(simulator_clock)
        variable x        : real;
        variable expected : real;
        variable actual   : real;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if simulation_counter > 0 then
                x        := 0.5 * (1.0 + real(to_integer(x_frac_of_y))/real(2**recip_word_length));
                expected := 1.0 / x;
                actual   := real(to_integer(y))/(2.0**(recip_word_length-2)-1.0);

                check(abs(actual - expected) < 0.001,
                    "reciprocal error too large at x_frac " & integer'image(to_integer(x_frac_of_y)));
            end if;

            x_frac_of_y <= x_frac;
            y           <= get_reciprocal_from_lut(x_frac);
            x_frac      <= x_frac + 1;

            reciprocal_index <= get_reciprocal_index(x_frac);
            point_value      <= point_lut(get_reciprocal_index(x_frac));
            slope_value      <= slope_lut(get_reciprocal_index(x_frac));

        end if; -- rising_edge
    end process stimulus_and_check;
------------------------------------------------------------------------
end sim;
