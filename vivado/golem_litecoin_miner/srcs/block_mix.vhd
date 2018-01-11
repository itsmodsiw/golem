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


entity block_mix is
  port (
    clk : in std_logic;
    rst : in std_logic;

    block_array_in       : in  block_array;
    block_array_in_valid : in  std_logic;
    block_array_in_ready : out std_logic;

    block_array_out       : out block_array;
    block_array_out_valid : out std_logic


    );

end block_mix;

architecture behavioral of block_mix is

  constant C_BLOCK_SIZE : integer := 1;
  constant C_NUM_ROUNDS : integer := 8;

  component salsa820 is
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

  signal x_int       : word_array;
  signal x_int_valid : std_logic;

  signal b_int : word_array;

  signal b_out       : block_array;
  signal b_out_valid : std_logic;


  signal t_int       : word_array;
  signal t_int_valid : std_logic;

  signal salsa_ready     : std_logic;
  signal salsa_out_valid : std_logic;
  signal salsa_out       : word_array;
  signal salsa_out_block : block_array;

  signal block_mix_busy : std_logic;
  signal block_mix_done : std_logic;

  signal block_counter : unsigned(7 downto 0);  --limits the blocksize to 128

begin

  -- initialise x_int;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        x_int       <= (others => (others => '0'));
        x_int_valid <= '0';

        block_counter <= (others => '0');

        block_mix_busy <= '0';
        block_mix_done <= '0';

      else
        -- if valid block array is received, initialise it
        x_int_valid    <= '0';
        block_mix_done <= '0';

        if (block_array_in_valid = '1') then
          -- x_int becomes last block
          x_int       <= to_word_array(block_array_in, 1);
          x_int_valid <= '1';

          block_counter <= (others => '0');

          block_mix_busy <= '1';

        end if;

        if (salsa_out_valid = '1') then
          if (block_counter < C_BLOCK_SIZE*2-1) then
            block_counter <= block_counter + 1;

            -- x_int becomes last salsa if we're not done
            x_int       <= salsa_out;
            x_int_valid <= '1';

          else
            -- if loop is done, flag
            block_counter  <= (others => '0');
            block_mix_done <= '1';

          end if;
        end if;

        -- if done, clear busy
        if (block_mix_done = '1') then
          block_mix_busy <= '0';

        end if;

      end if;
    end if;
  end process;

  b_int_gen : for i in C_BLOCK_SIZE*2-1 downto 0 generate
    b_int <= to_word_array(block_array_in, i) when (to_integer(block_counter) = i) else (others => (others => 'Z'));

  end generate b_int_gen;

  t_int       <= x_int xor b_int;
  t_int_valid <= x_int_valid;

  -- apply salsa to t_int

  salsa820_i : salsa820
    generic map (
      NUM_ROUNDS => C_NUM_ROUNDS
      )
    port map (
      clk => clk,
      rst => rst,

      word_in       => t_int,
      word_in_valid => t_int_valid,
      word_in_ready => salsa_ready,

      word_out       => salsa_out,
      word_out_valid => salsa_out_valid


      );

  salsa_out_block <= to_block_array(salsa_out,0);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        b_out       <= (others => (others => '0'));
        b_out_valid <= '0';

      else
        b_out_valid <= '0';

        for j in C_BLOCK_SIZE*2-1 downto 0 loop
          if salsa_out_valid = '1' and (to_integer(block_counter) = 1) then
            b_out(31 downto 16) <= salsa_out_block(15 downto 0);
          elsif salsa_out_valid = '1' and (to_integer(block_counter) = 0) then
            b_out(15 downto 0) <= salsa_out_block(15 downto 0);
          end if;
        end loop;  -- j

        -- result is valid on last loop
        if (salsa_out_valid = '1') and (to_integer(block_counter) = C_BLOCK_SIZE*2-1) then
          b_out_valid <= '1';
        end if;
      end if;
    end if;
  end process;

  block_array_out       <= b_out;
  block_array_out_valid <= b_out_valid;
  block_array_in_ready  <= not block_mix_busy;


end behavioral;
