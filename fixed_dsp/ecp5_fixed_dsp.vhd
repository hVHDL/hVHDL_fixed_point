LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

package fixed_dsp_pkg is

    type fixed_dsp_in_record is record
        a : signed(31 downto 0);
        d : signed(31 downto 0);
        b : signed(31 downto 0);
        c : signed(31 downto 0);

        request_with_1           : std_logic;
        accumulate_with_1        : std_logic; -- 0=p <= p + (a*b)
        pre_subtract_with_1      : std_logic; -- 0=a+d
        post_subtract_with_1     : std_logic; -- 0=mpy_out+d, 1 => mpy_out-d
        invert_result_with_1     : std_logic; -- 1 => negate multiplier result
        reset_accumulator_with_1 : std_logic;

    end record;

    procedure init_fixed_dsp (signal self : out fixed_dsp_in_record);

    type fixed_dsp_out_record is record
        ready_with_1 : std_logic;
        result : signed(63 downto 0);
    end record;

end package fixed_dsp_pkg;

package body fixed_dsp_pkg is

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

end package body fixed_dsp_pkg;

LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.fixed_dsp_pkg.all;

entity fixed_dsp is
    generic(g_radix : natural);
    port(
        clock : in std_logic := '0'
        ;fixed_dsp_in : in fixed_dsp_in_record
        ;fixed_dsp_out : out fixed_dsp_out_record

    );
end entity;
