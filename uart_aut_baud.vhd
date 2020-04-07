library ieee;
use ieee.std_logic_1164.all;

entity uart_aut_baud is
	generic(
		DBIT : integer := 8;
		SB_TICK : integer := 16
	);
	port(
		CLOCK_50 : in std_logic;
		KEY      : in std_logic_vector(1 downto 0);
		UART_RXD : in std_logic;
		LEDG     : out std_logic_vector(7 downto 0);
		LEDR     : out std_logic_vector(2 downto 0)
	);
end uart_aut_baud;

architecture arch of uart_aut_baud is
	signal tick, clr_flag : std_logic;
	signal rx_done_tick : std_logic;
	signal rx_data_out : std_logic_vector(7 downto 0);
	signal count_led   : std_logic_vector(16 downto 0);
begin
	uart_rx_unit : entity work.uart_rx(arch)
		generic map(DBIT => DBIT, SB_TICK => SB_TICK)
		port map(clk => CLOCK_50, reset => not(KEY(0)), 
				   rx => UART_RXD, baud_led => LEDR,
					rx_done_tick => rx_done_tick,
					--count_led => count_led,
					dout => rx_data_out);
	flag_buf_unit : entity work.flag_buf(arch)
		generic map(W => DBIT)
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					clr_flag => clr_flag, set_flag => rx_done_tick,
					din => rx_data_out, dout => LEDG, flag => open);
	--LEDR <= "0" & count_led(16 downto 8);
	--LEDG <= count_led(7 downto 0);
end arch;