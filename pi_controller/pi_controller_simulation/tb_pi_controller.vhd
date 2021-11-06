LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

library math_library;
    use math_library.multiplier_pkg.all;
    use math_library.state_variable_pkg.all;
    use math_library.pi_controller_pkg.all;

entity tb_pi_controller is
end;

architecture sim of tb_pi_controller is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 15000;
------------------------------------------------------------------------
    signal simulation_counter : natural := 0;

    signal hw_multiplier : multiplier_record;
    signal state_variable_multiplier : multiplier_record;

    constant kp : natural := 1e5;
    constant ki : natural := 1e4;
    constant pi_controller_radix : natural := 12;
    constant pi_controller_limit : natural := 10e3;

    signal dc_link_voltege : state_variable_record := init_state_variable_gain(200);
    signal voltage : int18 := 0;

    signal state_counter : natural := 0;

    signal pi_control : pi_controller_record := pi_controller_init;

begin

------------------------------------------------------------------------
    simtime : process
    begin
        simulation_running <= true;
        wait for simtime_in_clocks*clock_per;
        simulation_running <= false;
        report "pi control simulation ready";
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
        variable pi_error : int18 := 0;
        variable voltage_reference : int18 := 1000;
        variable load_current : int18 := -29e3;
    begin
        if rising_edge(simulator_clock) then

            simulation_counter <= simulation_counter + 1;
            create_multiplier(hw_multiplier);
            create_multiplier(state_variable_multiplier);
            create_pi_controller(hw_multiplier, pi_control, kp, ki);

            if state_counter = 0 then
                integrate_state(dc_link_voltege, state_variable_multiplier, 15, pi_control.pi_out - load_current);
                increment_counter_when_ready(state_variable_multiplier, state_counter);
            end if;

            if (simulation_counter + 1250) mod 2500 = 0 then
                load_current := -load_current;
            end if;

            if simulation_counter mod 10 = 0 then
                state_counter <= 0;
                calculate_pi_control(pi_control, voltage_reference - dc_link_voltege.state);
            end if; 

        end if; -- rstn
    end process clocked_reset_generator;	
------------------------------------------------------------------------
            voltage <=dc_link_voltege.state;

end sim;
