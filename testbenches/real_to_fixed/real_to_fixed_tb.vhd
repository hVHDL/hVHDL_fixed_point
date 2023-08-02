LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.real_to_fixed_pkg.all;

entity real_to_fixed_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of real_to_fixed_tb is

    constant wordlength : natural := 52;
    constant test_number : real := 3.634262646;
    signal testi : signed(wordlength-1 downto 0) := to_fixed(test_number , wordlength , wordlength-3);
    signal testireal : real := to_real(testi,wordlength-3);

begin

------------------------------------------------------------------------
    stimulus : process

        function "="
        (
            left, right : real
        )
        return boolean
        is
        begin
            return abs(1.0-(left / right)) < 0.001;
        end "=";

        impure function test
        (
            number : real;
            bit_width : natural
        )
        return boolean
        is
        begin
            return to_real(to_fixed(number, bit_width),bit_width) = number;
        end test;

    begin
        test_runner_setup(runner, runner_cfg);

        if run("test 15 bit conversion") then
            check(test(3.58, 15));

        elsif run("test 26 bit conversion") then
            check(test(0.56846, 26));

        elsif run("test 30 bit conversion") then
            check(test(0.5790234, 30));

        elsif run("test signed conversion") then
            check(testireal = test_number, real'image(testireal));
        end if;

        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
