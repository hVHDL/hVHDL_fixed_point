library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package dq_to_ab_transform_pkg is

------------------------------------------------------------------------
    type dq_to_ab_record is record
        dq_to_ab_multiplier_counter : natural range 0 to 15;
        dq_to_ab_calculation_counter : natural range 0 to 15;

        alpha     : int;
        alpha_sum : int;
        beta      : int;
        beta_sum  : int;

        sine   : int;
        cosine : int;
        d      : int;
        q      : int;

        dq_to_ab_calculation_is_ready : boolean;
    end record;

    ------------------------------
    constant init_dq_to_ab_transform : dq_to_ab_record := (15, 15, 0, 0, 0, 0, 0, 0, 0,0,false);

------------------------------------------------------------------------
    function dq_to_ab_transform_is_ready ( dq_ab_transform_object : dq_to_ab_record)
        return boolean;
------------------------------------------------------------------------
    function get_alpha ( dq_ab_transform_object : dq_to_ab_record)
        return int;
------------------------------------------------------------------------
    function get_beta ( dq_ab_transform_object : dq_to_ab_record)
        return int;
------------------------------------------------------------------------
    procedure request_dq_to_ab_transform (
        signal dq_ab_transform_object : out dq_to_ab_record;
        sine                          : in int;
        cosine                        : in int;
        d                             : in int;
        q                             : in int);
------------------------------------------------------------------------
    procedure create_dq_to_ab_transform (
        signal hw_multiplier          : inout multiplier_record;
        signal dq_ab_transform_object : inout dq_to_ab_record);
------------------------------------------------------------------------


end package dq_to_ab_transform_pkg;

package body dq_to_ab_transform_pkg is

------------------------------------------------------------------------
    function dq_to_ab_transform_is_ready
    (
        dq_ab_transform_object : dq_to_ab_record
    )
    return boolean
    is
    begin
        return dq_ab_transform_object.dq_to_ab_calculation_is_ready;
    end dq_to_ab_transform_is_ready;
------------------------------------------------------------------------
    function get_alpha
    (
        dq_ab_transform_object : dq_to_ab_record
    )
    return int
    is
    begin
        return dq_ab_transform_object.alpha;
        
    end get_alpha;
------------------------------------------------------------------------
    function get_beta
    (
        dq_ab_transform_object : dq_to_ab_record
    )
    return int
    is
    begin
        return dq_ab_transform_object.beta;
        
    end get_beta;
------------------------------------------------------------------------
    procedure request_dq_to_ab_transform
    (
        signal dq_ab_transform_object : out dq_to_ab_record;
        sine                          : in int;
        cosine                        : in int;
        d                             : in int;
        q                             : in int
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
        alias dq_to_ab_calculation_is_ready is dq_ab_transform_object.dq_to_ab_calculation_is_ready;

    begin
    --------------------------------------------------

        dq_to_ab_calculation_is_ready <= false;
    --------------------------------------------------
        CASE dq_to_ab_multiplier_counter is
            WHEN 0 => multiply_and_increment_counter(hw_multiplier , dq_to_ab_multiplier_counter , cosine , d);
            WHEN 1 => multiply_and_increment_counter(hw_multiplier , dq_to_ab_multiplier_counter , -sine  , q);
            WHEN 2 => multiply_and_increment_counter(hw_multiplier , dq_to_ab_multiplier_counter , sine   , d);
            WHEN 3 => multiply_and_increment_counter(hw_multiplier , dq_to_ab_multiplier_counter , cosine , q);
            WHEN others =>
        end CASE;

    --------------------------------------------------
        CASE dq_to_ab_calculation_counter is
            WHEN 0 =>
                if multiplier_is_ready(hw_multiplier) then
                    alpha_sum <= get_multiplier_result(hw_multiplier,15);
                    increment(dq_to_ab_calculation_counter);
                end if;
            WHEN 1 =>
                alpha <= alpha_sum + get_multiplier_result(hw_multiplier,15);
                increment(dq_to_ab_calculation_counter);
            WHEN 2 =>
                beta_sum <= get_multiplier_result(hw_multiplier,15);
                increment(dq_to_ab_calculation_counter);
            WHEN 3 =>
                dq_to_ab_calculation_is_ready <= true;
                beta <= beta_sum + get_multiplier_result(hw_multiplier,15);
                increment(dq_to_ab_calculation_counter);
            WHEN others => -- hang and wait for start
        end CASE;
    --------------------------------------------------
    end create_dq_to_ab_transform;

------------------------------------------------------------------------
end package body dq_to_ab_transform_pkg;
