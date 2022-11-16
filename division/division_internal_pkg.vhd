library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package division_internal_pkg is
    function remove_leading_zeros ( number : int)
        return int;

    function number_of_leading_zeroes (
        data : unsigned;
        max_shift : integer)
    return integer;

    function get_initial_value_for_division ( divisor : natural)
        return natural;

    function invert_bits ( number : natural)
        return natural;

end package division_internal_pkg;


package body division_internal_pkg is

    function number_of_leading_zeroes
    (
        data : std_logic_vector;
        max_shift : integer
    )
    return integer 
    is
        variable number_of_zeroes : integer := 0;
    begin
        for i in data'high - max_shift to data'high loop
            if data(i) = '0' then
                number_of_zeroes := number_of_zeroes + 1;
            else
                number_of_zeroes := 0;
            end if;
        end loop;

        return number_of_zeroes;
        
    end number_of_leading_zeroes;

    function number_of_leading_zeroes
    (
        data : unsigned;
        max_shift : integer
    )
    return integer 
    is
        variable number_of_zeroes : integer := 0;
    begin
        for i in data'high - max_shift to data'high loop
            if data(i) = '0' then
                number_of_zeroes := number_of_zeroes + 1;
            else
                number_of_zeroes := 0;
            end if;
        end loop;

        return number_of_zeroes;
        
    end number_of_leading_zeroes;

--------------------------------------------------
        function invert_bits
        (
            number : natural
        )
        return natural
        is
            variable number_in_std_logic : std_logic_vector(int_word_length-2 downto 0);
        begin
            number_in_std_logic := not std_logic_vector(to_unsigned(number,number_in_std_logic'length));
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

            variable u_number : unsigned(int_word_length-2 downto 0);
            variable lut_index : natural;
        begin 
            u_number  := to_unsigned(number, u_number'length);
            lut_index := to_integer(u_number(int_word_length-4 downto int_word_length-8)); 
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
        return divisor_lut(get_lut_index(divisor))*2**(int_word_length-7);
    end get_initial_value_for_division;
--------------------------------------------------
------------------------------------------------------------------------
    function remove_leading_zeros
    (
        number : int
    )
    return int
    is
        variable abs_number : natural;
        variable uint_number : unsigned(int_word_length-2 downto 0);
        variable zeroes : natural;

    begin
            abs_number := abs(number);
            uint_number := to_unsigned(abs_number, int_word_length-1);
            zeroes := number_of_leading_zeroes(uint_number, int_word_length-2);
            -- if abs_number < 2**1  then return abs_number*2**15; end if;
            -- if abs_number < 2**2  then return abs_number*2**14; end if;
            -- if abs_number < 2**3  then return abs_number*2**13; end if;
            -- if abs_number < 2**4  then return abs_number*2**12; end if;
            -- if abs_number < 2**5  then return abs_number*2**11; end if;
            -- if abs_number < 2**6  then return abs_number*2**10; end if;
            -- if abs_number < 2**7  then return abs_number*2**9; end if;
            -- if abs_number < 2**8  then return abs_number*2**8; end if;
            -- if abs_number < 2**9  then return abs_number*2**7; end if;
            -- if abs_number < 2**10 then return abs_number*2**6; end if;
            -- if abs_number < 2**11 then return abs_number*2**5; end if;
            -- if abs_number < 2**12 then return abs_number*2**4; end if;
            -- if abs_number < 2**13 then return abs_number*2**3; end if;
            -- if abs_number < 2**14 then return abs_number*2**2; end if;
            -- if abs_number < 2**15 then return abs_number*2**1; end if;

            -- return abs_number;

            return to_integer(shift_left(uint_number, number_of_leading_zeroes(uint_number, int_word_length-2)));

    end remove_leading_zeros; 

end package body division_internal_pkg;
