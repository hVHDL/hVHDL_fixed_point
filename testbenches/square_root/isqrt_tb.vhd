library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;
    use work.fixed_point_scaling_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;

package fixed_sqrt_pkg is
------------------------------------------------------------------------
    constant used_word_length       : natural := int_word_length;
    subtype fixed is signed(used_word_length-1 downto 0);

    type fixed_sqrt_record is record
        isqrt        : isqrt_record;
        shift_width  : natural;
        input        : fixed;
        scaled_input : fixed;
        pipeline     : std_logic_vector(3 downto 0);
        multiply_isqrt_result : boolean;
        sqrt_is_ready : boolean;
    end record;

    constant init_sqrt : fixed_sqrt_record := (init_isqrt, 0 , (others => '0'), (others => '0'), (others => '0'), false, false);
------------------------------------------------------------------------
    procedure create_sqrt (
        signal self       : inout fixed_sqrt_record;
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    function sqrt_is_ready ( self : fixed_sqrt_record)
        return boolean;
------------------------------------------------------------------------
    function get_sqrt_result (
        self : fixed_sqrt_record;
        multiplier : multiplier_record;
        radix : natural)
    return signed;
------------------------------------------------------------------------
    procedure request_sqrt (
        signal self : inout fixed_sqrt_record;
        number_to_be_squared : fixed);
------------------------------------------------------------------------

end package fixed_sqrt_pkg;

package body fixed_sqrt_pkg is
------------------------------------------------------------------------
    procedure create_sqrt
    (
        signal self       : inout fixed_sqrt_record;
        signal multiplier : inout multiplier_record
    ) is
    begin
        create_isqrt(self.isqrt, multiplier);

        self.pipeline     <= self.pipeline(2 downto 0) & '0';
        self.scaled_input <= scale_input(self.input);
        self.shift_width  <= get_number_of_leading_pairs_of_zeros(self.input);

        if self.pipeline(self.pipeline'left) = '1' then
            request_isqrt(self.isqrt, self.scaled_input, get_initial_guess(self.scaled_input),5);
        end if;

        if isqrt_is_ready(self.isqrt) then
            multiply(multiplier, get_isqrt_result(self.isqrt), self.input);
            self.multiply_isqrt_result <= true;
        end if;

        self.sqrt_is_ready <= false;
        if multiplier_is_ready(multiplier) and self.multiply_isqrt_result then
            self.multiply_isqrt_result <= false;
            self.sqrt_is_ready <= true;
        end if;

    end create_sqrt;
------------------------------------------------------------------------
    function get_sqrt_result
    (
        self : fixed_sqrt_record;
        multiplier : multiplier_record;
        radix : natural
    )
    return signed 
    is
    begin
        return get_multiplier_result(multiplier, int_word_length-2);
    end get_sqrt_result;
------------------------------------------------------------------------
    function sqrt_is_ready
    (
        self : fixed_sqrt_record
    )
    return boolean
    is
    begin
        return self.sqrt_is_ready;
    end sqrt_is_ready;
------------------------------------------------------------------------
    procedure request_sqrt
    (
        signal self : inout fixed_sqrt_record;
        number_to_be_squared : fixed
    ) is
    begin
        self.input <= number_to_be_squared;
        self.pipeline(0) <= '1';
        
    end request_sqrt;
------------------------------------------------------------------------

end package body fixed_sqrt_pkg;
------------------------------------------------------------------------
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

entity sqrt_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of sqrt_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 1500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant number_of_integer_bits : natural := 10;
    constant used_radix : natural := used_word_length-number_of_integer_bits;

    type real_array is array (integer range <>) of real;
    type sign_array is array (integer range <>) of signed(used_word_length-1 downto 0);

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

    constant input_values : real_array(0 to 9) := (1.29135620356203260, 1.0, 15.35689, 0.00125, 32.153, 33.315, 0.4865513, 25.00, 31.02837520, 511.999);
    constant fixed_input_values : sign_array(input_values'range) := to_fixed(input_values, input_values'length);

    signal sqrt_was_calculated : boolean := false;

    signal test_scaling : boolean := true;

    signal fixed_sqrt : fixed_sqrt_record := init_sqrt;
    signal multiplier : multiplier_record := init_multiplier;

    signal max_error : real := 0.0;
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
        if run("maximum error was less than 1e-11") then
            check(max_sqrt_error < 1.0e-11);
        elsif run("square root was calculated") then
            check(sqrt_was_ready);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        variable fixed_Result : signed(int_word_length-1 downto 0);

        impure function output_radix return natural
        is
            variable retval : natural;
        begin
            
            return 48 - fixed_sqrt.shift_width;
            
        end output_radix;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_sqrt(fixed_sqrt,multiplier);

            CASE simulation_counter is
                WHEN 10 => request_sqrt(fixed_sqrt, fixed_input_values(0));
                WHEN others =>
            end CASE;

            if sqrt_is_ready(fixed_sqrt) then
                sqrt_was_ready <= true;

                fix_result     <= get_multiplier_result(multiplier, output_radix);
                fixed_Result   := get_multiplier_result(multiplier, output_radix);

                result         <= to_real(fixed_result, 42);
                sqrt_error     <= sqrt(input_values(result_counter)) - to_real(fixed_result, 42);


                if result_counter < input_values'high then
                    result_counter <= result_counter + 1;
                    request_sqrt(fixed_sqrt, fixed_input_values(result_counter + 1));
                end if;
            end if;
            if abs(sqrt_error) > max_sqrt_error then
                max_sqrt_error <= abs(sqrt_error);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;