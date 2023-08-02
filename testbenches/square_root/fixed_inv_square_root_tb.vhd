library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

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
        input_number : signed);
------------------------------------------------------------------------
    function isqrt_is_ready ( self : isqrt_record)
        return boolean;

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
         0              ,
         0              ,
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
    begin
        CASE self.state_counter is
            WHEN 0 => multiply_and_increment_counter(multiplier,self.state_counter, self.x, self.x);
            WHEN 1 => multiply_and_increment_counter(multiplier,self.state_counter, self.x, self.sign_input_value);
            WHEN others => --do nothign
        end CASE;

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
                    mult_result := get_multiplier_result(multiplier,int_word_length-1);
                    self.x      <= self.x + self.x/2 - mult_result;
                    self.result <= self.x + self.x/2 - mult_result;
                    self.state_counter2 <= self.state_counter2 + 1;
                end if;
            WHEN others => --do nothign
        end CASE;
    end create_isqrt;
------------------------------------------------------------------------
    procedure request_isqrt
    (
        signal self : inout isqrt_record;
        input_number : signed
    ) is
    begin
        self.sign_input_value <= input_number;
        self.state_counter <= 0;
        self.state_counter2 <= 0;
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
end package body fixed_isqrt_pkg;
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
    constant simtime_in_clocks : integer := 60;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----

------------------------------------------------------------------------
    signal testi : boolean := true;

    signal input_value : real := 1.0;
    signal output_value : real := 0.0;

    signal inv_isqrt_is_ready : boolean := false;
    signal request_isqrt : boolean := false;



    signal sign_input_value : signed(int_word_length-1 downto 0) := to_fixed(1.0,int_word_length,14);


    signal square_root_was_requested : boolean := false;

    signal multiplier : multiplier_record := init_multiplier;


     signal self : isqrt_record := init_isqrt;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_per;
        if run("square root was requested") then
            check(square_root_was_requested);
        end if;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            request_isqrt <= false;
            if inv_isqrt_is_ready then
                if input_value < 2.0 then
                    input_value <= input_value + 0.02;
                    request_isqrt <= true;
                end if;
            end if;

            inv_isqrt_is_ready <= false;
            if request_isqrt then
                inv_isqrt_is_ready <= true;
                sign_input_value <= to_fixed(input_value,sign_input_value'length, sign_input_value'high-2);
                square_root_was_requested <= true;
            end if;

            CASE simulation_counter is
                WHEN 10 =>
                    inv_isqrt_is_ready <= true;
                WHEN others => --do nothing
            end CASE;

            create_multiplier(multiplier);
            create_isqrt(self, multiplier);

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
