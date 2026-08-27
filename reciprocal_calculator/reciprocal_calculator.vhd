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
    -- a small fifo of in-flight x_frac requests : the ram read has a
    -- fixed latency and neither stalls nor reorders, so an x_frac pushed
    -- in at request time is popped, once, by the ram-ready stage (to
    -- compute the interpolation fraction). unlike sine_calculator there
    -- is nothing left to recover once the dsp result comes back (no
    -- sign to flip), so a single read pointer is all this needs. the
    -- depth only needs to exceed the ram's own latency, so this is
    -- deliberately generous
    constant fifo_depth : natural := 16;
    type x_frac_fifo_t is array (0 to fifo_depth-1) of unsigned(recip_word_length-1 downto 0);
    signal x_frac_fifo : x_frac_fifo_t;

    signal write_ptr    : natural range 0 to fifo_depth-1 := 0;
    signal ram_read_ptr : natural range 0 to fifo_depth-1 := 0;

    signal dsp_interpolated : signed(recip_word_length-1 downto 0);

begin

    u_dpram : entity work.dual_port_ram
    generic map(
        g_dpram_subtype   => dp_ram_subtype
        ,g_ram_init_values => lut_ram_contents
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
        variable fraction_ram : unsigned(recip_fraction_width-1 downto 0);
    begin
        if rising_edge(clock) then

            -- push : a new request enters the fifo and its ram lookup is
            -- issued in the same cycle
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            if reciprocal_calculator_in.request_with_1 = '1' then
                x_frac_fifo(write_ptr) <= reciprocal_calculator_in.x_frac;
                write_ptr <= (write_ptr + 1) mod fifo_depth;

                index := get_reciprocal_index(reciprocal_calculator_in.x_frac);
                request_data_from_ram(ram_a_in, index);
                request_data_from_ram(ram_b_in, index + recip_number_of_entries);
            end if;

            -- ram ready : issue the dsp add for the oldest fifo entry not
            -- yet consumed by this stage ; result = slope*fraction + point<<radix.
            -- a/b/c are resized up to fixed_dsp_in's actual width (which
            -- may be wider than recip_word_length) before use ; c also
            -- has to be pre-shifted up to the multiplier's output width
            -- here, since fixed_dsp no longer does that internally
            init_fixed_dsp(fixed_dsp_in);
            if ram_read_is_ready(ram_a_out) then
                fraction_ram := x_frac_fifo(ram_read_ptr)(recip_fraction_width-1 downto 0);
                ram_read_ptr <= (ram_read_ptr + 1) mod fifo_depth;

                add(fixed_dsp_in
                    ,a => resize(signed(ram_b_out.data), fixed_dsp_in.a'length)
                    ,b => signed(resize(fraction_ram, fixed_dsp_in.b'length))
                    ,c => shift_left(resize(signed(ram_a_out.data), fixed_dsp_in.c'length), recip_fraction_width)
                );
            end if;

        end if;
    end process;

end rtl;
