library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_sqrt_pkg.all;

-- a fully pipelined square root over the whole unsigned input range : a new
-- radicand can be requested every clock cycle and the root comes out a
-- fixed number of clocks later, in request order.
--
--   root = sqrt(radicand * 2**-g_radix) * 2**g_radix
--
-- radicand and root are unsigned with one word length w > g_x_frac_width,
-- set by the caller's subtypes, and share the radix g_radix. the root is floored ; a
-- zero radicand gives 0. the reference is get_full_range_sqrt below, the
-- hardware matches it bit for bit.
--
--   1. the radicand is normalised into 0.5 <= y < 1 by a pipelined leading
--      zero shifter of g_shifter_stages register stages
--   2. sqrt_calculator looks up sqrt(y) with the g_x_frac_width bits that
--      follow the leading one, in a table of 2**g_index_width entries of
--      g_table_word_length bits at radix g_table_radix (defaults 256
--      entries, 16 bits, radix 15 and a 16 bit x_frac)
--   3. radicand = y * 2**e with e = w - zeros + g_radix, so the root is
--      sqrt(y) * 2**(e/2) : a fixed_dsp multiplies sqrt(y) with 1.0 for an
--      even e and with sqrt(2) for an odd e (radix 15 constants)
--   4. a pipelined barrel shifter of g_shifter_stages register stages
--      scales the product by 2**floor(e/2)
--
-- each shifter splits the bits of its shift count over g_shifter_stages
-- stages, high bits first : with 2 stages a 32 bit word shifts by 0, 4 ..
-- 28 and then by 0 .. 3. one stage shifts in one go, one stage per bit
-- gives the shortest logic per stage.
--
-- the shift count and the parity travel alongside in delay lines, which
-- needs the lookup and multiply latencies to be fixed : the root owns both
-- of its fixed_dsps (rtl architecture), g_pre_add_register is passed to them.
package full_range_sqrt_pkg is

    type full_range_sqrt_in_record is record
        radicand       : unsigned;
        request_with_1 : std_logic;
    end record;

    type full_range_sqrt_out_record is record
        root         : unsigned;
        ready_with_1 : std_logic;
    end record;

    procedure init_full_range_sqrt (signal self : out full_range_sqrt_in_record);

    procedure request_full_range_sqrt (
        signal self : out full_range_sqrt_in_record
        ;radicand   : unsigned
    );

    -- 1.0 and sqrt(2) at radix 15, the multipliers for an even and an odd
    -- exponent
    constant sqrt_one_radix15 : natural := 32768;
    constant sqrt_two_radix15 : natural := 46341;

    -- bit exact reference of the full_range_sqrt pipeline with its default
    -- table
    function get_full_range_sqrt (
        radicand : unsigned
        ;radix   : natural
    ) return unsigned;

    -- bit exact reference for any table : point_lut and slope_lut from
    -- lut_sqrt_pkg's make_sqrt_*_lut with the root's g_index_width,
    -- g_table_word_length and g_table_radix
    function get_full_range_sqrt (
        radicand      : unsigned
        ;radix        : natural
        ;point_lut    : sqrt_lut_array
        ;slope_lut    : sqrt_lut_array
        ;table_radix  : natural
        ;x_frac_width : natural
    ) return unsigned;

end package full_range_sqrt_pkg;

