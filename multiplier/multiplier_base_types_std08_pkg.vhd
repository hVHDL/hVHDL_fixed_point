library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package multiplier_base_types_pkg is

    type multiplier_record_unconstrained is record
        signed_data_a        : signed;
        signed_data_b        : signed;
        data_a_buffer        : signed;
        data_b_buffer        : signed;
        signed_36_bit_buffer : signed;
        signed_36_bit_result : signed;
        shift_register       : std_logic_vector(2 downto 0);
        multiplier_is_busy   : boolean;
        multiplier_is_requested_with_1 : std_logic;
    end record;


end package multiplier_base_types_pkg;

