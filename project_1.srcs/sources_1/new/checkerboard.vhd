library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.math_real."ceil";
use IEEE.math_real."log2";

entity checkerboard is 
  generic ( N : integer := 2); -- checkerboard cell size
  port (
    clk : in std_logic;
    rst : in std_logic;
    -- input stream
    inp_tvalid : in std_logic; -- valid input marker
    inp_tlast : in std_logic; -- last pixel marker
    inp_tuser : in std_logic_vector(0 downto 0); -- first pixel of frame marker
    inp_tdata : in std_logic_vector(7 downto 0);
    -- output stream
    outp_tvalid : out std_logic; -- valid output marker
    outp_tlast : out std_logic;
    outp_tuser : out std_logic_vector(0 downto 0);
    outp_tdata : out std_logic_vector(7 downto 0)
  );
end checkerboard;

architecture rtl of checkerboard is
constant BLACK : std_logic_vector(7 downto 0) := "00000000";
constant WHITE : std_logic_vector(7 downto 0) := "11111111";
constant M : integer := integer(ceil(log2(real(N)))); -- how many bits needed to code the N

signal hor_step_counter : unsigned(M - 1 downto 0);
signal vert_step_counter : unsigned(M - 1 downto 0);

signal intensity : std_logic_vector(7 downto 0);
signal start_of_line_is_white : std_logic;
signal should_change_color : std_logic;
signal should_change_start_of_line_color : std_logic;
signal should_reset_to_start_of_line_color : std_logic;

begin
    process (clk) is 
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                outp_tvalid <= '0';
                outp_tlast <= '0';
                outp_tuser <= "0";
                
                hor_step_counter <= conv_unsigned(0, M);
                vert_step_counter <= conv_unsigned(0, M);
                
                intensity <= BLACK;
                start_of_line_is_white <= '0';
                should_change_color <= '0';
                should_change_start_of_line_color <= '0';
                should_reset_to_start_of_line_color <= '0';
            else
                if inp_tvalid = '1' then
                    outp_tvalid <= '1';
                                                          
                    if inp_tuser = "1" then 
                        outp_tuser <= "1";
                        hor_step_counter <= conv_unsigned(0, M);
                        vert_step_counter <= conv_unsigned(0, M);
                        intensity <= WHITE;
                        start_of_line_is_white <= '1';
                        should_change_color <= '0';
                        should_change_start_of_line_color <= '0';
                        should_reset_to_start_of_line_color <= '0';
                    else
                        outp_tuser <= "0";
                    end if;
                    
                    if should_reset_to_start_of_line_color = '1' and inp_tuser = "0" then
                        should_reset_to_start_of_line_color <= '0';
                        if start_of_line_is_white = '1' then
                            intensity <= WHITE;
                        else
                            intensity <= BLACK;
                        end if;
                    end if;
                    
                    if should_change_start_of_line_color = '1' and inp_tuser = "0" then
                        should_change_start_of_line_color <= '0';
                        if start_of_line_is_white = '1' then
                            start_of_line_is_white <= '0';
                            intensity <= BLACK;
                        else
                            start_of_line_is_white <= '1';
                            intensity <= WHITE;
                        end if;
                    end if;
                    
                    if should_change_color = '1' then
                        should_change_color <= '0';
                        if intensity(0) = '1' then
                            intensity <= BLACK;
                        else
                            intensity <= WHITE;
                        end if;
                    end if;
                    
                    if hor_step_counter < conv_unsigned(N - 1, M) then
                        hor_step_counter <= hor_step_counter + conv_unsigned(1, M);
                    else
                        hor_step_counter <= conv_unsigned(0, M);
                        should_change_color <= '1';
                    end if;                 
                    
                    if inp_tlast = '1' then
                        outp_tlast <= '1';
                        hor_step_counter <= conv_unsigned(0, M);
                        should_change_color <= '0';
                        if vert_step_counter < conv_unsigned(N - 1, M) then
                            vert_step_counter <= vert_step_counter + conv_unsigned(1, M);
                            should_reset_to_start_of_line_color <= '1';
                        else
                            vert_step_counter <= conv_unsigned(0, M);
                            should_change_start_of_line_color <= '1';
                        end if;
                    else
                        outp_tlast <= '0';
                    end if;
                else
                    outp_tvalid <= '0'; -- invalid when input is valid
                    outp_tlast <= '0';
                    outp_tuser <= "0";
                end if;    
            end if;
        end if;
    end process;
    
    outp_tdata <= intensity;

end rtl;