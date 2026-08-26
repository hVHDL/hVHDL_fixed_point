LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.fixed_dsp_pkg.all;
    use work.real_to_fixed_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity fixed_dsp_tb is
  generic (
      runner_cfg : string
      -- rtl is a generic-width pipeline usable at any word length ; ecp5
      -- wraps the fixed-width mpy_32x32 hard IP (or its simulation model)
      -- and only works at its native 32x32 bits
      ;use_ecp5 : boolean := false
  );
end;

architecture sim of fixed_dsp_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 50;
------------------------------------------------------------------------
    signal simulation_counter : natural := 0;

    constant word_length : natural := 32;
    constant g_radix     : natural := 16;
    -- the multiplier output and the accumulator carry twice the input
    -- fractional bits, since c is shifted left by g_radix (done here now,
    -- not inside fixed_dsp) to line up with the a*b product before it is added
    constant result_radix : natural := 2*g_radix;

    subtype constrained_fixed_dsp_in_record is fixed_dsp_in_record(
        a(word_length-1 downto 0)
        ,d(word_length-1 downto 0)
        ,b(word_length-1 downto 0)
        -- c is added directly into the multiplier's output width
        ,c(2*word_length-1 downto 0)
    );

    subtype constrained_fixed_dsp_out_record is fixed_dsp_out_record(
        result(2*word_length-1 downto 0)
    );

    signal fixed_dsp_in  : constrained_fixed_dsp_in_record;
    signal fixed_dsp_out : constrained_fixed_dsp_out_record;

    -- exercises the fixed_dsp_pkg convenience procedures instead of
    -- poking the input record fields directly
    type op_kind_t is (op_reset, op_fmac, op_mac, op_add, op_sub);

    type test_case_record is record
        kind                  : op_kind_t;
        real_a                : real;
        real_d                : real;
        real_b                : real;
        real_c                : real;
        pre_subtract_with_1   : std_logic; -- only meaningful for op_fmac
        post_subtract_with_1  : std_logic; -- only meaningful for op_fmac
        invert_result_with_1  : std_logic; -- only meaningful for op_fmac
        accumulate_with_1     : std_logic; -- only meaningful for op_fmac
        expected_result       : real;
    end record;

    type test_case_array is array (natural range <>) of test_case_record;

    -- results below are hand calculated from the rtl : the accumulator
    -- (P) is shared between test cases, so accumulate/reset steps depend
    -- on whatever the previous step left behind
    constant test_cases : test_case_array(0 to 7) := (
        -- kind,      a,     d,   b,   c,     pre_sub, post_sub, invert, acc,  expected
        (op_reset, 0.0,   0.0, 0.0, 0.0,    '0',     '0',      '0',   '0',    0.0)  , -- clear the accumulator
        (op_add,   2.5,   0.0, 1.5, 0.0,    '0',     '0',      '0',   '0',    3.75) , -- add(a,b,0) : a*b
        (op_fmac,  5.0,   1.0, 2.0, 0.5,    '1',     '0',      '0',   '0',    8.5)  , -- fmac : (a-d)*b + c
        (op_sub,   3.0,   0.0, 2.0, 1.25,   '0',     '0',      '0',   '0',    4.75) , -- sub(a,b,c) : a*b - c
        (op_fmac,  3.0,   0.0, 2.0, 1.0,    '0',     '0',      '1',   '0',   -7.0)  , -- fmac w/ invert : -(a*b + c)
        (op_mac,   1.0,   0.0, 1.0, 0.0,    '0',     '0',      '0',   '0',   -6.0)  , -- mac(a,b) : P + a*b (P was -7.0)
        (op_fmac,  2.0,   0.0, 1.5, 0.0,    '0',     '1',      '0',   '1',   -9.0)  , -- fmac accumulate+subtract : P - a*b (P was -6.0)
        (op_reset, 0.0,   0.0, 0.0, 0.0,    '0',     '0',      '0',   '0',    0.0)    -- clear the accumulator again
    );

    constant tolerance : real := 0.001;

    -- fixed_dsp has no internal stall/enable : whatever it is fed on a
    -- given cycle overwrites the accumulator two cycles later, so the
    -- test cases must be issued back-to-back, with no idle cycles in
    -- between, exactly like the microprogram processor drives it
    signal issue_index : natural := 0;
    signal check_index : natural := 0;
    signal all_tests_done : boolean := false;
