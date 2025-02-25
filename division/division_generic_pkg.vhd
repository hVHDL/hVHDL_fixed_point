library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package division_generic_pkg is
    generic(package mult_div_pkg is new work.multiplier_generic_pkg generic map(<>));

    use mult_div_pkg.all;
--------------------------------------------------
    subtype range_of_nr_iteration is natural range 0 to 4;
    subtype int is integer range -2**(multiplier_word_length-1) to 2**(multiplier_word_length-1)-1;
    type division_record is record
        leading_zero_count                 : natural;
        shift_counter                      : natural range 0 to 3;
        division_process_counter           : natural range 0 to 3;
        x                                  : int;
        number_to_be_reciprocated          : int;
        number_of_newton_raphson_iteration : range_of_nr_iteration;
        dividend                           : int;
        divisor                            : int;
        check_division_to_be_ready         : boolean;
    end record;

    constant init_division : division_record := (0, 0, 3, 0, 0, 0, 0, 0, false);
------------------------------------------------------------------------
    procedure create_division (
        signal multiplier : inout multiplier_record;
        signal self : inout division_record);

------------------------------------------------------------------------
    function division_is_ready ( division_multiplier : multiplier_record; self : division_record)
        return boolean;

------------------------------------------------------------------------
    procedure request_division (
        signal self               : out division_record;
        number_to_be_divided      : int;
        number_to_be_reciprocated : int);
------------------------------------------------------------------------
    procedure request_division (
        signal self               : out division_record;
        number_to_be_divided      : int;
        number_to_be_reciprocated : int;
        iterations                : range_of_nr_iteration);
------------------------------------------------------------------------
    function division_is_busy ( self : in division_record)
        return boolean;
------------------------------
    function division_is_not_busy ( self : in division_record)
        return boolean;
------------------------------------------------------------------------
    function get_division_result (
        multiplier : multiplier_record;
        self       : division_record;
        radix      : natural)
    return integer;
------------------------------------------------------------------------
    function get_division_result (
        multiplier : multiplier_record;
        divisor    : natural;
        radix      : natural)
    return integer;
