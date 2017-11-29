----------------------------------------------------------------------------------
-- Company:
-- Engineer:    Stacey Rieck
--
-- Create Date: 27.01.2014 12:23:11
-- Design Name: Golem Litecoin Miner
-- Module Name:
-- Project Name:
-- Target Devices: Zynq
-- Tool Versions: Vivado 2017.1
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.common.all;


entity salsa820_tb is
end salsa820_tb;

architecture behavioral of salsa820_tb is


  component salsa820
    generic (
      NUM_ROUNDS : integer := 8
      );
    port (
      clk : in std_logic;
      rst : in std_logic;

      word_in       : in  word_array;
      word_in_valid : in  std_logic;
      word_in_ready : out std_logic;

      word_out       : out word_array;
      word_out_valid : out std_logic);

  end component;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';


  signal word_in       : word_array;
  signal word_in_valid : std_logic := '0';
  signal word_in_ready : std_logic;

  signal word_out       : word_array;
  signal word_out_valid : std_logic;

  signal word_expected    : word_array;
  signal word_error_valid : std_logic;
  signal word_error       : std_logic_vector(15 downto 0);

  signal fail_flag : std_logic;
  signal pass_flag : std_logic;

  signal cycle_counter : unsigned(31 downto 0);

  constant CLK_PERIOD : time := 8 ns;

begin

  -- generate clk/rst
  process
  begin
    clk <= '1';
    wait for CLK_PERIOD/2;
    clk <= '0';
    wait for CLK_PERIOD/2;
  end process;

  process
  begin
    wait for CLK_PERIOD*10;
    rst <= '1';
    wait for CLK_PERIOD*2;
    rst <= '0';
    wait;
  end process;

  word_in(0)  <= X"219A877E";
  word_in(1)  <= X"86C93E4F";
  word_in(2)  <= X"E640A97C";
  word_in(3)  <= X"268F7141";
  word_in(4)  <= X"5B55EEBA";
  word_in(5)  <= X"B5C1618C";
  word_in(6)  <= X"1146F80D";
  word_in(7)  <= X"1D3BCD6D";
  word_in(8)  <= X"19F324EE";
  word_in(9)  <= X"853D9BDF";
  word_in(10) <= X"4B1E1214";
  word_in(11) <= X"32AAC55A";
  word_in(12) <= X"291D0276";
  word_in(13) <= X"2948C709";
  word_in(14) <= X"8DC6EBED";
  word_in(15) <= X"5EC2B8B8";


  process
  begin

    word_in_valid <= '0';
    wait for CLK_PERIOD*100;
    word_in_valid <= '1';
    wait for CLK_PERIOD;
    word_in_valid <= '0';
    wait;
  end process;


  -- uut
  salsa820_i : salsa820
    generic map (
      NUM_ROUNDS => 8
      )
    port map (
      clk            => clk,
      rst            => rst,
      word_in        => word_in,
      word_in_valid  => word_in_valid,
      word_in_ready  => word_in_ready,
      word_out       => word_out,
      word_out_valid => word_out_valid
      );

  -- check word out.
  word_expected(0)  <= X"9C851FA4";
  word_expected(1)  <= X"99CC0866";
  word_expected(2)  <= X"CBCA813B";
  word_expected(3)  <= X"05EF0C02";
  word_expected(4)  <= X"81214B04";
  word_expected(5)  <= X"7D33FDA2";
  word_expected(6)  <= X"631C7BFD";
  word_expected(7)  <= X"292F6896";
  word_expected(8)  <= X"683139B4";
  word_expected(9)  <= X"BCE6C9E3";
  word_expected(10) <= X"B7C56BFE";
  word_expected(11) <= X"BA966DA0";
  word_expected(12) <= X"10CC24E4";
  word_expected(13) <= X"5C74912C";
  word_expected(14) <= X"3D67AD24";
  word_expected(15) <= X"818F61C7";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        word_error       <= (others => '0');
        word_error_valid <= '0';

      else
        word_error_valid <= word_out_valid;

        for i in 0 to 15 loop
          if (word_out(i) = word_expected(i)) then
            word_error(i) <= '0';
          else
            word_error(i) <= '1';
          end if;
        end loop;
      end if;
    end if;
  end process;

  pass_flag <= '1' when word_error = X"0000" and word_error_valid = '1' else '0';
  fail_flag <= '1' when word_error /= X"0000" and word_error_valid = '1' else '0';

end behavioral;
