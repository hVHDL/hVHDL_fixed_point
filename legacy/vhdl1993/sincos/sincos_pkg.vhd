library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all; 

    use work.multiplier_pkg.all;

package sincos_pkg is

------------------------------------------------------------------------
    type sincos_record is record
        sincos_process_counter : natural range 0 to 15;
        angle_rad16            : unsigned(15 downto 0);

        angle_squared : int;
        sin16 : int;
        cos16 : int;
        sin : int;
        cos : int;
        sincos_has_finished : boolean;
    end record;

    constant init_sincos : sincos_record := (15, (others => '0'), 0, 0, 0, 0, 0, false);
------------------------------------------------------------------------
    procedure request_sincos (
        signal self : inout sincos_record;
        angle_rad16 : in int);

    procedure request_sincos (
        signal self : inout sincos_record;
        angle_rad16 : in unsigned);
------------------------------------------------------------------------
    function get_sine ( self : sincos_record)
        return int;
------------------------------------------------------------------------
    function get_cosine ( self : sincos_record)
        return int;
------------------------------------------------------------------------
    function sincos_is_ready ( self : sincos_record)
        return boolean;
------------------------------------------------------------------------
    function angle_reduction ( angle_in_rad16 : int)
        return int;
------------------------------------------------------------------------
    procedure create_sincos (
        signal hw_multiplier : inout multiplier_record;
        signal self : inout sincos_record);
------------------------------------------------------------------------ 
end package sincos_pkg;


package body sincos_pkg is 
------------------------------------------------------------------------
    function angle_reduction
    (
        angle_in_rad16 : int
    )
        return int
    is
        variable sign16_angle : signed(17 downto 0);
    begin
        sign16_angle := to_signed(angle_in_rad16,18); 
        return to_integer((sign16_angle(13 downto 0)));
    end angle_reduction;
------------------------------------------------------------------------ 
    function sincos_is_busy
    (
        self : sincos_record
    )
    return boolean
    is
    begin
        return self.sincos_process_counter <= 8;
    end sincos_is_busy;
------------------------------------------------------------------------ 
    procedure request_sincos
    (
        signal self : inout sincos_record;
        angle_rad16 : in int
    ) is
    begin
            request_sincos(self, to_unsigned(angle_rad16, 16));
        
    end request_sincos;
------------------------------------------------------------------------ 
    procedure request_sincos
    (
        signal self : inout sincos_record;
        angle_rad16 : in unsigned
    ) is
    begin
        if self.sincos_process_counter >= 8 then
            self.angle_rad16 <= angle_rad16;
            self.sincos_process_counter <= 0;
        end if;
        
    end request_sincos;
------------------------------------------------------------------------ 
    function get_sine
    (
        self : sincos_record
    )
    return int
    is
    begin
        return self.sin;
    end get_sine;
------------------------------------------------------------------------ 
    function get_cosine
    (
        self : sincos_record
    )
    return int
    is
    begin
        return self.cos;
    end get_cosine;
------------------------------------------------------------------------ 
    function sincos_is_ready
    (
        self : sincos_record
    )
    return boolean
    is
    begin
        return self.sincos_has_finished;
    end sincos_is_ready;
------------------------------------------------------------------------ 
    procedure create_sincos
    (
        signal hw_multiplier : inout multiplier_record;
        signal self : inout sincos_record
    ) is

        type int_array is array (integer range <>) of int;
        constant sinegains : int_array(0 to 2) := (12868 , 21159 , 10180);
        constant cosgains  : int_array(0 to 2) := (32768 , 80805 , 64473);

        constant one_quarter   : integer := 8192  ;
        constant three_fourths : integer := 24576 ;
        constant five_fourths  : integer := 40960 ;
        constant seven_fourths : integer := 57344 ;
------------------------------------------------------------------------
    begin
            self.sincos_has_finished <= false;

            CASE self.sincos_process_counter is
                WHEN 0 => 
                    multiply(hw_multiplier, angle_reduction(to_integer(self.angle_rad16)), angle_reduction(to_integer(self.angle_rad16)));
                    self.sincos_process_counter <= self.sincos_process_counter + 1;
                WHEN 1 =>
                    if multiplier_is_ready(hw_multiplier) then
                        self.angle_squared <= get_multiplier_result(hw_multiplier, 15);
                        multiply(hw_multiplier,                sinegains(2), get_multiplier_result(hw_multiplier, 15));
                    end if;
                    increment_counter_when_ready(hw_multiplier,self.sincos_process_counter);
                WHEN 3 =>
                    if multiplier_is_ready(hw_multiplier) then 
                        multiply(hw_multiplier, self.angle_squared, sinegains(1) - get_multiplier_result(hw_multiplier, 15)); 
                    end if;
                    increment_counter_when_ready(hw_multiplier,self.sincos_process_counter);
                WHEN 5 =>
                    if multiplier_is_ready(hw_multiplier) then
                        multiply(hw_multiplier, angle_reduction((to_integer(self.angle_rad16))), sinegains(0) - get_multiplier_result(hw_multiplier, 15)); 
                    end if;
                    increment_counter_when_ready(hw_multiplier,self.sincos_process_counter);
                WHEN 7 =>
                    if multiplier_is_ready(hw_multiplier) then
                        self.sin16 <= get_multiplier_result(hw_multiplier,12);
                    end if;
                    increment_counter_when_ready(hw_multiplier,self.sincos_process_counter); 
                WHEN others => -- do nothing
            end CASE;

            CASE self.sincos_process_counter is
                WHEN 2 =>
                    multiply(hw_multiplier, self.angle_squared, cosgains(2));
                    self.sincos_process_counter <= self.sincos_process_counter + 1;
                WHEN 4 =>
                    multiply(hw_multiplier, self.angle_squared, cosgains(1) - get_multiplier_result(hw_multiplier, 15));
                    self.sincos_process_counter <= self.sincos_process_counter + 1;
                WHEN 6 => 
                    self.cos16 <= cosgains(0) - get_multiplier_result(hw_multiplier, 14);
                    self.sincos_process_counter <= self.sincos_process_counter + 1;
                WHEN 8 =>
                    self.sincos_process_counter <= self.sincos_process_counter + 1;
                    self.sincos_has_finished <= true;

                    if (to_integer(self.angle_rad16)) < one_quarter then
                        self.sin <= self.sin16;
                        self.cos <= self.cos16;
                    elsif (to_integer(self.angle_rad16)) < three_fourths then
                        self.sin <= self.cos16;
                        self.cos <= -self.sin16;
                    elsif (to_integer(self.angle_rad16)) < five_fourths then
                        self.sin <= -self.sin16;
                        self.cos <= -self.cos16;
                    elsif (to_integer(self.angle_rad16)) < seven_fourths then
                        self.sin <= -self.cos16;
                        self.cos <= self.sin16;
                    else
                        self.sin <= self.sin16;
                        self.cos <= self.cos16;
                    end if;

                when others => -- hange here and wait for triggering
            end CASE; 
        
    end create_sincos;

------------------------------------------------------------------------ 
end package body sincos_pkg; 
