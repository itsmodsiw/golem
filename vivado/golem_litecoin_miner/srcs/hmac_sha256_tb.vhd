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


entity hmac_sha256_tb is
end hmac_sha256_tb;

architecture behavioral of hmac_sha256_tb is

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


  signal clk  : std_logic := '1';
  signal rst  : std_logic := '1';
  signal rstn : std_logic := '0';

  constant CLK_PERIOD          : time                  := 8 ns;
  constant C_MESSAGE_IN_LENGTH : integer               := 2;
  constant C_KEY_IN_LENGTH     : integer               := 5;
  constant START_COUNT         : unsigned(31 downto 0) := to_unsigned(100, 32);

  signal message_in_counter  : unsigned(31 downto 0);
  signal key_in_counter      : unsigned(31 downto 0);
  signal message_out_counter : unsigned(31 downto 0);
  signal start_counter       : unsigned(31 downto 0);

  signal message_in_busy : std_logic;
  signal key_in_busy     : std_logic;

  type message_array is array (C_MESSAGE_IN_LENGTH-1 downto 0) of std_logic_vector(31 downto 0);
  type key_array is array (C_KEY_IN_LENGTH-1 downto 0) of std_logic_vector(31 downto 0);
  type output_array is array (7 downto 0) of std_logic_vector(31 downto 0);

  signal message_in_array : message_array;
  signal key_in_array     : key_array;

  signal hash_expected : output_array;


  signal message_in_length       : std_logic_vector(63 downto 0);
  signal message_in_length_valid : std_logic;
  signal message_in              : std_logic_vector(31 downto 0);
  signal message_in_valid        : std_logic;
  signal message_in_last         : std_logic;
  signal message_in_ready        : std_logic;
  signal key_in_length           : std_logic_vector(63 downto 0);
  signal key_in_length_valid     : std_logic;
  signal key_in                  : std_logic_vector(31 downto 0);
  signal key_in_valid            : std_logic;
  signal key_in_last             : std_logic;
  signal key_in_ready            : std_logic;
  signal hash_out_length         : std_logic_vector(63 downto 0);
  signal hash_out_length_valid   : std_logic;
  signal hash_out                : std_logic_vector(31 downto 0);
  signal hash_out_valid          : std_logic;
  signal hash_out_last           : std_logic;
  signal hash_out_ready          : std_logic;
  signal error_out               : std_logic_vector(3 downto 0);

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

  message_in_length <= std_logic_vector(to_unsigned(8, 64));

  -- example length 3
  --message_in_array(0)  <= X"61626380";

  -- example length 56

  message_in_array(0) <= X"48692054";
  message_in_array(1) <= X"68657265";

  key_in_length   <= std_logic_vector(to_unsigned(20, 64));
  key_in_array(0) <= X"0b0b0b0b";
  key_in_array(1) <= X"0b0b0b0b";
  key_in_array(2) <= X"0b0b0b0b";
  key_in_array(3) <= X"0b0b0b0b";
  key_in_array(4) <= X"0b0b0b0b";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        message_in_counter <= (others => '0');
        key_in_counter     <= (others => '0');
        start_counter      <= (others => '0');
        message_in_valid   <= '0';
        key_in_valid       <= '0';

        message_in_busy         <= '0';
        key_in_busy             <= '0';
        message_in_length_valid <= '0';
        key_in_length_valid     <= '0';

      else
        message_in_length_valid <= '0';
        key_in_length_valid     <= '0';

        if (message_in_busy = '0' and key_in_busy = '0') then
          if (start_counter < START_COUNT) then
            start_counter <= start_counter + 1;
          else
            message_in_busy         <= '1';
            message_in_length_valid <= '1';
            message_in_valid        <= '1';

            key_in_valid        <= '1';
            key_in_busy         <= '1';
            key_in_length_valid <= '1';
            start_counter       <= (others => '0');

          end if;
        end if;


        if (message_in_busy = '1' and message_in_ready = '1') then
          if (message_in_counter < to_unsigned(C_MESSAGE_IN_LENGTH-1, 32)) then
            message_in_counter <= message_in_counter + 1;

          else
            message_in_counter <= (others => '0');
            message_in_valid   <= '0';

          end if;

        end if;

        if (key_in_busy = '1' and key_in_ready = '1') then
          if (key_in_counter < to_unsigned(C_KEY_IN_LENGTH-1, 32)) then
            key_in_counter <= key_in_counter + 1;

          else
            key_in_counter <= (others => '0');
            key_in_valid   <= '0';

          end if;

        end if;

        --if hash out, clear busies
        if (hash_out_valid = '1' and hash_out_last = '1' and hash_out_ready = '1') then
          key_in_busy     <= '0';
          message_in_busy <= '0';

        end if;


      end if;
    end if;
  end process;

  message_in_last <= '1' when message_in_counter = to_unsigned(C_MESSAGE_IN_LENGTH-1, 32) else '0';

  message_in_gen : for i in 0 to C_MESSAGE_IN_LENGTH-1 generate
    message_in <= message_in_array(i) when (message_in_counter = i) else (others => 'Z');

  end generate message_in_gen;

  key_in_last <= '1' when key_in_counter = to_unsigned(C_KEY_IN_LENGTH-1, 32) else '0';

  key_in_gen : for i in 0 to C_KEY_IN_LENGTH-1 generate
    key_in <= key_in_array(i) when (key_in_counter = i) else (others => 'Z');

  end generate key_in_gen;

  hmac_sha256_2 : hmac_sha256
    port map (
      clk                     => clk,
      rst                     => rst,
      key_in_length           => key_in_length,
      key_in_length_valid     => key_in_length_valid,
      key_in                  => key_in,
      key_in_valid            => key_in_valid,
      key_in_last             => key_in_last,
      key_in_ready            => key_in_ready,
      message_in_length       => message_in_length,
      message_in_length_valid => message_in_length_valid,
      message_in              => message_in,
      message_in_valid        => message_in_valid,
      message_in_last         => message_in_last,
      message_in_ready        => message_in_ready,
      hash_out_length         => hash_out_length,
      hash_out_length_valid   => hash_out_length_valid,
      hash_out                => hash_out,
      hash_out_valid          => hash_out_valid,
      hash_out_last           => hash_out_last,
      hash_out_ready          => hash_out_ready,
      error_out               => error_out);

  hash_out_ready <= '1';

  hash_expected(0) <= X"b0344c61";
  hash_expected(1) <= X"d8db3853";
  hash_expected(2) <= X"5ca8afce";
  hash_expected(3) <= X"af0bf12b";
  hash_expected(4) <= X"881dc200";
  hash_expected(5) <= X"c9833da7";
  hash_expected(6) <= X"26e9376c";
  hash_expected(7) <= X"2e32cff7";

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

  pass_flag <= '1' when hash_error = X"00" and hash_error_valid = '1'  else '0';
  fail_flag <= '1' when hash_error /= X"00" and hash_error_valid = '1' else '0';


end behavioral;