------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    gen_rtl : if not use_ecp5 generate
        u_fixed_dsp : entity work.fixed_dsp(rtl)
        port map(
            clock => simulator_clock
            ,fixed_dsp_in  => fixed_dsp_in
            ,fixed_dsp_out => fixed_dsp_out
        );
    end generate;

    gen_ecp5 : if use_ecp5 generate
        u_fixed_dsp : entity work.fixed_dsp(ecp5)
        port map(
            clock => simulator_clock
            ,fixed_dsp_in  => fixed_dsp_in
            ,fixed_dsp_out => fixed_dsp_out
        );
    end generate;
------------------------------------------------------------------------

    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(all_tests_done, "fixed_dsp test cases did not all complete");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus_and_check : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            init_fixed_dsp(fixed_dsp_in);

            if issue_index <= test_cases'high then
                CASE test_cases(issue_index).kind is
                    WHEN op_reset =>
                        fixed_dsp_in.request_with_1          <= '1';
                        fixed_dsp_in.reset_accumulator_with_1 <= '1';

                    WHEN op_fmac =>
                        fmac(fixed_dsp_in
                            ,a => to_fixed(test_cases(issue_index).real_a, word_length, g_radix)
                            ,d => to_fixed(test_cases(issue_index).real_d, word_length, g_radix)
                            ,b => to_fixed(test_cases(issue_index).real_b, word_length, g_radix)
                            ,c => shift_left(resize(to_fixed(test_cases(issue_index).real_c, word_length, g_radix), 2*word_length), g_radix)
                            ,pre_subtract_with_1  => test_cases(issue_index).pre_subtract_with_1
                            ,post_subtract_with_1 => test_cases(issue_index).post_subtract_with_1
                            ,invert_result_with_1 => test_cases(issue_index).invert_result_with_1
                            ,accumulate_with_1    => test_cases(issue_index).accumulate_with_1
                        );

                    WHEN op_mac =>
                        mac(fixed_dsp_in
                            ,a => to_fixed(test_cases(issue_index).real_a, word_length, g_radix)
                            ,b => to_fixed(test_cases(issue_index).real_b, word_length, g_radix)
                        );

                    WHEN op_add =>
                        add(fixed_dsp_in
                            ,a => to_fixed(test_cases(issue_index).real_a, word_length, g_radix)
                            ,b => to_fixed(test_cases(issue_index).real_b, word_length, g_radix)
                            ,c => shift_left(resize(to_fixed(test_cases(issue_index).real_c, word_length, g_radix), 2*word_length), g_radix)
                        );

                    WHEN op_sub =>
                        sub(fixed_dsp_in
                            ,a => to_fixed(test_cases(issue_index).real_a, word_length, g_radix)
                            ,b => to_fixed(test_cases(issue_index).real_b, word_length, g_radix)
                            ,c => shift_left(resize(to_fixed(test_cases(issue_index).real_c, word_length, g_radix), 2*word_length), g_radix)
                        );
                end CASE;

                issue_index <= issue_index + 1;
            end if;

            if fixed_dsp_out.ready_with_1 = '1' then
                check(abs(to_real(fixed_dsp_out.result, result_radix) - test_cases(check_index).expected_result) < tolerance,
                    "fixed_dsp result mismatch at test case " & natural'image(check_index));

                if check_index = test_cases'high then
                    all_tests_done <= true;
                else
                    check_index <= check_index + 1;
                end if;
            end if;

        end if; -- rising_edge
    end process stimulus_and_check;
------------------------------------------------------------------------
end sim;
