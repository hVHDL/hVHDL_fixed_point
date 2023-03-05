library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package real_to_fixed_pkg is

------------------------------------------------------------------------
    function to_fixed (
        number : real;
        number_of_fractional_bits : integer)
    return integer;
------------------------------------------------------------------------
    function to_real (
        number : integer;
        number_of_fractional_bits : integer)
    return real;
------------------------------------------------------------------------

end package real_to_fixed_pkg;

package body real_to_fixed_pkg is

------------------------------------------------------------------------
    function to_fixed
    (
        number : real;
        number_of_fractional_bits : integer
    )
    return integer
    is
    begin
        return integer(number*2.0**number_of_fractional_bits);
    end to_fixed;
------------------------------------------------------------------------
    function to_real
    (
        number : integer;
        number_of_fractional_bits : integer
    )
    return real
    is
    begin
        return real(number)/2.0**(number_of_fractional_bits);
    end to_real;
------------------------------------------------------------------------

end package body real_to_fixed_pkg;
