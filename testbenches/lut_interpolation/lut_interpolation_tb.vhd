LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.lut_interpolation_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity lut_interpolation_tb is
  generic (runner_cfg : string);
end;

architecture sim of lut_interpolation_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 2**angle_word_length + 2;
------------------------------------------------------------------------
    signal simulation_counter : natural := 0;

    signal angle         : unsigned(angle_word_length-1 downto 0) := (others => '0');
    signal angle_of_sine : unsigned(angle_word_length-1 downto 0) := (others => '0');
    signal sine          : signed(angle_word_length-1 downto 0)   := (others => '0');
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
        variable expected : real;
        variable actual   : real;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if simulation_counter > 0 then
                expected := sin(2.0*math_pi*real(to_integer(angle_of_sine))/real(2**angle_word_length));
                actual   := real(to_integer(sine))/(2.0**(angle_word_length-1)-1.0);

                check(abs(actual - expected) < 0.001,
                    "sine error too large at angle " & integer'image(to_integer(angle_of_sine)));
            end if;

            angle_of_sine <= angle;
            sine          <= get_sine_from_quarter_wave_lut(angle);
            angle         <= angle + 1;

        end if; -- rising_edge
    end process stimulus_and_check;
------------------------------------------------------------------------
end sim;
