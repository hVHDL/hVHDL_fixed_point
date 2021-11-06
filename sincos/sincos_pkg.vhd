library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all; 

library math_library;
    use math_library.multiplier_pkg.all;

package sincos_pkg is

------------------------------------------------------------------------
    type sincos_record is record
        sincos_process_counter : natural range 0 to 15;
        angle_rad16            : unsigned(15 downto 0);

        angle_squared : int18;
        sin16 : int18;
        cos16 : int18;
        sin : int18;
        cos : int18;
        sincos_has_finished : boolean;
    end record;

    constant init_sincos : sincos_record := (15, (others => '0'), 0, 0, 0, 0, 0, false);
------------------------------------------------------------------------
    procedure request_sincos (
        signal sincos_object : inout sincos_record;
        angle_rad16 : in int18);

    procedure request_sincos (
        signal sincos_object : inout sincos_record;
        angle_rad16 : in unsigned);
------------------------------------------------------------------------
    function get_sine ( sincos_object : sincos_record)
        return int18;
------------------------------------------------------------------------
    function get_cosine ( sincos_object : sincos_record)
        return int18;
------------------------------------------------------------------------
    function sincos_is_ready ( sincos_object : sincos_record)
        return boolean;
------------------------------------------------------------------------
    function angle_reduction ( angle_in_rad16 : int18)
        return int18;
------------------------------------------------------------------------
    procedure create_sincos (
        signal hw_multiplier : inout multiplier_record;
        signal sincos_object : inout sincos_record);
------------------------------------------------------------------------ 
end package sincos_pkg;


package body sincos_pkg is 
------------------------------------------------------------------------
    function angle_reduction
    (
        angle_in_rad16 : int18
    )
        return int18
    is
        variable sign16_angle : signed(17 downto 0);
    begin
        sign16_angle := to_signed(angle_in_rad16,18); 
        return to_integer((sign16_angle(13 downto 0)));
    end angle_reduction;
------------------------------------------------------------------------ 
    function sincos_is_busy
    (
        sincos_object : sincos_record
    )
    return boolean
    is
    begin
        return sincos_object.sincos_process_counter <= 8;
    end sincos_is_busy;
------------------------------------------------------------------------ 
    procedure request_sincos
    (
        signal sincos_object : inout sincos_record;
        angle_rad16 : in int18
    ) is
    begin
            request_sincos(sincos_object, to_unsigned(angle_rad16, 16));
        
    end request_sincos;
------------------------------------------------------------------------ 
    procedure request_sincos
    (
        signal sincos_object : inout sincos_record;
        angle_rad16 : in unsigned
    ) is
    begin
        if sincos_object.sincos_process_counter >= 8 then
            sincos_object.angle_rad16 <= angle_rad16;
            sincos_object.sincos_process_counter <= 0;
        end if;
        
    end request_sincos;
------------------------------------------------------------------------ 
    function get_sine
    (
        sincos_object : sincos_record
    )
    return int18
    is
    begin
        return sincos_object.sin;
    end get_sine;
------------------------------------------------------------------------ 
    function get_cosine
    (
        sincos_object : sincos_record
    )
    return int18
    is
    begin
        return sincos_object.cos;
    end get_cosine;
------------------------------------------------------------------------ 
    function sincos_is_ready
    (
        sincos_object : sincos_record
    )
    return boolean
    is
    begin
        return sincos_object.sincos_has_finished;
    end sincos_is_ready;
------------------------------------------------------------------------ 
    procedure create_sincos
    (
        signal hw_multiplier : inout multiplier_record;
        signal sincos_object : inout sincos_record
    ) is
        alias sincos_process_counter is sincos_object.sincos_process_counter ;
        alias angle_rad16            is sincos_object.angle_rad16            ;
        alias angle_squared          is sincos_object.angle_squared          ;
        alias sin16                  is sincos_object.sin16                  ;
        alias cos16                  is sincos_object.cos16                  ;
        alias sin                    is sincos_object.sin                    ;
        alias cos                    is sincos_object.cos                    ;
        alias sincos_has_finished    is sincos_object.sincos_has_finished    ;

        type int18_array is array (integer range <>) of int18;
        constant sinegains : int18_array(0 to 2) := (12868 , 21159 , 10180);
        constant cosgains  : int18_array(0 to 2) := (32768 , 80805 , 64473);

        constant one_quarter   : integer := 8192  ;
        constant three_fourths : integer := 24576 ;
        constant five_fourths  : integer := 40960 ;
        constant seven_fourths : integer := 57344 ;
------------------------------------------------------------------------
    begin
            sincos_has_finished <= false;

            CASE sincos_process_counter is
                WHEN 0 => 
                    multiply(hw_multiplier, angle_reduction(to_integer(angle_rad16)), angle_reduction(to_integer(angle_rad16)));
                    sincos_process_counter <= sincos_process_counter + 1;
                WHEN 1 =>
                    if multiplier_is_ready(hw_multiplier) then
                        angle_squared <= get_multiplier_result(hw_multiplier, 15);
                        multiply(hw_multiplier,                sinegains(2), get_multiplier_result(hw_multiplier, 15));
                    end if;
                    increment_counter_when_ready(hw_multiplier,sincos_process_counter);
                WHEN 3 =>
                    if multiplier_is_ready(hw_multiplier) then 
                        multiply(hw_multiplier, angle_squared, sinegains(1) - get_multiplier_result(hw_multiplier, 15)); 
                    end if;
                    increment_counter_when_ready(hw_multiplier,sincos_process_counter);
                WHEN 5 =>
                    if multiplier_is_ready(hw_multiplier) then
                        multiply(hw_multiplier, angle_reduction((to_integer(angle_rad16))), sinegains(0) - get_multiplier_result(hw_multiplier, 15)); 
                    end if;
                    increment_counter_when_ready(hw_multiplier,sincos_process_counter);
                WHEN 7 =>
                    if multiplier_is_ready(hw_multiplier) then
                        sin16 <= get_multiplier_result(hw_multiplier,12);
                    end if;
                    increment_counter_when_ready(hw_multiplier,sincos_process_counter); 
                WHEN others => -- do nothing
            end CASE;

            CASE sincos_process_counter is
                WHEN 2 =>
                    multiply(hw_multiplier, angle_squared, cosgains(2));
                    sincos_process_counter <= sincos_process_counter + 1;
                WHEN 4 =>
                    multiply(hw_multiplier, angle_squared, cosgains(1) - get_multiplier_result(hw_multiplier, 15));
                    sincos_process_counter <= sincos_process_counter + 1;
                WHEN 6 => 
                    cos16 <= cosgains(0) - get_multiplier_result(hw_multiplier, 14);
                    sincos_process_counter <= sincos_process_counter + 1;
                WHEN 8 =>
                    sincos_process_counter <= sincos_process_counter + 1;
                    sincos_has_finished <= true;

                    if (to_integer(angle_rad16)) < one_quarter then
                        sin <= sin16;
                        cos <= cos16;
                    elsif (to_integer(angle_rad16)) < three_fourths then
                        sin <= cos16;
                        cos <= -sin16;
                    elsif (to_integer(angle_rad16)) < five_fourths then
                        sin <= -sin16;
                        cos <= -cos16;
                    elsif (to_integer(angle_rad16)) < seven_fourths then
                        sin <= -cos16;
                        cos <= sin16;
                    else
                        sin <= sin16;
                        cos <= cos16;
                    end if;

                when others => -- hange here and wait for triggering
            end CASE; 
        
    end create_sincos;

------------------------------------------------------------------------ 
end package body sincos_pkg; 
