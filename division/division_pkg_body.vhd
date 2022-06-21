package body division_pkg is

------------------------------------------------------------------------
    procedure create_division
    (
        signal hw_multiplier : inout multiplier_record;
        signal division : inout division_record
    ) is
    --------------------------------------------------
        alias division_process_counter is division.division_process_counter;
        alias x is division.x;
        alias number_to_be_reciprocated is division.number_to_be_reciprocated; 
        alias number_of_newton_raphson_iteration is division.number_of_newton_raphson_iteration; 
        alias dividend is division.dividend;
        alias check_division_to_be_ready is division.check_division_to_be_ready;
        variable xa : int18;
    --------------------------------------------------
    begin
        
            CASE division_process_counter is
                WHEN 0 =>
                    multiply(hw_multiplier, x, number_to_be_reciprocated);
                    division_process_counter <= division_process_counter + 1;
                WHEN 1 =>
                    increment_counter_when_ready(hw_multiplier,division_process_counter);
                    if multiplier_is_ready(hw_multiplier) then
                        multiply(hw_multiplier, x, invert_bits(get_multiplier_result(hw_multiplier, 16)));
                    end if;
                WHEN 2 =>
                    if multiplier_is_ready(hw_multiplier) then
                        x <= get_multiplier_result(hw_multiplier, 16);
                        if number_of_newton_raphson_iteration /= 0 then
                            number_of_newton_raphson_iteration <= number_of_newton_raphson_iteration - 1;
                            division_process_counter <= 0;
                        else
                            division_process_counter <= division_process_counter + 1;
                            multiply(hw_multiplier, get_multiplier_result(hw_multiplier, 16), dividend);
                            check_division_to_be_ready <= true;
                        end if;
                    end if;
                WHEN others => -- wait for start
                    if multiplier_is_ready(hw_multiplier) then
                        check_division_to_be_ready <= false;
                    end if;
            end CASE;
    end create_division;

------------------------------------------------------------------------
    procedure request_division
    (
        signal division : out division_record;
        number_to_be_divided : int18;
        number_to_be_reciprocated : int18
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
        number_to_be_divided : int18;
        number_to_be_reciprocated : int18;
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
    begin
        if division.check_division_to_be_ready then
            return multiplier_is_ready(division_multiplier);
        else
            return false;
        end if;
        
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
