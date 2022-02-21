library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_base_types_pkg.all;

package multiplier_pkg is

    subtype signed_36_bit is signed(35 downto 0);
    subtype int18 is integer range -2**17 to 2**17-1;
    subtype uint17 is integer range 0 to 2**17-1;

    subtype multiplier_record is work.multiplier_base_types_pkg.multiplier_base_record;
    constant multiplier_init_values : multiplier_record := initialize_multiplier_base;
    constant init_multiplier : multiplier_record := multiplier_init_values;

------------------------------------------------------------------------
    procedure increment ( signal counter_to_be_incremented : inout integer);
------------------------------------------------------------------------
    procedure create_multiplier (
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    procedure multiply_and_get_result (
        signal multiplier : inout multiplier_record;
        radix : natural range 0 to output_word_bit_width;
        signal result : out integer;
        left, right : integer) ; 
------------------------------------------------------------------------
    procedure multiply (
        signal multiplier : inout multiplier_record;
        data_a : in integer;
        data_b : in integer);
------------------------------------------------------------------------
    function get_multiplier_result (
        multiplier : multiplier_record;
        radix : natural range 0 to output_word_bit_width) 
    return integer ;
------------------------------------------------------------------------
    function multiplier_is_ready (
        multiplier : multiplier_record)
    return boolean;
------------------------------------------------------------------------
    function multiplier_is_not_busy (
        multiplier : multiplier_record)
    return boolean;
------------------------------------------------------------------------
    procedure sequential_multiply (
        signal multiplier : inout multiplier_record;
        data_a : in integer;
        data_b : in integer);
------------------------------------------------------------------------
    procedure increment_counter_when_ready (
        multiplier : multiplier_record;
        signal counter : inout natural);
------------------------------------------------------------------------
    procedure multiply_and_increment_counter (
        signal multiplier : inout multiplier_record;
        signal counter : inout integer;
        left, right : integer);

------------------------------------------------------------------------
end package multiplier_pkg;

    --------------------------------------------------
        -- impure function "*" ( left, right : integer)
        -- return integer
        -- is
        -- begin
        --     sequential_multiply(hw_multiplier, left, right);
        --     return get_multiplier_result(hw_multiplier, 15);
        -- end "*";
    --------------------------------------------------

package body multiplier_pkg is

    constant data_a_bit_width : integer := initialize_multiplier_base.signed_data_a(0)'length;
    constant data_b_bit_width : integer := initialize_multiplier_base.signed_data_b(0)'length;

------------------------------------------------------------------------
    function to_integer
    (
        std_vector : std_logic_vector 
    )
    return integer
    is
    begin
        return to_integer(unsigned(std_vector));
    end to_integer;
------------------------------------------------------------------------
    procedure increment
    (
        signal counter_to_be_incremented : inout integer
    ) is
    begin
        counter_to_be_incremented <= counter_to_be_incremented + 1;
    end increment;
------------------------------------------------------------------------
    procedure create_multiplier
    (
        signal multiplier : inout multiplier_record
    ) is

        alias multiplier_result           is multiplier.multiplier_result;
        alias shift_register                 is multiplier.shift_register;
        alias multiplier_is_busy             is multiplier.multiplier_is_busy;
        alias multiplier_is_requested_with_1 is multiplier.multiplier_is_requested_with_1;
        alias signed_data_a                  is multiplier.signed_data_a;
        alias signed_data_b                  is multiplier.signed_data_b;
    begin
        
        signed_data_a(signed_data_a'right) <= signed_data_a(0);
        signed_data_b(signed_data_b'right) <= signed_data_b(0);

        multiplier_result(multiplier_result'right) <= signed_data_a(signed_data_a'left) * signed_data_b(signed_data_b'left); 
        multiplier_is_requested_with_1 <= '0';
        shift_register <= shift_register(shift_register'left-1 downto 0) & multiplier_is_requested_with_1;

        multiplier_is_busy <= to_integer(shift_register) /= 0;

    end create_multiplier;

------------------------------------------------------------------------
    procedure multiply
    (
        signal multiplier : inout multiplier_record;
        data_a : in integer;
        data_b : in integer
    ) is
    begin
        multiplier.signed_data_a(0) <= to_signed(data_a, data_a_bit_width);
        multiplier.signed_data_b(0) <= to_signed(data_b, data_b_bit_width);
        multiplier.multiplier_is_requested_with_1 <= '1';

    end multiply;
------------------------------------------------------------------------
    procedure sequential_multiply
    (
        signal multiplier : inout multiplier_record;
        data_a : in integer;
        data_b : in integer
    ) is
    begin
        if multiplier_is_not_busy(multiplier) then
            multiplier.signed_data_a(0) <= to_signed(data_a, data_a_bit_width);
            multiplier.signed_data_b(0) <= to_signed(data_b, data_b_bit_width);
            multiplier.multiplier_is_requested_with_1 <= '1';
        end if;
        
    end sequential_multiply;

------------------------------------------------------------------------
    function multiplier_is_ready
    (
        multiplier : multiplier_record
    )
    return boolean
    is
    begin
        return multiplier.shift_register(multiplier.shift_register'left) = '1';
    end multiplier_is_ready;

------------------------------------------------------------------------
    -- get rounded result
    function get_multiplier_result
    (
        multiplier_output : signed(initialize_multiplier_base.multiplier_result(0)'range);
        radix : natural range 0 to output_word_bit_width
    ) return integer 
    is
    ---------------------------------------------------
        function "+"
        (
            left : integer;
            right : std_logic 
        )
        return integer
        is
        begin
            if left > 0 then
                if right = '1' then
                    return left + 1;
                else
                    return left;
                end if;
            else
                return left;
            end if;
        end "+";
    --------------------------------------------------         
        variable bit_vector_slice : signed(output_left_index downto 0);
        alias multiplier_raw_result is multiplier_output;
    begin
        bit_vector_slice := multiplier_raw_result((multiplier_raw_result'left-output_word_bit_width + radix) downto radix); 
        if radix > 0 then
            return to_integer(bit_vector_slice) + multiplier_raw_result(radix - 1);
        else
            return to_integer(bit_vector_slice);
        end if;
        
    end get_multiplier_result;
--------------------------------------------------
    function get_multiplier_result
    (
        multiplier : multiplier_record;
        radix : natural range 0 to output_word_bit_width
    )
    return integer
    is
    begin
        return get_multiplier_result(multiplier.multiplier_result(multiplier.multiplier_result'left), radix);
        
    end get_multiplier_result;

------------------------------------------------------------------------ 
    function multiplier_is_not_busy
    (
        multiplier : multiplier_record
    )
    return boolean
    is
    begin
        
        return to_integer(multiplier.shift_register) = 0 and (multiplier.multiplier_is_requested_with_1 = '0');
    end multiplier_is_not_busy;
------------------------------------------------------------------------
    procedure increment_counter_when_ready
    (
        multiplier : multiplier_record;
        signal counter : inout natural
    ) is
    begin
        if multiplier_is_ready(multiplier) then
            counter <= counter + 1;
        end if;
    end increment_counter_when_ready;
------------------------------------------------------------------------
    procedure multiply_and_get_result
    (
        signal multiplier : inout multiplier_record;
        radix : natural range 0 to output_word_bit_width;
        signal result : out integer;
        left, right : integer
    ) 
    is
    begin

        sequential_multiply(multiplier, left, right);
        if multiplier_is_ready(multiplier) then
            result <= get_multiplier_result(multiplier, radix);
        end if; 
        
    end multiply_and_get_result;

------------------------------------------------------------------------
    procedure multiply_and_increment_counter
    (
        signal multiplier : inout multiplier_record;
        signal counter : inout integer;
        left, right : integer
    ) 
    is
    begin

        multiply(multiplier, left, right);
        counter <= counter + 1;
        
    end multiply_and_increment_counter;

------------------------------------------------------------------------
end package body multiplier_pkg; 
