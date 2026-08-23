architecture ecp5 of fixed_dsp is

    signal buf_accumulate               : std_logic_vector(2 downto 0); -- 0=p <= p + (a*b)
    signal buf_pre_subtract             : std_logic_vector(2 downto 0); -- 0=a+d
    signal buf_post_subtract            : std_logic_vector(2 downto 0); -- 0=mpy_out+d, 1 => mpy_out-d
    signal buf_invert_result            : std_logic_vector(2 downto 0); -- 1 => negate multiplier result
    signal buf_reset_accumulator_with_1 : std_logic_vector(2 downto 0);

    -- c has to ride along the same 3-cycle latency as the mpy_32x32 IP
    -- (input register + pipelined multiplier + output register), same as
    -- the buf_* control bits above, or it would be added to a mpy_out
    -- that is 3 cycles stale
    type signed_array is array (natural range <>) of signed;
    signal buf_c : signed_array(2 downto 0)(fixed_dsp_in.c'range);

    signal pre     : fixed_dsp_in.a'subtype;
    signal mpy_out : std_logic_vector(fixed_dsp_in.a'length*2-1 downto 0) := (others => '0');
    signal res_buf : signed(fixed_dsp_in.a'length*2-1 downto 0);
    signal res     : signed(fixed_dsp_in.a'length*2-1 downto 0);

    signal arg : std_logic_vector(0 to 1);

    signal ready_pipeline : std_logic_vector(4 downto 0) := (others => '0');

begin

    pre <= fixed_dsp_in.a + fixed_dsp_in.d when fixed_dsp_in.pre_subtract_with_1 = '0'
     else  fixed_dsp_in.a - fixed_dsp_in.d;

    u_mpy : entity work.mpy_32x32
    port map(
        Clock   => clock
        ,ClkEn  => '1'
        ,Aclr   => '0'
        ,DataA  => std_logic_vector(pre)
        ,DataB  => std_logic_vector(fixed_dsp_in.b)
        ,Result => mpy_out
    );

    arg <= (0 => buf_accumulate(2) , 1 => buf_post_subtract(2));
    fixed_dsp_out.ready_with_1 <= ready_pipeline(ready_pipeline'high);

    process(clock)
    begin
        if rising_edge(clock) then

            ready_pipeline <= ready_pipeline(ready_pipeline'high-1 downto 0) & fixed_dsp_in.request_with_1;

            buf_accumulate              <= buf_accumulate(buf_accumulate'high-1 downto 0) & fixed_dsp_in.accumulate_with_1;
            buf_pre_subtract            <= buf_pre_subtract(buf_pre_subtract'high-1 downto 0) & fixed_dsp_in.pre_subtract_with_1;
            buf_post_subtract           <= buf_post_subtract(buf_post_subtract'high-1 downto 0) & fixed_dsp_in.post_subtract_with_1;
            buf_invert_result           <= buf_invert_result(buf_invert_result'high-1 downto 0) & fixed_dsp_in.invert_result_with_1;
            buf_reset_accumulator_with_1<= buf_reset_accumulator_with_1(buf_reset_accumulator_with_1'high-1 downto 0) & fixed_dsp_in.reset_accumulator_with_1;

            buf_c <= buf_c(1 downto 0) & fixed_dsp_in.c;

            CASE arg is
                WHEN "00" =>
                    if buf_invert_result(2) = '1' then
                        res_buf <= -(signed(mpy_out) + shift_left(resize(buf_c(2), res'length),g_radix));
                    else
                        res_buf <=  signed(mpy_out) + shift_left(resize(buf_c(2), res'length),g_radix);
                    end if;
                WHEN "01" =>
                    if buf_invert_result(2) = '1' then
                        res_buf <= -(signed(mpy_out) - shift_left(resize(buf_c(2), res'length),g_radix));
                    else
                        res_buf <=  signed(mpy_out) - shift_left(resize(buf_c(2), res'length),g_radix);
                    end if;
                WHEN "10" =>
                    res_buf <= res_buf + signed(mpy_out);
                WHEN others => --"11"
                    res_buf <= res_buf - signed(mpy_out);
            end CASE;

            if buf_reset_accumulator_with_1(2) = '1' then
                res_buf <= (others => '0');
            end if;
            res <= res_buf;

        end if;
    end process;

    fixed_dsp_out.result <= res;

end ecp5;
