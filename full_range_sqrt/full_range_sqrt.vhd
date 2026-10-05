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
-- radicand and root are unsigned with one word length w >= 17, set by the
-- caller's subtypes, and share the radix g_radix. the root is floored ; a
-- zero radicand gives 0. the reference is get_full_range_sqrt below, the
-- hardware matches it bit for bit.
--
--   1. the radicand is normalised into 0.5 <= y < 1 by a pipelined leading
--      zero shifter, one register stage per bit of the shift count zeros
--   2. sqrt_calculator looks up sqrt(y) (radix 15) with the 16 bits that
--      follow the leading one
--   3. radicand = y * 2**e with e = w - zeros + g_radix, so the root is
--      sqrt(y) * 2**(e/2) : a fixed_dsp multiplies sqrt(y) with 1.0 for an
--      even e and with sqrt(2) for an odd e (radix 15 constants)
--   4. a pipelined barrel shifter scales the product by 2**floor(e/2)
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

    -- bit exact reference of the full_range_sqrt pipeline
    function get_full_range_sqrt (
        radicand : unsigned
        ;radix   : natural
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

end package body full_range_sqrt_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.fixed_dsp_pkg.all;
    use work.sqrt_calculator_pkg.all;
    use work.full_range_sqrt_pkg.all;

entity full_range_sqrt is
    generic (
        g_radix             : natural
        ;g_pre_add_register : boolean := false
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
    -- w-1) to w + g_radix (zeros = 0), the product has radix 30
    constant max_half         : natural := (w + g_radix) / 2;
    constant min_half         : natural := (1 + g_radix) / 2;
    constant extra            : natural := maximum(0, max_half - 30);
    constant product_w        : natural := maximum(36, w) + extra;
    constant max_shift        : natural := 30 + extra - min_half;
    constant normalize_stages : natural := bits_for(w-1);
    constant shift_stages     : natural := bits_for(max_shift);
    constant dsp_latency      : natural := 2 + boolean'pos(g_pre_add_register);
    -- sqrt_calculator : its request register, the two stage ram read, its
    -- dsp request register and its fixed_dsp
    constant sqrt_latency     : natural := 4 + dsp_latency;

    type carry_record is record
        zero  : std_logic;
        valid : std_logic;
        zeros : unsigned(normalize_stages-1 downto 0);
    end record;

    constant init_carry : carry_record := (
        zero   => '0'
        ,valid => '0'
        ,zeros => (others => '0'));

    type carry_array     is array (natural range <>) of carry_record;
    type magnitude_array is array (natural range <>) of unsigned(w-1 downto 0);
    type product_array   is array (natural range <>) of unsigned(product_w-1 downto 0);
    type shift_array     is array (natural range <>) of unsigned(shift_stages-1 downto 0);

    signal normalize_carry     : carry_array(0 to normalize_stages)     := (others => init_carry);
    signal normalize_magnitude : magnitude_array(0 to normalize_stages) := (others => (others => '0'));
    signal sqrt_carry          : carry_array(1 to sqrt_latency)         := (others => init_carry);
    signal multiply_carry      : carry_array(0 to dsp_latency)          := (others => init_carry);
    signal shift_carry         : carry_array(0 to shift_stages)         := (others => init_carry);
    signal shift_value         : product_array(0 to shift_stages)       := (others => (others => '0'));
    signal shift_amount        : shift_array(0 to shift_stages)         := (others => (others => '0'));

    signal sqrt_in  : sqrt_calculator_in_record;
    signal sqrt_out : sqrt_calculator_out_record;

    -- sqrt_calculator's tables and the radix 15 multipliers fit an 18 bit dsp
    signal sqrt_dsp_in : fixed_dsp_in_record(
        a(17 downto 0), d(17 downto 0), b(17 downto 0), c(35 downto 0));
    signal sqrt_dsp_out : fixed_dsp_out_record(result(35 downto 0));

    signal multiply_dsp_in : fixed_dsp_in_record(
        a(17 downto 0), d(17 downto 0), b(17 downto 0), c(35 downto 0));
    signal multiply_dsp_out : fixed_dsp_out_record(result(35 downto 0));

    function exponent_is_odd (zeros : unsigned) return boolean is
    begin
        return (w - to_integer(zeros) + g_radix) mod 2 = 1;
    end function;

begin

    assert w >= 17
        report "full_range_sqrt needs a word length of at least 17 bits"
        severity failure;

    sqrt_in <= (
        x_frac          => normalize_magnitude(normalize_stages)(w-2 downto w-17)
        ,request_with_1 => normalize_carry(normalize_stages).valid);

    full_range_sqrt_out.root <=
        (full_range_sqrt_out.root'range => '0') when shift_carry(shift_stages).zero = '1'
        else shift_value(shift_stages)(w-1 downto 0);
    full_range_sqrt_out.ready_with_1 <= shift_carry(shift_stages).valid;

    process(clock)
        variable carry      : carry_record;
        variable magnitude  : unsigned(w-1 downto 0);
        variable value      : unsigned(product_w-1 downto 0);
        variable shift      : natural;
        variable multiplier : natural;
    begin
        if rising_edge(clock) then

            -- input register
            carry       := init_carry;
            carry.valid := full_range_sqrt_in.request_with_1;
            if full_range_sqrt_in.radicand = 0 then
                carry.zero := '1';
            end if;
            normalize_carry(0)     <= carry;
            normalize_magnitude(0) <= full_range_sqrt_in.radicand;

            -- leading zero shifter : stage k shifts by 2**(normalize_stages-k)
            -- when that many top bits are zero, which leaves the leading one
            -- in the top bit and the shift count in carry.zeros
            for k in 1 to normalize_stages loop
                carry     := normalize_carry(k-1);
                magnitude := normalize_magnitude(k-1);
                shift     := 2**(normalize_stages-k);
                if magnitude(w-1 downto w-shift) = 0 then
                    magnitude := shift_left(magnitude, shift);
                    carry.zeros(normalize_stages-k) := '1';
                end if;
                normalize_carry(k)     <= carry;
                normalize_magnitude(k) <= magnitude;
            end loop;

            -- the normalised radicand goes to sqrt_calculator (see sqrt_in),
            -- the rest waits for its result
            sqrt_carry <= normalize_carry(normalize_stages) & sqrt_carry(1 to sqrt_latency-1);

            -- multiply : sqrt(y) * 1.0 for an even exponent, * sqrt(2) for an
            -- odd one
            carry := sqrt_carry(sqrt_latency);
            assert (carry.valid = '1') = (sqrt_out.ready_with_1 = '1')
                report "full_range_sqrt : sqrt_calculator is not aligned with its delay line"
                severity failure;

            if exponent_is_odd(carry.zeros) then
                multiplier := sqrt_two_radix15;
            else
                multiplier := sqrt_one_radix15;
            end if;

            init_fixed_dsp(multiply_dsp_in);
            if carry.valid = '1' then
                fmac(multiply_dsp_in
                    ,a => signed(resize(sqrt_out.y, 18))
                    ,d => (multiply_dsp_in.d'range => '0')
                    ,b => to_signed(multiplier, 18)
                    ,c => (multiply_dsp_in.c'range => '0')
                );
            end if;
            multiply_carry <= carry & multiply_carry(0 to dsp_latency-1);

            -- barrel shifter : the product is sqrt(y) * 2**30 (times sqrt(2)
            -- for an odd exponent), shift right by 30 - floor(e/2) (after a
            -- left shift of extra for large word lengths and radixes)
            carry := multiply_carry(dsp_latency);
            assert (carry.valid = '1') = (multiply_dsp_out.ready_with_1 = '1')
                report "full_range_sqrt : multiply fixed_dsp is not aligned with its delay line"
                severity failure;

            shift_carry(0) <= carry;
            shift_value(0) <= shift_left(resize(unsigned(multiply_dsp_out.result), product_w), extra);
            -- a zero radicand, or an idle stage with no request, shifts by
            -- all normalize stages, which can be more than w-1 ; neither root
            -- is used
            if carry.zero = '1' or carry.valid = '0' then
                shift_amount(0) <= (others => '0');
            else
                shift_amount(0) <= to_unsigned(30 + extra - (w - to_integer(carry.zeros) + g_radix) / 2, shift_stages);
            end if;

            for k in 1 to shift_stages loop
                value := shift_value(k-1);
                if shift_amount(k-1)(shift_stages-k) = '1' then
                    value := shift_right(value, 2**(shift_stages-k));
                end if;
                shift_value(k)  <= value;
                shift_amount(k) <= shift_amount(k-1);
                shift_carry(k)  <= shift_carry(k-1);
            end loop;

        end if;
    end process;

    u_sqrt_calculator : entity work.sqrt_calculator
    port map(
        clock                => clock
        ,sqrt_calculator_in  => sqrt_in
        ,sqrt_calculator_out => sqrt_out
        ,fixed_dsp_in        => sqrt_dsp_in
        ,fixed_dsp_out       => sqrt_dsp_out
    );

    u_sqrt_dsp : entity work.fixed_dsp(rtl)
    generic map(g_pre_add_register => g_pre_add_register)
    port map(
        clock          => clock
        ,fixed_dsp_in  => sqrt_dsp_in
        ,fixed_dsp_out => sqrt_dsp_out
    );

    u_multiply_dsp : entity work.fixed_dsp(rtl)
    generic map(g_pre_add_register => g_pre_add_register)
    port map(
        clock          => clock
        ,fixed_dsp_in  => multiply_dsp_in
        ,fixed_dsp_out => multiply_dsp_out
    );

end rtl;
