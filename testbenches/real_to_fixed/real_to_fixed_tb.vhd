LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity real_to_fixed_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of real_to_fixed_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    constant number_of_bits : integer := 18;
    constant number_range_bits : integer := number_of_bits-1;

    function to_fixed
    (
        number : real;
        integer_bits : integer
    )
    return integer
    is
    begin
        return integer(number*2.0**(number_range_bits-integer_bits));
    end to_fixed;
------------------------------
    function to_fixed
    (
        number : real;
        number_range : real
    )
    return integer
    is
        constant bits_in_integer : integer := integer(round(log2(number_range)+0.51));
    begin
        return integer(number*2.0**(number_range_bits-bits_in_integer));
    end to_fixed;
------------------------------
    function to_fixed
    (
        number : real
    )
    return integer
    is
    begin
        return to_fixed(number,number_range_bits-1);
    end to_fixed;
------------------------------
    function to_real
    (
        number : integer
    )
    return real
    is
    begin
        return real(number)/2.0**(number_range_bits-1);
    end to_real;
    

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

        function "="
        (
            left, right : real
        )
        return boolean
        is
        begin
            return abs(1.0-(left / right)) < 0.001;
        end "=";

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            check(2**(number_of_bits-1) = to_fixed(2.0, 1)  , "fail1");
            check(1.0 = to_real(to_fixed(1.0,1))           , "fail2");
            check(0.5 = to_real(2**(number_of_bits-2)/2) , "fail3");

            check(6.0 = to_real(6*2**(number_of_bits-2)) , "fail4");
            -- check(6*2**(number_of_bits-4) = to_fixed(number => 6.0, number_range => 6.0) , "fail");

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
