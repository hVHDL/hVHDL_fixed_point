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

    begin
        test_runner_setup(runner, runner_cfg);

        check(2**(number_of_bits-1) = to_fixed(2.0  , 1) , "fail1");
        check(1.0 = to_real(to_fixed(1.0            , 1) , 1)        , "fail2");
        check(0.5 = to_real(2**(number_of_bits-2)/2 , 1) , "fail3");
        check(6.0 = to_real(6*2**(number_of_bits-2) , 1) , "fail4");

        check(6.13566836 = to_real(to_fixed(6.135668361,3),3) , "fail5");

        check(6*2**(number_of_bits-4)     = to_fixed(6.0  , 3)    , "fail");
        check(-6*2**(number_of_bits-4)    = to_fixed(-6.0 , 7.0)  , "fail");
        check(32*2**(number_range_bits-6) = to_fixed(32.0 , 32.0) , "fail");

        check(32*2**(number_range_bits-get_integer_bits(32.0))         = to_fixed(32.0)   , "fail");
        check(-2**16*2**(number_range_bits-get_integer_bits(-2.0**16)) = to_fixed(-2.0**16) , "fail");
        check(-468*2**(number_range_bits-get_integer_bits(-468.0))     = to_fixed(-468.0) , "fail");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
