
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fixed_point_scaling_pkg.all;
    use work.multiplier_pkg.all;
    use work.fixed_isqrt_pkg.all;

package fixed_sqrt_pkg is
------------------------------------------------------------------------
    constant used_word_length : natural := int_word_length;
    subtype fixed is signed(used_word_length-1 downto 0);

    type fixed_sqrt_record is record
        isqrt        : isqrt_record;
        shift_width  : natural;
        input        : fixed;
        scaled_input : fixed;
        pipeline     : std_logic_vector(2 downto 0);
        multiply_isqrt_result : boolean;
        sqrt_is_ready : boolean;
    end record;

    constant init_sqrt : fixed_sqrt_record := (init_isqrt, 0 , (others => '0'), (others => '0'), (others => '0'), false, false);
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
        constant number_of_iterations : integer := 5;
    begin
        create_isqrt(self.isqrt, multiplier);

        self.pipeline     <= self.pipeline(self.pipeline'high-1 downto 0) & '0';
        self.scaled_input <= scale_input(self.input);
        self.shift_width  <= get_number_of_leading_pairs_of_zeros(self.input);

        if self.pipeline(self.pipeline'left) = '1' then
            request_isqrt(self.isqrt, self.scaled_input, get_initial_guess(self.scaled_input),number_of_iterations);
        end if;

        if isqrt_is_ready(self.isqrt) then
            multiply(multiplier, get_isqrt_result(self.isqrt), self.input);
            self.multiply_isqrt_result <= true;
        end if;

        self.sqrt_is_ready <= false;
        if multiplier_is_ready(multiplier) and self.multiply_isqrt_result then
            self.multiply_isqrt_result <= false;
            self.sqrt_is_ready <= true;
        end if;

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
        return get_multiplier_result(multiplier, int_word_length-2);
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
        self.input <= number_to_be_squared;
        self.pipeline(0) <= '1';
        
    end request_sqrt;
------------------------------------------------------------------------
end package body fixed_sqrt_pkg;
