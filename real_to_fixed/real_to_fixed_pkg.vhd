library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.multiplier_base_types_pkg.all;

package real_to_fixed_pkg is

    constant number_of_bits : integer := number_of_input_bits;
    constant number_range_bits : integer := number_of_bits-1;

------------------------------------------------------------------------
    function get_integer_bits ( number : real )
        return integer;
------------------------------------------------------------------------
    function to_fixed (
        number : real;
        integer_bits : integer)
    return integer;
------------------------------------------------------------------------
    function to_fixed (
        number : real;
        number_range : real range 1.0 to 2.0**(number_range_bits-1))
    return integer;
------------------------------------------------------------------------
    function to_fixed ( number : real)
        return integer;
------------------------------------------------------------------------
    function to_real (
        number : integer;
        number_of_integer_bits : integer)
    return real;
------------------------------------------------------------------------

end package real_to_fixed_pkg;

package body real_to_fixed_pkg is

------------------------------------------------------------------------
    function get_integer_bits
    (
        number : real 
    )
    return integer
    is
        variable integer_bits : integer;
    begin
        if abs(number) >= 1.0 then
            integer_bits := integer(round(log2(abs(number))+0.51));
        else
            integer_bits := 1;
        end if;
        return integer_bits;
    end get_integer_bits;
------------------------------------------------------------------------
    function to_fixed
    (
        number : real;
        integer_bits : integer
    )
    return integer
    is
    begin
        return integer(number*2.0**(number_range_bits-integer_bits));
    end to_fixed;
------------------------------------------------------------------------
    function to_fixed
    (
        number : real;
        number_range : real range 1.0 to 2.0**(number_range_bits-1)
    )
    return integer
    is
        constant bits_in_integer : integer := integer(round(log2(number_range)+0.51));
    begin
        return integer(number*2.0**(number_range_bits-bits_in_integer));
    end to_fixed;
------------------------------------------------------------------------
    function to_fixed
    (
        number : real
    )
    return integer
    is
    begin
        return to_fixed(number,get_integer_bits(number));
    end to_fixed;
------------------------------------------------------------------------
    function to_real
    (
        number : integer;
        number_of_integer_bits : integer
    )
    return real
    is
    begin
        return real(number)/2.0**(number_range_bits-number_of_integer_bits);
    end to_real;
------------------------------------------------------------------------

end package body real_to_fixed_pkg;
