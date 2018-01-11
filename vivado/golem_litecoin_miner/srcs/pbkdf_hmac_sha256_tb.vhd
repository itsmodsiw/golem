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


entity pbkdf_hmac_sha256_tb is
end pbkdf_hmac_sha256_tb;

architecture behavioral of pbkdf_hmac_sha256_tb is

  component pbkdf_hmac_sha256  is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      iteration                : in  std_logic_vector(31 downto 0);
      iteration_valid          : in  std_logic;
      password_in_length       : in  std_logic_vector(63 downto 0);
      password_in_length_valid : in  std_logic;
      password_in              : in  std_logic_vector(31 downto 0);
      password_in_valid        : in  std_logic;
      password_in_last         : in  std_logic;
      password_in_ready        : out std_logic;
      salt_in_length           : in  std_logic_vector(63 downto 0);
      salt_in_length_valid     : in  std_logic;
      salt_in                  : in  std_logic_vector(31 downto 0);
      salt_in_valid            : in  std_logic;
      salt_in_last             : in  std_logic;
      salt_in_ready            : out std_logic;
      hash_out_length          : out std_logic_vector(63 downto 0);
      hash_out_length_valid    : out std_logic;
      hash_out                 : out std_logic_vector(31 downto 0);
      hash_out_valid           : out std_logic;
      hash_out_last            : out std_logic;
      hash_out_ready           : in  std_logic;
      error_out                : out std_logic_vector(3 downto 0));
  end component pbkdf_hmac_sha256;

  signal clk  : std_logic := '1';
  signal rst  : std_logic := '1';
  signal rstn : std_logic := '0';

  constant CLK_PERIOD           : time                  := 8 ns;
  constant C_SALT_IN_LENGTH     : integer               := 1;
  constant C_PASSWORD_IN_LENGTH : integer               := 2;
  constant START_COUNT          : unsigned(31 downto 0) := to_unsigned(100, 32);

  signal salt_in_counter     : unsigned(31 downto 0);
  signal password_in_counter : unsigned(31 downto 0);
  signal salt_out_counter    : unsigned(31 downto 0);
  signal start_counter       : unsigned(31 downto 0);

  signal salt_in_busy     : std_logic;
  signal password_in_busy : std_logic;

  type salt_array is array (C_SALT_IN_LENGTH-1 downto 0) of std_logic_vector(31 downto 0);
  type password_array is array (C_PASSWORD_IN_LENGTH-1 downto 0) of std_logic_vector(31 downto 0);
  type output_array is array (7 downto 0) of std_logic_vector(31 downto 0);

  signal salt_in_array     : salt_array;
  signal password_in_array : password_array;

  signal hash_expected : output_array;


  signal salt_in_length           : std_logic_vector(63 downto 0);
  signal salt_in_length_valid     : std_logic;
  signal salt_in                  : std_logic_vector(31 downto 0);
  signal salt_in_valid            : std_logic;
  signal salt_in_last             : std_logic;
  signal salt_in_ready            : std_logic;
  signal password_in_length       : std_logic_vector(63 downto 0);
  signal password_in_length_valid : std_logic;
  signal password_in              : std_logic_vector(31 downto 0);
  signal password_in_valid        : std_logic;
  signal password_in_last         : std_logic;
  signal password_in_ready        : std_logic;
  signal hash_out_length          : std_logic_vector(63 downto 0);
  signal hash_out_length_valid    : std_logic;
  signal hash_out                 : std_logic_vector(31 downto 0);
  signal hash_out_valid           : std_logic;
  signal hash_out_last            : std_logic;
  signal hash_out_ready           : std_logic;
  signal error_out                : std_logic_vector(3 downto 0);

  signal iteration       : std_logic_vector(31 downto 0);
  signal iteration_valid : std_logic;

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

  salt_in_length <= std_logic_vector(to_unsigned(4, 64));

  -- example length 3
  --salt_in_array(0)  <= X"61626380";

  -- example length 56

  salt_in_array(0) <= X"73616c74";

  password_in_length   <= std_logic_vector(to_unsigned(8, 64));
  password_in_array(0) <= X"70617373";
  password_in_array(1) <= X"776f7264";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        salt_in_counter     <= (others => '0');
        password_in_counter <= (others => '0');
        start_counter       <= (others => '0');
        salt_in_valid       <= '0';
        password_in_valid   <= '0';

        salt_in_busy             <= '0';
        password_in_busy         <= '0';
        salt_in_length_valid     <= '0';
        password_in_length_valid <= '0';

      else
        salt_in_length_valid     <= '0';
        password_in_length_valid <= '0';

        if (salt_in_busy = '0' and password_in_busy = '0') then
          if (start_counter < START_COUNT) then
            start_counter <= start_counter + 1;
          else
            salt_in_busy         <= '1';
            salt_in_length_valid <= '1';
            salt_in_valid        <= '1';

            password_in_valid        <= '1';
            password_in_busy         <= '1';
            password_in_length_valid <= '1';
            start_counter            <= (others => '0');

          end if;
        end if;


        if (salt_in_busy = '1' and salt_in_ready = '1') then
          if (salt_in_counter < to_unsigned(C_SALT_IN_LENGTH-1, 32)) then
            salt_in_counter <= salt_in_counter + 1;

          else
            salt_in_counter <= (others => '0');
            salt_in_valid   <= '0';

          end if;

        end if;

        if (password_in_busy = '1' and password_in_ready = '1') then
          if (password_in_counter < to_unsigned(C_PASSWORD_IN_LENGTH-1, 32)) then
            password_in_counter <= password_in_counter + 1;

          else
            password_in_counter <= (others => '0');
            password_in_valid   <= '0';

          end if;

        end if;

        --if hash out, clear busies
        if (hash_out_valid = '1' and hash_out_last = '1' and hash_out_ready = '1') then
          password_in_busy <= '0';
          salt_in_busy     <= '0';

        end if;


      end if;
    end if;
  end process;

  salt_in_last <= '1' when salt_in_counter = to_unsigned(C_SALT_IN_LENGTH-1, 32) else '0';

  salt_in_gen : for i in 0 to C_SALT_IN_LENGTH-1 generate
    salt_in <= salt_in_array(i) when (salt_in_counter = i) else (others => 'Z');

  end generate salt_in_gen;

  password_in_last <= '1' when password_in_counter = to_unsigned(C_PASSWORD_IN_LENGTH-1, 32) else '0';

  password_in_gen : for i in 0 to C_PASSWORD_IN_LENGTH-1 generate
    password_in <= password_in_array(i) when (password_in_counter = i) else (others => 'Z');

  end generate password_in_gen;

  pbkdf_hmac_sha256_1 : pbkdf_hmac_sha256
    port map (
      clk                      => clk,
      rst                      => rst,
      iteration                => X"00000002",
      iteration_valid          => password_in_length_valid,
      password_in_length       => password_in_length,
      password_in_length_valid => password_in_length_valid,
      password_in              => password_in,
      password_in_valid        => password_in_valid,
      password_in_last         => password_in_last,
      password_in_ready        => password_in_ready,
      salt_in_length           => salt_in_length,
      salt_in_length_valid     => salt_in_length_valid,
      salt_in                  => salt_in,
      salt_in_valid            => salt_in_valid,
      salt_in_last             => salt_in_last,
      salt_in_ready            => salt_in_ready,
      hash_out_length          => hash_out_length,
      hash_out_length_valid    => hash_out_length_valid,
      hash_out                 => hash_out,
      hash_out_valid           => hash_out_valid,
      hash_out_last            => hash_out_last,
      hash_out_ready           => hash_out_ready,
      error_out                => error_out);

  hash_out_ready <= '1';

  hash_expected(0) <= X"a769288e";
  hash_expected(1) <= X"7aa4b786";
  hash_expected(2) <= X"25942b55";
  hash_expected(3) <= X"301365b6";
  hash_expected(4) <= X"367ba31f";
  hash_expected(5) <= X"fee3bef0";
  hash_expected(6) <= X"48330023";
  hash_expected(7) <= X"81c53b1d";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        hash_error       <= (others => '0');
        hash_error_valid <= '0';

        salt_out_counter <= (others => '0');

      else
        hash_error_valid <= '0';

        if (hash_out_valid = '1' and hash_out_ready = '1') then
          if (hash_out_last = '1') then
            salt_out_counter <= (others => '0');

          else
            salt_out_counter <= salt_out_counter + 1;

          end if;
        end if;

        for i in 7 downto 0 loop
          if (salt_out_counter = i) then
            if (hash_expected(i) = hash_out) then
              hash_error(i) <= '0';
            else
              hash_error(i) <= '1';
            end if;

          end if;

        end loop;  -- i

        if (salt_out_counter = 7) then
          hash_error_valid <= '1';
        end if;

      end if;
    end if;
  end process;

  pass_flag <= '1' when hash_error = X"00" and hash_error_valid = '1'  else '0';
  fail_flag <= '1' when hash_error /= X"00" and hash_error_valid = '1' else '0';


end behavioral;
