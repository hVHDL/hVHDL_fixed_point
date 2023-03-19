library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package pi_controller_pkg is

------------------------------------------------------------------------
    type pi_controller_record is record
        integrator                    : int;
        pi_out                        : int;
        pi_control_process_counter    : natural range 0 to 7;
        pi_control_multiplier_counter : natural range 0 to 7;
        pi_error                      : int;
        pi_high_limit                 : int;
        pi_low_limit                  : int;
        result_is_ready               : boolean;
        is_ready                      : boolean;
        pi_controller_radix           : natural;
    end record;

    function pi_controller_init return pi_controller_record;

    function pi_controller_init ( radix : int)
        return pi_controller_record;

------------------------------------------------------------------------
    function get_pi_control_output ( pi_controller : pi_controller_record)
        return int;

    function init_pi_controller return pi_controller_record;

    function init_pi_controller ( symmetric_limit : integer)
        return pi_controller_record;

------------------------------------------------------------------------
    procedure create_pi_controller (
        signal hw_multiplier        : inout multiplier_record;
        signal pi_controller_object : inout pi_controller_record;
        proportional_gain           : in integer range 0 to int'high;
        integrator_gain             : in integer range 0 to int'high);

    procedure create_pi_control_and_multiplier (
        signal self       : inout pi_controller_record;
        signal multiplier : inout multiplier_record;
        proportional_gain : in integer range 0 to int'high;
        integrator_gain   : in integer range 0 to int'high);

    procedure create_pi_control_and_multiplier (
        signal self       : inout pi_controller_record;
        signal multiplier : inout multiplier_record;
        proportional_gain : in integer range 0 to int'high;
        integrator_gain   : in integer range 0 to int'high;
        high_limit        : int;
        low_limit         : int);

------------------------------------------------------------------------
    procedure calculate_pi_control (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int);

    procedure request_pi_control (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int);

------------------------------------------------------------------------
    function pi_control_calculation_is_ready ( pi_controller : pi_controller_record)
        return boolean;

    function pi_control_is_ready ( pi_controller : pi_controller_record)
        return boolean;

    function pi_control_result_is_ready ( pi_controller : pi_controller_record)
        return boolean;

------------------------------------------------------------------------
end package pi_controller_pkg;


package body pi_controller_pkg is

------------------------------------------------------------------------
    constant pi_controller_initial_values : pi_controller_record := (0, 0, 7, 7, 0, 32767, -32768, false, false, 12);

    function pi_controller_init return pi_controller_record
    is
    begin
        return pi_controller_initial_values;
    end pi_controller_init;

---
    function pi_controller_init
    (
        radix : int
    )
    return pi_controller_record
    is
        variable returned_value : pi_controller_record := pi_controller_initial_values;
    begin
        returned_value.pi_controller_radix := radix;
        return returned_value;
        
    end pi_controller_init;

---
    function init_pi_controller return pi_controller_record
    is
    begin
        return pi_controller_init;
    end init_pi_controller;
---
    function init_pi_controller
    (
        symmetric_limit : integer
    )
    return pi_controller_record
    is
        variable returned_pi_controller : pi_controller_record := pi_controller_init;
    begin
        returned_pi_controller.pi_high_limit := symmetric_limit;
        returned_pi_controller.pi_low_limit := symmetric_limit;
        return returned_pi_controller;
        
    end init_pi_controller;
------------------------------------------------------------------------
    procedure create_pi_controller
    (
        signal hw_multiplier        : inout multiplier_record;
        signal pi_controller_object : inout pi_controller_record;
        proportional_gain           : in integer range 0 to int'high;
        integrator_gain             : in integer range 0 to int'high
    ) is
        alias m is pi_controller_object;

    begin
        CASE m.pi_control_multiplier_counter is
            WHEN 0 =>
                multiply(hw_multiplier, proportional_gain , m.pi_error);
                m.pi_control_multiplier_counter <= m.pi_control_multiplier_counter  + 1;
            WHEN 1 =>
                multiply(hw_multiplier, integrator_gain , m.pi_error);
                m.pi_control_multiplier_counter <= m.pi_control_multiplier_counter + 1;
            WHEN others => -- wait for start
        end CASE;

        m.is_ready <= false;
        m.result_is_ready <= false;
        CASE m.pi_control_process_counter is
            WHEN 0 => 
                if multiplier_is_ready(hw_multiplier) then
                    m.pi_control_process_counter <= m.pi_control_process_counter + 1;

                    m.pi_out <= m.integrator + get_multiplier_result(hw_multiplier, m.pi_controller_radix);
                    if m.integrator + get_multiplier_result(hw_multiplier, m.pi_controller_radix) >= m.pi_high_limit then
                        m.pi_out          <= m.pi_high_limit;
                        m.integrator      <= m.pi_high_limit - get_multiplier_result(hw_multiplier, m.pi_controller_radix);
                        m.pi_control_process_counter <= m.pi_control_process_counter + 2;
                        m.is_ready <= true;
                    end if;

                    if m.integrator + get_multiplier_result(hw_multiplier, m.pi_controller_radix) <= m.pi_low_limit then
                        m.pi_out          <= m.pi_low_limit;
                        m.integrator      <= m.pi_low_limit - get_multiplier_result(hw_multiplier, m.pi_controller_radix);
                        m.pi_control_process_counter <= m.pi_control_process_counter + 2;
                        m.is_ready <= true;
                    end if;

                    m.result_is_ready <= true;
                end if;
            WHEN 1 =>
                m.integrator <= m.integrator + get_multiplier_result(hw_multiplier, m.pi_controller_radix);
                m.pi_control_process_counter <= m.pi_control_process_counter + 1;
                m.is_ready <= true;
            WHEN others => -- wait for restart
        end CASE;
        
    end create_pi_controller;
------------------------------------------------------------------------
    procedure calculate_pi_control
    (
        signal pi_controller : out pi_controller_record;
        pi_control_input     : in int
    ) is
    begin

        pi_controller.pi_control_process_counter <= 0;
        pi_controller.pi_control_multiplier_counter <= 0;
        pi_controller.pi_error <= pi_control_input;
        
    end calculate_pi_control;
------------------------------------------------------------------------ 
    procedure request_pi_control
    (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int
    ) is
    begin
        calculate_pi_control(pi_controller, pi_control_input);
        
    end request_pi_control;
------------------------------------------------------------------------ 
    function get_pi_control_output
    (
        pi_controller : pi_controller_record
    )
    return int
    is
    begin
        return pi_controller.pi_out;
    end get_pi_control_output;
------------------------------------------------------------------------ 
    function pi_control_calculation_is_ready
    (
        pi_controller : pi_controller_record
    )
    return boolean
    is
    begin
        return pi_controller.is_ready;
        
    end pi_control_calculation_is_ready;
------------------------------------------------------------------------ 
    procedure create_pi_control_and_multiplier
    (
        signal self       : inout pi_controller_record;
        signal multiplier : inout multiplier_record;
        proportional_gain : in integer range 0 to int'high;
        integrator_gain   : in integer range 0 to int'high
    ) is
    begin
        create_multiplier(multiplier);
        create_pi_controller(multiplier, self, proportional_gain, integrator_gain);
    end create_pi_control_and_multiplier;
------------------------------------------------------------------------ 
    procedure create_pi_control_and_multiplier
    (
        signal self       : inout pi_controller_record;
        signal multiplier : inout multiplier_record;
        proportional_gain : in integer range 0 to int'high;
        integrator_gain   : in integer range 0 to int'high;
        high_limit        : int;
        low_limit         : int
    ) is
    begin
        create_multiplier(multiplier);
        create_pi_controller(multiplier, self, proportional_gain, integrator_gain);
    end create_pi_control_and_multiplier;
------------------------------------------------------------------------ 
    function pi_control_is_ready
    (
        pi_controller : pi_controller_record
    )
    return boolean
    is
    begin
        return pi_controller.is_ready;
    end pi_control_is_ready;
------------------------------------------------------------------------ 
    function pi_control_result_is_ready
    (
        pi_controller : pi_controller_record
    )
    return boolean
    is
    begin
        return pi_controller.result_is_ready;
    end pi_control_result_is_ready;
------------------------------------------------------------------------ 
end package body pi_controller_pkg;
