library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_base_types_pkg.all;

package multiplier_pkg is

    subtype s_int is signed(number_of_input_bits-1 downto 0);
    type input_array is array (integer range number_of_input_registers-1 downto 0) of s_int;
    constant init_input_array :  input_array := (others => (others => '0'));
    type output_array is array (integer range number_of_output_registers-1 downto 0) of signed(init_input_array(0)'length*2-1 downto 0);
    constant init_output_array :  output_array := (others => (others => '0'));

    constant output_word_bit_width      : natural := init_input_array(0)'length;
    constant output_left_index          : natural := output_word_bit_width-1;


    alias int_word_length is number_of_input_bits;
    subtype int is integer range -2**(number_of_input_bits-1) to 2**(number_of_input_bits-1)-1;

    constant number_of_pipeline_cycles : integer := number_of_input_registers + number_of_output_registers-1;

    type multiplier_base_record is record
        signed_data_a                  : input_array;
        signed_data_b                  : input_array;
        multiplier_result              : output_array;
        shift_register                 : std_logic_vector(number_of_pipeline_cycles downto 0);
    end record;

    constant initialize_multiplier_base : multiplier_base_record := (init_input_array, init_input_array, init_output_array, (others => '0'));

    subtype multiplier_record is multiplier_base_record;
    constant multiplier_init_values : multiplier_record := initialize_multiplier_base;
    constant init_multiplier : multiplier_record := multiplier_init_values;

------------------------------------------------------------------------
    procedure increment ( signal counter_to_be_incremented : inout integer);
------------------------------------------------------------------------
    procedure create_multiplier (
        signal self : inout multiplier_record);
------------------------------------------------------------------------
    procedure multiply_and_get_result (
        signal self : inout multiplier_record;
        radix : natural range 0 to output_word_bit_width;
        signal result : out integer;
        left, right : integer) ; 
------------------------------------------------------------------------
    procedure multiply (
        signal self : inout multiplier_record;
        data_a : in integer;
        data_b : in integer);

    procedure multiply (
        signal self : inout multiplier_record;
        data_a : in signed;
        data_b : in signed);
------------------------------------------------------------------------
    function get_multiplier_result (
        multiplier : multiplier_record;
        radix : natural range 0 to output_word_bit_width) 
    return integer ;

    function get_multiplier_result (
        multiplier : multiplier_record;
        radix : natural range 0 to output_word_bit_width) 
    return signed;
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
        signal self : inout multiplier_record;
        data_a : in integer;
        data_b : in integer);
------------------------------------------------------------------------
    procedure increment_counter_when_ready (
        multiplier : multiplier_record;
        signal counter : inout natural);
------------------------------------------------------------------------
    procedure multiply_and_increment_counter (
        signal self : inout multiplier_record;
        signal counter : inout integer;
        left, right : integer);
------------
    procedure multiply_and_increment_counter (
        signal self : inout multiplier_record;
        signal counter : inout integer;
        left, right : signed);
------------------------------------------------------------------------
    function radix_multiply (
        left, right : signed;
        radix       : natural)
    return signed;
------------------------------------------------------------------------
    function radix_multiply (
        left, right : integer;
        word_length : natural;
        radix       : natural)
    return integer;
------------------------------------------------------------------------
    function set_number_if_integer_bits ( number : integer)
        return integer;
------------------------------------------------------------------------
end package multiplier_pkg;

    -- common local functions
    --------------------------------------------------
        -- impure function "*" ( left, right : integer)
        -- return integer
        -- is
        -- begin
        --     sequential_multiply(hw_multiplier, left, right);
        --     return get_multiplier_result(hw_multiplier, 15);
        -- end "*";
    --------------------------------------------------
        -- variable radix : integer := 15;
        --
        -- impure function "*" ( left, right : integer)
        -- return integer
        -- is
        --     constant word_length : integer := 18;
        -- begin
        --     return work.multiplier_pkg.radix_multiply(left,right, word_length, radix);
        -- end "*";
    --------------------------------------------------

