LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;

entity tb_square_root is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_square_root is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
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
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;
        x := 1.5*x - 0.5 * number_to_invert * x*x*x;

        return x;
        
    end nr_iteration;
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

    signal test_mult : integer := to_fixed(1.0, 5) * to_fixed(1.0, 5) * to_fixed(1.0, 5);

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

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            check(abs(test(simulation_counter mod test'length)) < 1.0e-9, "fail");


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
