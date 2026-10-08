LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity adc_scaler_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of adc_scaler_tb is

    constant clock_period      : time    := 1 ns;
    constant simtime_in_clocks : integer := 5000;
    signal simulator_clock : std_logic := '0';
    signal simulation_counter : natural := 0;

    signal test_out : real := 0.0;
    signal test_vector : real_vector(0 to 3) := (0.0, 0.0, 0.0, 0.0);

    use work.dual_port_ram_pkg.ram_array;
    use work.real_to_fixed_pkg.all;
    use work.adc_scaler_pkg.all;

    constant word_length : natural := 40;
    constant used_radix : natural := 28;

    function to_fixed is new generic_to_fixed generic map(word_length => word_length, used_radix => used_radix);

    constant init_values : ram_array(0 to 1023)(word_length-1 downto 0) := 
    (
     0 => to_fixed(1.0/100.0)
    ,1 => to_fixed(-0.5)

    ,2 => to_fixed(1.0/200.0)
    ,3 => to_fixed(-0.5)

    ,4 => to_fixed(1.0/300.0)
    ,5 => to_fixed(-1.5)

    ,6 => to_fixed(1.0/400.0)
    ,7 => to_fixed(-1.5)

    ,others => (others => '0'));

    signal self_in  : adc_scaler_in_record(data_in(word_length-1 downto 0));
    signal self_out : adc_scaler_out_record(data_out(word_length-1 downto 0));

begin

    u_adc_scaler : entity work.adc_scaler
    generic map(init_values, used_radix)
    port map(
        clock => simulator_clock
        ,self_in
        ,self_out
    );
------------------------------------------------------------------------

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        wait for simtime_in_clocks*clock_period;
        check_equal(test_vector(0), 0.5, max_diff => 1.0e-6);
        check_equal(test_vector(1), 0.5, max_diff => 1.0e-6);
        check_equal(test_vector(2), -0.5, max_diff => 1.0e-6);
        check_equal(test_vector(3), -0.5, max_diff => 1.0e-6);
        test_runner_cleanup(runner); -- Simulation ends here
        wait;
    end process simtime;	

    simulator_clock <= not simulator_clock after clock_period/2.0;
------------------------------------------------------------------------
    stimulus : process(simulator_clock)
    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            init_adc_scaler(self_in);

            CASE simulation_counter is
                WHEN 1 => request_scaling(self_in, signed(to_fixed(100.0)), 0);
                WHEN 2 => request_scaling(self_in, signed(to_fixed(200.0)), 1);
                WHEN 3 => request_scaling(self_in, signed(to_fixed(300.0)), 2);
                WHEN 4 => request_scaling(self_in, signed(to_fixed(400.0)), 3);
                WHEN others => --do nothing
            end CASE;

            if scaler_is_ready(self_out)
            then
                test_out <= to_real(get_converted_meas(self_out), used_radix);
                test_vector(get_converted_address(self_out)) <= to_real(get_converted_meas(self_out),used_radix);
            end if;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