package body full_range_sqrt_pkg is

    procedure init_full_range_sqrt (signal self : out full_range_sqrt_in_record) is
    begin
        self.radicand       <= (self.radicand'range => '0');
        self.request_with_1 <= '0';
    end procedure;

    procedure request_full_range_sqrt (
        signal self : out full_range_sqrt_in_record
        ;radicand   : unsigned
    ) is
    begin
        self.radicand       <= radicand;
        self.request_with_1 <= '1';
    end procedure;

    function get_full_range_sqrt (
        radicand : unsigned
        ;radix   : natural
    ) return unsigned is
        constant w         : natural := radicand'length;
        constant max_half  : natural := (w + radix) / 2;
        constant extra     : natural := maximum(0, max_half - 30);
        constant product_w : natural := maximum(36, w) + extra;
        variable m         : unsigned(w-1 downto 0) := radicand;
        variable zeros     : natural := 0;
        variable exponent  : natural;
        variable multiplier : natural;
        variable product   : unsigned(product_w-1 downto 0);
    begin
        if radicand = 0 then
            return to_unsigned(0, w);
        end if;

        while m(w-1) = '0' loop
            m     := shift_left(m, 1);
            zeros := zeros + 1;
        end loop;

        exponent := w - zeros + radix;
        if exponent mod 2 = 1 then
            multiplier := sqrt_two_radix15;
        else
            multiplier := sqrt_one_radix15;
        end if;

        product := resize(get_sqrt_from_lut(m(w-2 downto w-17)) * to_unsigned(multiplier, 17), product_w);
        product := shift_left(product, extra);
        product := shift_right(product, 30 + extra - exponent/2);

        return product(w-1 downto 0);
    end function;

    function get_full_range_sqrt (
        radicand      : unsigned
        ;radix        : natural
        ;point_lut    : sqrt_lut_array
        ;slope_lut    : sqrt_lut_array
        ;table_radix  : natural
        ;x_frac_width : natural
    ) return unsigned is
        constant w           : natural := radicand'length;
        constant word_length : natural := point_lut(point_lut'low)'length;
        -- the product of the table value and a radix 15 multiplier
        constant product_radix : natural := table_radix + 15;
        constant max_half    : natural := (w + radix) / 2;
        constant extra       : natural := maximum(0, max_half - product_radix);
        constant product_w   : natural := maximum(word_length + 17, w) + extra;
        variable m           : unsigned(w-1 downto 0) := radicand;
        variable zeros       : natural := 0;
        variable exponent    : natural;
        variable multiplier  : natural;
        variable product     : unsigned(product_w-1 downto 0);
    begin
        if radicand = 0 then
            return to_unsigned(0, w);
        end if;

        while m(w-1) = '0' loop
            m     := shift_left(m, 1);
            zeros := zeros + 1;
        end loop;

        exponent := w - zeros + radix;
        if exponent mod 2 = 1 then
            multiplier := sqrt_two_radix15;
        else
            multiplier := sqrt_one_radix15;
        end if;

        product := resize(get_sqrt_from_lut(m(w-2 downto w-1-x_frac_width), point_lut, slope_lut)
                          * to_unsigned(multiplier, 17), product_w);
        product := shift_left(product, extra);
        product := shift_right(product, product_radix + extra - exponent/2);

        return product(w-1 downto 0);
    end function;

end package body full_range_sqrt_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fixed_dsp_pkg.all;
    use work.lut_sqrt_pkg.all;
    use work.sqrt_calculator_pkg.all;
    use work.full_range_sqrt_pkg.all;
    use work.fixed_point_scaling_pkg.all;

entity full_range_sqrt is
    generic (
        g_radix             : natural
        -- the sqrt table : 2**g_index_width entries of g_table_word_length
        -- bits, sqrt(x) at radix g_table_radix, looked up with the
        -- g_x_frac_width bits after the radicand's leading one
        ;g_index_width       : natural := sqrt_index_width
        ;g_table_word_length : natural := sqrt_word_length
        ;g_table_radix       : natural := 15
        ;g_x_frac_width      : natural := 16
        ;g_pre_add_register : boolean  := false
        ;g_product_register : boolean  := false -- fixed_dsp's, one clock more per dsp
        ;g_shifter_stages   : positive := 2
        -- dual_port_ram's output register in the lookup table : without it
        -- the latency is one clock shorter
        ;g_ram_output_register : boolean := true
        -- register the requests to the fixed_dsps : without them each
        -- request goes to its fixed_dsp directly, two clocks shorter
        ;g_dsp_request_register : boolean := true
    );
    port (
        clock                : in std_logic
        ;full_range_sqrt_in  : in full_range_sqrt_in_record
        ;full_range_sqrt_out : out full_range_sqrt_out_record
    );
end entity;

architecture rtl of full_range_sqrt is

    constant w : natural := full_range_sqrt_in.radicand'length;

    -- smallest b with 2**b > max_value
    function bits_for (max_value : natural) return natural is
        variable b : natural := 0;
    begin
        while 2**b <= max_value loop
            b := b + 1;
        end loop;
        return b;
    end function;

    -- the exponent e = w - zeros + g_radix runs from 1 + g_radix (zeros =
    -- w-1) to w + g_radix (zeros = 0), the product has radix product_radix
    constant max_half         : natural := (w + g_radix) / 2;
    constant min_half         : natural := (1 + g_radix) / 2;
    -- the multiply : the table value (unsigned, one bit more as signed)
    -- times a radix 15 constant, at least an 18 bit dsp ; the product has
    -- radix g_table_radix + 15
    constant multiply_w       : natural := maximum(18, g_table_word_length + 1);
    constant product_radix    : natural := g_table_radix + 15;
    constant extra            : natural := maximum(0, max_half - product_radix);
    constant product_w        : natural := maximum(2*multiply_w, w) + extra;
    constant max_shift        : natural := product_radix + extra - min_half;
    -- bits in the normalisation shift count and in the output shift
    constant count_bits       : natural := bits_for(w-1);
    constant shift_bits       : natural := bits_for(max_shift);
    constant stages           : positive := g_shifter_stages;
    constant dsp_latency      : natural := 2 + boolean'pos(g_pre_add_register) + boolean'pos(g_product_register);
    -- sqrt_calculator : its request register, the ram read (2 clocks, 1
    -- without the ram's output register), its dsp request register (when
    -- g_dsp_request_register) and its fixed_dsp
    constant sqrt_latency     : natural := 2 + boolean'pos(g_ram_output_register)
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
        zero  : std_logic;
        valid : std_logic;
        zeros : unsigned(count_bits-1 downto 0);
    end record;

    constant init_carry : carry_record := (
        zero   => '0'
        ,valid => '0'
        ,zeros => (others => '0'));

    type carry_array     is array (natural range <>) of carry_record;
    type magnitude_array is array (natural range <>) of unsigned(w-1 downto 0);
    type product_array   is array (natural range <>) of unsigned(product_w-1 downto 0);
    type shift_array     is array (natural range <>) of unsigned(shift_bits-1 downto 0);

    signal normalize_carry     : carry_array(1 to stages)               := (others => init_carry);
    signal normalize_magnitude : magnitude_array(1 to stages)           := (others => (others => '0'));
    signal sqrt_carry          : carry_array(1 to sqrt_latency)         := (others => init_carry);
    signal multiply_carry      : carry_array(1 to multiply_latency)     := (others => init_carry);
    signal shift_carry         : carry_array(1 to stages)               := (others => init_carry);
    signal shift_value         : product_array(1 to stages)             := (others => (others => '0'));
    signal shift_amount        : shift_array(1 to stages)               := (others => (others => '0'));

    signal sqrt_in  : sqrt_calculator_in_record(x_frac(g_x_frac_width-1 downto 0));
    signal sqrt_out : sqrt_calculator_out_record(y(g_table_word_length-1 downto 0));

    -- the sqrt interpolation : the table words and the fraction (plus its
    -- sign bit), at least an 18 bit dsp
    constant sqrt_dsp_w : natural := maximum(18, maximum(g_table_word_length, g_x_frac_width - g_index_width + 1));
    signal sqrt_dsp_in : fixed_dsp_in_record(
        a(sqrt_dsp_w-1 downto 0), d(sqrt_dsp_w-1 downto 0),
        b(sqrt_dsp_w-1 downto 0), c(2*sqrt_dsp_w-1 downto 0));
    signal sqrt_dsp_out : fixed_dsp_out_record(result(2*sqrt_dsp_w-1 downto 0));

    signal multiply_dsp_in : fixed_dsp_in_record(
        a(multiply_w-1 downto 0), d(multiply_w-1 downto 0),
        b(multiply_w-1 downto 0), c(2*multiply_w-1 downto 0));
    signal multiply_request : multiply_dsp_in'subtype;
    signal multiply_dsp_out : fixed_dsp_out_record(result(2*multiply_w-1 downto 0));

    function exponent_is_odd (zeros : unsigned) return boolean is
    begin
        return (w - to_integer(zeros) + g_radix) mod 2 = 1;
    end function;

begin

    assert w > g_x_frac_width
        report "full_range_sqrt needs a word length above g_x_frac_width"
        severity failure;

    sqrt_in <= (
        x_frac          => normalize_magnitude(stages)(w-2 downto w-1-g_x_frac_width)
        ,request_with_1 => normalize_carry(stages).valid);

    full_range_sqrt_out.root <=
        (full_range_sqrt_out.root'range => '0') when shift_carry(stages).zero = '1'
        else shift_value(stages)(w-1 downto 0);
    full_range_sqrt_out.ready_with_1 <= shift_carry(stages).valid;

    process(clock)
        variable carry      : carry_record;
        variable magnitude  : unsigned(w-1 downto 0);
        variable value      : unsigned(product_w-1 downto 0);
        variable size       : natural;
        variable low        : natural;
        variable amount     : natural;
        variable shift      : unsigned(shift_bits-1 downto 0);
    begin
        if rising_edge(clock) then

            -- the first normaliser stage works straight off the inputs
            carry       := init_carry;
            carry.valid := full_range_sqrt_in.request_with_1;
            if full_range_sqrt_in.radicand = 0 then
                carry.zero := '1';
            end if;
            magnitude := full_range_sqrt_in.radicand;

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
                    -- the whole 2**low groups of leading zeros, without counting
                    -- them one by one : this is the first stage's critical path
                    amount    := get_leading_zero_groups(magnitude, 2**low, minimum(2**(low+size), w)) mod 2**size;
                    magnitude := shift_left(magnitude, amount * 2**low);
                    carry.zeros(low+size-1 downto low) := to_unsigned(amount, size);
                end if;
                normalize_carry(s)     <= carry;
                normalize_magnitude(s) <= magnitude;
            end loop;

            -- the normalised radicand goes to sqrt_calculator (see sqrt_in),
            -- the rest waits for its result
            sqrt_carry <= normalize_carry(stages) & sqrt_carry(1 to sqrt_latency-1);

            -- multiply : sqrt(y) * 1.0 for an even exponent, * sqrt(2) for an
            -- odd one
            carry := sqrt_carry(sqrt_latency);
            assert (carry.valid = '1') = (sqrt_out.ready_with_1 = '1')
                report "full_range_sqrt : sqrt_calculator is not aligned with its delay line"
                severity failure;

            multiply_carry <= carry & multiply_carry(1 to multiply_latency-1);

            -- barrel shifter : the product is sqrt(y) * 2**product_radix (times
            -- sqrt(2) for an odd exponent), shift right by product_radix -
            -- floor(e/2) (after a
            -- left shift of extra for large word lengths and radixes)
            carry := multiply_carry(multiply_latency);
            assert (carry.valid = '1') = (multiply_dsp_out.ready_with_1 = '1')
                report "full_range_sqrt : multiply fixed_dsp is not aligned with its delay line"
                severity failure;

            -- the first shifter stage works straight off the multiplier
            value := shift_left(resize(unsigned(multiply_dsp_out.result), product_w), extra);
            -- a zero radicand, or an idle stage with no request, has a
            -- meaningless shift count ; neither root is used
            if carry.zero = '1' or carry.valid = '0' then
                shift := (others => '0');
            else
                shift := to_unsigned(product_radix + extra - (w - to_integer(carry.zeros) + g_radix) / 2, shift_bits);
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
    -- the multiply request, combinational from the sqrt_calculator result and
    -- the delay line ; it reaches multiply_dsp_in through a register, or
    -- directly when g_dsp_request_register is false
    multiply_request_process : process(all)
        variable carry      : carry_record;
        variable multiplier : natural;
    begin
        carry := sqrt_carry(sqrt_latency);
        if exponent_is_odd(carry.zeros) then
            multiplier := sqrt_two_radix15;
        else
            multiplier := sqrt_one_radix15;
        end if;

        init_fixed_dsp(multiply_request);
        if carry.valid = '1' then
            fmac(multiply_request
                ,a => signed(resize(sqrt_out.y, multiply_w))
                ,d => (multiply_request.d'range => '0')
                ,b => to_signed(multiplier, multiply_w)
                ,c => (multiply_request.c'range => '0')
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

    u_sqrt_calculator : entity work.sqrt_calculator
    generic map(
        g_index_width           => g_index_width
        ,g_word_length          => g_table_word_length
        ,g_radix                => g_table_radix
        ,g_ram_output_register  => g_ram_output_register
        ,g_dsp_request_register => g_dsp_request_register)
    port map(
        clock                => clock
        ,sqrt_calculator_in  => sqrt_in
        ,sqrt_calculator_out => sqrt_out
        ,fixed_dsp_in        => sqrt_dsp_in
        ,fixed_dsp_out       => sqrt_dsp_out
    );

    u_sqrt_dsp : entity work.fixed_dsp(rtl)
    generic map(g_pre_add_register => g_pre_add_register, g_product_register => g_product_register)
    port map(
        clock          => clock
        ,fixed_dsp_in  => sqrt_dsp_in
        ,fixed_dsp_out => sqrt_dsp_out
    );

    u_multiply_dsp : entity work.fixed_dsp(rtl)
    generic map(g_pre_add_register => g_pre_add_register, g_product_register => g_product_register)
    port map(
        clock          => clock
        ,fixed_dsp_in  => multiply_dsp_in
        ,fixed_dsp_out => multiply_dsp_out
    );

end rtl;
