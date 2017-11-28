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

  word_in(0)  <= X"61707865";
  word_in(1)  <= X"04030201";
  word_in(2)  <= X"08070605";
  word_in(3)  <= X"0c0b0a09";
  word_in(4)  <= X"100f0e0d";
  word_in(5)  <= X"3320646e";
  word_in(6)  <= X"01040103";
  word_in(7)  <= X"06020905";
  word_in(8)  <= X"00000007";
  word_in(9)  <= X"00000000";
  word_in(10) <= X"79622d32";
  word_in(11) <= X"14131211";
  word_in(12) <= X"18171615";
  word_in(13) <= X"1c1b1a19";
  word_in(14) <= X"201f1e1d";
  word_in(15) <= X"6b206574";


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
      NUM_ROUNDS => 20
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
  word_expected(0)  <= X"b9a205a3";
  word_expected(1)  <= X"0695e150";
  word_expected(2)  <= X"aa94881a";
  word_expected(3)  <= X"adb7b12c";
  word_expected(4)  <= X"798942d4";
  word_expected(5)  <= X"26107016";
  word_expected(6)  <= X"64edb1a4";
  word_expected(7)  <= X"2d27173f";
  word_expected(8)  <= X"b1c7f1fa";
  word_expected(9)  <= X"62066edc";
  word_expected(10) <= X"e035fa23";
  word_expected(11) <= X"c4496f04";
  word_expected(12) <= X"2131e6b3";
  word_expected(13) <= X"810bde28";
  word_expected(14) <= X"f62cb407";
  word_expected(15) <= X"6bdede3d";

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
