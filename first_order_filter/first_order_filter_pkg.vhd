library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package first_order_filter_pkg is

------------------------------------------------------------------------
    type first_order_filter is record
        process_counter : natural range 0 to 15;
        filterin_is_ready : boolean;
        filter_is_busy : boolean;
        filter_input : int18;
        filter_output : int18;
        filter_memory : int18; 
    end record;

    constant init_filter_state : first_order_filter := (process_counter => 9, filterin_is_ready => false, filter_is_busy => false, filter_input => 0, filter_output => 0, filter_memory => 0); 

--------------------------------------------------
    procedure create_first_order_filter (
        signal filter : inout first_order_filter;
        signal multiplier : inout multiplier_record;
        constant b0 : int18;
        constant b1 : int18);
--------------------------------------------------
    procedure filter_data (
        signal filter : out first_order_filter;
        data_to_filter : in int18);
--------------------------------------------------
    function get_filter_output ( filter : in first_order_filter)
        return int18; 
------------------------------------------------------------------------
    function filter_is_ready ( filter : first_order_filter)
        return boolean;
------------------------------------------------------------------------

end package first_order_filter_pkg;


package body first_order_filter_pkg is
------------------------------------------------------------------------
    procedure create_first_order_filter
    (
        signal filter : inout first_order_filter;
        signal multiplier : inout multiplier_record;
        constant b0 : int18;
        constant b1 : int18
    ) is
        constant a1 : int18 := 2**17-1-b1-b0;
        alias filterin_is_ready is filter.filterin_is_ready;
        alias filter_is_busy  is filter.filter_is_busy;
        alias process_counter is filter.process_counter;
        alias filter_memory   is filter.filter_memory;
        alias filter_input    is filter.filter_input;
        alias filter_output   is filter.filter_output;
        variable y : int18;
    begin
            filterin_is_ready <= false;
            filter_is_busy <= true;
            CASE process_counter is
                WHEN 0 =>
                    multiply(multiplier, filter_input, b0);
                    process_counter <= process_counter + 1;

                WHEN 1 =>
                    multiply(multiplier, filter_input, b1);
                    process_counter <= process_counter + 1;

                WHEN 2 =>
                    if multiplier_is_ready(multiplier) then
                        y := filter_memory + get_multiplier_result(multiplier, 17);
                        filter_output <= y;
                        multiply(multiplier, y, a1);
                        process_counter <= process_counter + 1;
                    end if;

                WHEN 3 =>
                    filter_memory <= get_multiplier_result(multiplier, 17);
                    process_counter <= process_counter + 1;

                WHEN 4 => 

                    if multiplier_is_ready(multiplier) then
                        filter_memory <= filter_memory + get_multiplier_result(multiplier, 17);
                        process_counter <= process_counter + 1;
                        filterin_is_ready <= true;
                    end if;

                WHEN others => -- do nothing
                    filter_is_busy <= false;

            end CASE; 
        
    end create_first_order_filter;
------------------------------------------------------------------------ 

    procedure filter_data
    (
        signal filter : out first_order_filter;
        data_to_filter : in int18
    ) is
    begin
        filter.process_counter <= 0;
        filter.filter_input <= data_to_filter;
        
    end filter_data;

    function get_filter_output
    (
        filter : in first_order_filter
    )
    return int18
    is
    begin
        return filter.filter_output;
    end get_filter_output;

------------------------------------------------------------------------
    function filter_is_ready
    (
        filter : first_order_filter
    )
    return boolean
    is
    begin
        return filter.filterin_is_ready;
    end filter_is_ready;
------------------------------------------------------------------------



end package body first_order_filter_pkg;

