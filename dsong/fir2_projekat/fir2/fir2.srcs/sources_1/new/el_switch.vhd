----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/03/2023 02:30:40 PM
-- Design Name: 
-- Module Name: el_switch - Behavioral
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
use ieee.std_logic_misc.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity el_switch is
    generic(input_data_width: natural := 24);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           vot_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           switch_o : out STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           module_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0));
end el_switch;

architecture Behavioral of el_switch is
    signal ff_next: std_logic;
    signal ff_reg: std_logic;

    signal switch_s: std_logic_vector(input_data_width-1 downto 0); 
    signal xor_gate: std_logic_vector(input_data_width-1 downto 0);
begin
    xor_gate <= switch_s xor vot_i; 

    ff_next <= not or_reduce(xor_gate);
    
    esw_ff: process(clk, rst) 
    begin
        if(rst = '1') then
            ff_reg <= '1';
        elsif(rising_edge(clk)) then
            ff_reg <= ff_next;
        end if;
    end process;
    
    esw_mask: process(module_i, ff_reg)
    begin
        if(ff_reg = '1') then
            switch_s <= module_i;
        else
            switch_s <= std_logic_vector(to_signed(0, input_data_width));
        end if;
    end process;

    switch_o <= switch_s;
end Behavioral;
