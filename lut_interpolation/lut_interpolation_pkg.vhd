library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package lut_interpolation_pkg is

    -- angle is a 16 bit unsigned fraction of a full turn : 0 => 0 rad, 65536 => 2*pi rad
    constant angle_word_length : natural := 16;
    constant address_width     : natural := 8;
    constant fraction_width    : natural := angle_word_length - 2 - address_width;
    constant number_of_entries : natural := 2**address_width;

    -- lut entries share the angle's word length
    type sine_table_array is array (natural range <>) of signed(angle_word_length-1 downto 0);

------------------------------------------------------------------------
    function calculate_point_lut ( number_of_entries : natural)
        return sine_table_array;
------------------------------------------------------------------------
    function calculate_slope_lut ( number_of_entries : natural)
        return sine_table_array;
------------------------------------------------------------------------
    -- quarter wave symmetry : the index used to read both the point and the
    -- slope lut for a given angle (the angle is mirrored first when its
    -- quadrant is odd)
    function get_quarter_index ( angle_rad16 : unsigned(angle_word_length-1 downto 0))
        return natural;
------------------------------------------------------------------------
    -- quarter wave sine lookup with linear interpolation using a single MAC :
    -- sine = point_lut(address) + slope_lut(address) * fraction ;
    -- the output length follows from the lut entries used to build it
    function get_sine_from_quarter_wave_lut ( angle_rad16 : unsigned(angle_word_length-1 downto 0))
        return signed;
------------------------------------------------------------------------

    -- deferred constants : values are given in the package body, once the
    -- generator functions above have been elaborated
    constant point_lut : sine_table_array(0 to number_of_entries-1);
    constant slope_lut : sine_table_array(0 to number_of_entries-1);

------------------------------------------------------------------------
end package lut_interpolation_pkg;

package body lut_interpolation_pkg is
------------------------------------------------------------------------
    function calculate_point_lut
    (
        number_of_entries : natural
    )
    return sine_table_array
    is
        variable result : sine_table_array(0 to number_of_entries-1);
        constant scale  : real := 2.0**(result(0)'length-1) - 1.0;
    begin
        for i in 0 to number_of_entries-1 loop
            result(i) := to_signed(integer(round(sin(math_pi/2.0 * real(i)/real(number_of_entries)) * scale)), result(i)'length);
        end loop;
        return result;

    end calculate_point_lut;
------------------------------------------------------------------------
    function calculate_slope_lut
    (
        number_of_entries : natural
    )
    return sine_table_array
    is
        variable result : sine_table_array(0 to number_of_entries-1);
        constant scale  : real := 2.0**(result(0)'length-1) - 1.0;
        variable this_point, next_point : real;
    begin
        for i in 0 to number_of_entries-1 loop
            this_point := sin(math_pi/2.0 * real(i)/real(number_of_entries));
            next_point := sin(math_pi/2.0 * real(i+1)/real(number_of_entries));
            result(i) := to_signed(integer(round((next_point - this_point) * scale)), result(i)'length);
        end loop;
        return result;

    end calculate_slope_lut;
------------------------------------------------------------------------
    -- the next-to-top bit tells whether the quadrant is odd, in which case
    -- the quarter wave lut must be traversed backwards (quarter wave symmetry) ;
    -- not exported, used to build the quarter index and the fraction
    function get_phase_in_quadrant
    (
        angle_rad16 : unsigned(angle_word_length-1 downto 0)
    )
    return unsigned
    is
    begin
        if angle_rad16(angle_word_length-2) = '1' then
            return not angle_rad16(angle_word_length-3 downto 0);
        else
            return angle_rad16(angle_word_length-3 downto 0);
        end if;

    end get_phase_in_quadrant;
------------------------------------------------------------------------
    function get_quarter_index
    (
        angle_rad16 : unsigned(angle_word_length-1 downto 0)
    )
    return natural
    is
    begin
        return to_integer(get_phase_in_quadrant(angle_rad16)(angle_word_length-3 downto fraction_width));

    end get_quarter_index;
------------------------------------------------------------------------
    function get_sine_from_quarter_wave_lut
    (
        angle_rad16 : unsigned(angle_word_length-1 downto 0)
    )
    return signed
    is
        -- top bit tells whether the sine is in the negative half of the wave
        variable is_negative        : std_logic;
        variable quarter_index      : natural range 0 to number_of_entries-1;
        variable fraction           : unsigned(fraction_width-1 downto 0);
        variable product            : signed(point_lut(0)'length + fraction'length downto 0);
        variable interpolated_value : signed(point_lut(0)'length-1 downto 0);
    begin
        is_negative   := angle_rad16(angle_word_length-1);
        quarter_index := get_quarter_index(angle_rad16);
        fraction      := get_phase_in_quadrant(angle_rad16)(fraction_width-1 downto 0);

        -- single MAC operation : point + slope * fraction, done entirely with
        -- signed/unsigned arithmetic ; the radix scaling is a free bit-select
        -- on the product, not a separate shift operation ; the output length
        -- is simply the length of the lut entries feeding the MAC
        product := slope_lut(quarter_index) * signed('0' & fraction);

        interpolated_value := point_lut(quarter_index) + product(product'left-1 downto fraction'length);

        if is_negative = '1' then
            return -interpolated_value;
        else
            return interpolated_value;
        end if;

    end get_sine_from_quarter_wave_lut;
------------------------------------------------------------------------
    constant point_lut : sine_table_array(0 to number_of_entries-1) := calculate_point_lut(number_of_entries);
    constant slope_lut : sine_table_array(0 to number_of_entries-1) := calculate_slope_lut(number_of_entries);
------------------------------------------------------------------------
end package body lut_interpolation_pkg;
