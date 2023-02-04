library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.util_pkg.all;

entity fir_param is
    generic(fir_ord : natural :=20;
            input_data_width : natural := 24;
            output_data_width : natural := 24;
            number_samples_g:positive:= 2371);
    Port ( clk : in STD_LOGIC;
           reset : in std_logic;
           start_FIR: in std_logic;
                      
           we_i_coeff: in std_logic;
           
           coef_i_FIR : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i_FIR : in std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           
           data_i_FIR  : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           addr_data_o_BRAM1_FIR : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0); 

        -- BRAM2 interface, these signals must be moved to voter logic    
           data_o_FIR : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
           addr_data_o_FIR_BRAM2 : out std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
           we_o_fir_bram2 : out std_logic;

           ready_o_FIR: out std_logic);
         
end fir_param;

architecture Behavioral of fir_param is
    type std_2d is array (fir_ord downto 0) of std_logic_vector(2*input_data_width-1 downto 0);
    signal mac_inter : std_2d:=(others=>(others=>'0'));
    type coef_t is array (fir_ord downto 0) of std_logic_vector(input_data_width-1 downto 0);
    signal b_s : coef_t := (others=>(others=>'0')); 

    -- will be moved to upper lv 
    type state_type is (IDLE, S1_ADDRESS);
    signal state_reg, state_next: state_type;
    signal bram1_addr_reg, bram1_addr_next: std_logic_vector(log2c(number_samples_g+1)-1 downto 0);      
    signal bram2_addr_reg, bram2_addr_next: std_logic_vector(log2c(number_samples_g+1)-1 downto 0);      
                                                       
begin

    process(clk)
    begin
        if(clk'event and clk = '1')then
            if we_i_coeff = '1' then
                b_s(to_integer(unsigned(coef_addr_i_FIR))) <= coef_i_FIR;
            end if;
        end if;
    end process;
    
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
    
    -- citanje iz BRAM1
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

   
    first_section:
    entity work.mac(behavioral)
    generic map(input_data_width=>input_data_width)
    port map(clk=>clk,
             u_i=>data_i_FIR,
             b_i=>b_s(fir_ord),
             sec_i=>(others=>'0'),
             sec_o=>mac_inter(0));
                     
    other_sections:
    for i in 1 to fir_ord-1 generate
        fir_section:
        entity work.mac(behavioral)
        generic map(input_data_width=>input_data_width)
        port map(clk=>clk,
                 u_i=>data_i_FIR,
                 b_i=>b_s(fir_ord-i),
                 sec_i=>mac_inter(i-1),
                 sec_o=>mac_inter(i));
    end generate;
    
    process(clk)
    begin
        if(clk'event and clk='1')then
            -- upis rezultata u BRAM2
            data_o_FIR <= mac_inter(fir_ord - 1)(2*input_data_width-2 downto 2*input_data_width-output_data_width-1);
        end if;
    end process;
    
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
        
        -- generisanje adresa za BRAM2
        addr_data_o_FIR_BRAM2 <= bram2_addr_reg;

    end process;
    
end Behavioral;