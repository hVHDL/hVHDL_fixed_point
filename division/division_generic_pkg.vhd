library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

package division_generic_pkg is
    generic(package mult_div_pkg is new work.multiplier_generic_pkg generic map(<>));

    use mult_div_pkg.all;
--------------------------------------------------
    subtype range_of_nr_iteration is natural range 0 to 4;
    subtype int is integer range -2**(multiplier_word_length-1) to 2**(multiplier_word_length-1)-1;
    type division_record is record
        division_process_counter           : natural range 0 to 3;
        x                                  : int;
        number_to_be_reciprocated          : int;
        number_of_newton_raphson_iteration : range_of_nr_iteration;
        dividend                           : int;
        divisor                            : int;
        check_division_to_be_ready         : boolean;
    end record;

    constant init_division : division_record := (3, 0, 0, 0, 0, 0, false);
------------------------------------------------------------------------
    procedure create_division (
        signal multiplier : inout multiplier_record;
        signal self : inout division_record);

------------------------------------------------------------------------
    function division_is_ready ( division_multiplier : multiplier_record; self : division_record)
        return boolean;

------------------------------------------------------------------------
    procedure request_division (
        signal self           : out division_record;
        number_to_be_divided      : int;
        number_to_be_reciprocated : int);
------------------------------------------------------------------------
    procedure request_division (
        signal self           : out division_record;
        number_to_be_divided      : int;
        number_to_be_reciprocated : int;
        iterations                : range_of_nr_iteration);
------------------------------------------------------------------------
    function division_is_busy ( self : in division_record)
        return boolean;
------------------------------
    function division_is_not_busy ( self : in division_record)
        return boolean;
------------------------------------------------------------------------
    function get_division_result (
        multiplier : multiplier_record;
        self       : division_record;
        radix      : natural)
    return integer;
------------------------------------------------------------------------
    function get_division_result (
        multiplier : multiplier_record;
        divisor    : natural;
        radix      : natural)
    return integer;
------------------------------------------------------------------------
    procedure create_divider_and_multiplier (
        signal self    : inout division_record;
        signal multiplier : inout multiplier_record);
------------------------------------------------------------------------
end package division_generic_pkg;
