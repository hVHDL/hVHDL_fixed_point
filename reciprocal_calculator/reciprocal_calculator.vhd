library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_reciprocal_pkg.all;

-- a single fully pipelined 1/x lookup : a new x_frac can be requested
-- every clock cycle, before earlier requests have produced their result ;
-- internally this wraps a dual_port_ram (holding lut_reciprocal_pkg's
-- point_lut/slope_lut tables) and a fixed_dsp (performing the
-- interpolation multiply-add), each of which is itself a fixed-latency,
-- non-stalling pipeline stage. mirrors sine_calculator, but simpler :
-- 1/x has no quarter-wave mirroring and is always positive, so there is
-- no sign to track from request through to output.
--
-- fixed_dsp_in/fixed_dsp_out are left unconstrained, so the caller's
-- fixed_dsp can be any word length >= recip_word_length (e.g. a real
-- 32x32 hard multiplier, wider than lut_reciprocal_pkg's own tables) :
-- the a/b/c operands are resized up to whatever width fixed_dsp_in
-- actually has before use, and the result is resized back down to
-- recip_word_length once read back, which is exact regardless of the
-- intermediate width since resize sign-extends/truncates without
-- touching the low-order bits or the radix
package reciprocal_calculator_pkg is

    type reciprocal_calculator_in_record is record
        x_frac         : unsigned(recip_word_length-1 downto 0);
        request_with_1 : std_logic;
    end record;

    type reciprocal_calculator_out_record is record
        y            : unsigned(recip_word_length-1 downto 0);
        ready_with_1 : std_logic;
    end record;

    procedure init_reciprocal_calculator (signal self : out reciprocal_calculator_in_record);

    procedure request_reciprocal (
        signal self : out reciprocal_calculator_in_record
        ;x_frac : unsigned
    );

end package reciprocal_calculator_pkg;

package body reciprocal_calculator_pkg is

    procedure init_reciprocal_calculator (signal self : out reciprocal_calculator_in_record) is
    begin
        self <= (
            x_frac         => (self.x_frac'range => '0')
            ,request_with_1 => '0'
        );
    end procedure;

    procedure request_reciprocal (
        signal self : out reciprocal_calculator_in_record
        ;x_frac : unsigned
    ) is
    begin
        self.x_frac         <= x_frac;
        self.request_with_1 <= '1';
    end procedure;

end package body reciprocal_calculator_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_reciprocal_pkg.all;
    use work.dual_port_ram_pkg.all;
    use work.fixed_dsp_pkg.all;
    use work.reciprocal_calculator_pkg.all;

entity reciprocal_calculator is
    generic (
        -- dual_port_ram's output register : a ram read takes 2 clocks with
        -- it, 1 without, which takes one clock off the latency
        g_ram_output_register : boolean := true
        -- register the request to fixed_dsp : without it the request goes
        -- to fixed_dsp straight from the ram output, a clock shorter
        ;g_dsp_request_register : boolean := true
    );
    port (
        clock : in std_logic := '0'
        ;reciprocal_calculator_in  : in reciprocal_calculator_in_record
        ;reciprocal_calculator_out : out reciprocal_calculator_out_record
        -- fixed_dsp itself lives outside this entity : the caller
        -- instantiates it (choosing its architecture/generic) and wires
        -- these ports straight to it ; widths are left unconstrained
        -- here and fixed by the actual signal at the instantiation site
        ;fixed_dsp_in  : out fixed_dsp_in_record
        ;fixed_dsp_out : in fixed_dsp_out_record
    );
end entity;

architecture rtl of reciprocal_calculator is

    -- point_lut fills the low half of the ram's address space, slope_lut
    -- the high half
    function build_lut_ram_contents return ram_array is
        variable retval : ram_array(0 to 2*recip_number_of_entries-1)(recip_word_length-1 downto 0);
    begin
        for i in 0 to recip_number_of_entries-1 loop
            retval(i)                          := std_logic_vector(point_lut(i));
            retval(i + recip_number_of_entries) := std_logic_vector(slope_lut(i));
        end loop;
        return retval;
    end function;

    constant lut_ram_contents : ram_array(0 to 2*recip_number_of_entries-1)(recip_word_length-1 downto 0)
        := build_lut_ram_contents;

    constant dp_ram_subtype : dpram_ref_record := create_ref_subtypes(
        datawidth     => recip_word_length
        ,addresswidth => recip_index_width+1
    );

    signal ram_a_in  : dp_ram_subtype.ram_in'subtype;
    signal ram_a_out : dp_ram_subtype.ram_out'subtype;
    signal ram_b_in  : ram_a_in'subtype;
    signal ram_b_out : ram_a_out'subtype;

    ------------------------------------------------------------------------
    -- a delay line of the requested x_frac values : the ram read has a
    -- fixed latency and neither stalls nor reorders, so the x_frac of the
    -- lookup that is ready now is always the one requested
    -- ram_read_latency clocks ago (the request register in this process
    -- plus dual_port_ram's read, 2 clocks or 1 without its output
    -- register). 1/x has no sign to recover, so nothing has to travel past
    -- the dsp
    constant ram_read_latency : natural := 2 + boolean'pos(g_ram_output_register);
    type x_frac_delay_t is array (1 to ram_read_latency) of unsigned(recip_word_length-1 downto 0);
    signal x_frac_delay : x_frac_delay_t;

    signal dsp_interpolated : signed(recip_word_length-1 downto 0);


    signal dsp_request : fixed_dsp_in'subtype;

begin

    u_dpram : entity work.dual_port_ram
    generic map(
        g_dpram_subtype   => dp_ram_subtype
        ,g_ram_init_values => lut_ram_contents
        ,g_output_register => g_ram_output_register
    )
    port map(
        clock     => clock
        ,ram_a_in  => ram_a_in
        ,ram_a_out => ram_a_out
        ,ram_b_in  => ram_b_in
        ,ram_b_out => ram_b_out
    );

    ------------------------------------------------------------------------
    -- (point<<radix + slope*fraction) >> radix = point + (slope*fraction >> radix)
    -- exactly, since point<<radix is a multiple of 2**radix, so this
    -- reproduces get_reciprocal_from_lut bit for bit ; purely combinational
    -- from already-registered signals, so no extra latency is added on
    -- top of the dsp's own
    dsp_interpolated <= resize(shift_right(fixed_dsp_out.result, recip_fraction_width), recip_word_length);

    reciprocal_calculator_out.ready_with_1 <= fixed_dsp_out.ready_with_1;
    reciprocal_calculator_out.y            <= unsigned(dsp_interpolated);

    process(clock)
        variable index        : natural range 0 to recip_number_of_entries-1;
    begin
        if rising_edge(clock) then

            -- the delay line shifts every clock, request or not, so it
            -- stays aligned with the ram pipeline
            x_frac_delay <= reciprocal_calculator_in.x_frac & x_frac_delay(1 to ram_read_latency-1);

            -- a new request issues its ram lookup
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            if reciprocal_calculator_in.request_with_1 = '1' then
                index := get_reciprocal_index(reciprocal_calculator_in.x_frac);
                request_data_from_ram(ram_a_in, index);
                request_data_from_ram(ram_b_in, index + recip_number_of_entries);
            end if;

        end if;
    end process;

    ------------------------------------------------------------------------
    -- the request to fixed_dsp, combinational from the ram output and the
    -- delay line ; it reaches fixed_dsp_in through a register, or directly
    -- when g_dsp_request_register is false
    dsp_request_process : process(all)
        variable fraction_ram : unsigned(recip_fraction_width-1 downto 0);
    begin
        -- ram ready : issue the dsp add for the x_frac that left the
        -- delay line ; result = slope*fraction + point<<radix.
        -- a/b/c are resized up to fixed_dsp_in's actual width (which
        -- may be wider than recip_word_length) before use ; c also
        -- has to be pre-shifted up to the multiplier's output width
        -- here, since fixed_dsp no longer does that internally
        init_fixed_dsp(dsp_request);
        if ram_read_is_ready(ram_a_out) then
            fraction_ram := x_frac_delay(ram_read_latency)(recip_fraction_width-1 downto 0);

            add(dsp_request
                ,a => resize(signed(ram_b_out.data), dsp_request.a'length)
                ,b => signed(resize(fraction_ram, dsp_request.b'length))
                ,c => shift_left(resize(signed(ram_a_out.data), dsp_request.c'length), recip_fraction_width)
            );
        end if;
    end process;

    dsp_request_registered : if g_dsp_request_register generate
        process(clock)
        begin
            if rising_edge(clock) then
                fixed_dsp_in <= dsp_request;
            end if;
        end process;
    end generate;

    dsp_request_direct : if not g_dsp_request_register generate
        fixed_dsp_in <= dsp_request;
    end generate;

end rtl;
