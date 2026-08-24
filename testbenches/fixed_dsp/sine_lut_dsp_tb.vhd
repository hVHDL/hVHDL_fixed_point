LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.lut_sine_pkg.all;
    use work.sine_calculator_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

-- sine_calculator wraps a dual_port_ram (preloaded with lut_sine_pkg's
-- point_lut/slope_lut tables) and a fixed_dsp into a single fully
-- pipelined block : this sweeps every angle, checking each result once it
-- comes back. with use_gaps = false, a new angle is requested every
-- clock cycle without ever waiting for the previous request to complete ;
-- with use_gaps = true, requests are instead issued in irregular bursts
-- with idle cycles in between, to prove the pipeline also tracks
-- in-flight requests correctly when it is not kept saturated
entity sine_lut_dsp_tb is
  generic (
      runner_cfg : string
      ;use_gaps : boolean := false
  );
end;

architecture sim of sine_lut_dsp_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    -- a full sweep of every angle ; the gapped run needs extra cycles for
    -- its idle gaps, plus a little margin for the pipeline to drain, so
    -- reserve enough for that regardless of which mode is actually running
    constant simtime_in_clocks : integer := 2*2**angle_word_length + 20;
------------------------------------------------------------------------

    signal sine_calculator_in  : sine_calculator_in_record;
    signal sine_calculator_out : sine_calculator_out_record;

    signal test_angle : unsigned(angle_word_length-1 downto 0) := (others => '0');

    -- an arbitrary, irregular issue/idle pattern (not a simple period-2
    -- toggle) : bursts of 1-2 requests followed by 1-2 idle cycles
    constant gap_pattern : std_logic_vector(0 to 6) := "1101001";
    signal pattern_index : natural range 0 to gap_pattern'length-1 := 0;

    -- requests are issued in strict order (whether back-to-back or with
    -- gaps in between), and sine_calculator neither stalls nor reorders,
    -- so the k'th result it produces always belongs to the k'th angle
    -- requested -- no need to know its latency
    signal result_count : unsigned(angle_word_length-1 downto 0) := (others => '0');

    signal all_tests_done : boolean := false;
    constant tolerance : real := 0.001;
------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    u_sine_calculator : entity work.sine_calculator
    port map(
        clock => simulator_clock
        ,sine_calculator_in  => sine_calculator_in
        ,sine_calculator_out => sine_calculator_out
    );
------------------------------------------------------------------------

    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(all_tests_done, "sine_calculator sweep did not complete");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus_and_check : process(simulator_clock)
        variable expected      : signed(angle_word_length-1 downto 0);
        variable expected_real : real;
        variable actual_real   : real;
        variable issue_now     : boolean;
    begin
        if rising_edge(simulator_clock) then

            -- request a new angle either every single cycle, or (with
            -- use_gaps) only on the cycles the gap pattern marks as active :
            -- sine_calculator is a single non-stalling pipeline, so it never
            -- has to wait for a previous request to finish before accepting
            -- the next one, but it must also cope with genuine idle cycles
            init_sine_calculator(sine_calculator_in);

            issue_now := (not use_gaps) or (gap_pattern(pattern_index) = '1');
            if issue_now then
                request_sine(sine_calculator_in, test_angle);
                test_angle <= test_angle + 1;
            end if;
            pattern_index <= (pattern_index + 1) mod gap_pattern'length;

            if sine_calculator_out.ready_with_1 = '1' then
                expected := get_sine_from_quarter_wave_lut(result_count);

                check(sine_calculator_out.sine = expected,
                    "sine_calculator mismatch at angle " & natural'image(to_integer(result_count)));

                expected_real := sin(2.0*math_pi*real(to_integer(result_count))/real(2**angle_word_length));
                actual_real   := real(to_integer(sine_calculator_out.sine))/(2.0**(angle_word_length-1)-1.0);
                check(abs(actual_real - expected_real) < tolerance,
                    "sine error too large at angle " & natural'image(to_integer(result_count)));

                if result_count = 2**angle_word_length - 1 then
                    all_tests_done <= true;
                end if;
                result_count <= result_count + 1;
            end if;

        end if; -- rising_edge
    end process stimulus_and_check;
------------------------------------------------------------------------
end sim;
