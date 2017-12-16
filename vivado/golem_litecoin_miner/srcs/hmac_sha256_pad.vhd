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


entity hmac_sha256_pad is
  port (
    clk : in std_logic;
    rst : in std_logic;

    key_in_length       : in std_logic_vector(63 downto 0);
    key_in_length_valid : in std_logic;

    key_in       : in  std_logic_vector(31 downto 0);
    key_in_valid : in  std_logic;
    key_in_last  : in  std_logic;
    key_in_ready : out std_logic;

    key_out_length       : out std_logic_vector(63 downto 0);
    key_out_length_valid : out std_logic;

    key_out       : out std_logic_vector(31 downto 0);
    key_out_valid : out std_logic;
    key_out_last  : out std_logic;
    key_out_ready : in  std_logic;

    error_out : out std_logic_vector(3 downto 0)

    );

end hmac_sha256_pad;

architecture behavioral of hmac_sha256_pad is

  signal data_counter_busy : std_logic;

  signal data_counter      : unsigned(6 downto 0);
  signal data_length       : unsigned(6 downto 0);
  signal data_length_words : unsigned(4 downto 0);

  signal last_byte_valid_position : unsigned(1 downto 0);
  signal last_byte                : std_logic_vector(31 downto 0);


  signal key_out_i       : std_logic_vector(31 downto 0);
  signal key_out_i_valid : std_logic;
  signal key_out_i_last  : std_logic;

  signal const_64 : std_logic_vector(63 downto 0);

begin
  const_64 <= std_logic_vector(to_unsigned(64, 64));

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        data_counter_busy        <= '0';
        data_length              <= (others => '0');
        data_length_words        <= (others => '0');
        last_byte_valid_position <= (others => '0');

      else
        if (key_in_length_valid = '1') then
          if (unsigned(key_in_length) > 64) then
            data_length              <= to_unsigned(64, 7);
            data_length_words        <= to_unsigned(16, 5);
            last_byte_valid_position <= (others => '0');

          else
            data_length              <= unsigned(key_in_length(6 downto 0));
            last_byte_valid_position <= unsigned(key_in_length(1 downto 0));

            if (key_in_length(1 downto 0) = "00") then
              data_length_words <= unsigned(key_in_length(6 downto 2));
            else
              data_length_words <= unsigned(key_in_length(6 downto 2))+1;
            end if;
          end if;

          data_counter_busy <= '1';

        end if;

        if (key_out_i_valid = '1' and key_out_ready = '1' and key_out_i_last = '1') then
          data_counter_busy <= '0';

        end if;

      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        data_counter <= (others => '0');

      elsif (key_out_ready = '1') then

        if (key_out_i_valid = '1' and key_out_i_last = '1') then
          data_counter <= (others => '0');

        elsif (key_out_i_valid = '1') then
          data_counter <= data_counter + 1;

        end if;

      end if;
    end if;
  end process;

  last_byte <= key_in when last_byte_valid_position = "00" else
               key_in(31 downto 24) & X"000000" when last_byte_valid_position = "01" else
               key_in(31 downto 16) & X"0000"  when last_byte_valid_position = "10" else
               key_in(31 downto 8 ) & X"00"    when last_byte_valid_position = "11" else
               (others => '0');

  -- mux the input depending on if short is enabled or not
  key_out_i <= key_in when data_counter < data_length_words-1 else
               last_byte when data_counter = data_length_words-1 else
               (others => '0');

  key_out_i_valid <= '1'  when data_counter_busy = '1' or key_in_length_valid = '1' else '0';

  key_out_i_last  <= '1' when data_counter = 15 else '0';

  key_out       <= key_out_i;
  key_out_valid <= key_out_i_valid;
  key_out_last  <= key_out_i_last;

  key_out_length       <= const_64;
  key_out_length_valid <= key_in_length_valid;

  key_in_ready <= key_out_ready;

end behavioral;
