LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.math_real.all;

library vunit_lib;
    use vunit_lib.run_pkg.all;

library math_library;
    use math_library.multiplier_pkg.all;

entity tb_example is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of tb_example is

    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 5000;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    type filter_object_record is record
        multiplier       : multiplier_record ;
        counter          : natural           ;
        process_counter  : natural           ;
        process_counter2 : natural           ;
        y                : int18             ;
        mem              : int18             ;
    end record;
    constant init_filter : filter_object_record := (
        init_multiplier , 0 , 0 , 0 , 0 , 0) ;



    procedure create_filter
    (
        signal filter_object : inout filter_object_record
    ) is
        alias multiplier       is filter_object.multiplier       ;
        alias counter          is filter_object.counter          ;
        alias process_counter  is filter_object.process_counter  ;
        alias process_counter2 is filter_object.process_counter2 ;
        alias y                is filter_object.y                ;
        alias mem              is filter_object.mem              ;
        constant b0 : integer := 1500;
        constant b1 : integer := 150;
        constant a0 : integer := 2**16-b0-b1;
    begin
            create_multiplier(multiplier);

            Case process_counter is
                WHEN 0 =>
                    multiply(multiplier, counter, b0);
                    increment(process_counter);
                WHEN 1 =>
                    multiply(multiplier, counter, b1);
                    increment(process_counter);
                WHEN others => -- wait
            end case;

            Case process_counter2 is
                WHEN 0 =>
                    if multiplier_is_ready(multiplier) then
                        increment(process_counter2);
                        y <= mem + get_multiplier_result(multiplier, 16);
                    end if;
                WHEN 1 =>
                    if multiplier_is_ready(multiplier) then
                        increment(process_counter2);
                        mem <= get_multiplier_result(multiplier, 16);
                        multiply(multiplier, y, a0);
                    end if;
                When 2 =>
                    if multiplier_is_ready(multiplier) then
                        increment(process_counter2);
                        mem <= mem + get_multiplier_result(multiplier, 16);
                    end if;
                When 3 =>
                    process_counter <= 0;
                    process_counter2 <= 0;

                    counter <= counter + 1e3;
                    if counter = 10e3 then
                        counter <= 0;
                    end if;
                WHEN others => -- wait
            end case;

        
    end create_filter;
------------------------------------------------------------------------
    signal filter : filter_object_record := init_filter; 
    signal filter2 : filter_object_record := init_filter; 

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
        wait for clock_half_per;
        while simulation_running loop
            wait for clock_half_per;
                simulator_clock <= not simulator_clock;
            end loop;
        wait;
    end process;
------------------------------------------------------------------------

    stimulus : process(simulator_clock)

    begin
        if rising_edge(simulator_clock) then
            simulation_counter <= simulation_counter + 1;
            create_filter(filter);
            create_filter(filter2);



        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
