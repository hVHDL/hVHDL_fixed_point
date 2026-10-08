LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity adder_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of adder_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 50;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----

--------------------------------------------------
    constant wordlength : natural := 39;
    subtype addertype is signed(wordlength-1 downto 0);

    function to_signed
    (
        real_number : real;
        signed_word_length : natural;
        fractional_length : natural
    )
    return signed
    is
        variable int_result : integer;
    begin
        int_result := integer(real_number*2.0**fractional_length);
        return to_signed(int_result, signed_word_length);

    end to_signed;
--------------------------------------------------

    type adder_record is record
        a, b     : addertype;
        result   : addertype;
        pipeline : std_logic_vector(1 downto 0);
    end record;

    constant zero : addertype := (others => '0');
    constant init_adder : adder_record := (zero,zero,zero, (others => '0'));

--------------------------------------------------
    procedure create_adder
    (
        signal adder_object : inout adder_record
    ) is
        alias m is adder_object;
    begin
        m.result <= m.a + m.b;
        m.pipeline <= m.pipeline(m.pipeline'left -1 downto 0) & '0';
    end create_adder;
--------------------------------------------------
    procedure add
    (
        signal adder_object : inout adder_record;
        left, right : addertype
    ) is
    begin
        adder_object.a <= left;
        adder_object.b <= right;
        adder_object.pipeline(0) <= '1';
    end add;
--------------------------------------------------
    function adder_is_ready
    (
        adder_object : adder_record
    )
    return boolean is
    begin
        return adder_object.pipeline(adder_object.pipeline'left) = '1';
    end adder_is_ready;
--------------------------------------------------
    function get_adder_result
    (
        adder_object : adder_record
    )
    return signed
    is
    begin
        return adder_object.result;
    end get_adder_result;
--------------------------------------------------

    signal adder : adder_record := init_adder;
    signal result_counter : integer := 0;
    signal test_real_to_signed_function : addertype := to_signed(3.58, wordlength, 31);

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
    --------------------------------------------------
        procedure add
        (
            left, right : integer
        ) is
        begin
            add(adder, to_signed(left, wordlength), to_signed(right, wordlength));
        end add;
    --------------------------------------------------
        procedure subtract
        (
            left, right : integer
        ) is
        begin
            add(adder, to_signed(left, wordlength), to_signed(-right, wordlength));
        end subtract;
    --------------------------------------------------
        procedure test (
           constant expected_result_is : integer
        )
         is
        begin
            if adder_is_ready(adder) then
                check(to_signed(expected_result_is, wordlength) = get_adder_result(adder), "fail");
            end if;
        end test;
    --------------------------------------------------

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_adder(adder);

            CASE simulation_counter is
                WHEN 3 => add(1000, 2000);
                WHEN 4 => add(-1000, 2000);
                WHEN 5 => add(-1000, -2000);
                WHEN 8 => add(10e3, 20e3);
                WHEN 11 => add(-11e3, 20e3);
                WHEN 25 => subtract(100e3, 99e3);
                WHEN 26 => subtract(99e3, 100e3);
                when others => -- do nothing
            end CASE;

            if adder_is_ready(adder) then
                result_counter <= result_counter + 1;
            end if;

            CASE result_counter is
                WHEN 0 => test(3000);
                WHEN 1 => test(1000);
                WHEN 2 => test(-3000);
                WHEN 3 => test(30e3);
                WHEN 4 => test(9e3);
                WHEN 5 => test(1e3);
                WHEN 6 => test(-1e3);
                WHEN others => -- do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
