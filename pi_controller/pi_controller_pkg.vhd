library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library math_library;
    use math_library.multiplier_pkg.all;

package pi_controller_pkg is

------------------------------------------------------------------------
    type pi_controller_record is record
        integrator : int18;
        pi_out     : int18;
        pi_control_process_counter : natural range 0 to 7;
        pi_error : int18;
        pi_high_limit : int18;
        pi_low_limit : int18;
    end record;
    constant pi_controller_init : pi_controller_record := (0, 0, 7, 0, 32768, -32768);
    constant init_pi_controller : pi_controller_record := pi_controller_init;

------------------------------------------------------------------------
    function get_pi_control_output ( pi_controller : pi_controller_record)
        return int18;
------------------------------------------------------------------------
    procedure create_pi_controller (
        signal hw_multiplier : inout multiplier_record;
        signal pi_controller : inout pi_controller_record;
        proportional_gain    : in uint17;
        integrator_gain      : in uint17); 
------------------------------------------------------------------------
    procedure calculate_pi_control (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int18);

    procedure request_pi_control (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int18);

------------------------------------------------------------------------
    function pi_control_calculation_is_ready ( pi_controller : pi_controller_record)
        return boolean;
------------------------------------------------------------------------
end package pi_controller_pkg;


package body pi_controller_pkg is

------------------------------------------------------------------------
    procedure create_pi_controller
    (
        signal hw_multiplier : inout multiplier_record;
        signal pi_controller : inout pi_controller_record;
        proportional_gain    : in uint17;
        integrator_gain      : in uint17
    ) is
        alias pi_control_process_counter is pi_controller.pi_control_process_counter;
        alias kp is proportional_gain;
        alias ki is integrator_gain;
        alias pi_error is pi_controller.pi_error;
        alias pi_out is pi_controller.pi_out;
        alias integrator is pi_controller.integrator;
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
                    if integrator + get_multiplier_result(hw_multiplier, pi_controller_radix) >= pi_controller_limit then
                        pi_out          <= pi_controller_limit;
                        integrator      <= pi_controller_limit - get_multiplier_result(hw_multiplier, pi_controller_radix);
                        pi_control_process_counter <= pi_control_process_counter + 2;
                    end if;

                    if integrator + get_multiplier_result(hw_multiplier, pi_controller_radix) <= -pi_controller_limit then
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
        pi_control_input : in int18
    ) is
    begin

        pi_controller.pi_control_process_counter <= 0;
        pi_controller.pi_error <= pi_control_input;
        
    end calculate_pi_control;
------------------------------------------------------------------------ 
    procedure request_pi_control
    (
        signal pi_controller : out pi_controller_record;
        pi_control_input : in int18
    ) is
    begin
        calculate_pi_control(pi_controller, pi_control_input);
        
    end request_pi_control;
------------------------------------------------------------------------ 
    function get_pi_control_output
    (
        pi_controller : pi_controller_record
    )
    return int18
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

