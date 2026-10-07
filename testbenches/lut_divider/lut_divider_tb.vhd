LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.lut_divider_pkg.all;
    use work.lut_reciprocal_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

-- lut_divider is fully pipelined : this requests directed edge cases and
-- then random numerator / denominator pairs, every clock or (use_gaps) in
-- irregular bursts, and checks every quotient once it comes back against
-- the lut_divide reference bit for bit, and against a real division within
-- the lookup table's accuracy. the denominators are shifted right by a
-- random amount so every normalisation shift gets used.
entity lut_divider_tb is
  generic (
      runner_cfg : string
      ;word_length          : natural := 32
      ;quotient_radix       : natural := 16
      ;use_pre_add_register : boolean := false
      ;use_product_register : boolean := false
      ;use_gaps             : boolean := false
      ;shifter_stages       : positive := 2
      ;use_ram_output_register : boolean := true
      ;use_dsp_request_register : boolean := true
      -- the reciprocal table, defaults are lut_reciprocal_pkg's own
      ;index_width          : natural := 8
      ;table_word_length    : natural := 16
      ;table_radix          : natural := 14
      ;x_frac_width         : natural := 16
  );
end;

architecture sim of lut_divider_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;

    constant w : natural := word_length;

    constant point_lut : reciprocal_lut_array := make_reciprocal_point_lut(index_width, table_word_length, table_radix);
    constant slope_lut : reciprocal_lut_array := make_reciprocal_slope_lut(index_width, table_word_length, table_radix);
    subtype word is signed(w-1 downto 0);

    signal lut_divider_in  : lut_divider_in_record(numerator(w-1 downto 0), denominator(w-1 downto 0));
    signal lut_divider_out : lut_divider_out_record(quotient(w-1 downto 0));

    type pair_record is record
        numerator   : word;
        denominator : word;
    end record;
    type pair_array is array (natural range <>) of pair_record;

    constant directed_count : natural := 16;
    constant random_pairs : natural := 5000;
    constant total_pairs  : natural := directed_count + random_pairs;

    -- every request, in order, so each result can be matched to its pair
    signal requested       : pair_array(0 to total_pairs-1);
    signal request_count   : natural := 0;
    signal result_count    : natural := 0;
    signal all_tests_done  : boolean := false;
    signal max_relative_error : real := 0.0;

