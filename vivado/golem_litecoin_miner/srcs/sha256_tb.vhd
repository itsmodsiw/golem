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


entity sha256_tb is
end sha256_tb;

architecture behavioral of sha256_tb is

  component sha256 is
    port (
      clk              : in  std_logic;
      rst              : in  std_logic;
      message_in       : in  std_logic_vector(31 downto 0);
      message_in_valid : in  std_logic;
      message_in_last  : in  std_logic;
      message_in_ready : out std_logic;
      hash_out         : out std_logic_vector(31 downto 0);
      hash_out_valid   : out std_logic;
      hash_out_last    : out std_logic;
      hash_out_ready   : in  std_logic;
      error_out        : out std_logic_vector(3 downto 0));
  end component sha256;


  signal clk  : std_logic := '1';
  signal rst  : std_logic := '1';
  signal rstn : std_logic := '0';

  constant CLK_PERIOD        : time                  := 8 ns;
  constant MESSAGE_IN_LENGTH : integer               := 32;
  constant START_COUNT       : unsigned(31 downto 0) := to_unsigned(100, 32);

  signal message_in_counter  : unsigned(31 downto 0);
  signal message_out_counter : unsigned(31 downto 0);
  signal start_counter       : unsigned(31 downto 0);

  signal message_in_busy : std_logic;



  type input_array is array (MESSAGE_IN_LENGTH-1 downto 0) of std_logic_vector(31 downto 0);
  type output_array is array (7 downto 0) of std_logic_vector(31 downto 0);

  signal message_in_array : input_array;
  signal hash_expected    : output_array;


  signal message_in       : std_logic_vector(31 downto 0);
  signal message_in_valid : std_logic;
  signal message_in_last  : std_logic;
  signal message_in_ready : std_logic;
  signal hash_out         : std_logic_vector(31 downto 0);
  signal hash_out_valid   : std_logic;
  signal hash_out_last    : std_logic;
  signal hash_out_ready   : std_logic;
  signal error_out        : std_logic_vector(3 downto 0);

  signal hash_error       : std_logic_vector(7 downto 0);
  signal hash_error_valid : std_logic;
  signal pass_flag        : std_logic;
  signal fail_flag        : std_logic;

