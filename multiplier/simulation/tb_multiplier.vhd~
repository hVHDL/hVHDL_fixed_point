LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

library math_library;
    use math_library.multiplier_pkg.all;

entity tb_multiplier is
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
    signal int18_multiplier_output : int18 := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;

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

    begin
        if rstn = '0' then
        -- reset state
            clocked_reset <= '0';
    
        elsif rising_edge(simulator_clock) then
            clocked_reset <= '1';

            create_multiplier(hw_multiplier);

            simulation_counter <= simulation_counter + 1;
            CASE simulation_counter is
                WHEN 1 => multiply(hw_multiplier, -3, 1);
                WHEN 2 => multiply(hw_multiplier, -5, 1);
                WHEN 3 => multiply(hw_multiplier, -25, 1);
                WHEN 4 => multiply(hw_multiplier, 100, 1);
                WHEN 5 => multiply(hw_multiplier, 1000, 1);
                WHEN 6 => multiply(hw_multiplier, 985, 1);
                WHEN 7 => multiply(hw_multiplier, 10090, 1);
                WHEN 8 => multiply(hw_multiplier, 33586, 1);
                WHEN 9 =>
                    simulation_counter <= 9;
                    sequential_multiply(hw_multiplier, -1, -1);
                    if multiplier_is_not_busy(hw_multiplier) then
                        simulation_counter <= 10;
                    end if;

                WHEN others => -- do nothing
            end CASE;
            if multiplier_is_ready(hw_multiplier) then
                int18_multiplier_output <= get_multiplier_result(hw_multiplier,1);
                report "multiplication result at simulation_counter value " & integer'image(simulation_counter)  &" : " & integer'image((get_multiplier_result(hw_multiplier,0)));
            end if; 

        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------
end sim;
