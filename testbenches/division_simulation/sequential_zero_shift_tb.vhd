
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


    constant wordlength : natural := 36;
    constant radix : natural := wordlength-3;

    signal xi : signed(wordlength-1 downto 0) := to_fixed(0.5, wordlength, radix);
    signal a  : signed(wordlength-1 downto 0) := to_fixed(1.7*1.1, wordlength, radix-7);
    signal b  : signed(wordlength-1 downto 0) := to_fixed(1.7, wordlength, radix);

    signal b_div_a : signed(wordlength-1 downto 0) := to_fixed(0.0, wordlength, radix);

    signal result : real := 0.0;

    signal input_shift_register : unsigned(wordlength-2 downto 0) := (others => '1');
    signal input_zero_count     : natural   := 0;

    signal output_shift_register : a'subtype := (0 => '1' , others => '0');
    signal output_zero_count     : natural   := 0;

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

        function mpy (left : signed; right : signed) return signed is
            variable res : signed(2*left'length-1 downto 0);
            variable retval : signed(left'range);
        begin

            res := left*right;
            retval := res(left'high+radix downto radix);

            return retval;

        end function;

        -------------
        function inv_mantissa(a : signed) return signed is
            variable retval : signed(a'range) := a;
        begin
            return "00" & (not retval(retval'left-2 downto 0));
        end inv_mantissa;
        -------------
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            input_zero_count     <= number_of_leading_zeroes(input_shift_register, max_shift => 3);
            input_shift_register <= shift_left(
                                    input_shift_register
                                    ,(number_of_leading_zeroes(input_shift_register, max_shift => 3)));

            xi <= mpy(xi, (inv_mantissa( mpy(xi,signed("00" & input_shift_register(input_shift_register'left downto 1) )))));
            b_div_a <= mpy(b,xi);

            if a > 0 then
                result <= to_real(b_div_a, radix);
            else
                result <= -to_real(b_div_a, radix);
            end if;

            CASE simulation_counter is
                WHEN 6 =>
                    input_shift_register <= unsigned(a(input_shift_register'range));
                    input_zero_count <= 0;
                WHEN others => -- do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
