LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.fixed_point_scaling_pkg.all;
    use work.multiplier_pkg.all;

entity sqrt_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of sqrt_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant used_word_length       : natural := 54;
    constant number_of_integer_bits : natural := 10;
    constant used_radix : natural := used_word_length-number_of_integer_bits;

    subtype fixed is signed(used_word_length-1 downto 0);
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

    constant input_values : real_array(0 to 7) := (1.5, 1.0, 15.35689, 17.1359, 32.153, 33.315, 0.4865513, 25.00);
    constant fixed_input_values : sign_array(0 to 7) := to_fixed(input_values, 8);

    signal sqrt_was_calculated : boolean := false;
    signal result : real := 0.0;

    signal test_scaling : boolean := true;
------------------------------------------------------------------------
    type fixed_sqrt_record is record
        shift_width : natural;
        input        : fixed;
        scaled_input : fixed;
        pipeline     : std_logic_vector(3 downto 0);
    end record;

    constant init_sqrt : fixed_sqrt_record := (0,(others => '0'), (others => '0'), (others => '0'));
------------------------------------------------------------------------
    procedure create_sqrt
    (
        signal self       : inout fixed_sqrt_record;
        signal multiplier : inout multiplier_record
    ) is
    begin
        self.pipeline     <= self.pipeline(self.pipeline'left-1 downto 0) & '0';
        self.scaled_input <= scale_input(self.input);
        self.shift_width  <= get_number_of_leading_pairs_of_zeros(self.input);
    end create_sqrt;
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

    signal sqrt       : fixed_sqrt_record := init_sqrt;
    signal multiplier : multiplier_record := init_multiplier;

    signal max_error : real := 0.0;
    signal sqrt_was_ready : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        if run("maximum error was less than 1e-6") then
            check(test_scaling);
        elsif run("square root was calculated") then
            check(sqrt_was_ready);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        function one_or_two_leading_zeros
        (
            input : signed
        )
        return boolean
        is
            variable retval : boolean;
            variable should_have_one_or_two_zeros : std_logic_vector(2 downto 0);
        begin

            should_have_one_or_two_zeros := std_logic_vector(input(input'left downto input'left-2));
            retval := (should_have_one_or_two_zeros = "001") or 
                      (should_have_one_or_two_zeros = "011") or
                      (should_have_one_or_two_zeros = "010");
            
            return retval;
        end one_or_two_leading_zeros;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_sqrt(sqrt,multiplier);


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
