library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;


package lookup_table_generator_pkg is
    subtype lookup_table_generator_output is real range -1.0 to 1.0;
------------------------------------------------------------------------
------------------------------------------------------------------------
    -- this is the interface function to lookup table module
    function lookup_table_generator ( input : real range 0.0 to 1.0)
        return lookup_table_generator_output;
------------------------------------------------------------------------

end package lookup_table_generator_pkg;

package body lookup_table_generator_pkg is
------------------------------------------------------------------------
    function sine_with_harmonics
    (
        input : real range 0.0 to 1.0
    )
    return lookup_table_generator_output
    is
        variable sine_with_harmonics : real := 0.0;
    begin
        for i in 1 to 9 loop
            sine_with_harmonics := sine_with_harmonics + sin(2.0*math_pi*input*real(i))/real(i) * real(i mod 2);
        end loop;

        return sine_with_harmonics;
    end sine_with_harmonics;
------------------------------------------------------------------------
------------------------------------------------------------------------
    function lookup_table_generator
    (
        input : real range 0.0 to 1.0
    )
    return lookup_table_generator_output
    is

    begin
        return sine_with_harmonics(input);

    end lookup_table_generator;
------------------------------------------------------------------------

end package body  lookup_table_generator_pkg;
