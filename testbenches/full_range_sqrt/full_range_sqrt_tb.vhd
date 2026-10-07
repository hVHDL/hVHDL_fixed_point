LIBRARY ieee  ;
    USE ieee.NUMERIC_STD.all  ;
    USE ieee.std_logic_1164.all  ;
    use ieee.math_real.all;

    use work.full_range_sqrt_pkg.all;
    use work.lut_sqrt_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

-- full_range_sqrt is fully pipelined : this requests directed edge cases and
-- then random radicands, every clock or (use_gaps) in irregular bursts, and
-- checks every root once it comes back against get_full_range_sqrt bit for
-- bit, and against a real square root within the lookup table's accuracy.
-- the radicands are shifted right by a random amount so every
-- normalisation shift, and both exponent parities, get used.
entity full_range_sqrt_tb is
  generic (
      runner_cfg : string
      ;word_length          : natural := 32
      ;radix                : natural := 16
      ;use_pre_add_register : boolean := false
      ;use_product_register : boolean := false
      ;use_gaps             : boolean := false
      ;shifter_stages       : positive := 2
      ;use_ram_output_register : boolean := true
      ;use_dsp_request_register : boolean := true
      -- the sqrt table, defaults are lut_sqrt_pkg's own
      ;index_width          : natural := 8
      ;table_word_length    : natural := 16
      ;table_radix          : natural := 15
      ;x_frac_width         : natural := 16
  );
end;

architecture sim of full_range_sqrt_tb is

    signal simulator_clock : std_logic := '0';
    constant clock_period : time := 1 ns;

    constant w : natural := word_length;

    constant point_lut : sqrt_lut_array := make_sqrt_point_lut(index_width, table_word_length, table_radix);
    constant slope_lut : sqrt_lut_array := make_sqrt_slope_lut(index_width, table_word_length, table_radix);
    subtype word is unsigned(w-1 downto 0);
    type word_array is array (natural range <>) of word;

    signal full_range_sqrt_in  : full_range_sqrt_in_record(radicand(w-1 downto 0));
    signal full_range_sqrt_out : full_range_sqrt_out_record(root(w-1 downto 0));

    constant directed_count : natural := 12;
    constant random_count   : natural := 5000;
    constant total_count    : natural := directed_count + random_count;

    -- every request, in order, so each result can be matched to its radicand
    signal requested      : word_array(0 to total_count-1);
    signal request_count  : natural := 0;
    signal result_count   : natural := 0;
    signal all_tests_done : boolean := false;
    signal max_relative_error : real := 0.0;

    -- to_integer overflows for words with the top bit set
    function to_real (u : unsigned) return real is
        variable retval : real := 0.0;
    begin
        for i in u'range loop
            if u(i) = '1' then
                retval := retval + 2.0**(i - u'right);
            end if;
        end loop;
        return retval;
    end function;

begin

    simulator_clock <= not simulator_clock after clock_period/2.0;

    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait until all_tests_done for 3*total_count*clock_period + 1 us;
        check(all_tests_done, "full_range_sqrt did not return every root");
        info("max relative error " & real'image(max_relative_error));
        test_runner_cleanup(runner);
        wait;
    end process simtime;

    stimulus : process(simulator_clock)
        variable seed1    : positive := 5;
        variable seed2    : positive := 13;
        variable rnd      : real;
        variable radicand : word;
        variable issue    : boolean;

        impure function random_word return word is
            variable retval : word;
        begin
            for i in retval'range loop
                uniform(seed1, seed2, rnd);
                if rnd > 0.5 then retval(i) := '1'; else retval(i) := '0'; end if;
            end loop;
            return retval;
        end function;

        -- edge cases first : zero, small values, exact powers of four and two,
        -- one at the radix and the largest word
        function directed_radicand (index : natural) return word is
            variable retval : word;
        begin
            case index is
                when 0      => retval := to_unsigned(0, w);
                when 1      => retval := to_unsigned(1, w);
                when 2      => retval := to_unsigned(2, w);
                when 3      => retval := to_unsigned(3, w);
                when 4      => retval := to_unsigned(4, w);
                when 5      => retval := shift_left(to_unsigned(1, w), radix mod w);       -- 1.0
                when 6      => retval := shift_left(to_unsigned(1, w), (radix + 1) mod w); -- 2.0
                when 7      => retval := shift_left(to_unsigned(1, w), (radix + 2) mod w); -- 4.0
                when 8      => retval := shift_left(to_unsigned(1, w), w-1);
                when 9      => retval := (others => '1');
                when 10     => retval := shift_left(to_unsigned(1, w), (radix + w - 2) mod w);
                when others => retval := to_unsigned(12345, w);
            end case;
            return retval;
        end function;

    begin
        if rising_edge(simulator_clock) then
            init_full_range_sqrt(full_range_sqrt_in);

            issue := true;
            if use_gaps then
                uniform(seed1, seed2, rnd);
                issue := rnd > 0.4;
            end if;

            if issue and request_count < total_count then
                if request_count < directed_count then
                    radicand := directed_radicand(request_count);
                else
                    radicand := random_word;
                    uniform(seed1, seed2, rnd);
                    radicand := shift_right(radicand, integer(floor(rnd * real(w))));
                end if;
                request_full_range_sqrt(full_range_sqrt_in, radicand);
                requested(request_count) <= radicand;
                request_count <= request_count + 1;
            end if;
        end if;
    end process stimulus;

    check_results : process(simulator_clock)
        variable radicand : word;
        variable expected : word;
        variable exact    : real;
        variable error    : real;
    begin
        if rising_edge(simulator_clock) then
            if full_range_sqrt_out.ready_with_1 = '1' then
                radicand := requested(result_count);
                expected := get_full_range_sqrt(radicand, radix, point_lut, slope_lut, table_radix, x_frac_width);

                check(full_range_sqrt_out.root = expected,
                    "root " & integer'image(result_count) & " differs from get_full_range_sqrt : "
                    & to_hstring(full_range_sqrt_out.root) & " expected " & to_hstring(expected));

                exact := sqrt(to_real(radicand) * 2.0**(-radix)) * 2.0**radix;
                -- only roots that fit in the word, larger ones wrap
                if exact < 2.0**w - 2.0 then
                    error := abs(to_real(full_range_sqrt_out.root) - exact);
                    check(error <= exact * 2.0**(-(table_radix - 3)) + 2.0,
                        "root " & integer'image(result_count) & " error " & real'image(error)
                        & " for " & real'image(exact));
                    if exact > 2.0**10 and error / exact > max_relative_error then
                        max_relative_error <= error / exact;
                    end if;
                end if;

                result_count <= result_count + 1;
                if result_count = total_count-1 then
                    all_tests_done <= true;
                end if;
            end if;
        end if;
    end process check_results;

    u_full_range_sqrt : entity work.full_range_sqrt
    generic map(
        g_radix             => radix
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
        clock                => simulator_clock
        ,full_range_sqrt_in  => full_range_sqrt_in
        ,full_range_sqrt_out => full_range_sqrt_out
    );

end sim;
