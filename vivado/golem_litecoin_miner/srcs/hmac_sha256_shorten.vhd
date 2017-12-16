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


entity hmac_sha256_shorten is
  port (
    clk : in std_logic;
    rst : in std_logic;

    key_in_length       : in std_logic_vector(63 downto 0);
    key_in_length_valid : in std_logic;

    key_in       : in  std_logic_vector(31 downto 0);
    key_in_valid : in  std_logic;
    key_in_last  : in  std_logic;
    key_in_ready : out std_logic;

    hash_out_length       : out std_logic_vector(63 downto 0);
    hash_out_length_valid : out std_logic;

    hash_out       : out std_logic_vector(31 downto 0);
    hash_out_valid : out std_logic;
    hash_out_last  : out std_logic;
    hash_out_ready : in  std_logic;

    error_out : out std_logic_vector(3 downto 0)

    );

end hmac_sha256_shorten;

architecture behavioral of hmac_sha256_shorten is


  component sha256_wrapper is
    port (
      clk                     : in  std_logic;
      rst                     : in  std_logic;
      message_in_length       : in  std_logic_vector(63 downto 0);
      message_in_length_valid : in  std_logic;
      message_in              : in  std_logic_vector(31 downto 0);
      message_in_valid        : in  std_logic;
      message_in_last         : in  std_logic;
      message_in_ready        : out std_logic;
      hash_out_length         : out std_logic_vector(63 downto 0);
      hash_out_length_valid   : out std_logic;
      hash_out                : out std_logic_vector(31 downto 0);
      hash_out_valid          : out std_logic;
      hash_out_last           : out std_logic;
      hash_out_ready          : in  std_logic;
      error_out               : out std_logic_vector(3 downto 0));
  end component sha256_wrapper;

  signal short_enable   : std_logic;
  signal short_enable_l : std_logic;


  signal zeros : std_logic_vector(63 downto 0);

  signal hash_out_short       : std_logic_vector(31 downto 0);
  signal hash_out_short_valid : std_logic;
  signal hash_out_short_last  : std_logic;
  signal hash_out_short_ready : std_logic;

  signal hash_out_short_length       : std_logic_vector(63 downto 0);
  signal hash_out_short_length_valid : std_logic;

  signal key_in_valid_short_enable : std_logic;
  signal key_in_ready_short : std_logic;


begin
  zeros <= (others => '0');

  short_enable <= key_in_length_valid when unsigned(key_in_length) > 64 else
                  '0';

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        short_enable_l <= '0';

      else
        if (key_in_length_valid = '1') then
          short_enable_l <= short_enable;

        end if;

        -- de-latch short enable when the sha256 is done
        if (hash_out_short_last = '1' and short_enable_l = '1') then
          short_enable_l <= '0';
        end if;

      end if;
    end if;
  end process;

  -- generate new valid if required
  key_in_valid_short_enable <= '1' when key_in_valid = '1' and (short_enable_l = '1' or short_enable = '1')  else '0';

  -- shorten key
  -- enabled if short_enable_l is set
  sha256_wrapper_1 : sha256_wrapper
    port map (
      clk                     => clk,
      rst                     => rst,
      message_in_length       => key_in_length,
      message_in_length_valid => key_in_length_valid,
      message_in              => key_in,
      message_in_valid        => key_in_valid,
      message_in_last         => key_in_last,
      message_in_ready        => key_in_ready_short,
      hash_out_length         => hash_out_short_length,
      hash_out_length_valid   => hash_out_short_length_valid,
      hash_out                => hash_out_short,
      hash_out_valid          => hash_out_short_valid,
      hash_out_last           => hash_out_short_last,
      hash_out_ready          => hash_out_short_ready,
      error_out               => error_out);


  -- mux the input depending on if short is enabled or not
  hash_out       <= hash_out_short       when (short_enable_l = '1' or short_enable = '1') else key_in;
  hash_out_valid <= hash_out_short_valid when (short_enable_l = '1' or short_enable = '1') else key_in_valid;
  hash_out_last  <= hash_out_short_last  when (short_enable_l = '1' or short_enable = '1') else key_in_last;

  hash_out_length       <= hash_out_short_length       when (short_enable_l = '1' or short_enable = '1') else key_in_length;
  hash_out_length_valid <= hash_out_short_length_valid when (short_enable_l = '1' or short_enable = '1') else key_in_length_valid;


  key_in_ready         <= key_in_ready_short when (short_enable_l = '1' or short_enable = '1') else hash_out_ready;
  hash_out_short_ready <= hash_out_ready;

end behavioral;
