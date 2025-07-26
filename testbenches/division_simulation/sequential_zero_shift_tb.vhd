LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity seq_zero_shift_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of seq_zero_shift_tb is
    signal simulation_running : boolean;
    signal simulator_clock : std_logic := '0';
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 7500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    use work.reciproc_pkg.all;
    constant wordlength : natural := 36;
    constant radix : natural := wordlength-3;

    constant init_reciproc : reciprocal_record := create_reciproc_typeref(wordlength);

    signal self : init_reciproc'subtype := init_reciproc;

    use work.real_to_fixed_pkg.all;
    signal test_input : real := 127.0;

    signal result : real := 0.0;
    signal inv_a  : real := 0.0;
    signal ref_a  : real := 0.0;
    signal err_a  : real := 0.0;

    constant max_shift : natural := 8;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        -- wait for simtime_in_clocks*clock_per;
        wait until test_input < 16.0;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

------------------------------------------------------------------------
    simulator_clock <= not simulator_clock after clock_per/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

        variable used_test_input : real := 0.0;

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            create_reciproc(self, max_shift => max_shift, output_int_length => 8);
            inv_a <= to_real(get_result(self), radix);

            if is_ready(self)
            then
                ref_a <= 1.0/to_real(get_result(self), wordlength-3);
                err_a <= 1.0/to_real(get_result(self), wordlength-3) - test_input;
            end if;
            check(err_a < 1.0e-2);

            -- run system in idle loop for 200 clock cycles
            if is_ready(self) or simulation_counter = 200
            then
                used_test_input := test_input*0.9995;
                if (used_test_input < 127.9) and (used_test_input > 1.0)
                then
                    test_input <= used_test_input;
                    request_inv(self, to_fixed(used_test_input, wordlength, wordlength-8), iterations => 5);
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
