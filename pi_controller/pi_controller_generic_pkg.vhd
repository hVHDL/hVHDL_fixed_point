
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;

package pi_controller_generic_pkg is
    generic (package multiplier_pkg is new work.multiplier_generic_pkg generic map(<>)
            ;g_pi_controller_radix : natural := 12
            );

    use multiplier_pkg.all;
    constant pi_controller_radix : natural := g_pi_controller_radix;

------------------------------------------------------------------------
    type pi_controller_record is record
        integrator                    : mpy_signed;
        pi_out                        : mpy_signed;
        pi_control_process_counter    : natural range 0 to 7;
        pi_control_multiplier_counter : natural range 0 to 7;
        pi_error                      : mpy_signed;
        pi_high_limit                 : mpy_signed;
        pi_low_limit                  : mpy_signed;
        result_is_ready               : boolean;
        is_ready                      : boolean;
    end record;

    function pi_controller_init return pi_controller_record;

    procedure request_pi_control (
        signal pi_controller : out pi_controller_record;
        pi_control_input     : in integer);

    procedure create_pi_controller (
        signal self          : inout pi_controller_record;
        signal hw_multiplier : inout multiplier_record;
        proportional_gain    : in mpy_signed;
        integrator_gain      : in mpy_signed;
        feedforward          : in mpy_signed);

    procedure create_pi_controller (
        signal self          : inout pi_controller_record;
        signal hw_multiplier : inout multiplier_record;
        proportional_gain    : in mpy_signed;
        integrator_gain      : in mpy_signed);

------------------------------------------------------------------------
    function get_pi_control_output ( pi_controller : pi_controller_record)
        return mpy_signed;
------------------------------------------------------------------------
    function pi_control_is_ready ( pi_controller : pi_controller_record)
        return boolean;
------------------------------------------------------------------------
    -- pi control result is ready one cycle before integrator calculation
    function pi_control_result_is_ready ( pi_controller : pi_controller_record)
        return boolean;
------------------------------------------------------------------------
    function init_pi_controller ( symmetric_limit : integer)
    return pi_controller_record;
------------------------------------------------------------------------
end package pi_controller_generic_pkg;


package body pi_controller_generic_pkg is

------------------------------------------------------------------------
    constant pi_controller_initial_values : pi_controller_record := ((others => '0'), (others => '0'), 7, 7, (others => '0'), to_fixed(1.0,mpy_signed'length,15), to_fixed(-1.0,mpy_signed'length,mpy_signed'length), false, false);

    function pi_controller_init return pi_controller_record
    is
    begin
        return pi_controller_initial_values;
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
        returned_pi_controller.pi_high_limit := to_signed(symmetric_limit, mpy_signed'length);
        returned_pi_controller.pi_low_limit := -to_signed(symmetric_limit, mpy_signed'length);
        return returned_pi_controller;

    end init_pi_controller;
------------------------------------------------------------------------
    procedure create_pi_controller
    (
        signal self          : inout pi_controller_record;
        signal hw_multiplier : inout multiplier_record;
        proportional_gain    : in mpy_signed;
        integrator_gain      : in mpy_signed;
        feedforward          : in mpy_signed
    ) is

        variable output_with_feedforward : mpy_signed;
    begin
        CASE self.pi_control_multiplier_counter is
            WHEN 0 =>
                multiply(hw_multiplier, proportional_gain , self.pi_error);
                self.pi_control_multiplier_counter <= self.pi_control_multiplier_counter  + 1;
            WHEN 1 =>
                multiply(hw_multiplier, integrator_gain , self.pi_error);
                self.pi_control_multiplier_counter <= self.pi_control_multiplier_counter + 1;
            WHEN others => -- wait for start
        end CASE;

        self.is_ready <= false;
        self.result_is_ready <= false;
        CASE self.pi_control_process_counter is
            WHEN 0 => 
                if multiplier_is_ready(hw_multiplier) then
                    self.pi_control_process_counter <= self.pi_control_process_counter + 1;

                    output_with_feedforward := self.integrator 
                        + get_multiplier_result(hw_multiplier, pi_controller_radix, pi_controller_radix, pi_controller_radix)
                        + feedforward;

                    self.pi_out <= output_with_feedforward;

                    if output_with_feedforward >= self.pi_high_limit then
                        self.pi_out          <= self.pi_high_limit;
                        self.integrator      <= self.pi_high_limit 
                                                - get_multiplier_result(hw_multiplier, pi_controller_radix, pi_controller_radix, pi_controller_radix) 
                                                - feedforward;
                        self.pi_control_process_counter <= self.pi_control_process_counter + 2;
                        self.is_ready <= true;
                    end if;

                    if output_with_feedforward <= self.pi_low_limit then
                        self.pi_out          <= self.pi_low_limit;
                        self.integrator      <= self.pi_low_limit 
                                                - get_multiplier_result(hw_multiplier, pi_controller_radix, pi_controller_radix, pi_controller_radix) 
                                                - feedforward;
                        self.pi_control_process_counter <= self.pi_control_process_counter + 2;
                        self.is_ready <= true;
                    end if;

                    self.result_is_ready <= true;
                end if;
            WHEN 1 =>
                self.integrator <= self.integrator 
                                   + get_multiplier_result(hw_multiplier, pi_controller_radix, pi_controller_radix, pi_controller_radix);
                self.pi_control_process_counter <= self.pi_control_process_counter + 1;
                self.is_ready <= true;
            WHEN others => -- wait for restart
        end CASE;

    end create_pi_controller;
------------------------------------------------------------------------
    procedure create_pi_controller
    (
        signal self          : inout pi_controller_record;
        signal hw_multiplier : inout multiplier_record;
        proportional_gain    : in mpy_signed;
        integrator_gain      : in mpy_signed
    ) is
    begin
        create_pi_controller(self
            , hw_multiplier
            , proportional_gain
            , integrator_gain
            , (others => '0'));
    end create_pi_controller;
------------------------------------------------------------------------
    procedure request_pi_control
    (
        signal pi_controller : out pi_controller_record;
        pi_control_input     : in integer
    ) is
    begin

        pi_controller.pi_control_process_counter <= 0;
        pi_controller.pi_control_multiplier_counter <= 0;
        pi_controller.pi_error <= to_signed(pi_control_input, pi_controller.pi_error'length);

    end request_pi_control;
------------------------------------------------------------------------ 
    function get_pi_control_output
    (
        pi_controller : pi_controller_record
    )
    return mpy_signed
    is
    begin
        return pi_controller.pi_out;
    end get_pi_control_output;
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
    -- pi control result is ready one cycle before integrator calculation
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
end package body pi_controller_generic_pkg;
