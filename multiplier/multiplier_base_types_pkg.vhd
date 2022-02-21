library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package multiplier_base_types_pkg is


    type input_array is array (integer range 0 to 0) of signed(17 downto 0);
    constant init_input_array : input_array := (0=> (others => '0'));
    type output_array is array (integer range 0 to 0) of signed(35 downto 0);
    constant init_output_array : output_array := (0=> (others => '0'));

    type multiplier_base_record is record
        signed_data_a        : input_array;
        signed_data_b        : input_array;
        multiplier_result : output_array;
        shift_register       : std_logic_vector(0 downto 0);
        multiplier_is_busy   : boolean;
        multiplier_is_requested_with_1 : std_logic;
    end record;

    constant initialize_multiplier_base : multiplier_base_record := (init_input_array, init_input_array, init_output_array, (others => '0'), false, '0');
    constant output_word_bit_width : natural := 18;
    constant output_left_index : natural := output_word_bit_width-1;

end package multiplier_base_types_pkg;

