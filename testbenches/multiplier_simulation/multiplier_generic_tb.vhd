LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;
    use ieee.fixed_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity multiplier_generic_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of multiplier_generic_tb is

    package multiplier_pkg is new work.multiplier_generic_pkg generic map(24, 2, 2);
    use multiplier_pkg.all;

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
    signal multiplier : multiplier_record := init_multiplier;

    constant integer_bits : natural := 5;
    constant word_length  : natural := 15;
    constant zero         : sfixed(integer_bits downto integer_bits-word_length) := (others => '0');
    constant result_type  : mpy_signed := (others => '0');

    signal test_sfixed : sfixed(zero'range) := to_sfixed(3.135, zero);

    function to_signed
    (
        left : unresolved_sfixed
    )
    return signed 
    is
        variable retval : mpy_signed := (others => '0');

    begin
        if left'length > retval'length then
            for i in retval'range loop
                retval(i) := left(left'high - (retval'high-i));
            end loop;
        else
            for i in left'length-1 downto 0 loop
                retval(i) := left(left'high - (left'length-1-i));
            end loop;
        end if;

        return retval;

    end to_signed;

    constant test1 : signed(multiplier_word_length -1 downto 0) := (others => '0');

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

            CASE simulation_counter is
                WHEN 0 => multiply(multiplier, 
                        to_signed(to_sfixed(3.135, integer_bits, integer_bits-word_length)), 
                        to_signed(to_sfixed(3.135, integer_bits, integer_bits-word_length)));
                WHEN others => -- do nothing
            end CASE;


        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
