library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;
    use work.multiplier_pkg.all;

package square_root_pkg is

------------------------------------------------------------------------
    function nr_iteration ( number_to_invert, initial_value : real)
        return real;
------------------------------------------------------------------------
    function nr_iteration ( number_to_invert, initial_value : integer)
        return integer;
------------------------------------------------------------------------

end package square_root_pkg;

package body square_root_pkg is

    function nr_iteration
    (
        number_to_invert, initial_value : real
    )
    return real
    is
        variable x : real := 0.0;
    begin
        x := initial_value;
        x := x + x/2.0 - 0.5 * number_to_invert * x*x*x;
        x := x + x/2.0 - 0.5 * number_to_invert * x*x*x;
        x := x + x/2.0 - 0.5 * number_to_invert * x*x*x;
        x := x + x/2.0 - 0.5 * number_to_invert * x*x*x;

        return x;
        
    end nr_iteration;
------------------------------------------------------------------------
    function "*"
    (
        left, right : integer
    )
    return integer
    is
        variable sleft, sright : signed(31 downto 0);
        variable result : signed(63 downto 0);
    begin
        sleft := to_signed(left, 32);
        sright := to_signed(right, 32);
        result := sleft * sright;

        return to_integer(result(63-12 downto 32-12));
        
    end "*";
------------------------------------------------------------------------
    function nr_iteration
    (
        number_to_invert, initial_value : integer
    )
    return integer
    is
        variable x : integer := 0;
    begin
        x := initial_value;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;
        x := to_fixed(1.5,5)*x - to_fixed(0.5,5)* number_to_invert * x*x*x;

        return x;
        
    end nr_iteration;
------------------------------------------------------------------------


end package body square_root_pkg;

------------------------------------------------------------------------
------------------------------------------------------------------------
