library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_sine_pkg.all;

-- a single fully pipelined sine lookup : a new angle can be requested
-- every clock cycle, before earlier requests have produced their result ;
-- internally this wraps a dual_port_ram (holding lut_sine_pkg's
-- point_lut/slope_lut tables) and a fixed_dsp (performing the
-- interpolation multiply-add), each of which is itself a fixed-latency,
-- non-stalling pipeline stage
package sine_calculator_pkg is

    type sine_calculator_in_record is record
        angle          : unsigned(angle_word_length-1 downto 0);
        request_with_1 : std_logic;
    end record;

    type sine_calculator_out_record is record
        sine         : signed(angle_word_length-1 downto 0);
        ready_with_1 : std_logic;
    end record;

    procedure init_sine_calculator (signal self : out sine_calculator_in_record);

    procedure request_sine (
        signal self : out sine_calculator_in_record
        ;angle : unsigned
    );

end package sine_calculator_pkg;

package body sine_calculator_pkg is

    procedure init_sine_calculator (signal self : out sine_calculator_in_record) is
    begin
        self <= (
            angle          => (self.angle'range => '0')
            ,request_with_1 => '0'
        );
    end procedure;

    procedure request_sine (
        signal self : out sine_calculator_in_record
        ;angle : unsigned
    ) is
    begin
        self.angle          <= angle;
        self.request_with_1 <= '1';
    end procedure;

end package body sine_calculator_pkg;

------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.lut_sine_pkg.all;
    use work.dual_port_ram_pkg.all;
    use work.fixed_dsp_pkg.all;
    use work.sine_calculator_pkg.all;

entity sine_calculator is
    port (
        clock : in std_logic := '0'
        ;sine_calculator_in  : in sine_calculator_in_record
        ;sine_calculator_out : out sine_calculator_out_record
        ;fixed_dsp_in  : out fixed_dsp_in_record
        ;fixed_dsp_out : in fixed_dsp_out_record
    );
end entity;

architecture rtl of sine_calculator is

    -- point_lut fills the low half of the ram's address space, slope_lut
    -- the high half
    function build_lut_ram_contents return ram_array is
        variable retval : ram_array(0 to 2*number_of_entries-1)(angle_word_length-1 downto 0);
    begin
        for i in 0 to number_of_entries-1 loop
            retval(i)                     := std_logic_vector(point_lut(i));
            retval(i + number_of_entries) := std_logic_vector(slope_lut(i));
        end loop;
        return retval;
    end function;

    constant lut_ram_contents : ram_array(0 to 2*number_of_entries-1)(angle_word_length-1 downto 0)
        := build_lut_ram_contents;

    constant dp_ram_subtype : dpram_ref_record := create_ref_subtypes(
        datawidth     => angle_word_length
        ,addresswidth => address_width+1
    );

    signal ram_a_in  : dp_ram_subtype.ram_in'subtype;
    signal ram_a_out : dp_ram_subtype.ram_out'subtype;
    signal ram_b_in  : ram_a_in'subtype;
    signal ram_b_out : ram_a_out'subtype;

    -- mirrors lut_sine_pkg's own (private) get_phase_in_quadrant, needed
    -- here to recover the interpolation fraction alongside the (public)
    -- get_quarter_index
    function phase_in_quadrant (angle_rad16 : unsigned(angle_word_length-1 downto 0))
        return unsigned is
    begin
        if angle_rad16(angle_word_length-2) = '1' then
            return not angle_rad16(angle_word_length-3 downto 0);
        else
            return angle_rad16(angle_word_length-3 downto 0);
        end if;
    end function;

    ------------------------------------------------------------------------
    -- a small fifo of in-flight angles : the ram read and the dsp add each
    -- have their own fixed latency and neither stalls or reorders, so an
    -- angle pushed in at request time is popped once by the ram-ready
    -- stage (to compute the interpolation fraction) and again by the
    -- dsp-ready stage (to know which angle the finished result belongs to,
    -- for the sign flip). the depth only needs to exceed the combined
    -- ram+dsp latency, so this is deliberately generous
    constant fifo_depth : natural := 16;
    type angle_fifo_t is array (0 to fifo_depth-1) of unsigned(angle_word_length-1 downto 0);
    signal angle_fifo : angle_fifo_t;

    signal ram_read_ptr : natural range 0 to fifo_depth-1 := 0;
    signal output_ptr   : natural range 0 to fifo_depth-1 := 0;
    signal write_ptr     : natural range 0 to fifo_depth-1 := 0;

    signal dsp_interpolated : signed(angle_word_length-1 downto 0);

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
    -- reproduces get_sine_from_quarter_wave_lut bit for bit ; purely
    -- combinational from already-registered signals, so no extra latency
    -- is added on top of the dsp's own
    dsp_interpolated <= resize(shift_right(fixed_dsp_out.result, fraction_width), angle_word_length);

    sine_calculator_out.ready_with_1 <= fixed_dsp_out.ready_with_1;
    sine_calculator_out.sine <=
        -dsp_interpolated when angle_fifo(output_ptr)(angle_word_length-1) = '1'
        else dsp_interpolated;

    process(clock)
        variable quarter_index : natural range 0 to number_of_entries-1;
        variable fraction_ram  : unsigned(fraction_width-1 downto 0);
    begin
        if rising_edge(clock) then

            -- push : a new request enters the fifo and its ram lookup is
            -- issued in the same cycle
            init_ram(ram_a_in);
            init_ram(ram_b_in);
            if sine_calculator_in.request_with_1 = '1' then
                angle_fifo(write_ptr) <= sine_calculator_in.angle;
                write_ptr <= (write_ptr + 1) mod fifo_depth;

                quarter_index := get_quarter_index(sine_calculator_in.angle);
                request_data_from_ram(ram_a_in, quarter_index);
                request_data_from_ram(ram_b_in, quarter_index + number_of_entries);
            end if;

            -- ram ready : issue the dsp add for the oldest fifo entry not
            -- yet consumed by this stage ; c has to be pre-shifted up to
            -- the multiplier's output width here, since fixed_dsp no
            -- longer does that internally
            init_fixed_dsp(fixed_dsp_in);
            if ram_read_is_ready(ram_a_out) then
                fraction_ram := phase_in_quadrant(angle_fifo(ram_read_ptr))(fraction_width-1 downto 0);
                ram_read_ptr <= (ram_read_ptr + 1) mod fifo_depth;

                add(fixed_dsp_in
                    ,a => signed(ram_b_out.data)
                    ,b => signed(resize(fraction_ram, angle_word_length))
                    ,c => shift_left(resize(signed(ram_a_out.data), 2*angle_word_length), fraction_width)
                );
            end if;

            -- dsp ready : the oldest fifo entry not yet output now has its
            -- final sine value on sine_calculator_out (see the
            -- combinational assignments above)
            if fixed_dsp_out.ready_with_1 = '1' then
                output_ptr <= (output_ptr + 1) mod fifo_depth;
            end if;

        end if;
    end process;

end rtl;
