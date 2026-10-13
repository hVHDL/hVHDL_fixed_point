LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

    use work.lut_sine_pkg.all;

-- lut_sine_pkg's table read at every address, a read requested every clock :
-- each answer comes a clock after its request, sin(2 pi address/1024) scaled
-- by 2**16-1
entity lut_sine_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of lut_sine_tb is

    constant clock_period : time := 1 ns;

    signal clock : std_logic := '0';
    signal sine_lut : ram_record := init_ram_read_port;
    signal request_address : natural := 0;
    signal requesting : boolean := true;
    signal answers : natural := 0;

begin

    clock <= not clock after clock_period/2;

    stimulus : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until answers = lookup_table_size for 2*lookup_table_size*clock_period;
        check_equal(answers, lookup_table_size, "every address answered");
        test_runner_cleanup(runner);
        wait;
    end process;

    reads : process(clock)
        variable expected : integer;
    begin
        if rising_edge(clock) then
            create_lut_sine(sine_lut);

            if requesting then
                request_sine_from_lut(sine_lut, request_address);
                if request_address < lookup_table_size-1 then
                    request_address <= request_address + 1;
                else
                    requesting <= false;
                end if;
            end if;

            if sine_lut_is_ready(sine_lut) then
                expected := integer(sin(2.0*math_pi*real(answers)/real(lookup_table_size))*(2.0**16-1.0));
                check_equal(get_sine_from_lut(sine_lut), expected, "sine at " & integer'image(answers));
                answers <= answers + 1;
            end if;
        end if;
    end process;

end vunit_simulation;
