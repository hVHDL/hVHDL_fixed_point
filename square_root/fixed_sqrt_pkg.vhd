
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.fixed_point_scaling_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;
    use work.real_to_fixed_pkg.all;

package fixed_sqrt_pkg is
------------------------------------------------------------------------
    constant used_word_length : natural := int_word_length;
    subtype fixed is signed(used_word_length-1 downto 0);

    constant default_number_of_iterations : integer := 5;

    type fixed_sqrt_record is record
        isqrt                 : isqrt_record;
        post_scaling          : fixed;
        shift_width           : natural;
        number_of_iterations  : natural range 0 to 7;
        state_counter         : natural range 0 to 3;
        input                 : fixed;
        scaled_input          : fixed;
        pipeline              : std_logic_vector(2 downto 0);
        sqrt_is_ready         : boolean;
    end record;

    constant init_sqrt : fixed_sqrt_record := (init_isqrt, (others => '0'),0, default_number_of_iterations, 3, (others => '0'), (others => '0'), (others => '0'), false);
------------------------------------------------------------------------
    procedure create_sqrt (
        signal self       : inout fixed_sqrt_record;
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
    function sqrt_is_ready ( self : fixed_sqrt_record)
        return boolean;
------------------------------------------------------------------------
    function get_sqrt_result (
        self : fixed_sqrt_record;
        multiplier : multiplier_record;
        radix : natural)
    return signed;
------------------------------------------------------------------------
    procedure request_sqrt (
        signal self : inout fixed_sqrt_record;
        number_to_be_squared : fixed);
------------------------------------------------------------------------

end package fixed_sqrt_pkg;

package body fixed_sqrt_pkg is
------------------------------------------------------------------------
    procedure create_sqrt
    (
        signal self       : inout fixed_sqrt_record;
        signal multiplier : inout multiplier_record
    ) is
    begin
        create_isqrt(self.isqrt, multiplier);

        self.pipeline     <= self.pipeline(self.pipeline'high-1 downto 0) & '0';
        self.scaled_input <= shift_left(self.input, get_number_of_leading_zeros(self.input)-1);
        self.shift_width  <= get_number_of_leading_zeros(self.input);

        if get_number_of_leading_zeros(self.input) mod 2 = 0 then
            self.post_scaling <= to_fixed(1.0/sqrt(2.0), used_word_length, isqrt_radix);
        else
            self.post_scaling <= to_fixed(1.0, used_word_length, isqrt_radix);
        end if;

        if self.pipeline(self.pipeline'left) = '1' then
            request_isqrt(self.isqrt, self.scaled_input, get_initial_guess(self.scaled_input), self.number_of_iterations);
        end if;

        self.sqrt_is_ready <= false;
        CASE self.state_counter is
            WHEN 0 =>
                if isqrt_is_ready(self.isqrt) then
                    multiply(multiplier, get_isqrt_result(self.isqrt), self.input);
                    self.state_counter <= self.state_counter + 1;
                end if;
            WHEN 1 =>
                if multiplier_is_ready(multiplier) then
                    multiply(multiplier, get_multiplier_result(multiplier, isqrt_radix), self.post_scaling);
                    self.state_counter <= self.state_counter + 1;
                end if;
            WHEN 2 =>
                if multiplier_is_ready(multiplier) then
                    self.sqrt_is_ready <= true;
                    self.state_counter <= self.state_counter + 1;
                end if;
            WHEN others => --do nothing
        end CASE;
    end create_sqrt;
------------------------------------------------------------------------
    function get_sqrt_result
    (
        self : fixed_sqrt_record;
        multiplier : multiplier_record;
        radix : natural
    )
    return signed 
    is
    begin
        return get_multiplier_result(multiplier, radix);
    end get_sqrt_result;
------------------------------------------------------------------------
    function sqrt_is_ready
    (
        self : fixed_sqrt_record
    )
    return boolean
    is
    begin
        return self.sqrt_is_ready;
    end sqrt_is_ready;
------------------------------------------------------------------------
    procedure request_sqrt
    (
        signal self : inout fixed_sqrt_record;
        number_to_be_squared : fixed
    ) is
    begin
        self.input         <= number_to_be_squared;
        self.pipeline(0)   <= '1';
        self.state_counter <= 0;
        
    end request_sqrt;
------------------------------------------------------------------------
end package body fixed_sqrt_pkg;
