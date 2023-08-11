LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.fixed_point_scaling_pkg.all;

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

    constant used_word_length       : natural := 54;
    constant number_of_integer_bits : natural := 5;
    constant used_radix : natural := used_word_length-number_of_integer_bits;

    type real_array is array (integer range 0 to 7) of real;
    type sign_array is array (integer range 0 to 7) of signed(used_word_length-1 downto 0);

    subtype long_signed is signed(used_word_length-1 downto 0);

------------------------------------------------------------------------
    function to_fixed
    (
        number : real_array
    )
    return sign_array
    is
        variable return_value : sign_array := (others => (others => '0'));
    begin

        for i in real_array'range loop
            return_value(i) := to_fixed(number(i), used_word_length, used_radix);
        end loop;

        return return_value;
        
    end to_fixed;

------------------------------------------------------------------------

    constant input_values : real_array := (1.5, 1.0, 15.35689, 17.1359, 32.153, 33.315, 0.4865513, 25.00);
    constant fixed_input_values : sign_array := to_fixed(input_values);

    signal sqrt_was_calculated : boolean := false;
    signal result : real := 0.0;

    function shift_by_2n
    (
        to_be_shifted : signed;
        shift_amount : integer
    )
    return signed 
    is
    begin
        if shift_amount > 0 then
            return shift_left(to_be_shifted, 2*shift_amount);
        else
            return shift_right(to_be_shifted, abs(2*shift_amount));
        end if;
    end shift_by_2n;

    function scale_input
    (
        to_be_shifted : signed 
    )
    return signed 
    is
    begin
        return shift_by_2n(to_be_shifted,  get_number_of_leading_pairs_of_zeros(to_be_shifted) - 1);
    end scale_input;

    signal testi0 : long_signed := scale_input(fixed_input_values(0));
    signal testi1 : long_signed := scale_input(fixed_input_values(1));
    signal testi2 : long_signed := scale_input(fixed_input_values(2));
    signal testi3 : long_signed := scale_input(fixed_input_values(3));
    signal testi4 : long_signed := scale_input(fixed_input_values(4));
    signal testi5 : long_signed := scale_input(fixed_input_values(5));
    signal testi6 : long_signed := scale_input(fixed_input_values(6));
    signal testi7 : long_signed := scale_input(fixed_input_values(7));

    signal test_scaling : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        if run("correct shift was found") then
            -- check(test_scaling);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
        variable testi : long_signed := (others => '0');
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            -- testi := scale_input(fixed_input_values(7));
            -- test_scaling <= (testi(testi'left downto testi'left-3) = "0001");

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
