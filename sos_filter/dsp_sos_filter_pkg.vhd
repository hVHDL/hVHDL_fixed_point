library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

    use work.sos_filter_pkg.all;
    use work.fixed_point_dsp_pkg.all;

package dsp_sos_filter_pkg is
------------------------------------------------------------------------
    type sos_filter_record is record
        y, x1, x2, u               : integer;
        state_counter              : integer;
        result_counter             : integer;
        sos_filter_is_ready        : boolean;
        sos_filter_output_is_ready : boolean;
    end record;

    constant init_sos_filter : sos_filter_record := (0,0,0,0,5,5,false,false);
------------------------------------------------------------------------
    procedure create_sos_filter (
        signal self : inout sos_filter_record;
        signal dsp : inout fixed_point_dsp_record;
        b_gains : in fix_array;
        a_gains : in fix_array);
------------------------------------------------------------------------
    procedure request_sos_filter (
        signal sos_filter : out sos_filter_record;
        input_signal : in integer);
------------------------------------------------------------------------
    function get_sos_filter_output ( sos_filter : sos_filter_record)
        return integer;
------------------------------------------------------------------------

end package dsp_sos_filter_pkg;


package body dsp_sos_filter_pkg is
------------------------------------------------------------------------
    procedure create_sos_filter
    (
        signal self : inout sos_filter_record;
        signal dsp  : inout fixed_point_dsp_record;
        b_gains     : in fix_array;
        a_gains     : in fix_array
    ) is
    begin
        self.sos_filter_output_is_ready <= false;
        self.sos_filter_is_ready <= false;

        if self.state_counter < 5 then
            self.state_counter <= self.state_counter + 1;
        end if;

        if self.result_counter < 5 and fixed_point_dsp_is_ready(dsp) then
            self.result_counter <= self.result_counter + 1;
        end if;

    ------------------------------
        CASE self.state_counter is
            WHEN 0 => multiply_add(dsp , self.u , b_gains(0)   , self.x1);
            WHEN 1 => multiply_add(dsp , self.u , b_gains(1)   , self.x2);
            WHEN 2 => multiply(dsp     , self.u , b_gains(2));
            WHEN 3 => multiply_add(dsp , self.y , -a_gains(1)  , self.x1);
            WHEN 4 => multiply_add(dsp , self.y , -a_gains(2)  , self.x2);
            WHEN others => -- do nothing
        end CASE;
    ------------------------------
        if fixed_point_dsp_is_ready(dsp) then
            CASE self.result_counter is
                WHEN 0 => self.y  <= get_dsp_result(dsp); self.sos_filter_output_is_ready <= true;
                WHEN 1 => self.x1 <= get_dsp_result(dsp);
                WHEN 2 => self.x2 <= get_dsp_result(dsp);
                WHEN 3 => self.x1 <= get_dsp_result(dsp);
                WHEN 4 => self.x2 <= get_dsp_result(dsp); self.sos_filter_is_ready <= true;
                WHEN others => -- do nothing
            end CASE;
        end if;
    ------------------------------
    end create_sos_filter;

    procedure request_sos_filter
    (
        signal sos_filter : out sos_filter_record;
        input_signal : in integer
    ) is
    begin
       sos_filter.u <=  input_signal;
       sos_filter.result_counter <= 0;
       sos_filter.state_counter <= 0;
    end request_sos_filter;
------------------------------------------------------------------------
    function get_sos_filter_output
    (
        sos_filter : sos_filter_record
    )
    return integer
    is
    begin
        return sos_filter.y;
    end get_sos_filter_output;

end package body dsp_sos_filter_pkg;

