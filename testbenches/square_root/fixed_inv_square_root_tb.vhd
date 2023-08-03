library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;

package fixed_isqrt_pkg is
------------------------------------------------------------------------
    type isqrt_record is record
        x_squared        : signed(int_word_length-1 downto 0);
        x                : signed(int_word_length-1 downto 0);
        result           : signed(int_word_length-1 downto 0);
        sign_input_value : signed(int_word_length-1 downto 0);
        state_counter    : natural range 0 to 7;
        state_counter2   : natural range 0 to 7;
        isqrt_is_ready   : boolean;
        loop_value       : natural range 0 to 3;
    end record;

    function init_isqrt return isqrt_record;
------------------------------------------------------------------------
    procedure create_isqrt (
        signal self : inout isqrt_record;
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    procedure request_isqrt (
        signal self : inout isqrt_record;
        input_number : signed;
        guess : signed);

    procedure request_isqrt (
        signal self     : inout isqrt_record;
        input_number    : signed;
        guess           : signed;
        number_of_loops : natural range 0 to 3);
------------------------------------------------------------------------
    function isqrt_is_ready ( self : isqrt_record)
        return boolean;
------------------------------------------------------------------------
    function get_isqrt_result ( self : isqrt_record)
        return signed;
------------------------------------------------------------------------
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
         to_fixed(0.0   , 24)             ,
         to_fixed(0.826 , int_word_length , int_word_length-2) ,
         to_fixed(0.0   , int_word_length , int_word_length-2) ,
         to_fixed(0.0   , int_word_length , int_word_length-2) ,
         7              ,
         7              ,
         false          ,
         0);
         return returned_value;
    end init_isqrt;
------------------------------------------------------------------------
    procedure create_isqrt
    (
        signal self : inout isqrt_record;
        signal multiplier : inout multiplier_record
    ) is
        variable mult_result : signed(int_word_length-1 downto 0);
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
                    self.x_squared <= get_multiplier_result(multiplier, int_word_length-2);
                    self.state_counter2 <= self.state_counter2 + 1;
                end if;
            WHEN 1 => 
                if multiplier_is_ready(multiplier) then
                    multiply(multiplier, self.x_squared, get_multiplier_result(multiplier,int_word_length-2));
                    self.state_counter2 <= self.state_counter2 + 1;
                end if;
            WHEN 2 => 
                if multiplier_is_ready(multiplier) then
                    mult_result                := get_multiplier_result(multiplier,int_word_length-1);
                    inverse_square_root_result := self.x + self.x/2 - mult_result;
                    self.x              <= inverse_square_root_result;
                    self.state_counter2 <= self.state_counter2 + 1;
                    if self.loop_value > 0 then
                        request_isqrt(self , self.sign_input_value , inverse_square_root_result , self.loop_value - 1);
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
        number_of_loops : natural range 0 to 3
    ) is
    begin
        self.sign_input_value <= input_number;
        self.state_counter    <= 0;
        self.state_counter2   <= 0;
        self.x <= guess;
        self.loop_value       <= number_of_loops;
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
------------------------------------------------------------------------
    constant table_pow2 : natural := 5;
    constant number_of_entries : natural := 2**table_pow2;
    type testarray is array (integer range 0 to number_of_entries-1) of real;

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
    constant testaa_arrayta : testarray := get_table;

    ------------------------------------------------------------------------
    subtype sig is signed(int_word_length-1 downto 0);
    type signarray is array (integer range 0 to number_of_entries-1) of sig;

    ------------------------------------------------------------------------
    function get_signarray return signarray
    is
        constant realtable : testarray := get_table;
        variable retval : signarray;
    begin
        for i in signarray'range loop
            retval(i) := to_fixed(realtable(i), sig'length,sig'length-2);
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
    begin
        retval := testsignarray(to_integer('0' & number(number'high-2 downto number'high-1-table_pow2)));
        -- retval(number'high-2-11 downto 0) := (others => '0');
        
        return retval;
        
    end get_initial_guess;

------------------------------------------------------------------------
end package body fixed_isqrt_pkg;
------------------------------------------------------------------------
------------------------------------------------------------------------
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.square_root_pkg.all;
    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;

entity fixed_inv_square_root_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of fixed_inv_square_root_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant simtime_in_clocks : integer := 20e3;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
    signal input_value : real := 1.0;
    signal output_value : real := 0.0;

    signal inv_isqrt_is_ready : boolean := false;
    subtype sig is signed(int_word_length-1 downto 0);

    signal initial_guess    : sig := to_fixed(1.0/sqrt(1.0+1.0/64.0),int_word_length,int_word_length-2);
    signal sign_input_value : sig := to_fixed(1.0,int_word_length,int_word_length-2);
    signal fixed_result     : sig := to_fixed(1.0,int_word_length,int_word_length-2);

    signal square_root_was_requested : boolean := false;

    signal multiplier : multiplier_record := init_multiplier;

    signal self : isqrt_record := init_isqrt;
    signal result_error : real := 0.0;
    signal result : real := 1.0;

    signal max_result_error : real := 0.0;
    signal min_error : real := 1.0;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        if run("square root was requested") then
            check(square_root_was_requested);
        elsif run("max error was less than 0.05") then
            check(max_result_error < 0.05, "error was " & real'image(max_result_error));
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
        variable hihii : sig;
        constant stepsize : real := 1.0/1024.0;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_multiplier(multiplier);
            create_isqrt(self, multiplier);

            CASE simulation_counter is
                WHEN 10 =>
                    request_isqrt(self            => self,
                                  input_number    => to_fixed(input_value, sign_input_value'length, sign_input_value'length-2),
                                  guess           => initial_guess,
                                  number_of_loops => 0);

                WHEN others => --do nothing
            end CASE;

            if isqrt_is_ready(self) then
                if input_value < 2.0 then
                    input_value <= input_value + stepsize;
                    hihii := to_fixed(input_value + stepsize, sign_input_value'length, sign_input_value'length-2);

                    request_isqrt(self            => self,
                                  input_number    => to_fixed(input_value + stepsize, sign_input_value'length, sign_input_value'length-2),
                                  guess           => get_initial_guess(hihii),
                                  number_of_loops => 0);

                    square_root_was_requested <= true;
                end if;
            end if;

            if isqrt_is_ready(self) then
                result_error <= abs(1.0/sqrt(input_value) - to_real(get_isqrt_result(self), sign_input_value'length-2));
                result       <= 1.0/sqrt(input_value)*2.0**(sign_input_value'length-2);
                fixed_result <= get_isqrt_result(self);
            end if;

            if max_result_error < abs(result_error) then
                max_result_error <= abs(result_error);
            end if;

            if min_error > result_error and result_error > 0.0 then
                min_error <= result_error;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
