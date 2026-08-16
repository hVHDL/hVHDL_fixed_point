LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.lut_interpolation_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity lut_interpolation_tb is
  generic (runner_cfg : string);
end;

architecture sim of lut_interpolation_tb is
begin

------------------------------------------------------------------------
    test_runner : process
        variable angle    : unsigned(angle_word_length-1 downto 0);
        variable expected : real;
        variable actual   : real;
    begin
        test_runner_setup(runner, runner_cfg);

        for i in 0 to 2**angle_word_length-1 loop
            angle    := to_unsigned(i, angle_word_length);
            expected := sin(2.0*math_pi*real(i)/real(2**angle_word_length));
            actual   := real(to_integer(get_sine_from_quarter_wave_lut(angle)))/(2.0**(angle_word_length-1)-1.0);

            check(abs(actual - expected) < 0.001, "sine error too large at angle " & integer'image(i));
        end loop;

        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process test_runner;
------------------------------------------------------------------------

end sim;
