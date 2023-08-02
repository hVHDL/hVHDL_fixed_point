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
    function to_fixed (
        number : real;
        bit_width : natural;
        number_of_fractional_bits : integer)
    return signed;
------------------------------------------------------------------------
    function to_real (
        number : signed;
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
    function to_real
    (
        number : signed;
        number_of_fractional_bits : integer
    )
    return real
    is
        variable retval : real := 0.0;
        variable temp : signed(number'range) := abs(number);

    begin
        for i in number'high-1 downto number'low loop
            if temp(i) = '1' then
                retval := retval + 2.0**(i);
            end if;
        end loop;

        if number(number'high) = '1' then
            retval := -retval;
        end if;

        return retval/2.0**number_of_fractional_bits;
    end to_real;
------------------------------------------------------------------------
    function to_fixed
    (
        number : real;
        bit_width : natural;
        number_of_fractional_bits : integer
    )
    return signed
    is
        variable retval : signed(bit_width-1 downto 0) := (others => '0');
        variable temp : real := abs(number)*2.0**number_of_fractional_bits;
    begin

        for i in integer range bit_width-2 downto 0 loop
            if temp >= 2.0**i then
                temp := temp - 2.0**i;
                retval(i) := '1';
            else
                retval(i) := '0';
            end if;

        end loop;

        if number < 0.0 then
            retval := -retval;
        end if;

        return retval;
        
    end to_fixed;
------------------------------------------------------------------------

end package body real_to_fixed_pkg;
