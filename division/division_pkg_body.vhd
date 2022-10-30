package body division_pkg is

------------------------------------------------------------------------
    procedure create_division
    (
        signal hw_multiplier : inout multiplier_record;
        signal division : inout division_record
    ) is
    --------------------------------------------------
        alias m is division;
    --------------------------------------------------
    begin
        
            CASE m.division_process_counter is
                WHEN 0 =>
                    multiply(hw_multiplier, m.x, m.number_to_be_reciprocated);
                    m.division_process_counter <= m.division_process_counter + 1;
                WHEN 1 =>
                    increment_counter_when_ready(hw_multiplier,m.division_process_counter);
                    if multiplier_is_ready(hw_multiplier) then
                        multiply(hw_multiplier, m.x, invert_bits(get_multiplier_result(hw_multiplier, 16)));
                    end if;
                WHEN 2 =>
                    if multiplier_is_ready(hw_multiplier) then
                        m.x <= get_multiplier_result(hw_multiplier, 16);
                        if m.number_of_newton_raphson_iteration /= 0 then
                            m.number_of_newton_raphson_iteration <= m.number_of_newton_raphson_iteration - 1;
                            m.division_process_counter <= 0;
                        else
                            m.division_process_counter <= m.division_process_counter + 1;
                            multiply(hw_multiplier, get_multiplier_result(hw_multiplier, 16), m.dividend);
                            m.check_division_to_be_ready <= true;
                        end if;
                    end if;
                WHEN others => -- wait for start
                    if multiplier_is_ready(hw_multiplier) then
                        m.check_division_to_be_ready <= false;
                    end if;
            end CASE;
    end create_division;

------------------------------------------------------------------------
    procedure request_division
    (
        signal division : out division_record;
        number_to_be_divided : int;
        number_to_be_reciprocated : int
    ) is
    begin
        division.x                                  <= get_initial_value_for_division(remove_leading_zeros(number_to_be_reciprocated));
        division.number_to_be_reciprocated          <= remove_leading_zeros(number_to_be_reciprocated);
        division.dividend                           <= number_to_be_divided;
        division.divisor                            <= number_to_be_reciprocated;
        division.division_process_counter           <= 0;
        division.number_of_newton_raphson_iteration <= 0;
    end request_division;

------------------------------------------------------------------------
    procedure request_division
    (
        signal division : out division_record;
        number_to_be_divided : int;
        number_to_be_reciprocated : int;
        iterations : range_of_nr_iteration
    ) is
    begin
        request_division(division, number_to_be_divided, number_to_be_reciprocated);
        division.number_of_newton_raphson_iteration <= iterations - 1;
    end request_division;


------------------------------------------------------------------------
    function division_is_ready
    (
        division_multiplier : multiplier_record;
        division : division_record
    )
    return boolean
    is
        variable returned_value : boolean;
    begin
        if division.check_division_to_be_ready then
            returned_value := multiplier_is_ready(division_multiplier);
        else
            returned_value := false;
        end if;
        
        return returned_value;

    end division_is_ready;
------------------------------------------------------------------------ 

    function division_is_busy
    (
        division : in division_record
    )
    return boolean
    is
    begin
        return division.division_process_counter /= 3;
    end division_is_busy;
------------------------------
    function division_is_not_busy
    (
        division : in division_record
    )
    return boolean
    is
    begin
        return not division_is_busy(division);
    end division_is_not_busy;

------------------------------------------------------------------------
    function get_division_result
    (
        multiplier : multiplier_record;
        divisor : natural;
        radix : natural
    )
    return natural
    is
        variable multiplier_result : integer;
        variable multiplier_result2 : integer;
        variable used_radix : integer;
    begin

        used_radix := 16 + 16-radix;
            
        multiplier_result  := get_multiplier_result(multiplier,used_radix);
        multiplier_result2 := get_multiplier_result(multiplier,used_radix/2+1);

        if divisor < 2**1  then return (multiplier_result2)*2**7 ; end if ;
        if divisor < 2**2  then return (multiplier_result2)*2**6 ; end if ;
        if divisor < 2**3  then return (multiplier_result2)*2**5 ; end if ;
        if divisor < 2**4  then return (multiplier_result2)*2**4 ; end if ;
        if divisor < 2**5  then return (multiplier_result2)*2**3 ; end if ;
        if divisor < 2**6  then return (multiplier_result2)*2**2 ; end if ;
        if divisor < 2**7  then return (multiplier_result2)*2**1 ; end if ;
        if divisor < 2**8  then return (multiplier_result2)      ; end if ;
        if divisor < 2**9  then return (multiplier_result)*2**7  ; end if ;
        if divisor < 2**10 then return (multiplier_result)*2**6  ; end if ;
        if divisor < 2**11 then return (multiplier_result)*2**5  ; end if ;
        if divisor < 2**12 then return (multiplier_result)*2**4  ; end if ;
        if divisor < 2**13 then return (multiplier_result)*2**3  ; end if ;
        if divisor < 2**14 then return (multiplier_result)*2**2  ; end if ;
        if divisor < 2**15 then return (multiplier_result)*2**1  ; end if ;

        return (multiplier_result);
        
    end get_division_result;

------------------------------------------------------------------------
    function get_division_result
    (
        multiplier : multiplier_record;
        hw_divider : division_record;
        radix : natural
    )
    return natural
    is
        variable multiplier_result : integer;
    begin
            multiplier_result := get_multiplier_result(multiplier,radix); 
            return get_division_result(multiplier, hw_divider.divisor, radix);
        
    end get_division_result;

------------------------------------------------------------------------ 
end package body division_pkg;
