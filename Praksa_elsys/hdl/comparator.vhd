library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity comparator is
generic (DATA_WIDTH: integer:= 8);
 port(       
      a_i:   in std_logic_vector(DATA_WIDTH-1 downto 0);
      b_i:   in std_logic_vector(DATA_WIDTH-1 downto 0);
      
      max_o: out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
end comparator;

architecture Behavioral of comparator is
 signal sel: std_logic;

begin

compare: 
 process(a_i, b_i)
 begin
  if (a_i <= b_i) then
   sel <= '1';
  else
   sel <= '0';
  end if;
 end process; 
 
 mux1:
 process(a_i, b_i, sel)
 begin
  if (sel = '1') then
   max_o <= b_i;
  else
   max_o <= a_i;
  end if;
 end process;

end Behavioral;
