library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pipeline_registers_pkg;

    -- 20 bit wordlength
package multiplier_base_types_pkg is

    constant number_of_input_bits       : integer := 20;
    alias number_of_input_registers  is work.multiplier_pipeline_registers_pkg.input_registers;
    alias number_of_output_registers is work.multiplier_pipeline_registers_pkg.output_registers;
    subtype int is integer range -2**(number_of_input_bits-1) to 2**(number_of_input_bits-1)-1;

end package multiplier_base_types_pkg;
