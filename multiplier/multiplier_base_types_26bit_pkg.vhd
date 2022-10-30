library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    -- 26 bit wordlength
package multiplier_base_types_pkg is

    constant number_of_input_bits       : integer := 26;
    constant number_of_input_registers  : integer := 2;
    constant number_of_output_registers : integer := 2;

end package multiplier_base_types_pkg;
