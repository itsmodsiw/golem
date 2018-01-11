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


entity block_mix_tb is
end block_mix_tb;

architecture behavioral of block_mix_tb is


  component block_mix is
    generic (
      BLOCK_SIZE      : integer := 8;   --max 128
      BLOCK_SIZE_LOG2 : integer := 3;   --max 128
      NUM_ROUNDS      : integer := 8
      );
    port (
      clk : in std_logic;
      rst : in std_logic;

      block_array_in       : in  block_array;
      block_array_in_valid : in  std_logic;
      block_array_in_ready : out std_logic;

      block_array_out       : out block_array;
      block_array_out_valid : out std_logic);

  end component;

  signal clk : std_logic := '1';
  signal rst : std_logic := '1';


  signal block_array_in       : block_array;
  signal block_array_in_valid : std_logic := '0';
  signal block_array_in_ready : std_logic;

  signal block_array_out       : block_array;
  signal block_array_out_valid : std_logic;

  signal block_array_expected    : block_array;
  signal block_array_error_valid : std_logic;

  type block_error is array (1 downto 0) of std_logic_vector(15 downto 0);

  signal block_array_error : block_error;

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

  block_array_in(0)  <= X"650BCEF7";
  block_array_in(1)  <= X"A4722D3D";
  block_array_in(2)  <= X"ABF58C10";
  block_array_in(3)  <= X"DDFF12E9";
  block_array_in(4)  <= X"DB167677";
  block_array_in(5)  <= X"0EA727BB";
  block_array_in(6)  <= X"AEF30482";
  block_array_in(7)  <= X"AD6F0F2D";
  block_array_in(8)  <= X"488FF689";
  block_array_in(9)  <= X"7BE8D111";
  block_array_in(10) <= X"40D73BCC";
  block_array_in(11) <= X"29FD9F0A";
  block_array_in(12) <= X"84014F09";
  block_array_in(13) <= X"F3749563";
  block_array_in(14) <= X"31A1E59A";
  block_array_in(15) <= X"D7BC1752";
  block_array_in(16) <= X"44914989";
  block_array_in(17) <= X"22BB1372";
  block_array_in(18) <= X"4DB5256C";
  block_array_in(19) <= X"FB7063A8";
  block_array_in(20) <= X"804398CD";
  block_array_in(21) <= X"BB664637";
  block_array_in(22) <= X"BFB5FC8F";
  block_array_in(23) <= X"B054C240";
  block_array_in(24) <= X"517CD267";
  block_array_in(25) <= X"FED54ACE";
  block_array_in(26) <= X"0BC929D8";
  block_array_in(27) <= X"1B575A50";
  block_array_in(28) <= X"AD1C4D7F";
  block_array_in(29) <= X"DA3C526A";
  block_array_in(30) <= X"BC670E77";
  block_array_in(31) <= X"897EAFEA";


  process
  begin

    block_array_in_valid <= '0';
    wait for CLK_PERIOD*100;
    block_array_in_valid <= '1';
    wait for CLK_PERIOD;
    block_array_in_valid <= '0';
    wait;
  end process;


  -- uut


  block_mix_i : block_mix
    generic map (
      BLOCK_SIZE      => 1,
      BLOCK_SIZE_LOG2 => 0,
      NUM_ROUNDS      => 8
      )
    port map (
      clk                   => clk,
      rst                   => rst,
      block_array_in        => block_array_in,
      block_array_in_valid  => block_array_in_valid,
      block_array_in_ready  => block_array_in_ready,
      block_array_out       => block_array_out,
      block_array_out_valid => block_array_out_valid
      );

  -- check block_array out.
  block_array_expected(0)  <= X"9C851FA4";
  block_array_expected(1)  <= X"99CC0866";
  block_array_expected(2)  <= X"CBCA813B";
  block_array_expected(3)  <= X"05EF0C02";
  block_array_expected(4)  <= X"81214B04";
  block_array_expected(5)  <= X"7D33FDA2";
  block_array_expected(6)  <= X"631C7BFD";
  block_array_expected(7)  <= X"292F6896";
  block_array_expected(8)  <= X"683139B4";
  block_array_expected(9)  <= X"BCE6C9E3";
  block_array_expected(10) <= X"B7C56BFE";
  block_array_expected(11) <= X"BA966DA0";
  block_array_expected(12) <= X"10CC24E4";
  block_array_expected(13) <= X"5C74912C";
  block_array_expected(14) <= X"3D67AD24";
  block_array_expected(15) <= X"818F61C7";
  block_array_expected(16) <= X"75C9ED20";
  block_array_expected(17) <= X"A8813832";
  block_array_expected(18) <= X"4CF64005";
  block_array_expected(19) <= X"3CCD2D16";
  block_array_expected(20) <= X"FE7C0721";
  block_array_expected(21) <= X"E25F8D5F";
  block_array_expected(22) <= X"8F16A4B1";
  block_array_expected(23) <= X"B7783695";
  block_array_expected(24) <= X"803D3B7D";
  block_array_expected(25) <= X"ABE4603B";
  block_array_expected(26) <= X"E5960992";
  block_array_expected(27) <= X"B6534D9B";
  block_array_expected(28) <= X"58222A5D";
  block_array_expected(29) <= X"F5EDD577";
  block_array_expected(30) <= X"F1B92C84";
  block_array_expected(31) <= X"25E4EF4E";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        block_array_error       <= (others => (others => '0'));
        block_array_error_valid <= '0';

      else
        block_array_error_valid <= block_array_out_valid;

        for j in 0 to 1 loop
          for i in 0 to 15 loop
            if (block_array_out(j)(i) = block_array_expected(j)(i)) then
              block_array_error(j)(i) <= '0';
            else
              block_array_error(j)(i) <= '1';
            end if;
          end loop;
        end loop;
      end if;
    end if;
  end process;

  pass_flag <= '1' when block_array_error(0) = X"0000" and block_array_error(1) = X"0000" and block_array_error_valid = '1'    else '0';
  fail_flag <= '1' when (block_array_error(0) /= X"0000" or block_array_error(1) /= X"0000") and block_array_error_valid = '1' else '0';

end behavioral;
