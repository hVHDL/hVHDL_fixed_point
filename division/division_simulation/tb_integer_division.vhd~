LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.division_pkg.all;

entity tb_integer_division is
end;

architecture sim of tb_integer_division is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 10e3;
------------------------------------------------------------------------
    signal simulation_counter : natural := 1;

    signal hw_multiplier : multiplier_record := multiplier_init_values;
    signal hw_multiplier1 : multiplier_record := multiplier_init_values;
    signal division_process_counter : natural range 0 to 15 := 15;

    signal divisor_lut_index : natural := 15;
    signal number_to_be_reciprocated : natural := 32767 + divisor_lut_index*1024;

    signal divider : division_record := init_division;

------------------------------------------------------------------------ 
    signal test_divident : natural := 128;

    signal division_result : int18 := 0;
    signal x : int18 := 0;
------------------------------------------------------------------------
begin

------------------------------------------------------------------------
    simtime : process
    begin
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        report "*******************";
        report "division successful! last tested number " & integer'image(test_divident) & "at clock cycle " & integer'image(simtime_in_clocks);
        report "*******************";
        simulation_running <= false;
        wait;
    end process simtime;	

------------------------------------------------------------------------
    sim_clock_gen : process
    begin
        simulator_clock <= '0';
        rstn <= '0';
        simulator_clock <= '0';
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                rstn <= '1';
                simulator_clock <= not simulator_clock;
            end loop;
            report "division simulation finished";
        wait;
    end process;
------------------------------------------------------------------------

    clocked_reset_generator : process(simulator_clock, rstn)
    --------------------------------------------------
        variable div_result : int18;
    --------------------------------------------------
    begin
        if rising_edge(simulator_clock) then

            create_multiplier(hw_multiplier);
            create_division(hw_multiplier, divider);

            simulation_counter <= simulation_counter + 1;
            -- if simulation_counter mod 20  = 0 then
            if simulation_counter mod 25 = 0 then
                test_divident <= test_divident + 39;
                if test_divident < 32768 then 
                    request_division(divider , 500, 500, 2);
                end if;
            end if; 

            if division_is_ready(hw_multiplier, divider) then 

                division_result <= get_division_result(hw_multiplier , divider , 16);
                -- assert abs(division_result-65535) < 67 report "division result : " & integer'image(abs(division_result-65535)) & " input " & integer'image(test_divident-1) severity error;

            end if;

        end if; -- rstn
    end process clocked_reset_generator;	
    x <= divider.x;

------------------------------------------------------------------------
end sim;
