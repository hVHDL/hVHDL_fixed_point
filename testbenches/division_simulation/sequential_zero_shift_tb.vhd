
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity seq_zero_shift_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of seq_zero_shift_tb is

    constant int_word_length : integer := 20;

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
    signal multiplier : multiplier_record := init_multiplier;
    signal self       : division_record   := init_division;

    signal test1 : unsigned(25 downto 0) := (15 => '1', others => '0');

    signal shift_register : test1'subtype := (0 => '1' , others => '0');
    signal zero_count : natural := 0;

    signal test2 : mpy_signed := (18 => '1', others => '0');

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
    -- shift_register <= self.shift_register;

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_multiplier(multiplier);
            create_division(multiplier, self);

            CASE simulation_counter is
                WHEN 6 =>
                    request_division(self
                    ,to_integer(test2)
                    ,to_integer(test2)
                    ,7
                    );
                    -- zero_count <= 0;
                    -- shift_register <= (10 => '1', others => '0');
                WHEN others => -- do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
