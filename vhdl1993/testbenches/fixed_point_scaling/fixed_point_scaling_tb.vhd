LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.fixed_point_scaling_pkg.all;

entity fixed_point_scaling_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fixed_point_scaling_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 500;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

    signal should_be_zero  : integer;
    signal should_be_one   : integer;
    signal should_be_two   : integer;
    signal should_be_three : integer;
    signal should_be_131   : integer;
    signal should_be_132   : integer;

    constant three_leading_zeros  : signed(5 downto 0)   := "000100";
    constant two_leading_zeros    : signed(5 downto 0)   := "001100";
    constant one_leading_zero     : signed(6 downto 0)   := "0100100";
    constant zero_leading_zeros   : signed(131 downto 0) := (131 => '1', others => '0');
    constant leading_zeros_is_131 : signed(131 downto 0) := (0   => '1', others => '0');
    constant leading_zeros_is_132 : signed(131 downto 0) := (others => '0');

    signal should_have_zero_pairs      : integer;
    signal should_also_have_zero_pairs : integer;
    signal should_have_one_pair        : integer;
    signal should_also_have_one_pair   : integer;
    signal should_have_10_pairs        : integer;

    constant zero_leading_pairs_of_zeros      : signed(9 downto 0) := "0111111111";
    constant also_zero_leading_pairs_of_zeros : signed(9 downto 0) := "1111111111";
    constant one_leading_pair_of_zeros        : signed(9 downto 0) := "0001111111";
    constant also_one_leading_pair_of_zeros   : signed(9 downto 0) := "0010000000";

    constant number_of_pairs : natural := 10;
    constant has_10_pair_of_zeros   : signed(79 downto 0) := (79-number_of_pairs*2 => '1', others => '0');

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;

        -- these are run in a sequence
        if    run("count zero")  then check(should_be_zero  = 0);
        elsif run("count one")   then check(should_be_one   = 1);
        elsif run("count two")   then check(should_be_two   = 2);
        elsif run("count three") then check(should_be_three = 3);
        elsif run("count 131")   then check(should_be_131   = 131);
        elsif run("count 132")   then check(should_be_132   = 132);
        elsif run("count zero pairs with leading zero")  then check(should_have_zero_pairs      = 0);
        elsif run("count zero pairs from ones")          then check(should_also_have_zero_pairs = 0);
        elsif run("count one pair when 3 leading zeros") then check(should_have_one_pair        = 1);
        elsif run("count one pair when 2 leading zeros") then check(should_also_have_one_pair   = 1);
        elsif run("count 10 pairs from long word")       then check(should_have_10_pairs        = 10);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            should_be_zero  <= get_number_of_leading_zeros(zero_leading_zeros)  ;
            should_be_one   <= get_number_of_leading_zeros(one_leading_zero)    ;
            should_be_two   <= get_number_of_leading_zeros(two_leading_zeros)   ;
            should_be_three <= get_number_of_leading_zeros(three_leading_zeros) ;
            should_be_131   <= get_number_of_leading_zeros(leading_zeros_is_131);
            should_be_132   <= get_number_of_leading_zeros(leading_zeros_is_132);

            should_have_zero_pairs      <= get_number_of_leading_pairs_of_zeros(zero_leading_pairs_of_zeros);
            should_also_have_zero_pairs <= get_number_of_leading_pairs_of_zeros(also_zero_leading_pairs_of_zeros);
            should_have_one_pair        <= get_number_of_leading_pairs_of_zeros(one_leading_pair_of_zeros);
            should_also_have_one_pair   <= get_number_of_leading_pairs_of_zeros(also_one_leading_pair_of_zeros);
            should_have_10_pairs        <= get_number_of_leading_pairs_of_zeros(has_10_pair_of_zeros);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
