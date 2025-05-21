
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
    signal multiplier : multiplier_record := init_multiplier;
    signal self       : division_record   := init_division;

    signal test1 : unsigned(25 downto 0) := (15 => '1', others => '0');

    signal shift_register : test1'subtype := (0 => '1' , others => '0');
    signal zero_count : natural := 0;

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

            zero_count     <= zero_count + number_of_leading_zeroes(shift_register, max_shift => 4);
            -- self.shift_register <= shift_left(self.shift_register, number_of_leading_zeroes(self.shift_register, max_shift => 4));


            -- add shifter logic here
            -- CASE self.shift_counter is
            --     WHEN 0 => 
            --     WHEN others => --do nothing
            -- end CASE;
            --
            -- CASE self.division_process_counter is
            --     WHEN 0 =>
            --         multiply(multiplier
            --         , to_signed(self.x, mpy_signed'length)
            --         , to_signed(self.number_to_be_reciprocated, mpy_signed'length));
            --
            --         self.division_process_counter <= self.division_process_counter + 1;
            --     WHEN 1 =>
            --         if multiplier_is_ready(multiplier) then
            --             self.division_process_counter <= self.division_process_counter + 1;
            --             multiply(multiplier
            --             , to_signed(self.x, mpy_signed'length), 
            --             invert_bits(get_multiplier_result(multiplier,int_word_length-2, int_word_length-2, c_nr_radix)));
            --         end if;
            --     WHEN 2 =>
            --         if multiplier_is_ready(multiplier) then
            --             self.x <= get_multiplier_result(multiplier, c_nr_radix);
            --             if self.number_of_newton_raphson_iteration /= 0 then
            --                 self.number_of_newton_raphson_iteration <= self.number_of_newton_raphson_iteration - 1;
            --                 self.division_process_counter <= 0;
            --             else
            --                 self.division_process_counter <= self.division_process_counter + 1;
            --                 multiply(multiplier, to_signed(get_multiplier_result(multiplier, c_nr_radix), multiplier_word_length), to_signed(self.dividend, multiplier_word_length));
            --                 self.check_division_to_be_ready <= true;
            --             end if;
            --         end if;
            --     WHEN others => -- wait for start
            --         if multiplier_is_ready(multiplier) then
            --             self.check_division_to_be_ready <= false;
            --         end if;
            -- end CASE;


            CASE simulation_counter is
                WHEN 6 =>
                    -- zero_count <= 0;
                    -- shift_register <= (10 => '1', others => '0');
                WHEN others => -- do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
