
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

entity top_structure is
generic(    red_units : natural := 5;
            fir_ord : natural :=20;
            input_data_width : natural := 24;
            output_data_width : natural := 24;
            number_samples_g:positive:= 2731);
    Port ( clk : in STD_LOGIC;
           reset : in std_logic;
           start: in std_logic;
           we_bram1_i : in std_logic;
           
           coef_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           coef_addr_i : std_logic_vector(log2c(fir_ord+1)-1 downto 0);
           we_i_coeff: in std_logic;
           
           data_i : in STD_LOGIC_VECTOR (input_data_width-1 downto 0);
           addr_data_i : std_logic_vector(log2c(number_samples_g+1)-1 downto 0); --netacno, ima vise
           
           data_o : out STD_LOGIC_VECTOR (output_data_width-1 downto 0);
           -- port preko koga se salju adrese, sa kojih se citaju konacni rezultati
           addr_data_bram2_i : in std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
           
           ready_o : out STD_LOGIC);
end top_structure;

architecture Behavioral of top_structure is

 --general signals for BRAM
    signal zero : std_logic;
    signal zero_width_g : std_logic_vector(input_data_width-1 downto 0);
    signal en_mem_s : std_logic;
    
    
  --signals between BRAM1 and FIR
   signal data_i_FIR_S : STD_LOGIC_VECTOR (input_data_width-1 downto 0);
   signal addr_data_o_BRAM1_FIR_s : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
   --signals between FIR and BRAM2
   signal  data_o_FIR_BRAM2_s: STD_LOGIC_VECTOR (input_data_width-1 downto 0);
   signal addr_data_o_FIR_BRAM2_s : std_logic_vector(log2c(number_samples_g+1)-1 downto 0);
   signal we_FIR_BRAM2_s : std_logic;
  
    component  BRAM
    generic(
        width_g:positive:=24;
        size_g:positive:=number_samples_g
        );
    port(
        clka : in std_logic;
        clkb : in std_logic;
        ena: in std_logic;
        enb: in std_logic;
        wea: in std_logic;
        web: in std_logic;
        addra : in std_logic_vector(log2c(size_g)-1 downto 0);
        addrb : in std_logic_vector(log2c(size_g)-1 downto 0);
        dia: in std_logic_vector(width_g-1 downto 0);
        dib: in std_logic_vector(width_g-1 downto 0);
        doa: out std_logic_vector(width_g-1 downto 0);
        dob: out std_logic_vector(width_g-1 downto 0)
        );
    end component;
    
    
    component top_fir 
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
end component;
begin

en_mem_s <= '1';
zero <= '0';
zero_width_g <= std_logic_vector(to_unsigned(0,input_data_width));

 mem_1: BRAM
    generic map(
                width_g => input_data_width,
                size_g => number_samples_g
                )
    port map(
            clka => clk,
            clkb => clk,
            ena => en_mem_s,
            enb => en_mem_s,
            wea => we_bram1_i,       -- portA za UPIS pocetnih odbiraka u BRAM1
            web => zero,               -- portB za CITANJE odbiraka iz BRAM1 od strane FIR
            addra => addr_data_i,       --adresa na koju se upisuje odbirak sa starta
            addrb => addr_data_o_BRAM1_FIR_s,  --adresa sa koje fir cita ulazni podatak
            dia => data_i,
            dib => zero_width_g,  
            doa => open,
            dob => data_i_FIR_s      --ulazni odbirci za FIR
            );
 
 ft_fir: top_fir
    generic map(

                fir_ord  => fir_ord ,
                input_data_width  => input_data_width,
                output_data_width  => output_data_width,
                number_samples_g  => number_samples_g,
                red_units => red_units
                )
    port map(
            clk => clk,
            reset => reset,
            start_FIR => start,

            we_o_fir_bram2 => we_FIR_BRAM2_s,
            we_i_coeff => we_i_coeff,

            coef_i_FIR => coef_i,
            coef_addr_i_FIR => coef_addr_i,
           
            data_i_FIR => data_i_FIR_s,
            addr_data_o_BRAM1_FIR => addr_data_o_BRAM1_FIR_s, 
           
            data_o_FIR => data_o_FIR_BRAM2_s,
            addr_data_o_FIR_BRAM2 => addr_data_o_FIR_BRAM2_s,
            
            ready_o_FIR => ready_o
            );
            
    mem2: BRAM
    generic map(
                width_g => input_data_width,
                size_g => number_samples_g
                )
    port map(
            clka => clk,
            clkb => clk,
            ena => en_mem_s,
            enb => en_mem_s,
            wea => we_FIR_BRAM2_s,               -- portA za UPIS u BRAM2 iz FIRa
            web => zero,                         -- portB za CITANJE odbiraka iz BRAM2 za izlazne podatke
            addra => addr_data_o_FIR_BRAM2_s,  --adresa na koju se upisuje, iz FIRa
            addrb => addr_data_bram2_i,              --adresa sa koje se cita za izlazne podakte
            dia => data_o_FIR_BRAM2_s,
            dib => zero_width_g,  
            doa => open,
            dob =>  data_o                            --izlazni podaci
            );
end Behavioral;
