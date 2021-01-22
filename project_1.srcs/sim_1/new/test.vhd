library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity test is end entity;

architecture rtl of test is
constant BLACK : std_logic_vector(7 downto 0) := "00000000";
constant WHITE : std_logic_vector(7 downto 0) := "11111111";

signal clk : std_logic;
signal rst : std_logic;
signal inp_tvalid : std_logic;
signal inp_tlast : std_logic;
signal inp_tuser : std_logic_vector(0 downto 0);
signal inp_tdata : std_logic_vector(7 downto 0);
signal outp_tdata : std_logic_vector(7 downto 0);

procedure delay(n : integer; signal clk : std_logic) is
begin
    for i in 1 to n loop
        wait until clk'event and clk = '1';
    end loop;
end delay;

begin

DUT : entity work.checkerboard port map (
    clk => clk, 
    rst => rst, 
    inp_tvalid => inp_tvalid, 
    inp_tlast => inp_tlast, 
    inp_tuser => inp_tuser, 
    inp_tdata => inp_tdata,
    outp_tdata => outp_tdata
    );

rst <= '1', '0' after 20 ns;

process is
begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
end process;

process is
begin
    delay(3, clk);
    
    -- going to send 2 frames
    -- frame 1
    -- 000000
    -- 000000
    -- 00000
    -- frame 2
    -- 00000
    -- 00000
    -- expected output is
    -- frame 1
    -- 110011
    -- 110011
    -- 00110
    -- frame 2
    -- 11001
    -- 11001 
    -- where 1 is the white color and 0 is the black
    inp_tdata <= "00000000"; -- all black image
    inp_tvalid <= '1';
    inp_tlast <= '0';
    -- frame 1
    -- line 1
    inp_tuser <= "1";
    delay(1, clk);
    inp_tuser <= "0";
    delay(4, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    inp_tlast <= '1';
    delay(1, clk);
    assert (outp_tdata=WHITE) report "Test failed" severity failure;
    -- line 2
    inp_tlast <= '0';
    delay(5, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    inp_tlast <= '1';
    delay(1, clk);
    assert (outp_tdata=WHITE) report "Test failed" severity failure;
    -- line 3
    inp_tlast <= '0';
    delay(4, clk);
    assert (outp_tdata=WHITE) report "Test failed" severity failure;
    inp_tlast <= '1';
    delay(1, clk);
    assert (outp_tdata=WHITE) report "Test failed" severity failure;
    inp_tlast <= '0';
    -- frame 2
    -- line 1
    inp_tuser <= "1";
    delay(1, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    inp_tuser <= "0";
    delay(3, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    inp_tlast <= '1';
    delay(1, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    -- line 2
    inp_tlast <= '0';
    delay(4, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    inp_tlast <= '1';
    delay(1, clk);
    assert (outp_tdata=BLACK) report "Test failed" severity failure;
    -- finish
    inp_tvalid <= '0'; -- pause in video streaming
    delay(100, clk);
end process;

end rtl;
