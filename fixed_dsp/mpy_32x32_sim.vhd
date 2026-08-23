-- behavioral stand-in for the ECP5 sysDSP "mpy_32x32" hard IP block used
-- by arch_ecp5_fixed_dsp : the vendor-generated netlist depends on the
-- ECP5U primitive library and cannot be elaborated by a generic
-- simulator, so this model reproduces its externally visible timing
-- (input register + pipelined multiplier + output register = 3 clocks
-- from DataA/DataB to Result) without any vendor dependency
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity mpy_32x32 is
    port (
        Clock   : in  std_logic
        ;ClkEn  : in  std_logic
        ;Aclr   : in  std_logic
        ;DataA  : in  std_logic_vector(31 downto 0)
        ;DataB  : in  std_logic_vector(31 downto 0)
        ;Result : out std_logic_vector(63 downto 0)
    );
end entity;

architecture sim of mpy_32x32 is

    type sign_array is array (natural range <>) of signed;
    signal result_buffer : sign_array(2 downto 0)(Result'range);

begin

    result_buffer <= result_buffer(1 downto 0) & signed(DataA) * signed(DataB) when rising_edge(Clock);
    Result <= std_logic_vector(result_buffer(result_buffer'left));

end sim;
