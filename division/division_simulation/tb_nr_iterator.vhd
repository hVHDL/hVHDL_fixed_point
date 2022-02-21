LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

    use work.multiplier_pkg.all;
    use work.division_pkg.all;
    use work.division_internal_pkg.all;

entity tb_nr_iterator is
end;

architecture sim of tb_nr_iterator is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 200;

    signal division_process_counter           : natural := 3;
    signal x                                  : int18 := 0;
    signal number_to_be_reciprocated          : int18 := 0;
    signal number_of_newton_raphson_iteration : int18 := 0;
    signal dividend                           : int18 := 0;
    signal divisor                            : int18 := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;

    signal simulation_counter : natural := 0;

    signal check_division_to_be_ready : boolean := false;
    signal test_division : natural := 250;

    signal division_multiplier : multiplier_record := multiplier_init_values;
    signal divider             : division_record := init_division;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
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
        wait;
    end process;
------------------------------------------------------------------------

    clocked_reset_generator : process(simulator_clock, rstn)
    --------------------------------------------------
        variable xa : int18;
    --------------------------------------------------
    begin 
        if rising_edge(simulator_clock) then
        --------------------------------------------------
            create_multiplier(division_multiplier);
            create_division(division_multiplier, divider);

            create_multiplier(hw_multiplier);
        --------------------------------------------------
            CASE division_process_counter is
                WHEN 0 =>
                    check_division_to_be_ready <= false;
                    multiply(hw_multiplier, x, number_to_be_reciprocated);
                    division_process_counter <= division_process_counter + 1;
                WHEN 1 =>
                    check_division_to_be_ready <= false;
                    increment_counter_when_ready(hw_multiplier,division_process_counter);
                    if multiplier_is_ready(hw_multiplier) then
                        multiply(hw_multiplier, x, invert_bits(get_multiplier_result(hw_multiplier, 16)));
                    end if;
                WHEN 2 =>
                    check_division_to_be_ready <= false;
                    if multiplier_is_ready(hw_multiplier) then
                        x <= get_multiplier_result(hw_multiplier, 16);
                        if number_of_newton_raphson_iteration /= 0 then
                            number_of_newton_raphson_iteration <= number_of_newton_raphson_iteration - 1;
                            division_process_counter <= 0;
                        else
                            division_process_counter <= division_process_counter + 1;
                            multiply(hw_multiplier, dividend, get_multiplier_result(hw_multiplier, 16));
                            check_division_to_be_ready <= true;
                        end if;
                    end if;
                WHEN others => -- wait for start
                    if multiplier_is_ready(hw_multiplier) then
                        check_division_to_be_ready <= false;
                    end if;
            end CASE;

            simulation_counter <= simulation_counter + 1;
            if simulation_counter = 10 then
                x                                  <= get_initial_value_for_division(remove_leading_zeros(test_division));
                number_to_be_reciprocated          <= (remove_leading_zeros(test_division));
                dividend                           <= test_division/128;
                divisor                            <= test_division;
                division_process_counter           <= 0;
                number_of_newton_raphson_iteration <= 1;
                request_division(divider, test_division/128, test_division, 1);
                -- test_division <= test_division + 1;
            end if;


            -- if multiplier_is_ready(hw_multiplier) and check_division_to_be_ready then
            --     report "result from state machine " & integer'image(get_division_result(hw_multiplier,test_division,17));
            -- end if; 
            if division_is_ready(division_multiplier, divider) then 
                report "result from divider " & integer'image(get_division_result(division_multiplier,test_division,17))& " " & integer'image(test_division);
                test_division <= test_division + 1;
                request_division(divider, test_division/128, test_division, 1);
            end if;
    
        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------

end sim;
