LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 
    use ieee.numeric_std.all;

    use work.real_to_fixed_pkg.all;

package reciproc_pkg is

    type reciprocal_record is record
        seq_count             : natural range 0 to 7;
        iteration_count       : natural range 0 to 15;
        number_to_be_inverted : signed;
        x1                    : signed;
        xi                    : signed;
        input_zero_count      : natural range 0 to 127;
        input_shift_register  : unsigned;

        output_shift_count    : natural range 0 to 127;
        output_shift_register : signed;
        output_ready          : boolean;

        is_negative           : boolean;
        inv_a_out             : signed;
        is_ready              : boolean;

        -- TODO, use a dsp for this
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
    procedure create_reciproc(signal self : inout reciprocal_record ; constant max_shift : natural := 8 ; output_int_length : natural := 8);
    -------
    procedure request_inv(signal self : inout reciprocal_record ;a : signed ; iterations : natural);
    -------
    function is_ready ( self : reciprocal_record) return boolean;
    -------
    function get_result ( self : reciprocal_record) return signed;


end package reciproc_pkg;
------------------

package body reciproc_pkg is

    function is_ready ( self : reciprocal_record) return boolean is
    begin
        return self.is_ready;
    end is_ready;

    function get_result ( self : reciprocal_record) return signed is
    begin
        return self.inv_a_out;
    end get_result;


    function create_reciproc_typeref(wordlength : natural) return reciprocal_record is

        constant init_shifter : std_logic_vector(wordlength-2 downto 0) := (others => '1');

        constant radix  : natural := wordlength-3;
        constant retval : reciprocal_record := (
            seq_count               => 4
            , iteration_count       => 7
            , number_to_be_inverted => to_fixed(0.5, wordlength, radix)
            , x1                    => to_fixed(0.5, wordlength, radix)
            , xi                    => to_fixed(0.0, wordlength, radix)
            , input_zero_count      => 0
            , input_shift_register  => unsigned(init_shifter)
            , output_shift_count     => 0
            , output_shift_register => to_fixed(0.0, wordlength*2, radix)
            , output_ready          => false
            , is_negative           => false
            , inv_a_out             => to_fixed(0.0, wordlength, radix)
            , is_ready              => false

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
    procedure create_reciproc(
         signal self : inout reciprocal_record 
         ; constant max_shift : natural := 8
         ; output_int_length  : natural := 8
     ) is

        constant radix : natural := self.xi'length-3;
        variable vxi : signed(self.xi'range);

    begin
        self.input_zero_count     <= self.input_zero_count + number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift);
        self.input_shift_register <= shift_left(
                                self.input_shift_register
                                ,(number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift))
                            );

        self.output_ready <= false;
        if self.output_shift_count > 0 then
            if self.output_shift_count > 3
            then
                self.output_shift_count    <= self.output_shift_count - 3;
                self.output_shift_register <= shift_right(self.output_shift_register,3);
            else
                self.output_shift_count    <= 0;
                self.output_shift_register <= shift_right(self.output_shift_register,self.output_shift_count);
                self.output_ready          <= true;
            end if;
        end if;

        self.is_ready <= false;
        if self.output_ready
        then
            self.inv_a_out <= self.output_shift_register(self.xi'high+radix downto radix);
            self.is_ready  <= true;
        end if;

        self.mpyres       <= self.mpya * self.mpyb;
        self.mpy_pipeline <= self.mpy_pipeline(self.mpy_pipeline'left-1 downto 0) & '0';

        -------------------------------
        CASE self.seq_count is
            WHEN 0 => 
                if number_of_leading_zeroes(self.input_shift_register, max_shift => max_shift) = 0
                then
                    self.seq_count <= self.seq_count + 1;
                    self.xi <= to_fixed(2.0/3.0, self.xi'length, radix);
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
                    self.mpya <= self.xi;
                    self.mpyb <= inv_mantissa(vxi);
                    self.mpy_pipeline(0) <= '1';
                    self.seq_count <= self.seq_count + 1;

                end if;
            WHEN 3 => 
                if self.mpy_pipeline(self.mpy_pipeline'left) = '1' 
                then
                    if self.iteration_count > 0
                    then
                        self.iteration_count <= self.iteration_count -1;
                        self.seq_count <= 2;
                        vxi := self.mpyres(self.xi'high+radix downto radix);
                        self.xi <= vxi;

                        self.mpya <= vxi;
                        self.mpyb <= signed("00" & self.input_shift_register(self.input_shift_register'left downto 1));
                        self.mpy_pipeline(0) <= '1';

                    else
                        self.seq_count <= self.seq_count + 1;
                        -- TODO, minimize zeros in output
                        self.output_shift_register <= self.mpyres;
                        self.output_shift_count <= output_int_length-2 - self.input_zero_count;
                        -- vxi := self.mpyres(self.xi'high+radix downto radix);
                        -- self.inv_a_out <= shift_right(vxi , output_int_length-1 - self.input_zero_count);
                    end if;
                end if;
            WHEN others => -- do nothing
        end CASE;
        -------------------------------

    end procedure;
    ------------------------------------------
    procedure request_inv(signal self : inout reciprocal_record ;a : signed ; iterations : natural) is
    begin
        self.input_shift_register <= unsigned(a(self.input_shift_register'range));
        self.input_zero_count <= 0;
        self.iteration_count <= iterations;
        self.seq_count <= 0;
        self.is_negative <= a < 0;
    end request_inv;

end package body;

