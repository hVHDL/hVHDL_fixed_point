LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

    use work.sos_filter_pkg.all;
    use work.fixed_point_dsp_pkg.all;
    use work.dsp_sos_filter_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity ram_sos_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of ram_sos_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    
    signal simulator_clock     : std_logic := '0';
    signal simulation_counter  : natural   := 0;
    -----------------------------------
    -- simulation specific signals ----
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------

    ------------------------------
    signal state_counter : integer := 0;

    signal memory1 : real_array(0 to 1) := (others => 0.0);
    signal memory2 : real_array(0 to 1) := (others => 0.0);
    signal memory3 : real_array(0 to 1) := (others => 0.0);

    signal fix_memory1 : fix_array(0 to 1) := (others => 0);
    signal fix_memory2 : fix_array(0 to 1) := (others => 0);
    signal fix_memory3 : fix_array(0 to 1) := (others => 0);

    -- these gains were obtained with matlab using 
    -- [b,a] = cheby1(6, 1, 1/30);
    -- [sos, g] = tf2sos(b,a, 'down',2)

    constant b1 : real_array(0 to 2) := (1.10112824474792e-003 , 2.19578135597009e-003  , 1.09466577037144e-003);
    constant b2 : real_array(0 to 2) := (1.16088276025753e-003 , 2.32172985621810e-003  , 1.16086054728631e-003);
    constant b3 : real_array(0 to 2) := (42.4644359704529e-003 , 85.1798866651586e-003  , 42.7159465798333e-003) / 58.875768;
    constant a1 : real_array(0 to 2) := (1.00000000000000e+000 , -1.97840025988718e+000 , 987.883963652581e-003);
    constant a2 : real_array(0 to 2) := (1.00000000000000e+000 , -1.96191974906017e+000 , 967.208461633959e-003);
    constant a3 : real_array(0 to 2) := (1.00000000000000e+000 , -1.95425095615658e+000 , 955.427665692536e-003);

    constant fix_b1 : fix_array(0 to 2) := to_fixed(b1);
    constant fix_b2 : fix_array(0 to 2) := to_fixed(b2);
    constant fix_b3 : fix_array(0 to 2) := to_fixed(b3);

    constant fix_a1 : fix_array(0 to 2) := to_fixed(a1);
    constant fix_a2 : fix_array(0 to 2) := to_fixed(a2);
    constant fix_a3 : fix_array(0 to 2) := to_fixed(a3);

    signal filter_out : real := 0.0;
    signal filter_out1 : real := 0.0;
    signal filter_out2 : real := 0.0;

    signal fix_filter_out  : integer := 0;
    signal fix_filter_out1 : integer := 0;
    signal fix_filter_out2 : integer := 0;

    signal real_filter_output : real := 0.0;
    signal fixed_filter_output : real := 0.0;

    signal filter_error : real := 0.0;
    signal max_calculation_error : real := 0.0;

    signal y : integer := 0;

    signal sos_filter1 : sos_filter_record := init_sos_filter;
    signal sos_filter2 : sos_filter_record := init_sos_filter;
    signal sos_filter3 : sos_filter_record := init_sos_filter;

    signal fixed_point_dsp1 : fixed_point_dsp_record := init_fixed_point_dsp;
    signal fixed_point_dsp2 : fixed_point_dsp_record := init_fixed_point_dsp;
    signal fixed_point_dsp3 : fixed_point_dsp_record := init_fixed_point_dsp;

    signal serial_sos_out : real := 0.0;
------------------------------------------------------------------------
    signal ram : fix_array(0 to 5) := fix_b1 & fix_a1(1) & fix_a1(2) & 0;
    signal ram_data    : integer;
    signal ram_address : integer range 0 to ram'high := 0;

    signal ram_sos_dsp1 : fixed_point_dsp_record := init_fixed_point_dsp;
    signal ram_sos_filter1 : sos_filter_record := init_sos_filter;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check(max_calculation_error < 0.1, "calculation error is " & real'image(max_calculation_error));
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)
    --------------------------
        procedure calculate_real_sos
        (
            signal memory : inout real_array;
            input         : in real;
            signal output : inout real;
            counter       : in integer;
            b_gains       : in real_array;
            a_gains       : in real_array;
            constant counter_offset : in integer
        ) is
        begin
            if counter = 0 + counter_offset then output    <= input * b_gains(0) + memory(0);                       end if;
            if counter = 1 + counter_offset then memory(0) <= input * b_gains(1) - output * a_gains(1) + memory(1); end if;
            if counter = 2 + counter_offset then memory(1) <= input * b_gains(2) - output * a_gains(2);             end if;
        end calculate_real_sos;

    --------------------------
    --------------------------
        constant filter_input : real := 1.0;
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;

            if state_counter < 5 then
                state_counter <= state_counter + 1;
            end if;
             
            calculate_real_sos(memory1 , filter_input , filter_out  , state_counter , b1 , a1 , 0);
            calculate_real_sos(memory2 , filter_out   , filter_out1 , state_counter , b2 , a2 , 1);
            calculate_real_sos(memory3 , filter_out1  , filter_out2 , state_counter , b3 , a3 , 2);

        ------------------------------------------------------------------------
            calculate_sos(fix_memory1 , to_fixed(filter_input) , fix_filter_out  , state_counter , fix_b1 , fix_a1 , 0);
            calculate_sos(fix_memory2 , fix_filter_out         , fix_filter_out1 , state_counter , fix_b2 , fix_a2 , 1);
            calculate_sos(fix_memory3 , fix_filter_out1        , fix_filter_out2 , state_counter , fix_b3 , fix_a3 , 2);


            create_fixed_point_dsp(fixed_point_dsp1);
            create_fixed_point_dsp(fixed_point_dsp2);
            create_fixed_point_dsp(fixed_point_dsp3);
            create_sos_filter(sos_filter1, fixed_point_dsp1, fix_b1, fix_a1);
            create_sos_filter(sos_filter2, fixed_point_dsp2, fix_b2, fix_a2);
            create_sos_filter(sos_filter3, fixed_point_dsp3, fix_b3, fix_a3);

            create_fixed_point_dsp(ram_sos_dsp1);
            create_ram_sos_filter(ram_sos_filter1, ram_sos_dsp1, ram_data, ram_address, false);

            y <= get_sos_filter_output(sos_filter3);

            if sos_filter1.result_counter = 0 and fixed_point_dsp_is_ready(fixed_point_dsp1) then
                request_sos_filter(sos_filter2, get_sos_filter_output(sos_filter1));
            end if;
            if sos_filter2.result_counter = 0 and fixed_point_dsp_is_ready(fixed_point_dsp2) then
                request_sos_filter(sos_filter3, get_sos_filter_output(sos_filter2));
            end if;

            if simulation_counter mod 6 = 0 then
                request_sos_filter(sos_filter1, to_fixed(filter_input));
                request_sos_filter(ram_sos_filter1, to_fixed(filter_input));
                state_counter <= 0;
            end if;

            ram_data <= ram(ram_address);
            ram_address <= (simulation_counter + 7) mod 6;


            -- check values
            serial_sos_out <= real(get_sos_filter_output(sos_filter3))/2.0**fractional_bits;
            real_filter_output  <= filter_out2;
            fixed_filter_output <= real(fix_filter_out2)/2.0**fractional_bits;
            filter_error <= real_filter_output - fixed_filter_output;
            if abs(filter_error) > max_calculation_error then
                max_calculation_error <= abs(filter_error);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
