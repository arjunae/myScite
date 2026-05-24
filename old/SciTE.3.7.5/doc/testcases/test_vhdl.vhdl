library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Example : 4 bit Ring Counter 
-- from http://vhdlguru.blogspot.de/2010/09/example-4-bit-ring-counter-with.html
entity ring_counter is
port (
        DAT_O : out unsigned(3 downto 0);
        RST_I : in std_logic;
        CLK_I : in std_logic
        );
end ring_counter;

architecture Behavioral of ring_counter is

signal temp : unsigned(3 downto 0):=(others => '0');

begin

DAT_O <= temp;

process(CLK_I)
begin
    if( rising_edge(CLK_I) ) then
        if (RST_I = '1') then
            temp <= (0=> '1', others => '0');
        else
            temp(1) <= temp(0);
            temp(2) <= temp(1);
            temp(3) <= temp(2);
            temp(0) <= temp(3);
        end if;
    end if;
end process;
   
end Behavioral;