begin

    simulator_clock <= not simulator_clock after clock_period/2.0;

    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until all_tests_done for 3*total_pairs*clock_period + 1 us;
        check(all_tests_done, "lut_divider did not return every quotient");
        info("max relative error " & real'image(max_relative_error));
        test_runner_cleanup(runner);
        wait;
    end process simtime;

    stimulus : process(simulator_clock)
        variable seed1 : positive := 7;
        variable seed2 : positive := 11;
        variable rnd   : real;
        variable pair  : pair_record;
        variable issue : boolean;

        -- edge cases first : +-1, the extremes, a zero denominator and a
        -- few ordinary values
        function directed_pair (index : natural) return pair_record is
            variable max_word : word;
            variable min_word : word;
            variable retval   : pair_record;
        begin
            max_word := (others => '1');
            max_word(max_word'left) := '0';
            min_word := not max_word;
            case index is
                when 0      => retval := (to_signed(1, w), to_signed(1, w));
                when 1      => retval := (to_signed(1, w), to_signed(-1, w));
                when 2      => retval := (to_signed(-1, w), to_signed(1, w));
                when 3      => retval := (to_signed(-1, w), to_signed(-1, w));
                when 4      => retval := (min_word, to_signed(1, w));
                when 5      => retval := (min_word, to_signed(-1, w));
                when 6      => retval := (max_word, min_word);
                when 7      => retval := (min_word, min_word);
                when 8      => retval := (max_word, max_word);
                when 9      => retval := (to_signed(1000, w), to_signed(3, w));
                when 10     => retval := (to_signed(-1000, w), to_signed(7, w));
                when 11     => retval := (to_signed(12345, w), to_signed(0, w));
                when 12     => retval := (to_signed(0, w), to_signed(5, w));
                when 13     => retval := (to_signed(5, w), max_word);
                when 14     => retval := (to_signed(2**15, w), to_signed(2**10, w));
                when others => retval := (to_signed(-77777, w), to_signed(-3, w));
            end case;
            return retval;
        end function;

        impure function random_word return word is
            variable retval : word;
        begin
            for i in retval'range loop
                uniform(seed1, seed2, rnd);
                if rnd > 0.5 then retval(i) := '1'; else retval(i) := '0'; end if;
            end loop;
            return retval;
        end function;

    begin
        if rising_edge(simulator_clock) then
            init_lut_divider(lut_divider_in);

            issue := true;
            if use_gaps then
                uniform(seed1, seed2, rnd);
                issue := rnd > 0.4;
            end if;

            if issue and request_count < total_pairs then
                if request_count < directed_count then
                    pair := directed_pair(request_count);
                else
                    pair.numerator := random_word;
                    uniform(seed1, seed2, rnd);
                    pair.denominator := shift_right(random_word, integer(floor(rnd * real(w))));
                end if;
                request_lut_division(lut_divider_in, pair.numerator, pair.denominator);
                requested(request_count) <= pair;
                request_count <= request_count + 1;
            end if;
        end if;
    end process stimulus;

    check_results : process(simulator_clock)
        -- to_integer overflows for words over 32 bits
        function to_real (x : signed) return real is
            variable retval : real := 0.0;
        begin
            for i in x'range loop
                if x(i) = '1' then
                    if i = x'left then
                        retval := retval - 2.0**(i - x'right);
                    else
                        retval := retval + 2.0**(i - x'right);
                    end if;
                end if;
            end loop;
            return retval;
        end to_real;

        variable pair     : pair_record;
        variable expected : word;
        variable exact    : real;
        variable error    : real;
    begin
        if rising_edge(simulator_clock) then
            if lut_divider_out.ready_with_1 = '1' then
                pair     := requested(result_count);
                expected := lut_divide(pair.numerator, pair.denominator, quotient_radix
                    , point_lut, slope_lut, table_radix, x_frac_width);

                check(lut_divider_out.quotient = expected,
                    "quotient " & integer'image(result_count) & " differs from lut_divide : "
                    & to_hstring(lut_divider_out.quotient) & " expected " & to_hstring(expected));

                if pair.denominator = 0 then
                    check(lut_divider_out.division_by_zero = '1', "division by zero not flagged");
                else
                    check(lut_divider_out.division_by_zero = '0', "division by zero flagged");
                    exact := to_real(pair.numerator) / to_real(pair.denominator) * 2.0**quotient_radix;
                    -- only quotients that fit in the word, larger ones wrap
                    if abs(exact) < 2.0**(w-1) - 2.0 then
                        error := abs(to_real(lut_divider_out.quotient) - exact);
                        check(error <= abs(exact) * 2.0**(-(table_radix - 2)) + 2.0,
                            "quotient " & integer'image(result_count) & " error " & real'image(error)
                            & " for " & real'image(exact));
                        if abs(exact) > 2.0**10 and error / abs(exact) > max_relative_error then
                            max_relative_error <= error / abs(exact);
                        end if;
                    end if;
                end if;

                result_count <= result_count + 1;
                if result_count = total_pairs-1 then
                    all_tests_done <= true;
                end if;
            end if;
        end if;
    end process check_results;

    u_lut_divider : entity work.lut_divider
    generic map(
        g_quotient_radix    => quotient_radix
        ,g_index_width       => index_width
        ,g_table_word_length => table_word_length
        ,g_table_radix       => table_radix
        ,g_x_frac_width      => x_frac_width
        ,g_pre_add_register => use_pre_add_register
        ,g_product_register => use_product_register
        ,g_shifter_stages   => shifter_stages
        ,g_ram_output_register => use_ram_output_register
        ,g_dsp_request_register => use_dsp_request_register
    )
    port map(
        clock            => simulator_clock
        ,lut_divider_in  => lut_divider_in
        ,lut_divider_out => lut_divider_out
    );

end sim;
