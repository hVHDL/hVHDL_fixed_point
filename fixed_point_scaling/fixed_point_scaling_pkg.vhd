library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package fixed_point_scaling_pkg is
------------------------------------------------------------------------
    function get_number_of_leading_zeros (
        number    : signed;
        max_shift : natural)
        return integer;
------------------------------------------------------------------------
    function get_number_of_leading_zeros ( number : signed )
        return integer;
------------------------------------------------------------------------
    function get_number_of_leading_pairs_of_zeros ( number : signed)
        return natural;
------------------------------------------------------------------------
end package fixed_point_scaling_pkg;

package body fixed_point_scaling_pkg is
------------------------------------------------------------------------
    function get_number_of_leading_zeros
    (
        number    : signed;
        max_shift : natural
    )
    return integer 
    is
        variable number_of_leading_zeros : integer := 0;
    begin
        for i in integer range number'high-max_shift to number'high loop
            if number(i) = '1' then
                number_of_leading_zeros := 0;
            else
                number_of_leading_zeros := number_of_leading_zeros + 1;
            end if;
        end loop;

        return number_of_leading_zeros;
    end get_number_of_leading_zeros;
------------------------------------------------------------------------
    function get_number_of_leading_zeros
    (
        number : signed
    )
    return integer is
    begin
        return get_number_of_leading_zeros(number, number'high);
    end function;
------------------------------------------------------------------------
    function get_number_of_leading_pairs_of_zeros
    (
        number : signed
    )
    return natural 
    is
        variable number_of_leading_zeros : integer := 0;
    begin
        for i in integer range 0 to number'length/2-1 loop
            if number(i*2+1 downto i*2) /= "00" then
                number_of_leading_zeros := 0;
            else
                number_of_leading_zeros := number_of_leading_zeros + 1;
            end if;
        end loop;

        return number_of_leading_zeros;
        
    end get_number_of_leading_pairs_of_zeros;
------------------------------------------------------------------------
end package body fixed_point_scaling_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------
