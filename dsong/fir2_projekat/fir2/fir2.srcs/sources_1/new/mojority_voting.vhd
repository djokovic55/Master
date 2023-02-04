----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2023 02:35:57 PM
-- Design Name: 
-- Module Name: mojority_voting - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity majority_voting is
    generic(size: natural := 5;
            input_data_width: natural := 24);
    Port ( 
           module_bits_i : in STD_LOGIC_VECTOR (input_data_width*size-1 downto 0);
           major_bit_o : out std_logic_vector(input_data_width-1 downto 0));
end majority_voting;

architecture Behavioral of majority_voting is


begin
    voter_gen:for i in 0 to input_data_width-1 generate
        signal counter : integer := 0;
    begin
        process(module_bits_i)
        begin
            counter <= 0;
            for k in 0 to size-1 loop
                if module_bits_i(k*input_data_width) = '1' then
                    counter <= counter + 1;
                end if;
            end loop;
        end process;
        
        major_bit_o(i) <= '1' when (counter >= (size+1)/2) else '0';

    end generate;
end Behavioral;
