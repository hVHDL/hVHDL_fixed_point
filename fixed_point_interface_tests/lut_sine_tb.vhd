LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;

    use work.multiplier_pkg.all;
    use work.lut_sine_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity lut_sine_tb is
  generic (runner_cfg : string);
end;

architecture sim of lut_sine_tb is
    signal rstn : std_logic;

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 5000;
------------------------------------------------------------------------
    signal simulation_counter : natural := 0;

------------------------------------------------------------------------

    signal angle_rad16 : integer := 0;
    signal sincos_multiplier : multiplier_record := init_multiplier;

    signal sine_lut : ram_record;
    signal sine_from_lut : integer :=0;

    signal sine_error : real := 0.0;

------------------------------------------------------------------------
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

    clocked_reset_generator : process(simulator_clock, rstn)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(sincos_multiplier);
            create_lut_sine(sine_lut);

            if simulation_counter = 10 or sine_lut_is_ready(sine_lut) then
                angle_rad16 <= (angle_rad16 + 511) mod 2**16;
                -- request_sincos(sincos, 
                request_sine_from_lut(sine_lut, ((angle_rad16 + 511) mod 2**16)/2**6);
            end if; 

            if sine_lut_is_ready(sine_lut) then
                check(abs(real(get_sine_from_lut(sine_lut))/2.0**16 - sin(real(angle_rad16)/2.0**16*2.0*math_pi)) < 0.01,
                    "error is too large");
                sine_error <= abs(real(get_sine_from_lut(sine_lut))/2.0**16 - sin(real(angle_rad16)/2.0**16*2.0*math_pi));
                sine_from_lut <= get_sine_from_lut(sine_lut);
            end if;

        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------ 
end sim;
