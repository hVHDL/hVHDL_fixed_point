library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package division_internal_pkg is
    function remove_leading_zeros ( number : int18)
        return int18;

    function get_initial_value_for_division ( divisor : natural)
        return natural;

    function invert_bits ( number : natural)
        return natural;

end package division_internal_pkg;


package body division_internal_pkg is

    --------------------------------------------------
        function invert_bits
        (
            number : natural
        )
        return natural
        is
            variable number_in_std_logic : std_logic_vector(16 downto 0);
        begin
            number_in_std_logic := not std_logic_vector(to_unsigned(number,17));
            return to_integer(unsigned(number_in_std_logic));
        end invert_bits;
------------------------------------------------------------------------
    function get_initial_value_for_division
    (
        divisor : natural
    )
    return natural

    is
    --------------------------------------------------
        function get_lut_index
        (
            number : natural
        )
        return natural
        is

            variable u_number : unsigned(16 downto 0);
            variable lut_index : natural;
        begin 
            u_number  := to_unsigned(number, 17);
            lut_index := to_integer(u_number(14 downto 10)); 
            return lut_index; 
        end get_lut_index;
    -------------------------------------------------- 
        type divisor_lut_array is array (integer range 0 to 31) of natural;
        constant divisor_lut : divisor_lut_array := ( 
          0  => 63 ,
          1  => 61 ,
          2  => 59 ,
          3  => 57 ,
          4  => 56 ,
          5  => 54 ,
          6  => 53 ,
          7  => 52 ,
          8  => 50 ,
          9  => 49 ,
          10 => 48 ,
          11 => 47 ,
          12 => 46 ,
          13 => 45 ,
          14 => 44 ,
          15 => 43 , -- last
          16 => 42 ,
          17 => 41 , -- *
          18 => 40 ,
          19 => 39 ,
          20 => 39 ,
          21 => 38 ,
          22 => 37 ,
          23 => 37 ,
          24 => 36 ,
          25 => 36 ,
          26 => 35 ,
          27 => 34 ,
          28 => 34 ,
          29 => 33 ,
          30 => 32 ,
          31 => 32);
    begin
        return divisor_lut(get_lut_index(divisor))*2**11;
    end get_initial_value_for_division;
--------------------------------------------------
------------------------------------------------------------------------
    function remove_leading_zeros
    (
        number : int18
    )
    return int18
    is
        variable abs_number : natural;

    begin
            abs_number := (number);
            if abs_number < 2**1  then return abs_number*2**15; end if;
            if abs_number < 2**2  then return abs_number*2**14; end if;
            if abs_number < 2**3  then return abs_number*2**13; end if;
            if abs_number < 2**4  then return abs_number*2**12; end if;
            if abs_number < 2**5  then return abs_number*2**11; end if;
            if abs_number < 2**6  then return abs_number*2**10; end if;
            if abs_number < 2**7  then return abs_number*2**9; end if;
            if abs_number < 2**8  then return abs_number*2**8; end if;
            if abs_number < 2**9  then return abs_number*2**7; end if;
            if abs_number < 2**10 then return abs_number*2**6; end if;
            if abs_number < 2**11 then return abs_number*2**5; end if;
            if abs_number < 2**12 then return abs_number*2**4; end if;
            if abs_number < 2**13 then return abs_number*2**3; end if;
            if abs_number < 2**14 then return abs_number*2**2; end if;
            if abs_number < 2**15 then return abs_number*2**1; end if;
            -- if abs_number < 2**16 then return abs_number/2**0; end if;

            return abs_number;
        
    end remove_leading_zeros; 

end package body division_internal_pkg;

