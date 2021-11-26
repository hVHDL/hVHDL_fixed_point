library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package multiplier_pkg is

    subtype signed_36_bit is signed(35 downto 0);
    subtype int18 is integer range -2**17 to 2**17-1;
    subtype uint17 is integer range 0 to 2**17-1;

    type multiplier_record is record
        signed_data_a        : signed(17 downto 0);
        signed_data_b        : signed(17 downto 0);
        data_a_buffer        : signed(17 downto 0);
        data_b_buffer        : signed(17 downto 0);
        signed_36_bit_buffer : signed(35 downto 0);
        signed_36_bit_result : signed(35 downto 0);
        shift_register       : std_logic_vector(2 downto 0);
        multiplier_is_busy   : boolean;
        multiplier_is_requested_with_1 : std_logic;
    end record;

    constant multiplier_init_values : multiplier_record := ( (others => '0'),(others => '0'),(others => '0'), (others => '0'), (others => '0'), (others => '0'), (others => '0'), false, '0');
    constant init_multiplier : multiplier_record := multiplier_init_values;

------------------------------------------------------------------------
    procedure increment ( signal counter_to_be_incremented : inout integer);
------------------------------------------------------------------------
    procedure create_multiplier (
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    procedure multiply_and_get_result (
        signal multiplier : inout multiplier_record;
        radix : natural range 0 to 17;
        signal result : out int18;
        left, right : int18) ; 
------------------------------------------------------------------------
    procedure multiply (
        signal multiplier : inout multiplier_record;
        data_a : in int18;
        data_b : in int18);
------------------------------------------------------------------------
    function get_multiplier_result (
        multiplier : multiplier_record;
        radix : natural range 0 to 18) 
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
        data_a : in int18;
        data_b : in int18);
------------------------------------------------------------------------
    procedure increment_counter_when_ready (
        multiplier : multiplier_record;
        signal counter : inout natural);
------------------------------------------------------------------------
    procedure multiply_and_increment_counter (
        signal multiplier : inout multiplier_record;
        signal counter : inout integer;
        left, right : int18);

------------------------------------------------------------------------
end package multiplier_pkg;

    --------------------------------------------------
        -- impure function "*" ( left, right : int18)
        -- return int18
        -- is
        -- begin
        --     sequential_multiply(hw_multiplier, left, right);
        --     return get_multiplier_result(hw_multiplier, 15);
        -- end "*";
    --------------------------------------------------

package body multiplier_pkg is

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

        alias signed_36_bit_result is multiplier.signed_36_bit_result;
        alias shift_register is multiplier.shift_register;
        alias multiplier_is_busy is multiplier.multiplier_is_busy;
        alias multiplier_is_requested_with_1 is multiplier.multiplier_is_requested_with_1;
        alias signed_data_a is multiplier.signed_data_a;
        alias signed_data_b is multiplier.signed_data_b;
    begin
        
        multiplier.data_a_buffer <= signed_data_a;
        multiplier.data_b_buffer <= signed_data_b;

        multiplier.signed_36_bit_buffer <= multiplier.data_a_buffer * multiplier.data_b_buffer; 
        signed_36_bit_result <= multiplier.signed_36_bit_buffer;
        multiplier_is_requested_with_1 <= '0';
        shift_register <= shift_register(shift_register'left-1 downto 0) & multiplier_is_requested_with_1;

        multiplier_is_busy <= shift_register /= "000";

    end create_multiplier;

------------------------------------------------------------------------
    procedure multiply
    (
        signal multiplier : inout multiplier_record;
        data_a : in int18;
        data_b : in int18
    ) is
    begin
        multiplier.signed_data_a <= to_signed(data_a, 18);
        multiplier.signed_data_b <= to_signed(data_b, 18);
        multiplier.multiplier_is_requested_with_1 <= '1';

    end multiply;
------------------------------------------------------------------------
    procedure sequential_multiply
    (
        signal multiplier : inout multiplier_record;
        data_a : in int18;
        data_b : in int18
    ) is
    begin
        if multiplier_is_not_busy(multiplier) then
            multiplier.signed_data_a <= to_signed(data_a, 18);
            multiplier.signed_data_b <= to_signed(data_b, 18);
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
        multiplier_output : signed_36_bit;
        radix : natural range 0 to 18
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
        variable bit_vector_slice : signed(17 downto 0);
        constant output_word_bit_width : natural := 18;
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
        radix : natural range 0 to 18
    )
    return integer
    is
    begin
        return get_multiplier_result(multiplier.signed_36_bit_result, radix);
        
    end get_multiplier_result;

------------------------------------------------------------------------ 
    function multiplier_is_not_busy
    (
        multiplier : multiplier_record
    )
    return boolean
    is
    begin
        
        return multiplier.shift_register = "000" and (multiplier.multiplier_is_requested_with_1 = '0');
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
        radix : natural range 0 to 17;
        signal result : out int18;
        left, right : int18
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
        left, right : int18
    ) 
    is
    begin

        multiply(multiplier, left, right);
        counter <= counter + 1;
        
    end multiply_and_increment_counter;

------------------------------------------------------------------------
end package body multiplier_pkg; 
