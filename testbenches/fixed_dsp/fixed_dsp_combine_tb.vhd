LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.fixed_dsp_pkg.all;
    use work.real_to_fixed_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

-- exercises fixed_dsp_pkg's "and" operator : two independent processes
-- each build their own fixed_dsp_in_record request (starting from
-- init_fixed_dsp's idle state), and the two are combined via "and"
-- (bitwise or, port-onto-a-bus style, not arithmetic addition) into the
-- single request that actually drives one shared fixed_dsp instance.
--
-- process_a issues a plain add(2.0, 3.0, 0.0) = 6.0 on even cycles ;
-- process_b issues a mac(1.0, 1.0) (accumulate) on odd cycles. the two
-- never issue on the same cycle, so the combine is exact, and since
-- requests are gapless (one or the other every single cycle) results
-- come back in the same alternating order : a's add always overwrites
-- the accumulator to 6.0, so b's mac on top of it always lands on 7.0
entity fixed_dsp_combine_tb is
    generic (runner_cfg : string);
end;

architecture sim of fixed_dsp_combine_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;
    constant simtime_in_clocks : integer := 40;
------------------------------------------------------------------------

    constant word_length  : natural := 32;
    constant g_radix      : natural := 16;
    constant result_radix : natural := 2*g_radix;

    subtype constrained_fixed_dsp_in_record is fixed_dsp_in_record(
        a(word_length-1 downto 0)
        ,d(word_length-1 downto 0)
        ,b(word_length-1 downto 0)
        ,c(2*word_length-1 downto 0)
    );
    subtype constrained_fixed_dsp_out_record is fixed_dsp_out_record(
        result(2*word_length-1 downto 0)
    );

    signal req_a, req_b : constrained_fixed_dsp_in_record;
    signal fixed_dsp_in  : constrained_fixed_dsp_in_record;
    signal fixed_dsp_out : constrained_fixed_dsp_out_record;

    signal simulation_counter : natural := 0;
    signal result_count       : natural := 0;
    signal all_tests_done     : boolean := false;

    constant tolerance   : real := 0.001;
    constant expected_a  : real := 6.0;
    constant expected_b  : real := 7.0;
------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    u_fixed_dsp : entity work.fixed_dsp(rtl)
    port map(
        clock => simulator_clock
        ,fixed_dsp_in  => fixed_dsp_in
        ,fixed_dsp_out => fixed_dsp_out
    );

    -- the combine under test : two independently driven requests, or'd
    -- together into the one request that actually reaches the shared
    -- fixed_dsp (a bus combine, not an arithmetic sum)
    fixed_dsp_in <= req_a and req_b;
------------------------------------------------------------------------

    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(all_tests_done, "fixed_dsp_pkg ""and"" combine test did not complete");
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    -- process a : issues a plain add() on even cycles only
    process_a : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            init_fixed_dsp(req_a);
            if simulation_counter mod 2 = 0 then
                add(req_a
                    ,a => to_fixed(2.0, word_length, g_radix)
                    ,b => to_fixed(3.0, word_length, g_radix)
                    ,c => shift_left(resize(to_fixed(0.0, word_length, g_radix), 2*word_length), g_radix)
                );
            end if;
        end if;
    end process;

    -- process b : issues a mac() (accumulate) on odd cycles only ;
    -- never active on the same cycle as process a
    process_b : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            init_fixed_dsp(req_b);
            if simulation_counter mod 2 = 1 then
                mac(req_b
                    ,a => to_fixed(1.0, word_length, g_radix)
                    ,b => to_fixed(1.0, word_length, g_radix)
                );
            end if;
        end if;
    end process;

    check_process : process(simulator_clock)
        variable actual_real   : real;
        variable expected_real : real;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if fixed_dsp_out.ready_with_1 = '1' then
                actual_real := to_real(resize(shift_right(fixed_dsp_out.result, g_radix), word_length), g_radix);

                if result_count mod 2 = 0 then
                    expected_real := expected_a;
                else
                    expected_real := expected_b;
                end if;

                check(abs(actual_real - expected_real) < tolerance,
                    "fixed_dsp_pkg combine mismatch at result " & natural'image(result_count));

                if result_count = 15 then
                    all_tests_done <= true;
                end if;
                result_count <= result_count + 1;
            end if;
        end if;
    end process check_process;
------------------------------------------------------------------------
end sim;
