library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_sqrt_pkg.all;

-- a single fully pipelined sqrt(x) lookup : a new x_frac can be requested
-- every clock cycle, before earlier requests have produced their result ;
-- internally this wraps a dual_port_ram (holding lut_sqrt_pkg's
-- point_lut/slope_lut tables) and a fixed_dsp (performing the
-- interpolation multiply-add), each of which is itself a fixed-latency,
-- non-stalling pipeline stage. mirrors reciprocal_calculator : sqrt(x)
-- has no quarter-wave mirroring and is always positive, so there is no
-- sign to track from request through to output
package sqrt_calculator_pkg is

    type sqrt_calculator_in_record is record
        x_frac         : unsigned(sqrt_word_length-1 downto 0);
        request_with_1 : std_logic;
    end record;

    type sqrt_calculator_out_record is record
        y            : unsigned(sqrt_word_length-1 downto 0);
        ready_with_1 : std_logic;
    end record;

    procedure init_sqrt_calculator (signal self : out sqrt_calculator_in_record);

    procedure request_sqrt (
        signal self : out sqrt_calculator_in_record
        ;x_frac : unsigned
    );

end package sqrt_calculator_pkg;

package body sqrt_calculator_pkg is

    procedure init_sqrt_calculator (signal self : out sqrt_calculator_in_record) is
    begin
        self <= (
            x_frac         => (self.x_frac'range => '0')
            ,request_with_1 => '0'
        );
    end procedure;

    procedure request_sqrt (
        signal self : out sqrt_calculator_in_record
        ;x_frac : unsigned
    ) is
    begin
        self.x_frac         <= x_frac;
        self.request_with_1 <= '1';
    end procedure;

end package body sqrt_calculator_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_sqrt_pkg.all;
    use work.dual_port_ram_pkg.all;
    use work.fixed_dsp_pkg.all;
    use work.sqrt_calculator_pkg.all;

entity sqrt_calculator is
    port (
        clock : in std_logic := '0'
        ;sqrt_calculator_in  : in sqrt_calculator_in_record
        ;sqrt_calculator_out : out sqrt_calculator_out_record
    );
end entity;

architecture rtl of sqrt_calculator is

    -- point_lut fills the low half of the ram's address space, slope_lut
    -- the high half
    function build_lut_ram_contents return ram_array is
        variable retval : ram_array(0 to 2*sqrt_number_of_entries-1)(sqrt_word_length-1 downto 0);
    begin
        for i in 0 to sqrt_number_of_entries-1 loop
            retval(i)                        := std_logic_vector(point_lut(i));
            retval(i + sqrt_number_of_entries) := std_logic_vector(slope_lut(i));
        end loop;
        return retval;
    end function;

    constant lut_ram_contents : ram_array(0 to 2*sqrt_number_of_entries-1)(sqrt_word_length-1 downto 0)
        := build_lut_ram_contents;

    constant dp_ram_subtype : dpram_ref_record := create_ref_subtypes(
        datawidth     => sqrt_word_length
        ,addresswidth => sqrt_index_width+1
    );

    signal ram_a_in  : dp_ram_subtype.ram_in'subtype;
    signal ram_a_out : dp_ram_subtype.ram_out'subtype;
    signal ram_b_in  : ram_a_in'subtype;
    signal ram_b_out : ram_a_out'subtype;

    subtype constrained_fixed_dsp_in_record is fixed_dsp_in_record(
        a(sqrt_word_length-1 downto 0)
        ,d(sqrt_word_length-1 downto 0)
        ,b(sqrt_word_length-1 downto 0)
        ,c(sqrt_word_length-1 downto 0)
    );
    subtype constrained_fixed_dsp_out_record is fixed_dsp_out_record(
        result(2*sqrt_word_length-1 downto 0)
    );

    signal dsp_in  : constrained_fixed_dsp_in_record;
    signal dsp_out : constrained_fixed_dsp_out_record;

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
    type x_frac_fifo_t is array (0 to fifo_depth-1) of unsigned(sqrt_word_length-1 downto 0);
    signal x_frac_fifo : x_frac_fifo_t;

    signal write_ptr    : natural range 0 to fifo_depth-1 := 0;
    signal ram_read_ptr : natural range 0 to fifo_depth-1 := 0;

    signal dsp_interpolated : signed(sqrt_word_length-1 downto 0);

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

    u_fixed_dsp : entity work.fixed_dsp(rtl)
    generic map(g_radix => sqrt_fraction_width)
    port map(
        clock => clock
        ,fixed_dsp_in  => dsp_in
        ,fixed_dsp_out => dsp_out
    );

    ------------------------------------------------------------------------
    -- (point<<g_radix + slope*fraction) >> g_radix = point + (slope*fraction >> g_radix)
    -- exactly, since point<<g_radix is a multiple of 2**g_radix, so this
    -- reproduces get_sqrt_from_lut bit for bit ; purely combinational
    -- from already-registered signals, so no extra latency is added on
    -- top of the dsp's own
    dsp_interpolated <= resize(shift_right(dsp_out.result, sqrt_fraction_width), sqrt_word_length);

    sqrt_calculator_out.ready_with_1 <= dsp_out.ready_with_1;
    sqrt_calculator_out.y            <= unsigned(dsp_interpolated);

    process(clock)
        variable index        : natural range 0 to sqrt_number_of_entries-1;
        variable fraction_ram : unsigned(sqrt_fraction_width-1 downto 0);
    begin
        if rising_edge(clock) then

            -- push : a new request enters the fifo and its ram lookup is
            -- issued in the same cycle
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            if sqrt_calculator_in.request_with_1 = '1' then
                x_frac_fifo(write_ptr) <= sqrt_calculator_in.x_frac;
                write_ptr <= (write_ptr + 1) mod fifo_depth;

                index := get_sqrt_index(sqrt_calculator_in.x_frac);
                request_data_from_ram(ram_a_in, index);
                request_data_from_ram(ram_b_in, index + sqrt_number_of_entries);
            end if;

            -- ram ready : issue the dsp add for the oldest fifo entry not
            -- yet consumed by this stage ; result = slope*fraction + point<<g_radix
            init_fixed_dsp(dsp_in);
            if ram_read_is_ready(ram_a_out) then
                fraction_ram := x_frac_fifo(ram_read_ptr)(sqrt_fraction_width-1 downto 0);
                ram_read_ptr <= (ram_read_ptr + 1) mod fifo_depth;

                add(dsp_in
                    ,a => signed(ram_b_out.data)
                    ,b => signed(resize(fraction_ram, sqrt_word_length))
                    ,c => signed(ram_a_out.data)
                );
            end if;

        end if;
    end process;

end rtl;
