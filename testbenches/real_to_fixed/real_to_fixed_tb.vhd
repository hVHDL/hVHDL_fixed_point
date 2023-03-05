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

        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
