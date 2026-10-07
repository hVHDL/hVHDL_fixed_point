architecture rtl of fixed_dsp is

    -- the pre-adder output and the request as the multiplier stage sees
    -- them, registered when g_pre_add_register is set
    signal pre_add  : fixed_dsp_in.a'subtype;
    signal pre      : fixed_dsp_in.a'subtype;
    signal stage_in : fixed_dsp_in'subtype;

    signal mult : signed(fixed_dsp_in.a'length + fixed_dsp_in.b'length-1 downto 0);

    -- c arrives already at the multiplier's output width and radix ; just
    -- register it alongside mult, with no shift/resize of its own
    signal c_buf : fixed_dsp_in.c'subtype;

    signal P : fixed_dsp_out.result'subtype := (others => '0');

    signal buf_accumulate    : std_logic;-- 0=p <= p + (a*b)
    signal buf_pre_subtract  : std_logic;-- 0=a+d
    signal buf_post_subtract : std_logic;-- 0=mpy_out+d, 1 => mpy_out-d
    signal buf_invert_result : std_logic;-- 1 => negate multiplier result

    signal buf_reset_accumulator_with_1 : std_logic;

    -- the product and the request as the result adder sees them,
    -- registered once more when g_product_register is set
    signal product                 : signed(fixed_dsp_in.a'length + fixed_dsp_in.b'length-1 downto 0);
    signal product_c               : fixed_dsp_in.c'subtype;
    signal product_accumulate      : std_logic;
    signal product_post_subtract   : std_logic;
    signal product_invert_result   : std_logic;
    signal product_reset_accumulator : std_logic;

    signal ready_pipeline : std_logic_vector(1 + boolean'pos(g_product_register) downto 0) := (others => '0');

begin

    -- output
    fixed_dsp_out.result <= P;
    fixed_dsp_out.ready_with_1 <= ready_pipeline(ready_pipeline'high);

    -- Pre-adder
    pre_add <= fixed_dsp_in.a + fixed_dsp_in.d when fixed_dsp_in.pre_subtract_with_1 = '0'
     else      fixed_dsp_in.a - fixed_dsp_in.d;

    no_pre_add_register : if not g_pre_add_register generate
        pre      <= pre_add;
        stage_in <= fixed_dsp_in;
    end generate;

    pre_add_register : if g_pre_add_register generate
        process(clock)
        begin
            if rising_edge(clock) then
                pre      <= pre_add;
                stage_in <= fixed_dsp_in;
            end if;
        end process;
    end generate;

    process(clock)
    begin
        if rising_edge(clock) then

            ready_pipeline <= ready_pipeline(ready_pipeline'high-1 downto 0) & stage_in.request_with_1;

            --p1
            -- Resize to accumulator width
            mult  <= pre * stage_in.b;
            c_buf <= stage_in.c;

            buf_accumulate    <= stage_in.accumulate_with_1   ;
            buf_pre_subtract  <= stage_in.pre_subtract_with_1 ;
            buf_post_subtract <= stage_in.post_subtract_with_1;
            buf_invert_result <= stage_in.invert_result_with_1;
            buf_reset_accumulator_with_1 <= stage_in.reset_accumulator_with_1;

            --p2
            if product_invert_result = '1' then
                if product_post_subtract = '0' then
                    P <= -(product + product_c);
                else
                    P <= -(product - product_c);
                end if;
            else
                if product_post_subtract = '0' then
                    P <= product + product_c;
                else
                    P <= product - product_c;
                end if;
            end if;
            --

            if product_accumulate = '1' then
                if product_post_subtract = '1' then
                    P <= P - product;
                else
                    P <= P + product;
                end if;
            end if;

            if product_reset_accumulator = '1' then
                P <= (others => '0');
            end if;

        end if;
    end process;

    no_product_register : if not g_product_register generate
        product                   <= mult;
        product_c                 <= c_buf;
        product_accumulate        <= buf_accumulate;
        product_post_subtract     <= buf_post_subtract;
        product_invert_result     <= buf_invert_result;
        product_reset_accumulator <= buf_reset_accumulator_with_1;
    end generate;

    product_register : if g_product_register generate
        process(clock)
        begin
            if rising_edge(clock) then
                product                   <= mult;
                product_c                 <= c_buf;
                product_accumulate        <= buf_accumulate;
                product_post_subtract     <= buf_post_subtract;
                product_invert_result     <= buf_invert_result;
                product_reset_accumulator <= buf_reset_accumulator_with_1;
            end if;
        end process;
    end generate;

end rtl;

----------------------------------

