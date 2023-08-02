library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;

package square_root_pkg is

------------------------------------------------------------------------
    function nr_iteration ( number_to_invert, guess : real)
        return real;
------------------------------------------------------------------------
    function nr_iteration ( number_to_invert, guess : integer)
        return integer;
------------------------------------------------------------------------

end package square_root_pkg;

package body square_root_pkg is

    function nr_iteration
    (
        number_to_invert, guess : real
    )
    return real
    is
        variable x : real := 0.0;
    begin
        x := guess;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;

        return x;
        
    end nr_iteration;
------------------------------------------------------------------------
    function "*"
    (
        left, right : integer
    )
    return integer
    is
        variable sleft, sright : signed(31 downto 0);
        variable result : signed(63 downto 0);
    begin
        sleft := to_signed(left, 32);
        sright := to_signed(right, 32);
        result := sleft * sright;

        return to_integer(result(63-12 downto 32-12));
        
    end "*";
------------------------------------------------------------------------
    function nr_iteration
    (
        number_to_invert, guess : integer
    )
    return integer
    is
        variable x : integer := 0;
    begin
        x := guess;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;

        return x;
        
    end nr_iteration;
------------------------------------------------------------------------


end package body square_root_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;
    use work.square_root_pkg.all;

entity tb_square_root is
    generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_square_root is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 60;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
    type realarray is array (integer range <>) of real;
    signal test : realarray(0 to 9) := (
        nr_iteration(0.25     / 2.0**0     , 1.0) / 2.0**0 - 1.0 / sqrt(0.25)    ,
        nr_iteration(0.5      / 2.0**0     , 1.0) / 2.0**0 - 1.0 / sqrt(0.5)     ,
        nr_iteration(0.99     / 2.0**0     , 1.0) / 2.0**0 - 1.0 / sqrt(0.99)    ,
        nr_iteration(3.0      / 2.0**(2*1) , 1.0) / 2.0**1 - 1.0 / sqrt(3.0)     ,
        nr_iteration(5.0      / 2.0**(2*2) , 1.0) / 2.0**2 - 1.0 / sqrt(5.0)     ,
        nr_iteration(16.0     / 2.0**(2*3) , 1.0) / 2.0**3 - 1.0 / sqrt(16.0)    ,
        nr_iteration(155.7    / 2.0**(2*4) , 1.0) / 2.0**4 - 1.0 / sqrt(155.7)   ,
        nr_iteration(588.543  / 2.0**(2*5) , 1.0) / 2.0**5 - 1.0 / sqrt(588.543) ,
        nr_iteration(1588.543 / 2.0**(2*6) , 1.0) / 2.0**6 - 1.0 / sqrt(1588.543),
        nr_iteration(4588.543 / 2.0**(2*7) , 1.0) / 2.0**7 - 1.0 / sqrt(4588.543) );
------------------------------------------------------------------------

    signal test_mult : integer := to_fixed(1.0, 5) * to_fixed(1.0, 5) * to_fixed(1.0, 5);

    signal testi : boolean := true;

    signal input_value : real := 1.0;
    signal output_value : real := 0.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        if run("test real valued square root") then
            check(testi, "fail");
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            -- testi <= testi and abs(test(simulation_counter mod test'length)) < 1.0e-9;

            if input_value < 2.0 then
                output_value <=  sqrt(input_value)-nr_iteration(input_value, 0.826);
                input_value <= input_value + 0.02;
            end if;
        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
