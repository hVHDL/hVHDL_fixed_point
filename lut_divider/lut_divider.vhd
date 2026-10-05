library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_reciprocal_pkg.all;

-- a fully pipelined lookup table divider : a new numerator / denominator
-- pair can be requested every clock cycle and the quotient comes out a
-- fixed number of clocks later, in request order.
--
--   quotient = numerator / denominator * 2**g_quotient_radix
--
-- numerator, denominator and quotient are signed and share one word
-- length w, set by the caller's subtypes, w > g_x_frac_width and
-- w > g_table_word_length. the quotient is floored and
-- wraps to w bits when it does not fit ; a zero denominator gives 0 with
-- division_by_zero set. the reference is lut_divide below, the hardware
-- matches it bit for bit.
--
--   1. |denominator| is normalised into 0.5 <= x < 1 by a pipelined leading
--      zero shifter of g_shifter_stages register stages
--   2. reciprocal_calculator looks up 1/x with the g_x_frac_width bits that
--      follow the leading one, in a table of 2**g_index_width entries of
--      g_table_word_length bits at radix g_table_radix (defaults 256 entries,
--      16 bits, radix 14 and a 16 bit x_frac)
--   3. a fixed_dsp multiplies the numerator with 1/x, negated for a
--      negative denominator
--   4. a pipelined barrel shifter of g_shifter_stages register stages
--      scales the product back by the normalisation shift and the radix
--
-- each shifter splits the bits of its shift count over g_shifter_stages
-- stages, high bits first : with 2 stages a 32 bit word shifts by 0, 4 ..
-- 28 and then by 0 .. 3. one stage shifts in one go, one stage per bit
-- gives the shortest logic per stage.
--
-- the numerator, the sign and the shift count travel alongside in delay
-- lines, which needs the reciprocal and multiply latencies to be fixed : the
-- divider owns both of its fixed_dsps (rtl architecture), g_pre_add_register
-- is passed to them.
package lut_divider_pkg is

    type lut_divider_in_record is record
        numerator      : signed;
        denominator    : signed;
        request_with_1 : std_logic;
    end record;

    type lut_divider_out_record is record
        quotient         : signed;
        division_by_zero : std_logic;
        ready_with_1     : std_logic;
    end record;

    procedure init_lut_divider (signal self : out lut_divider_in_record);

    procedure request_lut_division (
        signal self   : out lut_divider_in_record
        ;numerator    : signed
        ;denominator  : signed
    );

    -- bit exact reference of the lut_divider pipeline with its default table
    function lut_divide (
        numerator       : signed
        ;denominator    : signed
        ;quotient_radix : natural
    ) return signed;

    -- bit exact reference for any table : point_lut and slope_lut from
    -- lut_reciprocal_pkg's make_reciprocal_*_lut with the divider's
    -- g_index_width, g_table_word_length and g_table_radix
    function lut_divide (
        numerator       : signed
        ;denominator    : signed
        ;quotient_radix : natural
        ;point_lut      : reciprocal_lut_array
        ;slope_lut      : reciprocal_lut_array
        ;table_radix    : natural
        ;x_frac_width   : natural
    ) return signed;

end package lut_divider_pkg;

