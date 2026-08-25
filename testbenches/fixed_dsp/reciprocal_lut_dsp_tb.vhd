LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.lut_reciprocal_pkg.all;
    use work.reciprocal_calculator_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

-- reciprocal_calculator wraps a dual_port_ram (preloaded with
-- lut_reciprocal_pkg's point_lut/slope_lut tables) and a fixed_dsp into a
-- single fully pipelined block : this sweeps every x_frac, checking each
-- result once it comes back. with use_gaps = false, a new x_frac is
-- requested every clock cycle without ever waiting for the previous
-- request to complete ; with use_gaps = true, requests are instead
-- issued in irregular bursts with idle cycles in between, to prove the
-- pipeline also tracks in-flight requests correctly when it is not kept
-- saturated
entity reciprocal_lut_dsp_tb is
  generic (
      runner_cfg : string
      ;use_gaps : boolean := false
  );
end;

architecture sim of reciprocal_lut_dsp_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    -- a full sweep of every x_frac ; the gapped run needs extra cycles
    -- for its idle gaps, plus a little margin for the pipeline to drain,
    -- so reserve enough for that regardless of which mode is running
    constant simtime_in_clocks : integer := 2*2**recip_word_length + 20;
------------------------------------------------------------------------

    signal reciprocal_calculator_in  : reciprocal_calculator_in_record;
    signal reciprocal_calculator_out : reciprocal_calculator_out_record;

    signal test_x_frac : unsigned(recip_word_length-1 downto 0) := (others => '0');

    -- an arbitrary, irregular issue/idle pattern (not a simple period-2
    -- toggle) : bursts of 1-2 requests followed by 1-2 idle cycles
    constant gap_pattern : std_logic_vector(0 to 6) := "1101001";
    signal pattern_index : natural range 0 to gap_pattern'length-1 := 0;

    -- requests are issued in strict order (whether back-to-back or with
    -- gaps in between), and reciprocal_calculator neither stalls nor
    -- reorders, so the k'th result it produces always belongs to the
    -- k'th x_frac requested -- no need to know its latency
    signal result_count : unsigned(recip_word_length-1 downto 0) := (others => '0');

    signal all_tests_done : boolean := false;
    constant tolerance : real := 0.001;

    signal calculated_reciprocal : real := 0.0;
    signal reciprocal_error      : real := 0.0;
------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    u_reciprocal_calculator : entity work.reciprocal_calculator
    port map(
        clock => simulator_clock
        ,reciprocal_calculator_in  => reciprocal_calculator_in
        ,reciprocal_calculator_out => reciprocal_calculator_out
    );
------------------------------------------------------------------------

    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(all_tests_done, "reciprocal_calculator sweep did not complete");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus_and_check : process(simulator_clock)
        variable x           : real;
        variable expected    : unsigned(recip_word_length-1 downto 0);
        variable expected_real : real;
        variable actual_real   : real;
        variable issue_now     : boolean;
    begin
        if rising_edge(simulator_clock) then

            -- request a new x_frac either every single cycle, or (with
            -- use_gaps) only on the cycles the gap pattern marks as active :
            -- reciprocal_calculator is a single non-stalling pipeline, so it
            -- never has to wait for a previous request to finish before
            -- accepting the next one, but it must also cope with genuine
            -- idle cycles
            init_reciprocal_calculator(reciprocal_calculator_in);

            issue_now := (not use_gaps) or (gap_pattern(pattern_index) = '1');
            if issue_now then
                request_reciprocal(reciprocal_calculator_in, test_x_frac);
                test_x_frac <= test_x_frac + 1;
            end if;
            pattern_index <= (pattern_index + 1) mod gap_pattern'length;

            if reciprocal_calculator_out.ready_with_1 = '1' then
                expected := get_reciprocal_from_lut(result_count);

                check(reciprocal_calculator_out.y = expected,
                    "reciprocal_calculator mismatch at x_frac " & natural'image(to_integer(result_count)));

                x             := 0.5 * (1.0 + real(to_integer(result_count))/real(2**recip_word_length));
                expected_real := 1.0 / x;
                actual_real   := real(to_integer(reciprocal_calculator_out.y))/(2.0**(recip_word_length-2)-1.0);
                calculated_reciprocal <= actual_real;
                check(abs(actual_real - expected_real) < tolerance,
                    "reciprocal error too large at x_frac " & natural'image(to_integer(result_count)));

                reciprocal_error <= actual_real - expected_real;
                if result_count = 2**recip_word_length - 1 then
                    all_tests_done <= true;
                end if;
                result_count <= result_count + 1;
            end if;

        end if; -- rising_edge
    end process stimulus_and_check;
------------------------------------------------------------------------
end sim;
