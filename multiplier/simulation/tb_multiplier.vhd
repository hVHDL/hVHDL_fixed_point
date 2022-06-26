LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    context vunit_lib.vunit_context;

    use work.multiplier_pkg.all;

entity tb_multiplier is
  generic (runner_cfg : string);
end;

architecture sim of tb_multiplier is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 50;

    signal simulation_counter : natural := 0;
    signal multiplier_output : signed(35 downto 0);
    signal multiplier_is_ready_when_1 : std_logic;
    signal int18_multiplier_output : integer := 0;
    signal multiplier_result : integer := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;

    type int_array is array (integer range <>) of integer;
    signal input_a_array : int_array(0 to 7) :=(-5  , 16899 , -6589 , 32768 , -32768 , 58295 , -65536, 55555);
    signal output_counter : natural := 0;
    signal result : integer := 0;

    signal output_needs_to_be_checked : boolean := false;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        test_runner_setup(runner, runner_cfg);
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        test_runner_cleanup(runner); -- Simulation ends here
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

    begin
        if rstn = '0' then
        -- reset state
            clocked_reset <= '0';
    
        elsif rising_edge(simulator_clock) then
            clocked_reset <= '1';

            create_multiplier(hw_multiplier);

            simulation_counter <= simulation_counter + 1;
            CASE simulation_counter is
                WHEN 0 => multiply(hw_multiplier , input_a_array(0) , 65536);
                WHEN 1 => multiply(hw_multiplier , input_a_array(1) , 65536);
                WHEN 2 => multiply(hw_multiplier , input_a_array(2) , 65536);
                WHEN 3 => multiply(hw_multiplier , input_a_array(3) , 65536);
                WHEN 4 => multiply(hw_multiplier , input_a_array(4) , 65536);
                WHEN 5 => multiply(hw_multiplier , input_a_array(5) , 65536);
                WHEN 6 => multiply(hw_multiplier , input_a_array(6) , 65536);
                WHEN 7 =>
                    simulation_counter <= 7;
                    sequential_multiply(hw_multiplier, input_a_array(7), 65536);
                    if multiplier_is_not_busy(hw_multiplier) then
                        simulation_counter <= 10;
                    end if;

                WHEN others => -- do nothing
            end CASE;
            multiplier_result <= get_multiplier_result(hw_multiplier, 16);
            output_needs_to_be_checked <= false;
            if multiplier_is_ready(hw_multiplier) then
                output_counter <= output_counter + 1;
                int18_multiplier_output <= get_multiplier_result(hw_multiplier,16);
                result <= input_a_array(output_counter) - get_multiplier_result(hw_multiplier,16);
                output_needs_to_be_checked <= true;
            end if; 

            if output_needs_to_be_checked then
                assert abs(result) <= 5 report "got " & integer'image(result);
            end if;

        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------
end sim;
