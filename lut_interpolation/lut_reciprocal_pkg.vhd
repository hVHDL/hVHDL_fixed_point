library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package lut_reciprocal_pkg is

    -- x_frac is an unsigned fixed point fraction representing a normalized
    -- mantissa 0.5 <= x < 1.0 : x = 0.5 + x_frac / 2**(recip_word_length+1)
    constant recip_word_length     : natural := 16;
    constant recip_index_width     : natural := 8;
    constant recip_fraction_width  : natural := recip_word_length - recip_index_width;
    constant recip_number_of_entries : natural := 2**recip_index_width;

    -- lut entries share x_frac's word length ; 1/x lands in 1.0 < y <= 2.0,
    -- so two integer bits are reserved (scale = 2**(word length-2) - 1)
    type reciprocal_table_array is array (natural range <>) of signed(recip_word_length-1 downto 0);

------------------------------------------------------------------------
    function calculate_reciprocal_point_lut ( number_of_entries : natural)
        return reciprocal_table_array;
------------------------------------------------------------------------
    function calculate_reciprocal_slope_lut ( number_of_entries : natural)
        return reciprocal_table_array;
------------------------------------------------------------------------
    -- the index used to read both the point and the slope lut for a given x_frac
    function get_reciprocal_index ( x_frac : unsigned(recip_word_length-1 downto 0))
        return natural;
------------------------------------------------------------------------
    -- piecewise-linear 1/x lookup with linear interpolation using a single MAC :
    -- 1/x = point_lut(index) + slope_lut(index) * fraction ;
    -- the output length follows from the lut entries used to build it
    function get_reciprocal_from_lut ( x_frac : unsigned(recip_word_length-1 downto 0))
        return unsigned;
------------------------------------------------------------------------

    -- deferred constants : values are given in the package body, once the
    -- generator functions above have been elaborated
    constant point_lut : reciprocal_table_array(0 to recip_number_of_entries-1);
    constant slope_lut : reciprocal_table_array(0 to recip_number_of_entries-1);

------------------------------------------------------------------------
end package lut_reciprocal_pkg;

package body lut_reciprocal_pkg is
------------------------------------------------------------------------
    -- 1/x for the x represented by address i of number_of_entries, i.e. the
    -- start of the i-th bucket in the 0.5 <= x < 1.0 domain
    function reciprocal_at
    (
        i, number_of_entries : natural
    )
    return real
    is
    begin
        return 1.0 / (0.5 * (1.0 + real(i)/real(number_of_entries)));

    end reciprocal_at;
------------------------------------------------------------------------
    function calculate_reciprocal_point_lut
    (
        number_of_entries : natural
    )
    return reciprocal_table_array
    is
        variable result : reciprocal_table_array(0 to number_of_entries-1);
        constant scale  : real := 2.0**(result(0)'length-2) - 1.0;
    begin
        for i in 0 to number_of_entries-1 loop
            result(i) := to_signed(integer(round(reciprocal_at(i, number_of_entries) * scale)), result(i)'length);
        end loop;
        return result;

    end calculate_reciprocal_point_lut;
------------------------------------------------------------------------
    function calculate_reciprocal_slope_lut
    (
        number_of_entries : natural
    )
    return reciprocal_table_array
    is
        variable result : reciprocal_table_array(0 to number_of_entries-1);
        constant scale  : real := 2.0**(result(0)'length-2) - 1.0;
        variable this_point, next_point : real;
    begin
        for i in 0 to number_of_entries-1 loop
            this_point := reciprocal_at(i,   number_of_entries);
            next_point := reciprocal_at(i+1, number_of_entries);
            result(i) := to_signed(integer(round((next_point - this_point) * scale)), result(i)'length);
        end loop;
        return result;

    end calculate_reciprocal_slope_lut;
------------------------------------------------------------------------
    function get_reciprocal_index
    (
        x_frac : unsigned(recip_word_length-1 downto 0)
    )
    return natural
    is
    begin
        return to_integer(x_frac(recip_word_length-1 downto recip_fraction_width));

    end get_reciprocal_index;
------------------------------------------------------------------------
    function get_reciprocal_from_lut
    (
        x_frac : unsigned(recip_word_length-1 downto 0)
    )
    return unsigned
    is
        variable index               : natural range 0 to recip_number_of_entries-1;
        variable fraction            : unsigned(recip_fraction_width-1 downto 0);
        variable product             : signed(point_lut(0)'length + fraction'length downto 0);
        variable interpolated_value  : signed(point_lut(0)'length-1 downto 0);
    begin
        index    := get_reciprocal_index(x_frac);
        fraction := x_frac(recip_fraction_width-1 downto 0);

        -- single MAC operation : point + slope * fraction, done entirely with
        -- signed/unsigned arithmetic ; the radix scaling is a free bit-select
        -- on the product, not a separate shift operation
        product := slope_lut(index) * signed('0' & fraction);

        interpolated_value := point_lut(index) + product(product'left-1 downto fraction'length);

        -- 1/x is always positive over the 0.5 <= x < 1.0 domain
        return unsigned(interpolated_value);

    end get_reciprocal_from_lut;
------------------------------------------------------------------------
    constant point_lut : reciprocal_table_array(0 to recip_number_of_entries-1) := calculate_reciprocal_point_lut(recip_number_of_entries);
    constant slope_lut : reciprocal_table_array(0 to recip_number_of_entries-1) := calculate_reciprocal_slope_lut(recip_number_of_entries);
------------------------------------------------------------------------
end package body lut_reciprocal_pkg;
