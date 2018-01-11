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


entity pbkdf_function is
  port (
    clk : in std_logic;
    rst : in std_logic;

    iteration : in std_logic_vector(31 downto 0);
    iteration_valid : in std_logic;

    -- maps to sha key
    password_in_length       : in std_logic_vector(63 downto 0);
    password_in_length_valid : in std_logic;

    password_in       : in  std_logic_vector(31 downto 0);
    password_in_valid : in  std_logic;
    password_in_last  : in  std_logic;
    password_in_ready : out std_logic;

    -- maps to sha message
    salt_in_length       : in std_logic_vector(63 downto 0);
    salt_in_length_valid : in std_logic;

    salt_in       : in  std_logic_vector(31 downto 0);
    salt_in_valid : in  std_logic;
    salt_in_last  : in  std_logic;
    salt_in_ready : out std_logic;

    hash_out_length       : out std_logic_vector(63 downto 0);
    hash_out_length_valid : out std_logic;

    hash_out       : out std_logic_vector(31 downto 0);
    hash_out_valid : out std_logic;
    hash_out_last  : out std_logic;
    hash_out_ready : in  std_logic;


    error_out : out std_logic_vector(3 downto 0)

    );

end pbkdf_function;

architecture behavioral of pbkdf_function is

  component hmac_sha256 is
    port (
      clk                     : in  std_logic;
      rst                     : in  std_logic;
      key_in_length           : in  std_logic_vector(63 downto 0);
      key_in_length_valid     : in  std_logic;
      key_in                  : in  std_logic_vector(31 downto 0);
      key_in_valid            : in  std_logic;
      key_in_last             : in  std_logic;
      key_in_ready            : out std_logic;
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
  end component hmac_sha256;

  signal salt_in_length_new : std_logic_vector(63 downto 0);

  signal salt_in_last_new : std_logic;
  signal salt_in_valid_new : std_logic;
  signal salt_in_ready_new : std_logic;
  signal salt_in_ready_i : std_logic;
  signal salt_in_new : std_logic_vector(31 downto 0);

  signal iteration_i : std_logic_vector(31 downto 0);

begin

  salt_in_length_new <= std_logic_vector(unsigned(salt_in_length) + 4);

  -- apply the prf to the input
  -- but append iteration_i onto the end of the salt input and extend the length by 1
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        salt_in_last_new <= '0';
        iteration_i <= (others => '0');

      else
        --delay last by 1
        if (salt_in_ready_i = '1' and salt_in_last = '1') then
          salt_in_last_new <= salt_in_last;
        else
          salt_in_last_new <= '0';
        end if;


        if (iteration_valid = '1') then
          iteration_i <= iteration;

        end if;
      end if;
    end if;
  end process;

  salt_in_valid_new <= salt_in_valid or salt_in_last_new;
  salt_in_new <= salt_in when salt_in_last_new = '0' else iteration_i;
  salt_in_ready_new <= salt_in_ready_i when salt_in_last_new = '0' else '0';

  hmac_sha256_1 : hmac_sha256
    port map (
      clk                     => clk,
      rst                     => rst,
      key_in_length           => password_in_length,
      key_in_length_valid     => password_in_length_valid,
      key_in                  => password_in,
      key_in_valid            => password_in_valid,
      key_in_last             => password_in_last,
      key_in_ready            => password_in_ready,
      message_in_length       => salt_in_length_new,
      message_in_length_valid => salt_in_length_valid,
      message_in              => salt_in_new,
      message_in_valid        => salt_in_valid_new,
      message_in_last         => salt_in_last_new,
      message_in_ready        => salt_in_ready_i,
      hash_out_length         => hash_out_length,
      hash_out_length_valid   => hash_out_length_valid,
      hash_out                => hash_out,
      hash_out_valid          => hash_out_valid,
      hash_out_last           => hash_out_last,
      hash_out_ready          => hash_out_ready,
      error_out               => error_out);

  salt_in_ready <= salt_in_ready_new;

end behavioral;
