LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package fixed_dsp_pkg is

    type fixed_dsp_in_record is record
        a : signed;
        d : signed;
        b : signed;
        -- c is added directly into the (a+-d)*b product with no internal
        -- scaling : it must already be at the multiplier output's width
        -- (a'length + b'length), pre-shifted/resized by the caller to
        -- whatever radix that product is meant to carry
        c : signed;

        request_with_1           : std_logic;
        accumulate_with_1        : std_logic; -- 0=p <= p + (a*b)
        pre_subtract_with_1      : std_logic; -- 0=a+d
        post_subtract_with_1     : std_logic; -- 0=mpy_out+d, 1 => mpy_out-d
        invert_result_with_1     : std_logic; -- 1 => negate multiplier result
        reset_accumulator_with_1 : std_logic;

    end record;

    function init_fixed_dsp_in (wordlength : natural := 32) return fixed_dsp_in_record;

    procedure init_fixed_dsp (signal self : out fixed_dsp_in_record);

    -- numeric_std has no bitwise logical operators for signed/unsigned ;
    -- this casts to std_logic_vector, ors bit for bit, and casts back
    function "or" (left : signed; right : signed) return signed;

    -- lets several processes each build their own fixed_dsp_in_record
    -- (starting from an idle/all-zero state, e.g. via init_fixed_dsp,
    -- and setting only the fields their own request needs) and combine
    -- them into one request that drives a single shared fixed_dsp
    -- instance : this is combining independent ports onto a shared bus,
    -- not adding values together, so every field is bitwise or'd ; only
    -- correct when at most one side is active at a time
    function "and" (left : fixed_dsp_in_record; right : fixed_dsp_in_record) return fixed_dsp_in_record;

    -- general fused multiply-add : result = +-((a +- d) * b) +- c
    -- (or, when accumulate_with_1 = '1', result = P +- (a*b) instead)
    procedure fmac (
        signal self : out fixed_dsp_in_record
        ;a : signed
        ;d : signed
        ;b : signed
        ;c : signed
        ;pre_subtract_with_1  : std_logic := '0'
        ;post_subtract_with_1 : std_logic := '0'
        ;invert_result_with_1 : std_logic := '0'
        ;accumulate_with_1    : std_logic := '0'
    );

    -- accumulate : P <= P + a*b
    procedure mac (signal self : out fixed_dsp_in_record; a : signed; b : signed);

    -- result = a*b + c
    procedure add (signal self : out fixed_dsp_in_record; a : signed; b : signed; c : signed);

    -- result = a*b - c
    procedure sub (signal self : out fixed_dsp_in_record; a : signed; b : signed; c : signed);

    type fixed_dsp_out_record is record
        ready_with_1 : std_logic;
        result : signed;
    end record;

end package fixed_dsp_pkg;

