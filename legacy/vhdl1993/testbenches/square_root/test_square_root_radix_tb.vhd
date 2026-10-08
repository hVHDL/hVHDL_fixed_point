
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.fixed_point_scaling_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;
    use work.fixed_sqrt_pkg.all;

entity test_sqrt_radix_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of test_sqrt_radix_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 1500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant number_of_integer_bits : natural := 6;
    constant used_radix             : natural := used_word_length   - number_of_integer_bits;
    constant fix_to_real_radix      : natural := used_word_length-2 - number_of_integer_bits/2;

    signal s_input_radix  : natural := used_word_length   - number_of_integer_bits;
    signal s_output_radix : natural := used_word_length-2 - number_of_integer_bits/2;
    signal s_iradix       : natural := isqrt_radix;

    type real_array is array (natural range <>) of real;
    type sign_array is array (natural range <>) of signed(used_word_length-1 downto 0);

------------------------------------------------------------------------
    function to_fixed
    (
        number : real_array;
        length : natural
    )
    return sign_array
    is
        variable return_value : sign_array(0 to length-1) := (others => (others => '0'));
    begin

        for i in return_value'range loop
            return_value(i) := to_fixed(number(i), used_word_length, used_radix);
        end loop;

        return return_value;
        
    end to_fixed;

------------------------------------------------------------------------
    constant input_values : real_array := (1.291356  , 1.0       , 15.35689        ,
                                           0.125     , 32.153    , 33.315          ,
                                           0.4865513 , 25.00     , 55.02837520     ,
                                           122.999   , 34.125116 , 111.135423642);

    signal fixed_input_values : sign_array(input_values'range) := to_fixed(input_values, input_values'length);

    signal sqrt_was_calculated : boolean := false;

    signal multiplier : multiplier_record := init_multiplier;
    signal self       : fixed_sqrt_record := init_sqrt;

    signal sqrt_was_ready : boolean := false;

    signal result : real := 0.0;
    signal fix_result : signed(int_word_length-1 downto 0) := (others => '0');
    signal sqrt_error : real := 0.0;

    signal result_counter : integer := 0;
    signal max_sqrt_error : real := 0.0;

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
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_sqrt(self,multiplier);

            if simulation_counter = 10 then
                request_sqrt(self, fixed_input_values(0));
            end if;

            if sqrt_is_ready(self) then
                if result_counter < input_values'high then
                    result_counter <= result_counter + 1;
                    request_sqrt(self, fixed_input_values(result_counter + 1));
                end if;

                fix_result     <= get_sqrt_result(self, multiplier, 3, (int_word_length-1 - self.shift_width/2)+1);

                result         <= to_real(get_sqrt_result(self, multiplier, used_radix), fix_to_real_radix);
                sqrt_error     <= sqrt(input_values(result_counter)) - to_real(get_sqrt_result(self, multiplier, used_radix), fix_to_real_radix);

            end if;

            if abs(sqrt_error) > max_sqrt_error then
                max_sqrt_error <= abs(sqrt_error);
            end if;

            sqrt_was_ready <= sqrt_was_ready or sqrt_is_ready(self);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
