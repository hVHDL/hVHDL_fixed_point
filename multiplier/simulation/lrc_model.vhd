LIBRARY ieee  ; 
LIBRARY std  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    USE ieee.std_logic_textio.all  ; 
    use ieee.math_real.all;
    USE std.textio.all  ; 

library math_library;
    use math_library.multiplier_pkg.all;

entity lrc_model is
end;

architecture sim of lrc_model is
    signal rstn : std_logic;

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    signal clocked_reset : std_logic;
    constant clock_per : time := 8.4 ns;
    constant clock_half_per : time := 4.2 ns;
    constant simtime_in_clocks : integer := 25e3;

    signal simulation_counter : natural := 0;
    signal multiplier_output : signed(35 downto 0);
    signal multiplier_is_ready_when_1 : std_logic;
    signal int18_multiplier_output : int18 := 0;

    signal hw_multiplier : multiplier_record := multiplier_init_values;
    signal hw_multiplier2 : multiplier_record := multiplier_init_values;
------------------------------------------------------------------------
    signal shift_register : std_logic_vector(2 downto 0);

    signal signal_multiplier_is_ready : boolean := false;

------------------------------------------------------------------------
    type state_variable_record is record
        state                    : int18;
        state_equation           : int18;
        integrator_state_counter : natural range 0 to 7;
    end record;

    constant init_state_variable : state_variable_record := (0,0,0);


    --------------------------------------------------
    procedure create_state_variable
    (
        signal state_variable : inout state_variable_record;
        signal multiplier : inout multiplier_record;
        state_equation : in int18;
        integrator_gain : in int18
    ) is
        alias integrator_state_counter is state_variable.integrator_state_counter;
    begin
        CASE integrator_state_counter is
            WHEN 0 =>
                sequential_multiply(multiplier, integrator_gain, state_equation);
                if multiplier_is_ready(multiplier) then
                    state_variable.state <= state_variable.state + get_multiplier_result(multiplier, 15);
                    integrator_state_counter <= integrator_state_counter + 1;
                end if;
            WHEN others => -- wait for being set to zero
        end CASE;
    end procedure create_state_variable;

    procedure integrate
    (
        signal state_variable : inout state_variable_record;
        signal multiplier : inout multiplier_record 
    ) is
    begin
        
    end integrate;
------------------------------------------------------------------------ 
    -- lrc model signals
    signal inductor_current : int18  := 0;
    signal inductor2_current : int18  := 0;

    signal capacitor_voltage : int18 := 0;
    signal capacitor2_voltage : int18 := 0;
    signal input_voltage : int18     := 0;
    signal capacitor_delta : int18   := 0;

    signal inductor_current_delta : int18 := 0;

    signal inductor_integrator_gain : int18  := 25e3;
    signal capacitor_integrator_gain : int18 := 2000;
    signal load_resistance : int18           := 10;

    signal inductor_series_resistance : int18 := 500;

    signal load_current : int18 := 0;

    signal process_counter : natural := 0;

    signal simulation_trigger_counter : natural := 0;
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

    clocked_reset_generator : process(simulator_clock)
        impure function "*" ( left, right : int18)
        return int18
        is
        begin
            sequential_multiply(hw_multiplier, left, right);
            if multiplier_is_ready(hw_multiplier) then
                process_counter <= process_counter + 1;
            end if;
            return get_multiplier_result(hw_multiplier, 15);
        end "*";

    --------------------------------------------------
        procedure calculate_state
        (
            signal multiplier : inout multiplier_record;
            signal state      : inout int18;
            integrator_gain   : int18;
            state_equation    : int18
            
        ) is
        begin
            sequential_multiply(multiplier, integrator_gain, state_equation); 
            if multiplier_is_ready(multiplier) then
                state <= get_multiplier_result(multiplier, 15) + state;
                process_counter <= process_counter + 1;
            end if;
            
        end calculate_state;
    --------------------------------------------------

    begin
        if rising_edge(simulator_clock) then

            create_multiplier(hw_multiplier); 
            create_multiplier(hw_multiplier2); 
            simulation_counter <= simulation_counter + 1;

            simulation_trigger_counter <= simulation_trigger_counter + 1;
            if simulation_trigger_counter = 20 then
                simulation_trigger_counter <= 0;
                process_counter <= 0;
            end if;

            input_voltage <= 32e2;
            if simulation_counter = 12000  then
                -- load_resistance <= 65e3;
                load_current <= -25e3;
            end if;

            CASE process_counter is 
                WHEN 0 => 
                    inductor_current_delta <= inductor_series_resistance * inductor_current;

                WHEN 1 => 
                    calculate_state(hw_multiplier, inductor_current, inductor_integrator_gain, input_voltage - capacitor_voltage - inductor_current_delta);
                    calculate_state(hw_multiplier2, inductor2_current, inductor_integrator_gain, capacitor_voltage - capacitor2_voltage);

                WHEN 2 => 
                    capacitor_delta <= load_resistance * capacitor2_voltage;

                WHEN 3 =>
                    calculate_state(hw_multiplier, capacitor_voltage, capacitor_integrator_gain, inductor_current - inductor2_current );
                    calculate_state(hw_multiplier2, capacitor2_voltage, capacitor_integrator_gain, inductor2_current - load_current - capacitor_delta);
                WHEN others => -- do nothing

            end CASE; 
        end if; -- rstn
    end process clocked_reset_generator;	

------------------------------------------------------------------------
end sim;