package body fixed_dsp_pkg is

    function "or" (left : signed; right : signed) return signed is
    begin
        return signed(std_logic_vector(left) or std_logic_vector(right));
    end function;

    -- combines two independently-prepared requests into one, so that
    -- separate processes can each build their own fixed_dsp_in_record
    -- (starting from init_fixed_dsp's all-zero/idle state, and setting
    -- only the fields their own request needs) while still sharing a
    -- single fixed_dsp instance : combining independent ports onto a
    -- shared bus, not adding values together, so every field (including
    -- a/b/c/d) is bitwise or'd via the "or" overload above ; safe as
    -- long as at most one side is actually active on a given cycle,
    -- since idle fields are always zero either way
    function "and" (left : fixed_dsp_in_record; right : fixed_dsp_in_record) return fixed_dsp_in_record is
        variable retval : left'subtype;
    begin
        retval.a := left.a or right.a;
        retval.d := left.d or right.d;
        retval.b := left.b or right.b;
        retval.c := left.c or right.c;

        retval.request_with_1           := left.request_with_1           or right.request_with_1;
        retval.accumulate_with_1        := left.accumulate_with_1        or right.accumulate_with_1;
        retval.pre_subtract_with_1      := left.pre_subtract_with_1      or right.pre_subtract_with_1;
        retval.post_subtract_with_1     := left.post_subtract_with_1     or right.post_subtract_with_1;
        retval.invert_result_with_1     := left.invert_result_with_1     or right.invert_result_with_1;
        retval.reset_accumulator_with_1 := left.reset_accumulator_with_1 or right.reset_accumulator_with_1;

        return retval;
    end function;

    function init_fixed_dsp_in (wordlength : natural := 32) return fixed_dsp_in_record is
        constant zero_in : signed(wordlength-1 downto 0) := (others => '0');
        -- c is added straight into the multiplier's own output width (no
        -- radix shift happens inside fixed_dsp any more), so it is twice
        -- as wide as a/b/d
        constant zero_c  : signed(2*wordlength-1 downto 0) := (others => '0');
        constant retval : fixed_dsp_in_record :=(
            a => zero_in
            ,b=> zero_in
            ,c => zero_c
            ,d => zero_in
            ,request_with_1           => '0'
            ,accumulate_with_1        => '0'-- 0=p <= p + (a*b)
            ,pre_subtract_with_1      => '0'-- 0=a+d
            ,post_subtract_with_1     => '0'-- 0=mpy_out+d, 1 => mpy_out-d
            ,invert_result_with_1     => '0'-- 1 => negate multiplier result
            ,reset_accumulator_with_1 => '0'
        );

    begin

        return retval;
    end function;

    procedure init_fixed_dsp (signal self : out fixed_dsp_in_record) is
    begin
        self <= (
            a  => (self.a'range => '0')
            ,d => (self.d'range => '0')
            ,b => (self.b'range => '0')
            ,c => (self.c'range => '0')

            ,request_with_1           => '0'
            ,accumulate_with_1        => '0'-- 0=p <= p + (a*b)
            ,pre_subtract_with_1      => '0'-- 0=a+d
            ,post_subtract_with_1     => '0'-- 0=mpy_out+d, 1 => mpy_out-d
            ,invert_result_with_1     => '0'-- 1 => negate multiplier result
            ,reset_accumulator_with_1 => '0'
        );
    end procedure;

    procedure fmac (
        signal self : out fixed_dsp_in_record
        ;a : signed
        ;d : signed
        ;b : signed
        ;c : signed
        ;pre_subtract_with_1  : std_logic := '0'
        ;post_subtract_with_1 : std_logic := '0'
        ;invert_result_with_1 : std_logic := '0'
        ;accumulate_with_1    : std_logic := '0'
    ) is
    begin
        self <= (
            a  => a
            ,d => d
            ,b => b
            ,c => c

            ,request_with_1           => '1'
            ,accumulate_with_1        => accumulate_with_1
            ,pre_subtract_with_1      => pre_subtract_with_1
            ,post_subtract_with_1     => post_subtract_with_1
            ,invert_result_with_1     => invert_result_with_1
            ,reset_accumulator_with_1 => '0'
        );
    end procedure;

    procedure mac (signal self : out fixed_dsp_in_record; a : signed; b : signed) is
    begin
        fmac(self
            ,a => a
            ,d => signed'(a'range => '0')
            ,b => b
            ,c => signed'(self.c'range => '0')
            ,accumulate_with_1 => '1'
        );
    end procedure;

    procedure add (signal self : out fixed_dsp_in_record; a : signed; b : signed; c : signed) is
    begin
        fmac(self
            ,a => a
            ,d => signed'(a'range => '0')
            ,b => b
            ,c => c
        );
    end procedure;

    procedure sub (signal self : out fixed_dsp_in_record; a : signed; b : signed; c : signed) is
    begin
        fmac(self
            ,a => a
            ,d => signed'(a'range => '0')
            ,b => b
            ,c => c
            ,post_subtract_with_1 => '1'
        );
    end procedure;

end package body fixed_dsp_pkg;

LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.fixed_dsp_pkg.all;

entity fixed_dsp is
    port(
        clock : in std_logic := '0'
        ;fixed_dsp_in : in fixed_dsp_in_record
        ;fixed_dsp_out : out fixed_dsp_out_record

    );
end entity;
