LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

    use work.multiplier_pkg.all;
    use work.sincos_pkg.all;
    use work.lut_sine_pkg.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

entity sincos_tb is
  generic (runner_cfg : string);
end;

architecture sim of sincos_tb is
    signal rstn : std_logic;

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 5000;
------------------------------------------------------------------------
    signal simulation_counter : natural := 0;

------------------------------------------------------------------------

    signal angle_rad16 : unsigned(15 downto 0) := (others => '0');

    signal sincos_multiplier : multiplier_record := init_multiplier;
    signal sincos : sincos_record := init_sincos;
    signal sin : int18 := 0;
    signal cos : int18 := 32768;
    signal lutsine : integer := 0;

------------------------------------------------------------------------
------------------------------------------------------------------------

    signal sin_lut : ram_record;

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

    clocked_reset_generator : process(simulator_clock, rstn)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(sincos_multiplier);
            create_sincos(sincos_multiplier, sincos);
            create_lut_sine(sin_lut);

            if simulation_counter = 10 or sincos_is_ready(sincos) then
                angle_rad16 <= angle_rad16 + 511;
                request_sincos(sincos, angle_rad16);
            end if; 
            if sincos_is_ready(sincos) then
                sin <= get_sine(sincos);
                cos <= get_cosine(sincos);
            end if;

            request_sine_from_lut(sin_lut, simulation_counter mod 2**10);
            lutsine <= get_sine_from_lut(sin_lut);

        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------ 
end sim;