------------------------------------------------------------------------
    procedure create_divider_and_multiplier (
        signal self    : inout division_record;
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    function remove_leading_zeros ( number : int) return int;
------------------------------------------------------------------------
    function number_of_leading_zeroes (
        data        : unsigned
        ; max_shift : integer)
    return integer ;
------------------------------------------------------------------------
end package division_generic_pkg;

-------------------------------------------------
-------------------------------------------------

package body division_generic_pkg is

    constant c_nr_radix        : integer := multiplier_word_length-2;
    constant int_word_length : integer := multiplier_word_length;

    function to_signed(input : integer) return signed is
    begin
        return to_signed(input, multiplier_word_length);
    end to_signed;

--------------------------------------------------
--------------------------------------------------
    function number_of_leading_zeroes
    (
        data        : unsigned
        ; max_shift : integer
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
        number : signed
    )
    return signed
    is
        variable retval : signed(number'range);
    begin
        retval := signed(not std_logic_vector(number));
        retval(retval'left) := '0';
        return retval;
    end invert_bits;
------------------------------------------------------------------------
    function get_initial_value_for_division
    (
        divisor : natural
    )
    return natural is
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

            return to_integer(shift_left(uint_number, zeroes-1));

    end remove_leading_zeros; 


------------------------------------------------------------------------
    procedure create_division
    (
        signal multiplier : inout multiplier_record;
        signal self : inout division_record
    ) is
    begin
            -- add shifter logic here
            CASE self.shift_counter is
                WHEN others => --do nothing
            end CASE;
        
            CASE self.division_process_counter is
                WHEN 0 =>
                    multiply(multiplier
                    , to_signed(self.x)
                    , to_signed(self.number_to_be_reciprocated));

                    self.division_process_counter <= self.division_process_counter + 1;
                WHEN 1 =>
                    if multiplier_is_ready(multiplier) then
                        self.division_process_counter <= self.division_process_counter + 1;
                        multiply(multiplier
                        , to_signed(self.x), 
                        invert_bits(get_multiplier_result(multiplier,int_word_length-2, int_word_length-2, c_nr_radix)));
                    end if;
                WHEN 2 =>
                    if multiplier_is_ready(multiplier) then
                        self.x <= get_multiplier_result(multiplier, c_nr_radix);
                        if self.number_of_newton_raphson_iteration /= 0 then
                            self.number_of_newton_raphson_iteration <= self.number_of_newton_raphson_iteration - 1;
                            self.division_process_counter <= 0;
                        else
                            self.division_process_counter <= self.division_process_counter + 1;
                            multiply(multiplier, to_signed(get_multiplier_result(multiplier, c_nr_radix), multiplier_word_length), to_signed(self.dividend, multiplier_word_length));
                            self.check_division_to_be_ready <= true;
                        end if;
                    end if;
                WHEN others => -- wait for start
                    if multiplier_is_ready(multiplier) then
                        self.check_division_to_be_ready <= false;
                    end if;
            end CASE;
    end create_division;

------------------------------------------------------------------------
    procedure request_division
    (
        signal self : out division_record;
        number_to_be_divided : int;
        number_to_be_reciprocated : int;
        iterations : range_of_nr_iteration
    ) is
    begin
        self.x                                  <= get_initial_value_for_division(remove_leading_zeros(number_to_be_reciprocated));
        self.number_to_be_reciprocated          <= remove_leading_zeros(number_to_be_reciprocated);
        self.dividend                           <= number_to_be_divided;
        self.divisor                            <= number_to_be_reciprocated;
        self.division_process_counter           <= 0;
        self.shift_counter                      <= 0;
        self.number_of_newton_raphson_iteration <= iterations - 1;
    end request_division;
------------------------------------------------------------------------
    procedure request_division
    (
        signal self           : out division_record;
        number_to_be_divided      : int;
        number_to_be_reciprocated : int
    ) is
    begin
        request_division(self, number_to_be_divided, number_to_be_reciprocated, 1);
    end request_division;
------------------------------------------------------------------------
    function division_is_ready
    (
        division_multiplier : multiplier_record;
        self : division_record
    )
    return boolean
    is
        variable returned_value : boolean;
    begin
        if self.check_division_to_be_ready then
            returned_value := multiplier_is_ready(division_multiplier);
        else
            returned_value := false;
        end if;
        
        return returned_value;

    end division_is_ready;
------------------------------------------------------------------------ 

    function division_is_busy
    (
        self : in division_record
    )
    return boolean
    is
    begin
        return self.division_process_counter /= 3;
    end division_is_busy;
------------------------------
    function division_is_not_busy
    (
        self : in division_record
    )
    return boolean
    is
    begin
        return not division_is_busy(self);
    end division_is_not_busy;

------------------------------------------------------------------------
    function get_division_result
    (
        multiplier : multiplier_record;
        divisor : natural;
        radix : natural
    )
    return integer
    is
        constant used_radix        : integer := c_nr_radix + c_nr_radix-radix;
        variable multiplier_result : integer;
        variable returned_value    : integer;
    begin

        multiplier_result := get_multiplier_result(multiplier,used_radix);

        for i in integer range int_word_length-2 downto 0 loop
            if divisor < 2**i then
                returned_value := multiplier_result*2**((int_word_length-2)-i);
            end if;
        end loop;

        return returned_value;
        
    end get_division_result;

------------------------------------------------------------------------
    function get_division_result
    (
        multiplier : multiplier_record;
        self : division_record;
        radix : natural
    )
    return integer
    is
        variable multiplier_result : integer;
        variable returned_value    : integer;
    begin
            multiplier_result := get_multiplier_result(multiplier,radix);
            returned_value    := get_division_result(multiplier, abs(self.divisor), radix);
            if self.divisor < 0 then
                returned_value := -returned_value;
            end if;

            return returned_value;
        
    end get_division_result;

------------------------------------------------------------------------ 
    procedure create_divider_and_multiplier
    (
        signal self    : inout division_record;
        signal multiplier : inout multiplier_record
    ) is
    begin
        create_multiplier(multiplier);
        create_division(multiplier, self);
        
    end create_divider_and_multiplier;
------------------------------------------------------------------------
end package body division_generic_pkg;
