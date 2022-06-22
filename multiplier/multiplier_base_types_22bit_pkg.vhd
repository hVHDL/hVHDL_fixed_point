library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package multiplier_base_types_pkg is

    constant number_of_input_bits : integer := 22;

    type input_array is array (integer range 1 downto 0) of signed(number_of_input_bits-1 downto 0);
    constant init_input_array :  input_array := (0=> (others => '0'), 1 => (others => '0'));
    type output_array is array (integer range 1 downto 0) of signed(init_input_array(0)'length*2-1 downto 0);
    constant init_output_array :  output_array := (0=> (others => '0'), 1 => (others => '0'));

    constant output_word_bit_width      : natural := init_input_array(0)'length;
    constant output_left_index          : natural := output_word_bit_width-1;

end package multiplier_base_types_pkg;
