library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.division_internal_pkg.all; -- used in body

package division_pkg is
--------------------------------------------------
    subtype range_of_nr_iteration is natural range 0 to 4;
    type division_record is record
        division_process_counter : natural range 0 to 3;
        x: int18;
        number_to_be_reciprocated : int18;
        number_of_newton_raphson_iteration : range_of_nr_iteration;
        dividend : int18;
        divisor : int18;
        check_division_to_be_ready : boolean;
    end record;

    constant init_division : division_record := (3, 0, 0, 0, 0, 0, false);
------------------------------------------------------------------------
    procedure create_division (
        signal hw_multiplier : inout multiplier_record;
        signal division : inout division_record);

------------------------------------------------------------------------
    function division_is_ready ( division_multiplier : multiplier_record; division : division_record)
        return boolean;

------------------------------------------------------------------------
    procedure request_division (
        signal division : out division_record;
        number_to_be_divided : int18;
        number_to_be_reciprocated : int18);
------------------------------------------------------------------------
    procedure request_division (
        signal division : out division_record;
        number_to_be_divided : int18;
        number_to_be_reciprocated : int18;
        iterations : range_of_nr_iteration);
------------------------------------------------------------------------
    function division_is_busy ( division : in division_record)
        return boolean;
------------------------------------------------------------------------
    function get_division_result (
        multiplier : multiplier_record;
        hw_divider : division_record;
        radix      : natural)
    return natural;
------------------------------------------------------------------------
    function get_division_result (
        multiplier : multiplier_record;
        divisor : natural;
        radix : natural)
    return natural;
------------------------------------------------------------------------
end package division_pkg;
