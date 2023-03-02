library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity tb is
--  Port ( );
end tb;

architecture Behavioral of tb is
    signal pi_clk : std_logic;
    signal pi_rst_n : std_logic;

    signal pi_column_length_east : std_logic_vector(7 downto 0);
    signal pi_column_length_west : std_logic_vector(7 downto 0);
    signal pi_column_length_north : std_logic_vector(7 downto 0);
    signal pi_column_length_south : std_logic_vector(7 downto 0);

    signal pi_active_mode : std_logic;
    signal pi_error_detected : std_logic;

    signal po_semaphore_ctrl_east :  std_logic_vector(2 downto 0);
    signal po_semaphore_ctrl_west :  std_logic_vector(2 downto 0);
    signal po_semaphore_ctrl_north :  std_logic_vector(2 downto 0);
    signal po_semaphore_ctrl_south :  std_logic_vector(2 downto 0);

    constant period : time := 20 ns;

    component semaphore is
    port (
        pi_clk : in std_logic;
        pi_rst_n : in std_logic;

        pi_column_length_east : in std_logic_vector(7 downto 0);
        pi_column_length_west : in std_logic_vector(7 downto 0);
        pi_column_length_north : in std_logic_vector(7 downto 0);
        pi_column_length_south : in std_logic_vector(7 downto 0);

        pi_active_mode : in std_logic;
        pi_error_detected : in std_logic;

        po_semaphore_ctrl_east : out std_logic_vector(2 downto 0);
        po_semaphore_ctrl_west : out std_logic_vector(2 downto 0);
        po_semaphore_ctrl_north : out std_logic_vector(2 downto 0);
        po_semaphore_ctrl_south : out std_logic_vector(2 downto 0)
    );
    end component;

    begin

        dut: semaphore
        port map(pi_clk => pi_clk,
                 pi_rst_n => pi_rst_n,
                 pi_column_length_east => pi_column_length_east,
                 pi_column_length_west => pi_column_length_west,
                 pi_column_length_north => pi_column_length_north,
                 pi_column_length_south => pi_column_length_south,
                 pi_active_mode => pi_active_mode,
                 pi_error_detected => pi_error_detected,
                 po_semaphore_ctrl_east => po_semaphore_ctrl_east,
                 po_semaphore_ctrl_west => po_semaphore_ctrl_west,
                 po_semaphore_ctrl_north => po_semaphore_ctrl_north,
                 po_semaphore_ctrl_south => po_semaphore_ctrl_south
                 );


    clk_process:
    process
    begin
        pi_clk <= '0';
        wait for period/2;
        pi_clk <= '1';
        wait for period/2;
    end process;


    stim_proc: process
    begin

        pi_rst_n <= '1', '0' after 500 ns; 
        --upis koeficijenata
        pi_active_mode <= '1';
        pi_error_detected <= '0';

        pi_column_length_east <= std_logic_vector(to_unsigned(15, 8));
        pi_column_length_west <= std_logic_vector(to_unsigned(65, 8));
        pi_column_length_north <= std_logic_vector(to_unsigned(35, 8));
        pi_column_length_south <= std_logic_vector(to_unsigned(25, 8));
        wait until falling_edge(pi_clk);
        

    end process;


                 end architecture Behavioral;