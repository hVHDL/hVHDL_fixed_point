LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.square_root_pkg.all;
    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;

entity isqrt_scaling_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of isqrt_scaling_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    type real_array is array (integer range 0 to 7) of real;
    type sign_array is array (integer range 0 to 7) of signed(int_word_length-1 downto 0);

    function to_fixed
    (
        number : real_array
    )
    return sign_array
    is
        variable return_value : sign_array := (others => (others => '0'));
    begin

        for i in real_array'range loop
            return_value(i) := to_fixed(number(i), int_word_length, int_word_length-8);
        end loop;

        return return_value;
        
    end to_fixed;

    function to_fixed
    (
        number : real
    )
    return signed
    is
    begin
        return to_fixed(number, int_word_length, int_word_length-2);
        
    end to_fixed;

    constant input_values : real_array := (1.5, 1.0, 15.35689, 17.1359, 32.153, 33.315, 0.4865513, 25.00);
    constant fixed_input_values : sign_array := to_fixed(input_values);

    signal multiplier : multiplier_record := init_multiplier;
    signal isqrt : isqrt_record := init_isqrt;

    signal sqrt_was_calculated : boolean := false;
    signal result : real := 0.0;


    function get_number_of_leading_zeros
    (
        number : signed 
    )
    return integer 
    is
        variable number_of_leading_zeros : integer := 0;
    begin
        for i in integer range number'low to number'high loop
            if number(i) = '1' then
                number_of_leading_zeros := 0;
            else
                number_of_leading_zeros := number_of_leading_zeros + 1;
            end if;
        end loop;

        return number_of_leading_zeros;
    end get_number_of_leading_zeros;


    signal should_be_zero  : boolean := false;
    signal should_be_one   : boolean := false;
    signal should_be_two   : boolean := false;
    signal should_be_three : boolean := false;
    signal should_be_131 : boolean := false;


begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        if run("count zero") then
            check(should_be_zero);
        elsif run("count one") then
            check(should_be_one);
        elsif run("count two") then
            check(should_be_two);
        elsif run("count three") then
            check(should_be_three);
        elsif run("count 131") then
            check(should_be_131);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        constant three_leading_zeros  : signed(5 downto 0)   := "000100";
        constant two_leading_zeros    : signed(5 downto 0)   := "001100";
        constant one_leading_zero     : signed(6 downto 0)   := "0100100";
        constant zero_leading_zeros   : signed(131 downto 0) := (131 => '1', others => '0');
        constant leading_zeros_is_131 : signed(131 downto 0) := (0 => '1', others => '0');


    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            should_be_zero  <= get_number_of_leading_zeros(zero_leading_zeros)   = 0;
            should_be_one   <= get_number_of_leading_zeros(one_leading_zero)     = 1;
            should_be_two   <= get_number_of_leading_zeros(two_leading_zeros)    = 2;
            should_be_three <= get_number_of_leading_zeros(three_leading_zeros)  = 3;
            should_be_131 <= get_number_of_leading_zeros(leading_zeros_is_131)  = 131;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
