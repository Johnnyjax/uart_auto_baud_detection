library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
	generic(
		DBIT : integer := 8;
		SB_TICK : integer := 16
	);
	port(
		clk, reset : in std_logic;
		rx : in std_logic;
		rx_done_tick : out std_logic;
		dout : out std_logic_vector(7 downto 0);
		baud_led : out std_logic_vector(2 downto 0)
		--count_led : out std_logic_vector(16 downto 0)
	);
end uart_rx;

architecture arch of uart_rx is
	type state_type is (baud, idle0, idle1, idle2, start, data, stop);
	signal state_reg, state_next : state_type;
	signal s_reg, s_next : unsigned(3 downto 0);
	signal bcnt_reg, bcnt_next : unsigned(16 downto 0);
	signal n_reg, n_next : unsigned(2 downto 0);
	signal b_reg, b_next : std_logic_vector(7 downto 0);
	signal r_reg, r_next : unsigned(12 downto 0);
	signal m : integer range 0 to 700;
	signal s_tick : std_logic;
begin
	m <= 651 when bcnt_reg > 72000 else
		  326 when bcnt_reg > 36000 and bcnt_reg < 37000 else 
		  163 when bcnt_reg > 18000 and bcnt_reg < 19000 else
		  0;
	baud_led <= "001" when bcnt_reg > 72000 else
		         "010" when bcnt_reg > 36000 and bcnt_reg < 37000 else 
		         "100" when bcnt_reg > 18000 and bcnt_reg < 19000 else 
		         "000";
	--count_led <= std_logic_vector(bcnt_reg);
	process(clk, reset)
	begin
		if(reset = '1') then	
			state_reg <= idle0;
			s_reg <= (others => '0');
			n_reg <= (others => '0');
			b_reg <= (others => '0');
			bcnt_reg <= (others => '0');
			r_reg <= (others => '0');
		elsif (clk'event and clk = '1') then	
			state_reg <= state_next;
			s_reg <= s_next;
			n_reg <= n_next;
			b_reg <= b_next;
			bcnt_reg <= bcnt_next;
			r_reg <= r_next;
		end if;
	end process;
	
	process(state_reg, s_reg, n_reg, b_reg, bcnt_reg, s_tick, rx)
	begin
		state_next <= state_reg;
		s_next <= s_reg;
		n_next <= n_reg;
		b_next <= b_reg;
		bcnt_next <= bcnt_reg;
		rx_done_tick <= '0';
		case state_reg is
			when idle0 =>
				if rx = '0' then
					state_next <= idle1;
					bcnt_next <= (others => '0');
				end if;
			when idle1 => 
				if rx = '1' then
					state_next <= baud;
				end if;
			when baud =>
				if rx = '1' then
					bcnt_next <= bcnt_reg + 1;
				else
					state_next <= idle2;
				end if;
			when idle2 =>
				if rx = '0' then
					state_next <= start;
					s_next <= (others => '0');
				end if;
			when start =>
				if(s_tick = '1') then
					if(s_reg = 7) then
						state_next <= data;
						s_next <= (others => '0');
						n_next <= (others => '0');
					else
						s_next <= s_reg + 1;
					end if;
				end if;
			when data =>
				if (s_tick = '1') then
					if s_reg  = 15 then
						s_next <= (others => '0');
						b_next <= rx & b_reg(7 downto 1);
						if n_reg = (DBIT - 1) then
							state_next <= stop;
						else 
							n_next <= n_reg + 1;
						end if;
					else
						s_next <= s_reg + 1;
					end if;
				end if;
			when stop =>
				if(s_tick = '1') then
					if s_reg = (SB_TICK - 1) then
						state_next <= idle2;
						rx_done_tick <= '1';
					else
						s_next <= s_reg + 1;
					end if;
				end if;
		end case;
	end process;
	r_next <= (others => '0') when r_reg = m-1 else
				 r_reg + 1;
	s_tick <= '1' when r_reg = (m-1) else '0';
	dout <= b_reg;
end arch;