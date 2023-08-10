----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/04/2023 11:19:22 AM
-- Design Name: 
-- Module Name: top_structure2 - Behavioral
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

entity top_fir is
   generic( fir_ord : natural :=20;
            input_data_width : natural := 24;
            output_data_width : natural := 24;
            number_samples_g:positive:= 2371;
            red_units: natural := 5);
    Port ( clk : in STD_LOGIC;
           reset : in std_logic;
           start_FIR: in std_logic;
                      
           we_i_coeff: in std_logic;
           
           coef_i_FIR : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i_FIR : in std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           
           data_i_FIR  : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           addr_data_o_BRAM1_FIR : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0); 

           data_o_FIR : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
           addr_data_o_FIR_BRAM2 : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
           we_o_fir_bram2 : out std_logic;

           ready_o_FIR: out std_logic);
end top_fir;

architecture Behavioral of top_fir is
    --------------------------- COMPONENT DECLARATIONS -------------------------------------
    component fir_param
    generic(fir_ord : natural :=20;
            input_data_width : natural := 24;
            output_data_width : natural := 24;
            number_samples_g:positive:= 2371);
    Port ( clk : in STD_LOGIC;
           we_i_coeff: in std_logic;
           coef_i_FIR : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i_FIR : in std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           data_i_FIR  : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           data_o_FIR : out STD_LOGIC_VECTOR (output_data_width-1 downto 0)
           );
    end component fir_param;

    component majority_voting
    generic(red_units: natural := 5;
            input_data_width: natural := 24);
    Port ( 
           clk : in std_logic;
           reset : in std_logic;
           module_switch_bits_i : in STD_LOGIC_VECTOR (input_data_width*red_units-1 downto 0);
           major_bit_o : out std_logic_vector(input_data_width-1 downto 0));
    end component majority_voting;

    component el_switch
    generic(input_data_width: natural := 24);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           vot_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           switch_o : out STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           module_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0));
    end component el_switch;
    
    --------------------------- SIGNAL DECLARATIONS ------------------------------------------
    type switch_array is array (0 to red_units-1) of std_logic_vector(input_data_width-1 downto 0);
    signal switch_input_data : switch_array;
    signal switch_output_data: std_logic_vector(red_units*input_data_width-1 downto 0);
    signal vot_compare_data: std_logic_vector(input_data_width-1 downto 0);

    -- will be moved to upper lv 
    type state_type is (IDLE, S1_ADDRESS);
    signal state_reg, state_next: state_type;
    signal bram1_addr_reg, bram1_addr_next: std_logic_vector(log2c(number_samples_g+1)-1 downto 0);      
    signal bram2_addr_reg, bram2_addr_next: std_logic_vector(log2c(number_samples_g+1)-1 downto 0);   
begin

    -- generate firs, switches and voter

    generate_firs: for i in 0 to red_units-1 generate
        firs: fir_param generic map(fir_ord => fir_ord, 
                                    input_data_width => input_data_width,
                                    output_data_width => output_data_width,
                                    number_samples_g => number_samples_g)
                        port map (clk => clk, 
                                we_i_coeff => we_i_coeff,
                                coef_i_FIR => coef_i_FIR,
                                coef_addr_i_FIR => coef_addr_i_FIR,
                                data_i_FIR => data_i_FIR,
                                data_o_FIR => switch_input_data(i)
                        );
    end generate;

    generate_switches: for i in 0 to red_units-1 generate
        switches: el_switch generic map(input_data_width => input_data_width)
                            port map (clk => clk,
                                      reset => reset,
                                      vot_i => vot_compare_data,
                                      switch_o => switch_output_data((i+1)*input_data_width-1 downto i*input_data_width),
                                      module_i => switch_input_data(i)
                            );

    end generate;
    -- made it sync
    generate_voter : majority_voting generic map(red_units => red_units,
                                                 input_data_width => input_data_width
                                     )
                                     port map(
                                              clk => clk,
                                              reset =>reset,
                                              module_switch_bits_i => switch_output_data,
                                              major_bit_o => vot_compare_data 
                                     );
    -- form output data
    data_o_FIR <= vot_compare_data;


    -- Address and state registers
    process(clk)
    begin
        if(clk'event and clk = '1')then
            if(reset = '1')then
                state_reg <= IDLE;
                bram1_addr_reg <= (others=> '0');
                bram2_addr_reg <= (others=> '0');
            else
                state_reg <= state_next;
                bram1_addr_reg <= bram1_addr_next;
                bram2_addr_reg <= bram2_addr_next;
            end if;
         end if;
    end process;
    
    -- Reading logic from BRAM1
   process(state_next, state_reg, start_FIR, data_i_FIR, bram1_addr_next, bram1_addr_reg) 
   begin
    
    bram1_addr_next <= bram1_addr_reg;

    case(state_reg) is
        when IDLE => 
            if(start_FIR = '1')then
                state_next <= S1_ADDRESS;
            else
                state_next <= IDLE;
            end if;
      when S1_ADDRESS =>
            addr_data_o_BRAM1_FIR <= bram1_addr_reg;
            bram1_addr_next <= std_logic_vector(unsigned(bram1_addr_reg) + 1);
            if(bram1_addr_reg = std_logic_vector(to_unsigned(number_samples_g - 1, log2c(number_samples_g + 1)))) then
                bram1_addr_next <= (others => '0');
                state_next <= IDLE;
            end if;
     end case;
   end process;


 -- Writing logic to BRAM2
    process(bram1_addr_next, bram1_addr_reg, bram2_addr_reg, bram2_addr_next)
    begin

        ready_o_FIR <= '0';
        we_o_fir_bram2 <= '0';

        if((bram1_addr_reg >= std_logic_vector(to_unsigned(3, log2c(number_samples_g+1))) or 
           bram2_addr_reg >= std_logic_vector(to_unsigned(3, log2c(number_samples_g+1)))) and
           bram2_addr_reg < std_logic_vector(to_unsigned(number_samples_g - 1, log2c(number_samples_g+1)))) then

            we_o_fir_bram2 <= '1';

            bram2_addr_next <= std_logic_vector(unsigned(bram2_addr_reg) + 1);
            if(bram2_addr_next = std_logic_vector(to_unsigned(number_samples_g - 1, log2c(number_samples_g+1)))) then

                ready_o_FIR <= '1';
            end if;

        else
            bram2_addr_next <= (others => '0');
        end if;
        
        -- Address assignment for BRAM2
        addr_data_o_FIR_BRAM2 <= bram2_addr_reg;

    end process;
    




end Behavioral;
