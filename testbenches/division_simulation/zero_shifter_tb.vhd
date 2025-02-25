
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;


entity zero_shifter_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of zero_shifter_tb is

    constant int_word_length : integer := 24;

    use work.real_to_fixed_pkg.all;

    package multiplier_pkg is new work.multiplier_generic_pkg generic map(int_word_length, 1, 1);
    use multiplier_pkg.all;

    package division_pkg is new work.division_generic_pkg generic map(multiplier_pkg);
    use division_pkg.all;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant test1 : unsigned(17 downto 0) := (5 => '1', others => '0');
    signal testin_nollat : integer := number_of_leading_zeroes(test1, 17);
    constant test2 : unsigned := (shift_left(test1, testin_nollat));
    constant test3 : integer := remove_leading_zeros(2**8);
    constant test4 : integer := remove_leading_zeros(2**15);

    signal div_multiplier : multiplier_record := init_multiplier;
    signal self : division_record := init_division;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            check(testin_nollat = 17-5, integer'image(testin_nollat));
            check(test2(test2'left) = '1', "left most bit was not zero");
            check(test3 = test4, "leading zeroes failed");

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
