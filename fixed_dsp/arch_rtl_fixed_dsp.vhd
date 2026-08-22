architecture rtl of fixed_dsp is

    signal pre  : fixed_dsp_in.a'subtype;
    signal mult : signed(fixed_dsp_in.a'length + fixed_dsp_in.b'length-1 downto 0);

    signal c_buf : mult'subtype;

    signal P : result'subtype := (others => '0');

    signal buf_accumulate    : std_logic;-- 0=p <= p + (a*b)
    signal buf_pre_subtract  : std_logic;-- 0=a+d
    signal buf_post_subtract : std_logic;-- 0=mpy_out+d, 1 => mpy_out-d
    signal buf_invert_result : std_logic;-- 1 => negate multiplier result

    signal buf_reset_accumulator_with_1 : std_logic;

    signal ready_pipeline : std_logic_vector(1 downto 0) := (others => '0');

begin

    -- output
    result <= P;
    ready_with_1 <= ready_pipeline(ready_pipeline'high);

    -- Pre-adder
    pre <= fixed_dsp_in.a + fixed_dsp_in.d when fixed_dsp_in.pre_subtract_with_1 = '0'
     else  fixed_dsp_in.a - fixed_dsp_in.d;

    process(clock)
    begin
        if rising_edge(clock) then

            ready_pipeline <= ready_pipeline(ready_pipeline'high-1 downto 0) & fixed_dsp_in.request_with_1;

            --p1
            -- Resize to accumulator width
            mult  <= pre * fixed_dsp_in.b;
            c_buf <= shift_left(resize(fixed_dsp_in.c, c_buf'length), g_radix);

            buf_accumulate    <= fixed_dsp_in.accumulate_with_1   ;
            buf_pre_subtract  <= fixed_dsp_in.pre_subtract_with_1 ;
            buf_post_subtract <= fixed_dsp_in.post_subtract_with_1;
            buf_invert_result <= fixed_dsp_in.invert_result_with_1;
            buf_reset_accumulator_with_1 <= fixed_dsp_in.reset_accumulator_with_1;

            --p2
            if buf_invert_result = '1' then
                if buf_post_subtract = '0' then
                    P <= -(mult + c_buf);
                else
                    P <= -(mult - c_buf);
                end if;
            else
                if buf_post_subtract = '0' then
                    P <= mult + c_buf;
                else
                    P <= mult - c_buf;
                end if;
            end if;
            --

            if buf_accumulate = '1' then
                if buf_post_subtract = '1' then
                    P <= P - mult;
                else
                    P <= P + mult;
                end if;
            end if;

            if buf_reset_accumulator_with_1 = '1' then
                P <= (others => '0');
            end if;

        end if;
    end process;

end rtl;

----------------------------------

