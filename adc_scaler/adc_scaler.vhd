-- entity and package
LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

package adc_scaler_pkg is

    type adc_scaler_in_record is record
        conversion_requested : boolean ;
        data_in              : signed  ;
        address              : natural ;
    end record;

    type adc_scaler_out_record is record
        data_out             : signed  ;
        out_address          : natural ;
        is_ready             : std_logic ;
    end record;

    procedure init_adc_scaler(signal self_in : out adc_scaler_in_record);
    procedure request_scaling(signal self_in : out adc_scaler_in_record
         ; data : in signed
         ; address : in natural);

    function scaler_is_ready(self_out : adc_scaler_out_record) return boolean;
    function get_converted_meas(self_out : adc_scaler_out_record) return signed;
    function get_converted_address(self_out : adc_scaler_out_record) return natural;

    procedure scale_measurement(
        signal self_in    : out adc_scaler_in_record
        ;signal requested : inout boolean
        ; variable ready  : inout boolean
        ; measurement     : unsigned
        ; address         : integer
        ; word_length     : in integer := 40);

end package adc_scaler_pkg;

package body adc_scaler_pkg is

    procedure init_adc_scaler(signal self_in : out adc_scaler_in_record) is
    begin
        self_in.conversion_requested <= false;
    end init_adc_scaler;

    procedure request_scaling(signal self_in : out adc_scaler_in_record
         ; data : in signed
         ; address : in natural) is
    begin
        self_in.conversion_requested <= true;
        self_in.data_in <= data;
        self_in.address <= address;
    end request_scaling;

    function scaler_is_ready(self_out : adc_scaler_out_record) return boolean is
    begin
        return self_out.is_ready = '1';
    end scaler_is_ready;

    function get_converted_meas(self_out : adc_scaler_out_record) return signed is
    begin
        return self_out.data_out;
    end get_converted_meas;

    function get_converted_address(self_out : adc_scaler_out_record) return natural is
    begin
        return self_out.out_address;
    end get_converted_address;

    procedure scale_measurement(
        signal self_in : out adc_scaler_in_record 
        ;signal requested : inout boolean 
        ; variable ready : inout boolean
        ; measurement : unsigned
        ; address : integer
        ; word_length : in integer := 40) is
    begin
        if requested and ready
        then
            request_scaling(self_in, resize(signed(measurement), word_length)
            ,address => address);
            requested <= false;
            ready := false;
        end if;
    end procedure;
    ----

end package body adc_scaler_pkg;

LIBRARY ieee  ; 
    USE ieee.NUMERIC_STD.all  ; 
    USE ieee.std_logic_1164.all  ; 

    use work.dual_port_ram_pkg.all;
    use work.adc_scaler_pkg.all;

entity adc_scaler is
    generic (init_values : work.dual_port_ram_pkg.ram_array
            ;radix : natural);
    port(
        clock     : in std_logic
        ;self_in  : in adc_scaler_in_record
        ;self_out : out adc_scaler_out_record
    );
end adc_scaler;

architecture rtl of adc_scaler is

    function address_width return integer is
        variable temp   : integer := init_values'length;
        variable retval : integer := 0;
    begin
        while temp > 1 loop
            retval := retval + 1;
            temp   := temp / 2;
        end loop;

        return retval;
    end function;

    constant dp_ram_subtype : dpram_ref_record := 
        create_ref_subtypes(
            datawidth      => init_values(0)'length
            , addresswidth => address_width);

    --------------------
    signal ram_a_in  : dp_ram_subtype.ram_in'subtype;
    signal ram_a_out : dp_ram_subtype.ram_out'subtype;
    --------------------
    signal ram_b_in  : ram_a_in'subtype;
    signal ram_b_out : ram_a_out'subtype;
    --------------------
    type address_array is array(integer range 0 to 15) of natural;
    type data_array is array(integer range 0 to 15) of signed(self_in.data_in'range);
    signal address_pipeline : address_array := (0 => 0, 1 => 1, 2 => 2, others => 15);
    signal data_pipeline : data_array :=(others => (others => '0'));
    constant zero : signed(self_in.data_in'range) := (others => '0');

    constant datawidth : natural := dp_ram_subtype.ram_in.data'length;

    signal a, b, c , cbuf : signed(datawidth-1 downto 0);
    signal mpy_res        : signed(2*datawidth-1 downto 0);
    signal mpy_res2       : signed(2*datawidth-1 downto 0);
    
    signal ready_pipeline : std_logic_vector(0 to 15) := (others => '0');

begin

    process(clock)
    begin
        if rising_edge(clock) then
            ---------------
            mpy_res2 <= a * b;
            cbuf     <= c;
            mpy_res  <= mpy_res2 + shift_left(resize(cbuf , mpy_res'length), radix) ;
            ---------------
            init_ram(ram_a_in);
            init_ram(ram_b_in);

            address_pipeline <= self_in.address & address_pipeline(0 to 14);
            data_pipeline    <= self_in.data_in & data_pipeline(0 to 14);
            ready_pipeline   <= '0' & ready_pipeline(0 to 14);

            if self_in.conversion_requested
            then 
                ready_pipeline(0) <= '1';
                request_data_from_ram(ram_a_in, self_in.address*2);
                request_data_from_ram(ram_b_in, self_in.address*2+1);
            end if;

            if ram_read_is_ready(ram_a_out) 
            then
                a <= resize(data_pipeline(2), datawidth);
                b <= resize(signed(get_ram_data(ram_a_out)), datawidth);
                c <= resize(signed(get_ram_data(ram_b_out)), datawidth);
            end if;

            self_out.out_address <= address_pipeline(5);
            self_out.data_out    <= mpy_res(radix+ram_a_out.data'length-1 downto radix);
            self_out.is_ready    <= ready_pipeline(5);

        end if; -- rising_edge
    end process;

    u_dpram : entity work.dual_port_ram
    generic map(dp_ram_subtype, init_values)
    port map(
    clock
    , ram_a_in   
    , ram_a_out  
    --------------
    , ram_b_in  
    , ram_b_out);
--------------------------------------------
end rtl;
