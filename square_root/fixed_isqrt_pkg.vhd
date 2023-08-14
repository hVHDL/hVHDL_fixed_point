
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;

package fixed_isqrt_pkg is
    constant isqrt_radix : natural := int_word_length-2;
------------------------------------------------------------------------
    type isqrt_record is record
        x_squared        : signed(int_word_length-1 downto 0);
        x                : signed(int_word_length-1 downto 0);
        result           : signed(int_word_length-1 downto 0);
        sign_input_value : signed(int_word_length-1 downto 0);
        state_counter    : natural range 0 to 7;
        state_counter2   : natural range 0 to 7;
        isqrt_is_ready   : boolean;
        loop_value       : natural range 0 to 7;
    end record;

    function init_isqrt return isqrt_record;
------------------------------------------------------------------------
    procedure create_isqrt (
        signal self       : inout isqrt_record;
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    procedure request_isqrt (
        signal self  : inout isqrt_record;
        input_number : signed;
        guess        : signed);

    procedure request_isqrt (
        signal self     : inout isqrt_record;
        input_number    : signed;
        guess           : signed;
        number_of_loops : natural range 1 to 7);
------------------------------------------------------------------------
    function isqrt_is_ready ( self : isqrt_record)
        return boolean;
------------------------------------------------------------------------
    function get_isqrt_result ( self : isqrt_record)
        return signed;
------------------------------------------------------------------------
    constant table_pow2 : natural := 4;
    constant number_of_entries : natural := 2**table_pow2;
    type testarray is array (integer range 0 to number_of_entries-1) of real;

    function get_table return testarray ;

    subtype sig is signed(int_word_length-1 downto 0);
    type signarray is array (integer range 0 to number_of_entries-1) of sig;

    function get_signarray return signarray;

    function get_initial_guess ( number : signed)
    return signed;

end package fixed_isqrt_pkg;

package body fixed_isqrt_pkg is

------------------------------------------------------------------------
    function to_fixed
    (
        number : real;
        radix : natural
    )
    return signed
    is
    begin
        return to_fixed(number, int_word_length, radix);
    end to_fixed;

------------------------------------------------------------------------
    function init_isqrt return isqrt_record
    is
        variable returned_value : isqrt_record;
    begin
        returned_value := (
         (others => '0') ,
         (others => '0') ,
         (others => '0') ,
         (others => '0') ,
         7               ,
         7               ,
         false           ,
         0);
         return returned_value;
    end init_isqrt;
------------------------------------------------------------------------
    procedure create_isqrt
    (
        signal self : inout isqrt_record;
        signal multiplier : inout multiplier_record
    ) is
        variable mult_result                : signed(int_word_length-1 downto 0);
        variable inverse_square_root_result : signed(int_word_length-1 downto 0);
    begin
        CASE self.state_counter is
            WHEN 0 => multiply_and_increment_counter(multiplier,self.state_counter, self.x, self.x);
            WHEN 1 => multiply_and_increment_counter(multiplier,self.state_counter, self.x, self.sign_input_value);
            WHEN others => --do nothign
        end CASE;

        self.isqrt_is_ready <= false;
        CASE self.state_counter2 is
            WHEN 0 => 
                if multiplier_is_ready(multiplier) then
                    self.x_squared <= get_multiplier_result(multiplier, isqrt_radix);
                    self.state_counter2 <= self.state_counter2 + 1;
                end if;
            WHEN 1 => 
                if multiplier_is_ready(multiplier) then
                    multiply(multiplier, self.x_squared, get_multiplier_result(multiplier,isqrt_radix));
                    self.state_counter2 <= self.state_counter2 + 1;
                end if;
            WHEN 2 => 
                if multiplier_is_ready(multiplier) then
                    mult_result                := get_multiplier_result(multiplier,isqrt_radix+1);
                    inverse_square_root_result := self.x + self.x/2 - mult_result;
                    self.x              <= inverse_square_root_result;
                    self.state_counter2 <= self.state_counter2 + 1;
                    if self.loop_value > 0 then
                        request_isqrt(self , self.sign_input_value , inverse_square_root_result , self.loop_value);
                    else
                        self.isqrt_is_ready <= true;
                        self.result <= inverse_square_root_result;
                    end if;

                end if;
            WHEN others => --do nothign
        end CASE;
    end create_isqrt;
------------------------------------------------------------------------
    procedure request_isqrt
    (
        signal self : inout isqrt_record;
        input_number : signed;
        guess : signed
    ) is
    begin
        self.sign_input_value <= input_number;
        self.state_counter    <= 0;
        self.state_counter2   <= 0;
        self.loop_value       <= 0;
        self.x <= guess;
    end request_isqrt;

    procedure request_isqrt
    (
        signal self     : inout isqrt_record;
        input_number    : signed;
        guess           : signed;
        number_of_loops : natural range 1 to 7
    ) is
    begin
        self.sign_input_value <= input_number;
        self.state_counter    <= 0;
        self.state_counter2   <= 0;
        self.x <= guess;
        self.loop_value       <= number_of_loops-1;
    end request_isqrt;

------------------------------------------------------------------------
    function isqrt_is_ready
    (
        self : isqrt_record
    )
    return boolean
    is
    begin
        return self.isqrt_is_ready;
    end isqrt_is_ready;
------------------------------------------------------------------------
    function get_isqrt_result
    (
        self : isqrt_record
    )
    return signed
    is
    begin

        return self.result;
        
    end get_isqrt_result;
------------------------------------------------------------------------
    -- get initial guess
------------------------------------------------------------------------
    function get_table return testarray 
    is
        variable retval : testarray := (others => 0.0);
    begin
        for i in retval'range loop
            retval(i) := (1.0/(sqrt(real(i*2+number_of_entries*2+1)/real(number_of_entries)/2.0)));
        end loop;

        return retval;
        
    end get_table;

    ------------------------------------------------------------------------
    function get_signarray return signarray
    is
        constant realtable : testarray := get_table;
        variable retval : signarray;
    begin
        for i in signarray'range loop
            retval(i) := to_fixed(realtable(i) , sig'length , isqrt_radix);
        end loop;

        return retval;
        
    end get_signarray;

    ------------------------------------------------------------------------
    constant testsignarray : signarray := get_signarray;

    function get_initial_guess
    (
        number : signed
    )
    return signed 
    is
        variable retval : sig := (others => '0');
        variable table_index : natural := 0;
    begin
        table_index := to_integer('0' & number(number'high-2 downto number'high-1-table_pow2));

        if number(number'high-1) = '1' then
            retval := testsignarray(table_index);
        elsif number(number'high-1) = '0' then
            retval := to_fixed(1.16, sig'length, isqrt_radix);
        end if;

        return retval;
        
    end get_initial_guess;

------------------------------------------------------------------------
end package body fixed_isqrt_pkg;
