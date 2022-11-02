library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.multiplier_pkg.all;

package pi_controller_pkg is

------------------------------------------------------------------------
    type pi_controller_record is record
        integrator : int;
        pi_out     : int;
        pi_control_process_counter : natural range 0 to 7;
        pi_error : int;
        pi_high_limit : int;
        pi_low_limit : int;
    end record;
    constant pi_controller_init : pi_controller_record := (0, 0, 7, 0, 32768, -32768);

------------------------------------------------------------------------
    function get_pi_control_output ( pi_controller : pi_controller_record)
        return int;

    function init_pi_controller return pi_controller_record;

    function init_pi_controller ( symmetric_limit : integer)
        return pi_controller_record;
------------------------------------------------------------------------
    procedure create_pi_controller (
        signal hw_multiplier : inout multiplier_record;
        signal pi_controller_object : inout pi_controller_record;
        proportional_gain    : in integer range 0 to int'high;
        integrator_gain      : in integer range 0 to int'high); 
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
------------------------------------------------------------------------
end package pi_controller_pkg;


package body pi_controller_pkg is

    function init_pi_controller return pi_controller_record
    is
    begin
        return pi_controller_init;
    end init_pi_controller;
--------------------
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
        signal hw_multiplier : inout multiplier_record;
        signal pi_controller_object : inout pi_controller_record;
        proportional_gain    : in integer range 0 to int'high;
        integrator_gain      : in integer range 0 to int'high
    ) is
        alias m is pi_controller_object;

        alias pi_control_process_counter is pi_controller_object.pi_control_process_counter;
        alias kp is proportional_gain;
        alias ki is integrator_gain;
        alias pi_error is pi_controller_object.pi_error;
        alias pi_out is pi_controller_object.pi_out;
        alias integrator is pi_controller_object.integrator;
        constant pi_controller_radix : natural := 12;
        constant pi_controller_limit : natural := 2**15;
    begin
        CASE pi_control_process_counter is
            WHEN 0 =>
                multiply(hw_multiplier, kp , pi_error);
                pi_control_process_counter <= pi_control_process_counter + 1;
            WHEN 1 =>
                multiply(hw_multiplier, ki , pi_error);
                pi_control_process_counter <= pi_control_process_counter + 1;
            WHEN 2 => 

                if multiplier_is_ready(hw_multiplier) then
                    pi_control_process_counter <= pi_control_process_counter + 1;
                    pi_out <= integrator + get_multiplier_result(hw_multiplier, pi_controller_radix);
                    if integrator + get_multiplier_result(hw_multiplier, pi_controller_radix) >= m.pi_high_limit then
                        pi_out          <= pi_controller_limit;
                        integrator      <= pi_controller_limit - get_multiplier_result(hw_multiplier, pi_controller_radix);
                        pi_control_process_counter <= pi_control_process_counter + 2;
                    end if;

                    if integrator + get_multiplier_result(hw_multiplier, pi_controller_radix) <= -m.pi_low_limit then
                        pi_out          <= -pi_controller_limit;
                        integrator      <= -pi_controller_limit - get_multiplier_result(hw_multiplier, pi_controller_radix);
                        pi_control_process_counter <= pi_control_process_counter + 2;
                    end if;
                end if;
            WHEN 3 =>
                integrator <= integrator + get_multiplier_result(hw_multiplier, pi_controller_radix);
                pi_control_process_counter <= pi_control_process_counter + 1;
            WHEN others => -- wait for restart
        end CASE;
        
    end create_pi_controller;
------------------------------------------------------------------------
    procedure calculate_pi_control
    (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int
    ) is
    begin

        pi_controller.pi_control_process_counter <= 0;
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
        return pi_controller.pi_control_process_counter = 3;
        
    end pi_control_calculation_is_ready;
------------------------------------------------------------------------ 
end package body pi_controller_pkg;

