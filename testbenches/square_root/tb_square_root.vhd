LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;
    use work.square_root_pkg.all;

entity tb_square_root is
    generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_square_root is

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

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        if run("test real valued square root") then
            check(testi, "fail");
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

            if input_value < 2.0 then
                inv_sqrt_error := 1.0/sqrt(input_value)-nr_iteration(input_value, 0.826);

                testi        <= testi and (inv_sqrt_error < 1.0e-4);
                output_value <= inv_sqrt_error;

                input_value <= input_value + 0.02;
            end if;
        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
