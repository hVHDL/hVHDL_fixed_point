library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package dq_to_ab_transform_pkg is

------------------------------------------------------------------------
    type dq_to_ab_record is record
        dq_to_ab_multiplier_counter : natural range 0 to 15;
        dq_to_ab_calculation_counter : natural range 0 to 15;

        alpha     : int18;
        alpha_sum : int18;
        beta      : int18;
        beta_sum  : int18;

        sine   : int18;
        cosine : int18;
        d      : int18;
        q      : int18;
    end record;
------------------------------------------------------------------------

    constant init_dq_to_ab_transform : dq_to_ab_record := (15, 15, 0, 0, 0, 0, 0, 0, 0,0);

------------------------------------------------------------------------
    procedure request_dq_to_ab_transform (
        signal dq_ab_transform_object : out dq_to_ab_record;
        sine                          : in int18;
        cosine                        : in int18;
        d                             : in int18;
        q                             : in int18);
------------------------------------------------------------------------
    procedure create_dq_to_ab_transform (
        signal hw_multiplier          : inout multiplier_record;
        signal dq_ab_transform_object : inout dq_to_ab_record);
------------------------------------------------------------------------


end package dq_to_ab_transform_pkg;

package body dq_to_ab_transform_pkg is

------------------------------------------------------------------------
    procedure request_dq_to_ab_transform
    (
        signal dq_ab_transform_object : out dq_to_ab_record;
        sine                          : in int18;
        cosine                        : in int18;
        d                             : in int18;
        q                             : in int18
    ) is
    begin
        dq_ab_transform_object.dq_to_ab_multiplier_counter <= 0;
        dq_ab_transform_object.dq_to_ab_calculation_counter <= 0;

        dq_ab_transform_object.sine   <= sine  ;
        dq_ab_transform_object.cosine <= cosine;
        dq_ab_transform_object.d      <= d     ;
        dq_ab_transform_object.q      <= q     ;
    end request_dq_to_ab_transform;
------------------------------------------------------------------------
    procedure create_dq_to_ab_transform
    (
        signal hw_multiplier          : inout multiplier_record;
        signal dq_ab_transform_object : inout dq_to_ab_record
    ) is

        alias dq_to_ab_multiplier_counter  is dq_ab_transform_object.dq_to_ab_multiplier_counter ;
        alias dq_to_ab_calculation_counter is dq_ab_transform_object.dq_to_ab_calculation_counter;

        alias alpha     is dq_ab_transform_object.alpha    ;
        alias alpha_sum is dq_ab_transform_object.alpha_sum;
        alias beta      is dq_ab_transform_object.beta     ;
        alias beta_sum  is dq_ab_transform_object.beta_sum ;

        alias sine   is dq_ab_transform_object.sine  ;
        alias cosine is dq_ab_transform_object.cosine;
        alias d      is dq_ab_transform_object.d     ;
        alias q      is dq_ab_transform_object.q     ;

    begin

        CASE dq_to_ab_multiplier_counter is
            WHEN 0 =>
                multiply_and_increment_counter(hw_multiplier, dq_to_ab_multiplier_counter, cosine, d);
            WHEN 1 =>
                multiply_and_increment_counter(hw_multiplier, dq_to_ab_multiplier_counter, sine, q);
            WHEN 2 =>
                multiply_and_increment_counter(hw_multiplier, dq_to_ab_multiplier_counter, -sine, d);
            WHEN 3 =>
                multiply_and_increment_counter(hw_multiplier, dq_to_ab_multiplier_counter, cosine, q);
            WHEN others =>
        end CASE;

        CASE dq_to_ab_calculation_counter is
            WHEN 0 =>
                if multiplier_is_ready(hw_multiplier) then
                    alpha_sum <= get_multiplier_result(hw_multiplier,15);
                    increment(dq_to_ab_calculation_counter);
                end if;
            WHEN 1 =>
                alpha <= get_multiplier_result(hw_multiplier,15);
                increment(dq_to_ab_calculation_counter);
            WHEN 2 =>
                beta_sum <= alpha_sum + get_multiplier_result(hw_multiplier,15);
                increment(dq_to_ab_calculation_counter);
            WHEN 3 =>
                beta <= beta_sum + get_multiplier_result(hw_multiplier,15);
                increment(dq_to_ab_calculation_counter);
            WHEN others => -- hang and wait for start
        end CASE;
    end create_dq_to_ab_transform;

------------------------------------------------------------------------
end package body dq_to_ab_transform_pkg;
