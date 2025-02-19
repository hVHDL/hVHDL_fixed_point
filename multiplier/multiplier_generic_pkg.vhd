
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use ieee.fixed_pkg.all;

package multiplier_generic_pkg is
    generic(g_number_of_input_bits : natural;
            g_input_registers    : natural;
            g_output_registers   : natural);

    constant output_word_bit_width : natural := g_number_of_input_bits;
    constant multiplier_word_length : natural := g_number_of_input_bits;

    subtype mpy_signed is signed(multiplier_word_length-1 downto 0);
    
    type input_array is array (integer range g_input_registers-1 downto 0) of signed(g_number_of_input_bits-1 downto 0);
    constant init_input_array  : input_array  := (others => (others => '0'));

    type output_array is array (integer range g_output_registers-1 downto 0) of signed(g_number_of_input_bits*2-1 downto 0);
    constant init_output_array : output_array := (others => (others => '0'));

    constant number_of_pipeline_cycles : integer := g_input_registers + g_output_registers-1;

    type multiplier_record is record
        signed_data_a     : input_array;
        signed_data_b     : input_array;
        multiplier_result : output_array;
        shift_register    : std_logic_vector(number_of_pipeline_cycles downto 0);
    end record;

    constant init_multiplier : multiplier_record := (init_input_array, init_input_array, init_output_array, (others => '0'));

    function to_signed ( left : unresolved_sfixed)
        return signed;

------------------------------------------------------------------------
    procedure create_multiplier (
        signal self : inout multiplier_record);

------------------------------------------------------------------------
    procedure multiply (
        signal self : inout multiplier_record;
        data_a : in signed;
        data_b : in signed);
------------------------------------------------------------------------
    function multiplier_is_ready (
        multiplier : multiplier_record)
    return boolean;
------------------------------------------------------------------------
    function get_multiplier_result (
        self : multiplier_record;
        input_a_radix : natural;
        input_b_radix : natural;
        target_radix : natural)
    return signed;

    function get_multiplier_result (
        self : multiplier_record;
        input_a : sfixed;
        input_b : sfixed;
        target : sfixed)
    return signed;

    function get_multiplier_result (
        multiplier : multiplier_record;
        radix : natural range 0 to output_word_bit_width) 
    return integer ;
------------------------------------------------------------------------
end package multiplier_generic_pkg;

package body multiplier_generic_pkg is

------------------------------------------------------------------------
    function to_signed
    (
        left : unresolved_sfixed
    )
    return signed 
    is
        variable retval : mpy_signed := (others => '0');

    begin
        if left'length > retval'length then
            for i in retval'range loop
                retval(i) := left(left'high - (retval'high-i));
            end loop;
        else
            for i in left'length-1 downto 0 loop
                retval(i) := left(left'high - (left'length-1-i));
            end loop;
        end if;

        return retval;

    end to_signed;

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

------------------------------------------------------------------------
    function get_multiplier_result
    (
        multiplier_output : signed(init_output_array(0)'range);
        radix : natural range 0 to output_word_bit_width
    ) return signed 
    is
    ---------------------------------------------------
        function "+"
        (
            left : signed;
            right : std_logic 
        )
        return signed
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
        variable bit_vector_slice : signed(init_input_array(0)'range);
    begin
        bit_vector_slice := multiplier_output((multiplier_output'left-output_word_bit_width + radix) downto radix); 
        if radix > 0 then
            bit_vector_slice := bit_vector_slice + multiplier_output(radix - 1);
        end if;

        return bit_vector_slice;
        
    end get_multiplier_result;
------------------------------------------------------------------------
    function get_multiplier_result
    (
        self : multiplier_record;
        input_a_radix : natural;
        input_b_radix : natural;
        target_radix : natural
    )
    return signed
    is
    begin
        return get_multiplier_result(self.multiplier_result(self.multiplier_result'left), input_a_radix + input_b_radix - target_radix);
        
    end get_multiplier_result;

------------------------------------------------------------------------
    function get_multiplier_result
    (
        self    : multiplier_record;
        input_a : sfixed;
        input_b : sfixed;
        target  : sfixed
    )
    return signed
    is
        variable signed_result : signed(multiplier_word_length-1 downto 0) := (others => '0');
    begin
        signed_result := get_multiplier_result(self.multiplier_result(self.multiplier_result'left), abs(input_a'low) + abs(input_b'low) - abs(target'low));
        return signed_result;
        
    end get_multiplier_result;
------------------------------------------------------------------------
    function get_multiplier_result
    (
    multiplier : multiplier_record;
    radix : natural range 0 to output_word_bit_width
    )
    return integer
    is 
    begin 
        return to_integer(get_multiplier_result(multiplier.multiplier_result(multiplier.multiplier_result'left), radix));
        
    end get_multiplier_result;
------------------------------------------------------------------------
end package body multiplier_generic_pkg; 
