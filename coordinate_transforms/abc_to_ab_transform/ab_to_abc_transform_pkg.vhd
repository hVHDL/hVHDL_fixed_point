library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package ab_to_abc_transform_pkg is
------------------------------------------------------------------------
    type alpha_beta_to_abc_transform_record is record

        alpha_beta_to_abc_multiplier_process_counter : natural range 0 to 15;
        alpha_beta_to_abc_calculation_process_counter : natural range 0 to 15;

        phase_a : int18;
        phase_b : int18;
        phase_c : int18;

        phase_a_sum : int18;
        phase_b_sum : int18;
        phase_c_sum : int18;

        alpha_beta_to_abc_transform_is_ready : boolean;
    end record;

    constant init_alpha_beta_to_abc_transform : alpha_beta_to_abc_transform_record := 
        (0, 0, 0, 0, 0,
        0, 0, 0, false);

------------------------------------------------------------------------
    function get_phase_a ( alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record)
        return integer;
------------------------------------------------------------------------
    function get_phase_b ( alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record)
        return integer;
------------------------------------------------------------------------
    function get_phase_c ( alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record)
        return integer;
------------------------------------------------------------------------
    function ab_to_abc_transform_is_ready ( alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record)
        return boolean;
------------------------------------------------------------------------
    procedure request_alpha_beta_to_abc_transform (
        signal alpha_beta_to_abc_object : inout alpha_beta_to_abc_transform_record);
------------------------------------------------------------------------
    procedure create_alpha_beta_to_abc_transformer (
        signal hw_multiplier : inout multiplier_record;
        signal alpha_beta_to_abc_object : inout alpha_beta_to_abc_transform_record;
        alpha : integer;
        beta : integer;
        gamma : integer);

------------------------------------------------------------------------
end package ab_to_abc_transform_pkg;

package body ab_to_abc_transform_pkg is
------------------------------------------------------------------------
    function get_phase_a
    (
        alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record
    )
    return integer
    is
    begin
        return alpha_beta_to_abc_object.phase_a;
    end get_phase_a;
------------------------------------------------------------------------
    function get_phase_b
    (
        alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record
    )
    return integer
    is
    begin
        return alpha_beta_to_abc_object.phase_b;
    end get_phase_b;
------------------------------------------------------------------------
    function get_phase_c
    (
        alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record
    )
    return integer
    is
    begin
        return alpha_beta_to_abc_object.phase_c;
    end get_phase_c;
------------------------------------------------------------------------
    function ab_to_abc_transform_is_ready
    (
        alpha_beta_to_abc_object : alpha_beta_to_abc_transform_record
    )
    return boolean
    is
    begin
        return alpha_beta_to_abc_object.alpha_beta_to_abc_transform_is_ready;
    end ab_to_abc_transform_is_ready;
------------------------------------------------------------------------
    procedure request_alpha_beta_to_abc_transform
    (
        signal alpha_beta_to_abc_object : inout alpha_beta_to_abc_transform_record
    ) is
    begin
        alpha_beta_to_abc_object.alpha_beta_to_abc_multiplier_process_counter  <= 0;
        alpha_beta_to_abc_object.alpha_beta_to_abc_calculation_process_counter <= 0;
        
    end request_alpha_beta_to_abc_transform;

------------------------------------------------------------------------
    procedure create_alpha_beta_to_abc_transformer
    (
        signal hw_multiplier : inout multiplier_record;
        signal alpha_beta_to_abc_object : inout alpha_beta_to_abc_transform_record;
        alpha : integer;
        beta : integer;
        gamma : integer
    ) is
        alias abc_multiplier_process_counter is alpha_beta_to_abc_object.alpha_beta_to_abc_multiplier_process_counter;
        alias abc_transform_process_counter is alpha_beta_to_abc_object.alpha_beta_to_abc_calculation_process_counter;

        alias phase_a is alpha_beta_to_abc_object.phase_a;
        alias phase_b  is alpha_beta_to_abc_object.phase_b;
        alias phase_c is alpha_beta_to_abc_object.phase_c;

        alias phase_a_sum is alpha_beta_to_abc_object.phase_a_sum;
        alias phase_b_sum  is alpha_beta_to_abc_object.phase_b_sum;
        alias phase_c_sum is alpha_beta_to_abc_object.phase_c_sum;

        alias alpha_beta_to_abc_transform_is_ready is alpha_beta_to_abc_object.alpha_beta_to_abc_transform_is_ready;
    begin

        ------------------------------------------------------------------------
            alpha_beta_to_abc_transform_is_ready <= false;
        ------------------------------------------------------------------------
            CASE abc_multiplier_process_counter is
                WHEN 0 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , alpha , 65536 );
                WHEN 1 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , beta  , 0 );
                WHEN 2 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , gamma , 65536 );

                WHEN 3 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , alpha , -32768 );
                WHEN 4 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , beta  , 56756 );
                WHEN 5 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , gamma , 65536 );

                WHEN 6 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , alpha , -32768 );
                WHEN 7 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , beta  , -56756 );
                WHEN 8 => multiply_and_increment_counter(hw_multiplier , abc_multiplier_process_counter , gamma , 65536 );
                WHEN others => -- wait for restart
            end CASE;

        ------------------------------------------------------------------------
            CASE abc_transform_process_counter is
                WHEN 0 =>
                    if multiplier_is_ready(hw_multiplier) then
                        phase_a_sum <= get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                    end if;
                WHEN 1 =>
                        phase_a_sum <= phase_a_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 2 =>
                        phase_a <= phase_a_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 3 =>
                        phase_b_sum <= get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 4 =>
                        phase_b_sum <= phase_b_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 5 =>
                        phase_b <= phase_b_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;

                WHEN 6 =>
                        phase_c_sum <= get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 7 =>
                        phase_c_sum <= phase_c_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                WHEN 8 =>
                        phase_c <= phase_c_sum + get_multiplier_result(hw_multiplier,16);
                        abc_transform_process_counter <= abc_transform_process_counter + 1;
                        alpha_beta_to_abc_transform_is_ready <= true;

                WHEN others => -- wait for restart
            end CASE;
        ------------------------------------------------------------------------

    end create_alpha_beta_to_abc_transformer;

------------------------------------------------------------------------

end package body ab_to_abc_transform_pkg;
