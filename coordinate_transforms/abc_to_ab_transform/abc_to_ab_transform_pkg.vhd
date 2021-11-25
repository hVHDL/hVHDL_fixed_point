library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package abc_to_ab_transform_pkg is

    type abc_to_ab_transform_record is record
        abc_to_ab_multiplier_process_counter : natural range 0 to 15;
        abc_to_ab_calculation_process_counter : natural range 0 to 15;
        alpha : int18;
        beta  : int18;
        gamma : int18;

        alpha_sum : int18;
        beta_sum : int18;
        gamma_sum: int18;
    end record;

    constant init_abc_to_ab_transform : abc_to_ab_transform_record := 
        (0, 0, 0, 0, 0,
        0, 0, 0);

end package abc_to_ab_transform_pkg;
