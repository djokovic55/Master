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
use work.util_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity majority_voting is
    generic(red_units: natural := 5;
            input_data_width: natural := 24);
    Port ( 
           module_switch_bits_i : in STD_LOGIC_VECTOR (input_data_width*red_units-1 downto 0);
           major_bit_o : out std_logic_vector(input_data_width-1 downto 0));
end majority_voting;

architecture Behavioral of majority_voting is

    type counter_array is array (0 to input_data_width-1) of std_logic_vector(log2c(red_units)-1 downto 0);
    signal big_counter : counter_array;

begin

    voter_gen:for i in 0 to input_data_width-1 generate
    -- signal counter : std_logic_vector(log2c(red_units)-1 downto 0);
    begin
        process(module_switch_bits_i, big_counter(i))
        begin
            -- counter <= std_logic_vector(to_unsigned(0, log2c(red_units)-1)) & module_switch_bits_i(i*input_data_width);

            for k in 0 to red_units-1 loop
                -- critical bug, i needs to be added in order to target each set of voter bits correctly
                -- if(k = 0) then

                    -- counter <= std_logic_vector(to_unsigned(0, log2c(red_units)-1)) & module_switch_bits_i(k*input_data_width + i);
                -- else
                    if module_switch_bits_i(k*input_data_width + i) = '1' then
                        big_counter(i) <= std_logic_vector(unsigned(big_counter(i)) + to_unsigned(1, log2c(red_units)));
                        else 
                        big_counter(i) <= big_counter(i);
                    end if;
                -- end if;
            end loop;

            if(unsigned(big_counter(i)) >= (red_units+1)/2) then
                major_bit_o(i) <= '1';
            else    
                major_bit_o(i) <= '0';
            end if;
        end process;

    end generate;
end Behavioral;
