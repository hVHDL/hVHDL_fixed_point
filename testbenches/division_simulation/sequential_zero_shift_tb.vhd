LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;

package reciproc_pkg is

    type reciprocal_record is record
        seq_count             : natural range 0 to 7;
        rec_count             : natural range 0 to 7;
        iteration_count       : natural range 0 to 7;
        number_to_be_inverted : signed;
        x1                    : signed;
        xi                    : signed;
        input_zero_count      : natural range 0 to 127;
        input_shift_register  : unsigned;
        is_negative           : boolean;
        inv_a_out             : signed;

        mpya         : signed;
        mpyb         : signed;
        mpyres       : signed;
        mpy_pipeline : std_logic_vector(1 downto 0);
    end record;

    -------
    function create_reciproc_typeref(wordlength : natural) return reciprocal_record;

    -------
    function mpy (left : signed; right : signed) return signed;

    -------
    function inv_mantissa(a : signed) return signed;

    -------
    procedure create_reciproc(signal self : inout reciprocal_record ; constant max_shift : natural := 8 ; return_radix : natural := 7);
    -------

end package reciproc_pkg;
------------------

package body reciproc_pkg is

    function create_reciproc_typeref(wordlength : natural) return reciprocal_record is

        constant radix  : natural := wordlength-3;
        constant retval : reciprocal_record := (
            seq_count               => 3
            , rec_count             => 3
            , iteration_count       => 7
            , number_to_be_inverted => to_fixed(0.5, wordlength, radix)
            , x1                    => to_fixed(0.5, wordlength, radix)
            , xi                    => to_fixed(1.0/1.7, wordlength, radix)
            , input_zero_count      => 0
            , input_shift_register  => unsigned(std_logic_vector'(to_fixed(0.0, wordlength-1, radix)))
            , is_negative           => false
            , inv_a_out             => to_fixed(0.0, wordlength, radix)

            -- refactor to use a module
            , mpya                  => to_fixed(0.0, wordlength, radix)
            , mpyb                  => to_fixed(0.0, wordlength, radix)
            , mpyres                => to_fixed(0.0, wordlength*2, radix)
            , mpy_pipeline          => (others => '0')
        );

    begin
        return retval;
    end create_reciproc_typeref;

    -------------
    function mpy (left : signed; right : signed) return signed is
        variable res : signed(2*left'length-1 downto 0);
        variable retval : signed(left'range);
        constant radix : natural := left'length-3;
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
    -------------

    ------------------------------------------
    procedure create_reciproc(signal self : inout reciprocal_record ; constant max_shift : natural := 8 ; return_radix : natural := 7) is
        constant radix : natural := self.xi'length-3;
        variable vxi : signed(self.xi'range);
    begin
        self.input_zero_count     <= self.input_zero_count + number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift);
        self.input_shift_register <= shift_left(
                                self.input_shift_register
                                ,(number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift)));

        self.mpyres <= self.mpya * self.mpyb;
        self.mpy_pipeline <= self.mpy_pipeline(self.mpy_pipeline'left-1 downto 0) & '0';

        CASE self.seq_count is
            WHEN 0 => 
                if number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift) = 0
                then
                    self.seq_count <= self.seq_count + 1;
                end if;
            WHEN 1 => 
                self.mpya <= self.xi;
                self.mpyb <= signed("00" & self.input_shift_register(self.input_shift_register'left downto 1));
                self.mpy_pipeline(0) <= '1';

                self.seq_count <= self.seq_count + 1;
            WHEN 2 => 
                if self.mpy_pipeline(self.mpy_pipeline'left) = '1' 
                then
                    vxi := self.mpyres(self.xi'high+radix downto radix);
                    self.xi <= mpy(self.xi, inv_mantissa(vxi));

                    if self.iteration_count > 0
                    then
                        self.iteration_count <= self.iteration_count -1;
                        self.seq_count <= 1;
                    else
                        self.seq_count <= self.seq_count + 1;
                        -- get from dsp output register
                        self.inv_a_out <= signed(resize(shift_right(self.xi , return_radix-1) , self.inv_a_out'length));
                    end if;
                end if;
            WHEN others => -- do nothing

        end CASE;
    end procedure;
    ------------------------------------------

end package body;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;
    use ieee.math_real.all;


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
    use work.reciproc_pkg.all;
    constant wordlength : natural := 51;
    constant radix : natural := wordlength-3;

    constant init_reciproc : reciprocal_record := create_reciproc_typeref(wordlength);

    signal self : init_reciproc'subtype := init_reciproc;

    use work.real_to_fixed_pkg.all;
    signal q  : signed(wordlength-1 downto 0) := to_fixed(98.95, wordlength, radix-5);

    signal result : real := 0.0;
    signal inv_a  : real := 0.0;
    signal ref_a  : real := 0.0;

    constant max_shift : natural := 8;

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

            create_reciproc(self, max_shift => max_shift);
            inv_a <= to_real(self.inv_a_out, radix);

            if inv_a /= 0.0
            then
                ref_a <= 1.0/inv_a;
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