begin

  hash_out_ready <= '1';

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

  rstn <= not rst;

  -- example length 16
  -- message_in_array(0)  <= X"61626380";
  -- message_in_array(1)  <= X"00000000";
  -- message_in_array(2)  <= X"00000000";
  -- message_in_array(3)  <= X"00000000";
  -- message_in_array(4)  <= X"00000000";
  -- message_in_array(5)  <= X"00000000";
  -- message_in_array(6)  <= X"00000000";
  -- message_in_array(7)  <= X"00000000";
  -- message_in_array(8)  <= X"00000000";
  -- message_in_array(9)  <= X"00000000";
  -- message_in_array(10) <= X"00000000";
  -- message_in_array(11) <= X"00000000";
  -- message_in_array(12) <= X"00000000";
  -- message_in_array(13) <= X"00000000";
  -- message_in_array(14) <= X"00000000";
  -- message_in_array(15) <= X"00000018";

  -- example length 32

  message_in_array(0)  <= X"61626364";
  message_in_array(1)  <= X"62636465";
  message_in_array(2)  <= X"63646566";
  message_in_array(3)  <= X"64656667";
  message_in_array(4)  <= X"65666768";
  message_in_array(5)  <= X"66676869";
  message_in_array(6)  <= X"6768696a";
  message_in_array(7)  <= X"68696a6b";
  message_in_array(8)  <= X"696a6b6c";
  message_in_array(9)  <= X"6a6b6c6d";
  message_in_array(10) <= X"6b6c6d6e";
  message_in_array(11) <= X"6c6d6e6f";
  message_in_array(12) <= X"6d6e6f70";
  message_in_array(13) <= X"6e6f7071";
  message_in_array(14) <= X"80000000";
  message_in_array(15) <= X"00000000";
  message_in_array(16) <= X"00000000";
  message_in_array(17) <= X"00000000";
  message_in_array(18) <= X"00000000";
  message_in_array(19) <= X"00000000";
  message_in_array(20) <= X"00000000";
  message_in_array(21) <= X"00000000";
  message_in_array(22) <= X"00000000";
  message_in_array(23) <= X"00000000";
  message_in_array(24) <= X"00000000";
  message_in_array(25) <= X"00000000";
  message_in_array(26) <= X"00000000";
  message_in_array(27) <= X"00000000";
  message_in_array(28) <= X"00000000";
  message_in_array(29) <= X"00000000";
  message_in_array(30) <= X"00000000";
  message_in_array(31) <= X"000001c0";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        message_in_counter <= (others => '0');
        start_counter      <= (others => '0');

        message_in_busy <= '0';

      else
        if (start_counter < START_COUNT) then
          start_counter <= start_counter + 1;
        else
          message_in_busy <= '1';

        end if;

        if (message_in_busy = '1' and message_in_ready = '1') then
          if (message_in_counter < to_unsigned(MESSAGE_IN_LENGTH-1, 32)) then
            message_in_counter <= message_in_counter + 1;

          else
            message_in_counter <= (others => '0');
            message_in_busy    <= '0';

          end if;

        end if;

      end if;
    end if;
  end process;

  message_in_valid <= message_in_busy;
  message_in_last  <= '1' when message_in_counter = to_unsigned(MESSAGE_IN_LENGTH-1, 32) else '0';

  message_in_gen : for i in 0 to MESSAGE_IN_LENGTH-1 generate
    message_in <= message_in_array(i) when (message_in_counter = i) else (others => 'Z');

  end generate message_in_gen;

  sha256_1 : sha256
    port map (
      clk              => clk,
      rst              => rst,
      message_in       => message_in,
      message_in_valid => message_in_valid,
      message_in_last  => message_in_last,
      message_in_ready => message_in_ready,
      hash_out         => hash_out,
      hash_out_valid   => hash_out_valid,
      hash_out_last    => hash_out_last,
      hash_out_ready   => hash_out_ready,
      error_out        => error_out);


  -- check block_array out.
  -- 16 length example
  -- hash_expected(0) <= X"ba7816bf";
  -- hash_expected(1) <= X"8f01cfea";
  -- hash_expected(2) <= X"414140de";
  -- hash_expected(3) <= X"5dae2223";
  -- hash_expected(4) <= X"b00361a3";
  -- hash_expected(5) <= X"96177a9c";
  -- hash_expected(6) <= X"b410ff61";
  -- hash_expected(7) <= X"f20015ad";

  -- 32 length example
  hash_expected(0) <= X"248d6a61";
  hash_expected(1) <= X"d20638b8";
  hash_expected(2) <= X"e5c02693";
  hash_expected(3) <= X"0c3e6039";
  hash_expected(4) <= X"a33ce459";
  hash_expected(5) <= X"64ff2167";
  hash_expected(6) <= X"f6ecedd4";
  hash_expected(7) <= X"19db06c1";


  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        hash_error       <= (others => '0');
        hash_error_valid <= '0';

        message_out_counter <= (others => '0');

      else
        hash_error_valid <= '0';

        if (hash_out_valid = '1' and hash_out_ready = '1') then
          if (hash_out_last = '1') then
            message_out_counter <= (others => '0');

          else
            message_out_counter <= message_out_counter + 1;

          end if;
        end if;

        for i in 7 downto 0 loop
          if (message_out_counter = i) then
            if (hash_expected(i) = hash_out) then
              hash_error(i) <= '0';
            else
              hash_error(i) <= '1';
            end if;

          end if;

        end loop;  -- i

        if (message_out_counter = 7) then
          hash_error_valid <= '1';
        end if;

      end if;
    end if;
  end process;

  pass_flag <= '1' when hash_error = X"00" and hash_error_valid = '1' else '0';
  fail_flag <= '1' when hash_error /= X"00" and hash_error_valid = '1' else '0';


end behavioral;
