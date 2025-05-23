LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;

package reciproc_pkg is

    constant wordlength : natural := 36;
    constant radix : natural := wordlength-3;
    constant max_shift : natural := 8;

    type reciprocal_record is record
        seq_count            : natural range 0 to 7;
        iteration_count      : natural range 0 to 7;
        x1                   : signed(wordlength-1 downto 0);
        xi                   : signed(wordlength-1 downto 0);
        input_zero_count     : natural range 0 to wordlength;
        input_shift_register : unsigned(wordlength-2 downto 0);
        is_negative : boolean;
        inv_a_out : signed(wordlength-1 downto 0);
    end record;

    constant init_reciproc : reciprocal_record := (
        seq_count         => 3
        , iteration_count => 7
        , x1              => to_fixed(0.5, wordlength, radix)
        , xi              => to_fixed(1.0/1.7, wordlength, radix)
        , input_zero_count => 0
        , input_shift_register => (others => '1')
        , is_negative => false
        , inv_a_out => (others => '0')
    );

        function mpy (left : signed; right : signed) return signed;
        function inv_mantissa(a : signed) return signed;
        procedure create_reciproc(signal self : inout reciprocal_record);

end package reciproc_pkg;
------------------

package body reciproc_pkg is
        function mpy (left : signed; right : signed) return signed is
            variable res : signed(2*left'length-1 downto 0);
            variable retval : signed(left'range);
        begin

            res := left*right;
            retval := res(left'high+radix downto radix);

            return retval;

        end function;

        -------------
        function inv_mantissa(a : signed) return signed is
            variable retval : signed(a'range) := a;
        begin
            return "00" & (not retval(retval'left-2 downto 0));
        end inv_mantissa;
        -------------


    function number_of_leading_zeroes
    (
        data        : unsigned
        ; max_shift : integer
    )
    return integer 
    is
        variable number_of_zeroes : integer := 0;
    begin
        for i in data'high - max_shift to data'high loop
            if data(i) = '0' then
                number_of_zeroes := number_of_zeroes + 1;
            else
                number_of_zeroes := 0;
            end if;
        end loop;

        return number_of_zeroes;
        
    end number_of_leading_zeroes;

        procedure create_reciproc(signal self : inout reciprocal_record) is
        begin
            self.input_zero_count     <= self.input_zero_count + number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift);
            self.input_shift_register <= shift_left(
                                    self.input_shift_register
                                    ,(number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift)));

            CASE self.seq_count is
                WHEN 0 => 
                    if number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift) = 0
                    then
                        self.seq_count <= self.seq_count + 1;
                    end if;
                WHEN 1 => 
                    self.x1 <= inv_mantissa(mpy(self.xi ,signed("00" & self.input_shift_register(self.input_shift_register'left downto 1) )));

                    self.seq_count <= self.seq_count + 1;
                WHEN 2 => 
                    self.xi <= mpy(self.xi, self.x1);

                    if self.iteration_count > 0
                    then
                        self.iteration_count <= self.iteration_count -1;
                        self.seq_count <= 1;
                    else
                        self.seq_count <= self.seq_count + 1;
                        -- get from dsp output register
                        self.inv_a_out <= signed(resize(shift_right(self.xi,6), self.inv_a_out'length));
                    end if;

                WHEN 3 => 
                    self.seq_count <= self.seq_count + 1;
                WHEN others => -- do nothing

            end CASE;
        end procedure;


end package body;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use work.reciproc_pkg.all;

library vunit_lib;
    context vunit_lib.vunit_context;

entity seq_zero_shift_tb is
  generic (runner_cfg : string);
end;

architecture vunit_simulation of seq_zero_shift_tb is
    signal simulation_running : boolean;
    signal simulator_clock : std_logic;
    constant clock_per : time := 1 ns;
    constant clock_half_per : time := 0.5 ns;
    constant simtime_in_clocks : integer := 500;

    signal simulation_counter : natural := 0;
    -----------------------------------
    -- simulation specific signals ----
    use work.real_to_fixed_pkg.all;

    signal q  : signed(wordlength-1 downto 0) := to_fixed(88.95, wordlength, radix-5);
    signal b  : signed(wordlength-1 downto 0) := to_fixed(1.7, wordlength, radix);

    signal b_div_a : signed(wordlength-1 downto 0) := to_fixed(0.0, wordlength, radix);

    signal result : real := 0.0;
    signal inv_a : real := 0.0;
    signal ref_a : real := 0.0;


    signal output_shift_register : signed(wordlength-1 downto 0) := (0 => '1' , others => '0');
    signal output_shift_count     : natural   := 0;


    signal self : reciprocal_record := init_reciproc;

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

            -- unneeded right now
            if output_shift_count > 0
            then
                -- output_shift_count <= 
                if output_shift_count > 3 then
                    output_shift_count <= output_shift_count-3;
                    output_shift_register <= shift_left(output_shift_register,3);
                else
                    output_shift_count <= 0;
                    output_shift_register <= shift_left(output_shift_register,output_shift_count);
                end if;
            end if;
            ----

            create_reciproc(self);
            CASE self.seq_count is
                WHEN 3 =>
                    b_div_a <= mpy(b,self.xi);
                WHEN others => --do nothing
            end CASE;

            inv_a <= to_real(self.inv_a_out, radix);

            if inv_a /= 0.0
            then
                ref_a <= 1.0/inv_a;
            end if;

            if self.is_negative then
                result <= to_real(b_div_a, radix);
            else
                result <= -to_real(b_div_a, radix);
            end if;

            CASE simulation_counter is
                WHEN 0 =>
                    self.input_shift_register <= unsigned(q(self.input_shift_register'range));
                    self.is_negative <= q < 0;
                    self.input_zero_count <= 0;
                    self.iteration_count <= 5;
                    self.seq_count <= 0;
                WHEN others => -- do nothing
            end CASE;

        end if; -- rising_edge
    end process stimulus;	
------------------------------------------------------------------------
end vunit_simulation;
