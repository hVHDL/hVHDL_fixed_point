LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;
    use work.division_pkg.all;

entity divider_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of divider_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal multiplier : multiplier_record := init_multiplier;
    signal division : division_record := init_division;

    function to_radix14
    (
        number : real
    )
    return integer
    is
    begin
        return integer(number*2.0**12);
    end to_radix14;

    signal division_result : integer := 0;
    signal expected_result : integer := 0;

    type real_array is array (integer range 0 to 9) of real;

    function "/" ( left, right : real_array) return real_array
    is
        variable result : real_array;
    begin
        for i in left'range loop
            result(i) := left(i)/right(i);
        end loop;
        return result;
    end "/";

    constant dividends : real_array := (1.0     , 0.986    , 0.2353  , 7.3519 , 4.2663 , 3.7864 , 0.3699 , 5.31356 , 4.1369 , 1.3468);
    constant divisors : real_array  := (1.83369 , 2.468168 , 3.46876 , 5.356  , 6.3269 , 1.5316 , 4.136  , 0.866   , 0.5469 , 2.8899);
    signal results : real_array := dividends/divisors;
    signal i : integer := 0;

    signal used_divisor  : real := 0.0;
    signal used_dividend : real := 0.0;

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
            create_division(multiplier, division);

            if simulation_counter = 5 then
                request_division(division, to_radix14(dividends(i)), to_radix14(divisors(i)));
                used_dividend <= dividends(i);
                used_divisor <= divisors(i);
                i <= (i + 1) mod 10;
            end if;

            if division_is_ready(multiplier, division) then
                i <= (i + 1) mod 10;
                request_division(division, to_radix14(dividends(i)), to_radix14(divisors(i)));
                used_dividend <= dividends(i);
                used_divisor <= divisors(i);
                division_result <= get_division_result(multiplier, division, 14);
                expected_result <= integer((used_dividend/used_divisor)*2.0**14);
            end if;

            check(abs(division_result - expected_result) < 100, "division error should be less than 100!");


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
