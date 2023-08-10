library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity semaphore is
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
end entity;

architecture behavioral of semaphore is

    type state_type is (PASSIVE, GREEN_NS, GREEN_NS_COUNT, RED_YELLOW, GREEN_EW, GREEN_EW_COUNT, GREEN_YELLOW);
    signal state_r, state_nxt: state_type;

    signal ew_nxt, ew_r: std_logic_vector(7 downto 0);      
    signal ns_nxt, ns_r: std_logic_vector(7 downto 0);      

    signal passive_mode_check: std_logic;

    signal ew_max, ns_max: std_logic_vector(7 downto 0);      

    constant RED : std_logic_vector(2 downto 0) := "100";
    constant YELLOW : std_logic_vector(2 downto 0) := "010";
    constant GREEN : std_logic_vector(2 downto 0) := "001";

    component comparator is
        generic (DATA_WIDTH: integer:= 8);
        port(       
            a_i:   in std_logic_vector(DATA_WIDTH-1 downto 0);
            b_i:   in std_logic_vector(DATA_WIDTH-1 downto 0);
            
            max_o: out std_logic_vector(DATA_WIDTH-1 downto 0)
            );
    end component;

begin
    ew_comparator: comparator
    generic map(DATA_WIDTH => 8)
    port map(a_i => pi_column_length_east,
             b_i => pi_column_length_west,
             max_o => ew_max);

    ns_comparator: comparator
    generic map(DATA_WIDTH => 8)
    port map(a_i => pi_column_length_north,
             b_i
              => pi_column_length_south,
             max_o => ns_max);

    passive_mode_check <= pi_error_detected or not(pi_active_mode);

    -- Address and state registers
    STATE_TRANS_PROC:process(pi_clk)
    begin
        if(pi_clk'event and pi_clk = '1') then
            if(pi_rst_n = '1') then
                state_r <= PASSIVE;
                ew_r <= (others=> '0');
                ns_r <= (others=> '0');
            else
                state_r <= state_nxt;
                ew_r <= ew_nxt;
                ns_r <= ns_nxt;
            end if;
         end if;
    end process;


   STATE_GEN_PROC:process(state_nxt, state_r, ew_nxt, ew_r, ns_nxt, ns_r, 
                          pi_column_length_east, pi_column_length_west, pi_column_length_north, pi_column_length_south, 
                          pi_active_mode, pi_error_detected) 
   begin
    
    state_nxt <= state_r;
    ns_nxt <= ns_r;
    ew_nxt <= ew_r;

    case(state_r) is
        when PASSIVE => 

            if(passive_mode_check = '1') then 
                state_nxt <= PASSIVE;
            else
                state_nxt <= GREEN_NS;
            end if;

        when GREEN_NS =>

            ns_nxt <= ns_max;

            if(passive_mode_check = '1') then 
                state_nxt <= PASSIVE;
            else
                if(unsigned(ns_nxt) >= 1) then
                    state_nxt <= GREEN_NS_COUNT;
                else 
                    state_nxt <= RED_YELLOW;
                end if;
            end if;

        when GREEN_NS_COUNT =>
            if(pi_error_detected = '1') then 
                state_nxt <= PASSIVE;
            else
                if(pi_active_mode = '0') then
                    state_nxt <= PASSIVE;
                else
                    ns_nxt <= std_logic_vector(unsigned(ns_r) - 1);
                    if(unsigned(ns_nxt) = to_unsigned(0, 8)) then
                        state_nxt <= RED_YELLOW;
                    else
                        state_nxt <= GREEN_NS_COUNT;
                    end if;
                end if;
            end if;
        when RED_YELLOW =>
            if(passive_mode_check = '1') then 
                state_nxt <= PASSIVE;
            else
                state_nxt <= GREEN_EW;
            end if;
        when GREEN_EW =>
            ew_nxt <= ew_max;

            if(passive_mode_check = '1') then 
                state_nxt <= PASSIVE;
            else
                if(unsigned(ew_nxt) >= 1) then
                    state_nxt <= GREEN_EW_COUNT;
                else 
                    state_nxt <= GREEN_YELLOW;
                end if;
            end if;
        when GREEN_EW_COUNT =>
            if(pi_error_detected = '1') then 
                state_nxt <= PASSIVE;
            else
                if(pi_active_mode = '0') then
                    state_nxt <= PASSIVE;
                else
                    ew_nxt <= std_logic_vector(unsigned(ew_r) - 1);
                    if(unsigned(ew_nxt) = to_unsigned(0, 8)) then
                        state_nxt <= GREEN_YELLOW;
                    else
                        state_nxt <= GREEN_EW_COUNT;
                    end if;
                end if;
            end if;
        when GREEN_YELLOW =>
            if(passive_mode_check = '1') then 
                state_nxt <= PASSIVE;
            else
                state_nxt <= GREEN_NS;
            end if;
        when others =>
            state_nxt <= state_r;
     end case;
   end process;

   OUTPUT_GEN_PROC:process(state_nxt, state_r, ew_nxt, ew_r, ns_nxt, ns_r, 
                          pi_column_length_east, pi_column_length_west, pi_column_length_north, pi_column_length_south, 
                          pi_active_mode, pi_error_detected) 
   begin
    
    po_semaphore_ctrl_east <= YELLOW;
    po_semaphore_ctrl_west <= YELLOW;
    po_semaphore_ctrl_north <= YELLOW;
    po_semaphore_ctrl_south <= YELLOW;
    case(state_r) is
        when PASSIVE =>
        -- use deafult values
        when GREEN_NS =>

            po_semaphore_ctrl_east <= RED;
            po_semaphore_ctrl_west <= RED;

            if(passive_mode_check = '1') then 
            else
                
                po_semaphore_ctrl_north <= GREEN;
                po_semaphore_ctrl_south <= GREEN;
            end if;

        when GREEN_NS_COUNT =>
            po_semaphore_ctrl_east <= RED;
            po_semaphore_ctrl_west <= RED;
            po_semaphore_ctrl_north <= GREEN;
            po_semaphore_ctrl_south <= GREEN;
        when RED_YELLOW =>
            -- use deafult values
        when GREEN_EW =>
            po_semaphore_ctrl_north <= RED;
            po_semaphore_ctrl_south <= RED;

            if(passive_mode_check = '1') then 
            else
                po_semaphore_ctrl_east <= GREEN;
                po_semaphore_ctrl_west <= GREEN;
            end if;
        when GREEN_EW_COUNT =>
            po_semaphore_ctrl_north <= RED;
            po_semaphore_ctrl_south <= RED;
            po_semaphore_ctrl_east <= GREEN;
            po_semaphore_ctrl_west <= GREEN;
        when GREEN_YELLOW =>
            -- use deafult values
        when others =>
            -- use deafult values
     end case;
   end process;
end architecture behavioral;