package body lut_divider_pkg is

    procedure init_lut_divider (signal self : out lut_divider_in_record) is
    begin
        self.numerator      <= (self.numerator'range => '0');
        self.denominator    <= (self.denominator'range => '0');
        self.request_with_1 <= '0';
    end procedure;

    procedure request_lut_division (
        signal self   : out lut_divider_in_record
        ;numerator    : signed
        ;denominator  : signed
    ) is
    begin
        self.numerator      <= numerator;
        self.denominator    <= denominator;
        self.request_with_1 <= '1';
    end procedure;

    function lut_divide (
        numerator       : signed
        ;denominator    : signed
        ;quotient_radix : natural
    ) return signed is
        constant w       : natural := numerator'length;
        constant extra   : natural := maximum(0, quotient_radix - 15);
        variable n       : signed(w-1 downto 0) := numerator;
        -- abs of the most negative denominator wraps to itself, which read
        -- as unsigned is the right magnitude 2**(w-1)
        variable m       : unsigned(w-1 downto 0) := unsigned(abs(denominator));
        variable zeros   : natural := 0;
        variable product : signed(2*w-1 downto 0);
        variable shifted : signed(2*w+extra-1 downto 0);
    begin
        if denominator = 0 then
            return to_signed(0, w);
        end if;

        while m(w-1) = '0' loop
            m     := shift_left(m, 1);
            zeros := zeros + 1;
        end loop;

        product := resize(n * signed('0' & get_reciprocal_from_lut(m(w-2 downto w-17))), 2*w);
        if denominator(denominator'left) = '1' then
            product := -product;
        end if;

        shifted := shift_left(resize(product, shifted'length), extra);
        shifted := shift_right(shifted, 14 + w - quotient_radix + extra - zeros);

        return shifted(w-1 downto 0);
    end function;

    function lut_divide (
        numerator       : signed
        ;denominator    : signed
        ;quotient_radix : natural
        ;point_lut      : reciprocal_lut_array
        ;slope_lut      : reciprocal_lut_array
        ;table_radix    : natural
        ;x_frac_width   : natural
    ) return signed is
        constant w       : natural := numerator'length;
        constant extra   : natural := maximum(0, quotient_radix - (table_radix + 1));
        variable n       : signed(w-1 downto 0) := numerator;
        -- abs of the most negative denominator wraps to itself, which read
        -- as unsigned is the right magnitude 2**(w-1)
        variable m       : unsigned(w-1 downto 0) := unsigned(abs(denominator));
        variable zeros   : natural := 0;
        variable product : signed(2*w-1 downto 0);
        variable shifted : signed(2*w+extra-1 downto 0);
    begin
        if denominator = 0 then
            return to_signed(0, w);
        end if;

        while m(w-1) = '0' loop
            m     := shift_left(m, 1);
            zeros := zeros + 1;
        end loop;

        product := resize(n * signed('0' & get_reciprocal_from_lut(m(w-2 downto w-1-x_frac_width), point_lut, slope_lut)), 2*w);
        if denominator(denominator'left) = '1' then
            product := -product;
        end if;

        shifted := shift_left(resize(product, shifted'length), extra);
        shifted := shift_right(shifted, table_radix + w - quotient_radix + extra - zeros);

        return shifted(w-1 downto 0);
    end function;

end package body lut_divider_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fixed_dsp_pkg.all;
    use work.lut_reciprocal_pkg.all;
    use work.reciprocal_calculator_pkg.all;
    use work.lut_divider_pkg.all;
    use work.fixed_point_scaling_pkg.all;

entity lut_divider is
    generic (
        g_quotient_radix    : natural
        -- the reciprocal table : 2**g_index_width entries of
        -- g_table_word_length bits, 1/x at radix g_table_radix, looked up with
        -- the g_x_frac_width bits after the denominator's leading one
        ;g_index_width       : natural := recip_index_width
        ;g_table_word_length : natural := recip_word_length
        ;g_table_radix       : natural := 14
        ;g_x_frac_width      : natural := 16
        ;g_pre_add_register : boolean  := false
        ;g_shifter_stages   : positive := 2
        -- dual_port_ram's output register in the lookup table : without it
        -- the latency is one clock shorter
        ;g_ram_output_register : boolean := true
        -- register the requests to the fixed_dsps : without them each
        -- request goes to its fixed_dsp directly, two clocks shorter
        ;g_dsp_request_register : boolean := true
    );
    port (
        clock            : in std_logic
        ;lut_divider_in  : in lut_divider_in_record
        ;lut_divider_out : out lut_divider_out_record
    );
end entity;

architecture rtl of lut_divider is

    constant w     : natural := lut_divider_in.numerator'length;
    constant extra : natural := maximum(0, g_quotient_radix - (g_table_radix + 1));

    -- smallest b with 2**b > max_value
    function bits_for (max_value : natural) return natural is
        variable b : natural := 0;
    begin
        while 2**b <= max_value loop
            b := b + 1;
        end loop;
        return b;
    end function;

    -- bits in the normalisation shift count and in the output shift
    constant count_bits         : natural := bits_for(w-1);
    constant max_shift          : natural := g_table_radix + w - g_quotient_radix + extra;
    constant shift_bits         : natural := bits_for(max_shift);
    constant stages             : positive := g_shifter_stages;
    constant dsp_latency        : natural := 2 + boolean'pos(g_pre_add_register);
    -- reciprocal_calculator : its request register, the ram read (2 clocks,
    -- 1 without the ram's output register), its dsp request register (when
    -- g_dsp_request_register) and its fixed_dsp
    constant reciprocal_latency : natural := 2 + boolean'pos(g_ram_output_register)
                                            + boolean'pos(g_dsp_request_register) + dsp_latency;
    -- the multiply : its request register (when g_dsp_request_register) and
    -- its fixed_dsp
    constant multiply_latency : natural := boolean'pos(g_dsp_request_register) + dsp_latency;

    -- a shift count's bits split over the stages, high bits first : stage s
    -- (1 = the first) handles bits group_low .. group_low + group_size - 1
    function group_size (total_bits : natural; stage : positive) return natural is
    begin
        if stage <= total_bits mod stages then
            return total_bits / stages + 1;
        else
            return total_bits / stages;
        end if;
    end function;

    function group_low (total_bits : natural; stage : positive) return natural is
        variable low : natural := total_bits;
    begin
        for k in 1 to stage loop
            low := low - group_size(total_bits, k);
        end loop;
        return low;
    end function;

    type carry_record is record
        numerator        : signed(w-1 downto 0);
        negative         : std_logic;
        division_by_zero : std_logic;
        valid            : std_logic;
        zeros            : unsigned(count_bits-1 downto 0);
    end record;

    constant init_carry : carry_record := (
        numerator         => (others => '0')
        ,negative         => '0'
        ,division_by_zero => '0'
        ,valid            => '0'
        ,zeros            => (others => '0'));

    type carry_array     is array (natural range <>) of carry_record;
    type magnitude_array is array (natural range <>) of unsigned(w-1 downto 0);
    type product_array   is array (natural range <>) of signed(2*w+extra-1 downto 0);
    type shift_array     is array (natural range <>) of unsigned(shift_bits-1 downto 0);

    signal normalize_carry     : carry_array(1 to stages)               := (others => init_carry);
    signal normalize_magnitude : magnitude_array(1 to stages)           := (others => (others => '0'));
    signal reciprocal_carry    : carry_array(1 to reciprocal_latency)   := (others => init_carry);
    signal multiply_carry      : carry_array(1 to multiply_latency)     := (others => init_carry);
    signal shift_carry         : carry_array(1 to stages)               := (others => init_carry);
    signal shift_value         : product_array(1 to stages)             := (others => (others => '0'));
    signal shift_amount        : shift_array(1 to stages)               := (others => (others => '0'));

    signal reciprocal_in  : reciprocal_calculator_in_record(x_frac(g_x_frac_width-1 downto 0));
    signal reciprocal_out : reciprocal_calculator_out_record(y(g_table_word_length-1 downto 0));

    -- the reciprocal interpolation : the table words and the fraction (plus
    -- its sign bit), at least an 18 bit dsp
    constant reciprocal_dsp_w : natural := maximum(18, maximum(g_table_word_length, g_x_frac_width - g_index_width + 1));
    signal reciprocal_dsp_in : fixed_dsp_in_record(
        a(reciprocal_dsp_w-1 downto 0), d(reciprocal_dsp_w-1 downto 0),
        b(reciprocal_dsp_w-1 downto 0), c(2*reciprocal_dsp_w-1 downto 0));
    signal reciprocal_dsp_out : fixed_dsp_out_record(result(2*reciprocal_dsp_w-1 downto 0));

    signal multiply_dsp_in : fixed_dsp_in_record(
        a(w-1 downto 0), d(w-1 downto 0), b(w-1 downto 0), c(2*w-1 downto 0));
    signal multiply_request : multiply_dsp_in'subtype;
    signal multiply_dsp_out : fixed_dsp_out_record(result(2*w-1 downto 0));

begin

    assert w > g_x_frac_width and w > g_table_word_length
        report "lut_divider needs a word length above g_x_frac_width and g_table_word_length"
        severity failure;

    reciprocal_in <= (
        x_frac          => normalize_magnitude(stages)(w-2 downto w-1-g_x_frac_width)
        ,request_with_1 => normalize_carry(stages).valid);

    lut_divider_out.quotient <=
        (lut_divider_out.quotient'range => '0') when shift_carry(stages).division_by_zero = '1'
        else shift_value(stages)(w-1 downto 0);
    lut_divider_out.division_by_zero <= shift_carry(stages).division_by_zero;
    lut_divider_out.ready_with_1     <= shift_carry(stages).valid;

    process(clock)
        variable carry     : carry_record;
        variable magnitude : unsigned(w-1 downto 0);
        variable value     : signed(2*w+extra-1 downto 0);
        variable size      : natural;
        variable low       : natural;
        variable leading   : natural;
        variable amount    : natural;
        variable shift     : unsigned(shift_bits-1 downto 0);
    begin
        if rising_edge(clock) then

            -- the first normaliser stage works straight off the inputs
            carry           := init_carry;
            carry.numerator := lut_divider_in.numerator;
            carry.negative  := lut_divider_in.denominator(lut_divider_in.denominator'left);
            carry.valid     := lut_divider_in.request_with_1;
            if lut_divider_in.denominator = 0 then
                carry.division_by_zero := '1';
            end if;
            -- abs of the most negative denominator wraps to itself, which
            -- read as unsigned is the right magnitude 2**(w-1)
            magnitude := unsigned(abs(lut_divider_in.denominator));

            -- leading zero shifter : stage s removes the leading zeros of its
            -- group, a multiple of 2**low up to its group's worth, which
            -- leaves the leading one in the top bit after the last stage and
            -- the shift count in carry.zeros. the earlier stages have removed
            -- the larger multiples, so a nonzero magnitude has fewer than
            -- 2**(low+size) leading zeros left here
            for s in 1 to stages loop
                if s > 1 then
                    carry     := normalize_carry(s-1);
                    magnitude := normalize_magnitude(s-1);
                end if;
                size      := group_size(count_bits, s);
                low       := group_low(count_bits, s);
                if size > 0 then
                    leading   := get_number_of_leading_zeros(signed(magnitude), minimum(2**(low+size) - 1, w-1));
                    amount    := (leading / 2**low) mod 2**size;
                    magnitude := shift_left(magnitude, amount * 2**low);
                    carry.zeros(low+size-1 downto low) := to_unsigned(amount, size);
                end if;
                normalize_carry(s)     <= carry;
                normalize_magnitude(s) <= magnitude;
            end loop;

            -- the normalised denominator goes to reciprocal_calculator (see
            -- reciprocal_in), the rest waits for its result
            reciprocal_carry <= normalize_carry(stages) & reciprocal_carry(1 to reciprocal_latency-1);

            -- multiply : numerator * 1/x, negated for a negative denominator
            carry := reciprocal_carry(reciprocal_latency);
            assert (carry.valid = '1') = (reciprocal_out.ready_with_1 = '1')
                report "lut_divider : reciprocal_calculator is not aligned with its delay line"
                severity failure;

            multiply_carry <= carry & multiply_carry(1 to multiply_latency-1);

            -- barrel shifter : the product is n/x * 2**table radix and |denominator|
            -- = x * 2**(w - zeros), shift right by table radix + w - zeros - radix
            -- (after a left shift of extra for radixes above 15)
            carry := multiply_carry(multiply_latency);
            assert (carry.valid = '1') = (multiply_dsp_out.ready_with_1 = '1')
                report "lut_divider : multiply fixed_dsp is not aligned with its delay line"
                severity failure;

            -- the first shifter stage works straight off the multiplier
            value := shift_left(resize(multiply_dsp_out.result, 2*w+extra), extra);
            -- a zero denominator, or an idle stage with no request, has a
            -- meaningless shift count ; neither quotient is used
            if carry.division_by_zero = '1' or carry.valid = '0' then
                shift := (others => '0');
            else
                shift := to_unsigned(max_shift - to_integer(carry.zeros), shift_bits);
            end if;

            for s in 1 to stages loop
                if s > 1 then
                    carry := shift_carry(s-1);
                    value := shift_value(s-1);
                    shift := shift_amount(s-1);
                end if;
                size  := group_size(shift_bits, s);
                low   := group_low(shift_bits, s);
                if size > 0 then
                    value := shift_right(value, to_integer(shift(low+size-1 downto low)) * 2**low);
                end if;
                shift_value(s)  <= value;
                shift_amount(s) <= shift;
                shift_carry(s)  <= carry;
            end loop;

        end if;
    end process;

    ------------------------------------------------------------------------
    -- the multiply request, combinational from the reciprocal_calculator result and
    -- the delay line ; it reaches multiply_dsp_in through a register, or
    -- directly when g_dsp_request_register is false
    multiply_request_process : process(all)
        variable carry      : carry_record;
    begin
        carry := reciprocal_carry(reciprocal_latency);
        init_fixed_dsp(multiply_request);
        if carry.valid = '1' then
            fmac(multiply_request
                ,a => carry.numerator
                ,d => (multiply_request.d'range => '0')
                ,b => resize(signed('0' & reciprocal_out.y), w)
                ,c => (multiply_request.c'range => '0')
                ,invert_result_with_1 => carry.negative
            );
        end if;
    end process;

    multiply_request_registered : if g_dsp_request_register generate
        process(clock)
        begin
            if rising_edge(clock) then
                multiply_dsp_in <= multiply_request;
            end if;
        end process;
    end generate;

    multiply_request_direct : if not g_dsp_request_register generate
        multiply_dsp_in <= multiply_request;
    end generate;

    u_reciprocal_calculator : entity work.reciprocal_calculator
    generic map(
        g_index_width           => g_index_width
        ,g_word_length          => g_table_word_length
        ,g_radix                => g_table_radix
        ,g_ram_output_register  => g_ram_output_register
        ,g_dsp_request_register => g_dsp_request_register)
    port map(
        clock                      => clock
        ,reciprocal_calculator_in  => reciprocal_in
        ,reciprocal_calculator_out => reciprocal_out
        ,fixed_dsp_in              => reciprocal_dsp_in
        ,fixed_dsp_out             => reciprocal_dsp_out
    );

    u_reciprocal_dsp : entity work.fixed_dsp(rtl)
    generic map(g_pre_add_register => g_pre_add_register)
    port map(
        clock          => clock
        ,fixed_dsp_in  => reciprocal_dsp_in
        ,fixed_dsp_out => reciprocal_dsp_out
    );

    u_multiply_dsp : entity work.fixed_dsp(rtl)
    generic map(g_pre_add_register => g_pre_add_register)
    port map(
        clock          => clock
        ,fixed_dsp_in  => multiply_dsp_in
        ,fixed_dsp_out => multiply_dsp_out
    );

end rtl;
