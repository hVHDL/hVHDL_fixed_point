library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package abc_to_ab_transform_pkg is

------------------------------------------------------------------------
    type abc_to_ab_transform_record is record

        abc_to_ab_multiplier_process_counter : natural range 0 to 15;
        abc_to_ab_calculation_process_counter : natural range 0 to 15;

        alpha : int18;
        beta  : int18;
        gamma : int18;

        alpha_sum : int18;
        beta_sum  : int18;
        gamma_sum : int18;

        abc_to_ab_is_ready : boolean;
    end record;

    constant init_abc_to_ab_transform : abc_to_ab_transform_record := 
        (0, 0, 0, 0, 0,
        0, 0, 0, false);

------------------------------------------------------------------------
    function get_alpha ( abc_to_ab_object : abc_to_ab_transform_record)
        return integer;
------------------------------------------------------------------------
    function get_beta ( abc_to_ab_object : abc_to_ab_transform_record)
        return integer;
------------------------------------------------------------------------
    function get_gamma ( abc_to_ab_object : abc_to_ab_transform_record)
        return integer;
------------------------------------------------------------------------
    function abc_to_ab_transform_is_ready ( abc_to_ab_object : abc_to_ab_transform_record)
        return boolean;
------------------------------------------------------------------------
    procedure request_abc_to_ab_transform (
        signal abc_to_ab_object : inout abc_to_ab_transform_record);
------------------------------------------------------------------------
    procedure create_abc_to_ab_transformer (
        signal hw_multiplier : inout multiplier_record;
        signal abc_to_ab_object : inout abc_to_ab_transform_record;
        phase_a : integer;
        phase_b : integer;
        phase_c : integer);
------------------------------------------------------------------------

end package abc_to_ab_transform_pkg;

package body abc_to_ab_transform_pkg is
------------------------------------------------------------------------
    function get_alpha
    (
        abc_to_ab_object : abc_to_ab_transform_record
    )
    return integer
    is
    begin
        return abc_to_ab_object.alpha;
    end get_alpha;
------------------------------------------------------------------------
    function get_beta
    (
        abc_to_ab_object : abc_to_ab_transform_record
    )
    return integer
    is
    begin
        return abc_to_ab_object.beta;
    end get_beta;
------------------------------------------------------------------------
    function get_gamma
    (
        abc_to_ab_object : abc_to_ab_transform_record
    )
    return integer
    is
    begin
        return abc_to_ab_object.gamma;
    end get_gamma;
------------------------------------------------------------------------
    function abc_to_ab_transform_is_ready
    (
        abc_to_ab_object : abc_to_ab_transform_record
    )
    return boolean
    is
    begin
        return abc_to_ab_object.abc_to_ab_is_ready;
    end abc_to_ab_transform_is_ready;
------------------------------------------------------------------------
    procedure request_abc_to_ab_transform
    (
        signal abc_to_ab_object : inout abc_to_ab_transform_record
    ) is
    begin
        abc_to_ab_object.abc_to_ab_multiplier_process_counter  <= 0;
        abc_to_ab_object.abc_to_ab_calculation_process_counter <= 0;
        
    end request_abc_to_ab_transform;

------------------------------------------------------------------------
    procedure create_abc_to_ab_transformer
    (
        signal hw_multiplier : inout multiplier_record;
        signal abc_to_ab_object : inout abc_to_ab_transform_record;
        phase_a : integer;
        phase_b : integer;
        phase_c : integer
    ) is
        alias abc_multiplier_process_counter is abc_to_ab_object.abc_to_ab_multiplier_process_counter;
        alias abc_transform_process_counter is abc_to_ab_object.abc_to_ab_calculation_process_counter;

        alias alpha is abc_to_ab_object.alpha;
        alias beta  is abc_to_ab_object.beta;
        alias gamma is abc_to_ab_object.gamma;

        alias alpha_sum is abc_to_ab_object.alpha_sum;
        alias beta_sum  is abc_to_ab_object.beta_sum;
        alias gamma_sum is abc_to_ab_object.gamma_sum;

        alias abc_to_ab_is_ready is abc_to_ab_object.abc_to_ab_is_ready;

    begin

            abc_to_ab_is_ready <= false;
            CASE abc_multiplier_process_counter is
                WHEN 0 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_a, 43691 );
                WHEN 1 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_b, -21845 );
                WHEN 2 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_c, -21845 );

                WHEN 3 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_a, 0 );
                WHEN 4 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_b, 37837 );
                WHEN 5 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_c, -37837 );

                WHEN 6 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_a, 21845 );
                WHEN 7 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_b, 21845 );
                WHEN 8 => multiply_and_increment_counter(hw_multiplier, abc_multiplier_process_counter, phase_c, 21845 );
                WHEN others =>
            end CASE;

            CASE abc_transform_process_counter is
                WHEN 0 =>
                    if multiplier_is_ready(hw_multiplier) then
                        alpha_sum <= get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                    end if;
                WHEN 1 =>
                        alpha_sum <= alpha_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 2 =>
                        alpha <= alpha_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 3 =>
                        beta_sum <= get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 4 =>
                        beta_sum <= beta_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 5 =>
                        beta <= beta_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 6 =>
                        gamma_sum <= get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 7 =>
                        gamma_sum <= gamma_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 8 =>
                        gamma <= gamma_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                        abc_to_ab_is_ready <= true;

                WHEN others => -- wait for restart
            end CASE;
    end create_abc_to_ab_transformer;

------------------------------------------------------------------------
end package body abc_to_ab_transform_pkg;