package body multiplier_pkg is

    constant data_a_bit_width           : integer := initialize_multiplier_base.signed_data_a(0)'length;
    constant data_b_bit_width           : integer := initialize_multiplier_base.signed_data_b(0)'length;
    constant number_of_input_registers  : integer := initialize_multiplier_base.signed_data_a'length;
    constant number_of_output_registers : integer := initialize_multiplier_base.multiplier_result'length;

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
        signal self : inout multiplier_record
    ) is
    begin
        
        self.signed_data_a     <= self.signed_data_a(self.signed_data_a'left-1 downto 0)         & self.signed_data_a(0);
        self.signed_data_b     <= self.signed_data_b(self.signed_data_b'left-1 downto 0)         & self.signed_data_b(0);
        self.multiplier_result <= self.multiplier_result(self.multiplier_result'left-1 downto 0) & (self.signed_data_a(self.signed_data_a'left) * self.signed_data_b(self.signed_data_b'left));
        self.shift_register    <= self.shift_register(self.shift_register'left-1 downto 0)       & '0';

    end create_multiplier;

------------------------------------------------------------------------
    procedure multiply
    (
        signal self : inout multiplier_record;
        data_a : in signed;
        data_b : in signed
    ) is
    begin
        self.signed_data_a(0) <= data_a;
        self.signed_data_b(0) <= data_b;
        self.shift_register(0) <= '1';

    end multiply;

    procedure multiply
    (
        signal self : inout multiplier_record;
        data_a : in integer;
        data_b : in integer
    ) is
    begin
        self.signed_data_a(0) <= to_signed(data_a, data_a_bit_width);
        self.signed_data_b(0) <= to_signed(data_b, data_b_bit_width);
        self.shift_register(0) <= '1';

    end multiply;

------------------------------------------------------------------------
    procedure sequential_multiply
    (
        signal self : inout multiplier_record;
        data_a : in integer;
        data_b : in integer
    ) is
    begin
        if multiplier_is_not_busy(self) then
            self.signed_data_a(0) <= to_signed(data_a, data_a_bit_width);
            self.signed_data_b(0) <= to_signed(data_b, data_b_bit_width);
            self.shift_register(0) <= '1';
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
------------------------------
    function get_multiplier_result
    (
        multiplier_output : signed(initialize_multiplier_base.multiplier_result(0)'range);
        radix : natural range 0 to output_word_bit_width
    ) return signed 
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
    begin
        bit_vector_slice := multiplier_output((multiplier_output'left-output_word_bit_width + radix) downto radix); 
        if radix > 0 then
            bit_vector_slice := (bit_vector_slice) + multiplier_output(radix - 1);
        end if;

        return bit_vector_slice;
        
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

    function get_multiplier_result
    (
        multiplier : multiplier_record;
        radix : natural range 0 to output_word_bit_width
    )
    return signed
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
        
        return to_integer(multiplier.shift_register) = 0;
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
        signal self : inout multiplier_record;
        radix : natural range 0 to output_word_bit_width;
        signal result : out integer;
        left, right : integer
    ) 
    is
    begin

        sequential_multiply(self, left, right);
        if multiplier_is_ready(self) then
            result <= get_multiplier_result(self, radix);
        end if; 
        
    end multiply_and_get_result;

------------------------------------------------------------------------
    procedure multiply_and_increment_counter
    (
        signal self : inout multiplier_record;
        signal counter : inout integer;
        left, right : integer
    ) 
    is
    begin

        multiply(self, left, right);
        counter <= counter + 1;
        
    end multiply_and_increment_counter;
------------------------------
    procedure multiply_and_increment_counter
    (
        signal self : inout multiplier_record;
        signal counter : inout integer;
        left, right : signed
    ) 
    is
    begin

        multiply(self, left, right);
        counter <= counter + 1;
    end multiply_and_increment_counter;
        
------------------------------------------------------------------------
    function radix_multiply
    (
        left, right : signed;
        radix       : natural
    )
    return signed
    is
        constant word_length : natural := left'length + right'length;
        variable result : signed(word_length-1 downto 0);
    begin
        result := left * right;
        return result(left'length+radix-1 downto radix);
    end radix_multiply;
------------------------------------------------------------------------
    function radix_multiply
    (
        left, right : integer;
        word_length : natural;
        radix       : natural
    )
    return integer
    is
        variable result : signed(word_length-1 downto 0);
    begin
        result := radix_multiply(to_signed(left, word_length), to_signed(right, word_length), radix);
        return to_integer(result);
    end radix_multiply;
------------------------------------------------------------------------
    function set_number_if_integer_bits
    (
        number : integer
    )
    return integer
    is
    begin
        return int_word_length-number-1;
    end set_number_if_integer_bits;

end package body multiplier_pkg; 
