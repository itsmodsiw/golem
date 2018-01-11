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


entity sha256_wrapper is
  port (
    clk : in std_logic;
    rst : in std_logic;

    message_in_length       : in std_logic_vector(63 downto 0);
    message_in_length_valid : in std_logic;

    message_in       : in  std_logic_vector(31 downto 0);
    message_in_valid : in  std_logic;
    message_in_last  : in  std_logic;
    message_in_ready : out std_logic;

    hash_out_length       : out std_logic_vector(63 downto 0);
    hash_out_length_valid : out std_logic;

    hash_out       : out std_logic_vector(31 downto 0);
    hash_out_valid : out std_logic;
    hash_out_last  : out std_logic;
    hash_out_ready : in  std_logic;

    error_out : out std_logic_vector(3 downto 0)

    );

end sha256_wrapper;

architecture behavioral of sha256_wrapper is

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

  component sha256_add9
    port (
      A : in  std_logic_vector(63 downto 0);
      S : out std_logic_vector(63 downto 0)
      );
  end component;

  component sha256_fifo
    port (
      s_aclk        : in  std_logic;
      s_aresetn     : in  std_logic;
      s_axis_tvalid : in  std_logic;
      s_axis_tready : out std_logic;
      s_axis_tdata  : in  std_logic_vector(31 downto 0);
      s_axis_tlast  : in  std_logic;
      m_axis_tvalid : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis_tdata  : out std_logic_vector(31 downto 0);
      m_axis_tlast  : out std_logic
      );
  end component;

  -- total length in 64b blocks and bytes
  signal length_total_bytes        : std_logic_vector(63 downto 0);
  signal length_total_words_padded : unsigned(61 downto 0);
  signal length_total_blocks       : std_logic_vector(57 downto 0);

  -- point at which the appended byte must be added
  signal append_byte_position : std_logic_vector(1 downto 0);

  -- new word with the appended byte
  signal append_byte_word : std_logic_vector(31 downto 0);

  -- length to be appended
  signal append_length_word1 : std_logic_vector(31 downto 0);
  signal append_length_word2 : std_logic_vector(31 downto 0);


  signal pad_enable   : std_logic;
  signal pad_required : std_logic;

  signal message_in_sha256       : std_logic_vector(31 downto 0);
  signal message_in_sha256_valid : std_logic;
  signal message_in_sha256_last  : std_logic;
  signal message_in_sha256_ready : std_logic;

  signal message_in_sha256_fifo       : std_logic_vector(31 downto 0);
  signal message_in_sha256_fifo_valid : std_logic;
  signal message_in_sha256_fifo_last  : std_logic;
  signal message_in_sha256_fifo_ready : std_logic;

  signal write_counter        : unsigned(61 downto 0);
  signal message_length       : unsigned(63 downto 0);
  signal message_length_words : unsigned(61 downto 0);

  signal write_first_length  : std_logic;
  signal write_second_length : std_logic;
  signal write_appended_byte : std_logic;
  signal write_data          : std_logic;
  signal write_padding       : std_logic;
  signal idle                : std_logic;

  signal wrapper_busy  : std_logic;
  signal lengths_ready : std_logic;

  signal rstn : std_logic;

  signal const_32 : std_logic_vector(63 downto 0);

  signal hash_out_valid_z : std_logic;
  signal hash_out_valid_i : std_logic;


begin

  rstn     <= not rst;
  const_32 <= std_logic_vector(to_unsigned(32, 64));

  sha256_1 : sha256
    port map (
      clk              => clk,
      rst              => rst,
      message_in       => message_in_sha256_fifo,
      message_in_valid => message_in_sha256_fifo_valid,
      message_in_last  => message_in_sha256_fifo_last,
      message_in_ready => message_in_sha256_fifo_ready,
      hash_out         => hash_out,
      hash_out_valid   => hash_out_valid_i,
      hash_out_last    => hash_out_last,
      hash_out_ready   => hash_out_ready,
      error_out        => error_out);


  -- length in bytes
  -- +1b for an appended 0x80
  -- +8b for an appended length

  sha256_add9_1 : sha256_add9
    port map (
      A => message_in_length,
      S => length_total_bytes);

  message_length_words <= message_length(63 downto 2) when message_length(1 downto 0) = 0 else
                          message_length(63 downto 2)+1;


  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        length_total_blocks  <= (others => '0');
        append_byte_position <= (others => '0');
        message_length       <= (others => '0');
        wrapper_busy         <= '0';
        lengths_ready        <= '0';
        hash_out_valid_z     <= '0';

      else
        hash_out_valid_z <= hash_out_valid_i;
        lengths_ready    <= '0';

        -- append based on number of bytes in message
        append_byte_position <= message_in_length(1 downto 0);

        if (message_in_sha256_valid = '1' and message_in_sha256_last = '1' and message_in_sha256_ready = '1') then
          wrapper_busy <= '0';

        end if;

        if (message_in_length_valid = '1') then
          message_length <= unsigned(message_in_length);
          wrapper_busy   <= '1';
          lengths_ready  <= '1';

        end if;

        if (length_total_bytes(5 downto 0) = "000000") then
          -- special case where length_total_bytes is already a multiple of 64
          -- (so no padding required)
          length_total_blocks <= length_total_bytes(63 downto 6);


        else
          -- other normal case where padding is required
          -- so here we need an extra block
          length_total_blocks <= std_logic_vector(unsigned(length_total_bytes(63 downto 6)) + 1);

        end if;

      end if;
    end if;
  end process;

  length_total_words_padded(61 downto 4) <= unsigned(length_total_blocks);
  length_total_words_padded(3 downto 0)  <= "0000";

  -- word to be appended
  append_byte_word <= message_in(31 downto 24) & X"800000" when append_byte_position = "01" else
                      message_in(31 downto 16) & X"8000" when append_byte_position = "10" else
                      message_in(31 downto 8) & X"80"    when append_byte_position = "11" else
                      X"80000000";

  -- length to be appended
  -- word1 is the MSBs of the length
  append_length_word1 <= std_logic_vector(message_length(60 downto 29));
  append_length_word2 <= std_logic_vector(message_length(28 downto 0)) & "000";

  -- count the writes
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        -- all 1s is counter reset value
        write_counter <= (others => '1');

      else
        -- when data is received, set counter to 0
        if (message_in_length_valid = '1') then
          write_counter <= (others => '0');

        end if;

        if (message_in_sha256_valid = '1' and message_in_sha256_ready = '1') then
          if (write_counter < (length_total_words_padded-1)) then
            write_counter <= write_counter + 1;
          else
            -- all 1s is counter reset value
            write_counter <= (others => '1');
          end if;
        end if;
      end if;
    end if;
  end process;



  write_first_length  <= '1' when write_counter = length_total_words_padded-2 else '0';
  write_second_length <= '1' when write_counter = length_total_words_padded-1 else '0';

  write_appended_byte <= '1' when append_byte_position = "00" and write_counter = message_length_words else
                         '1' when append_byte_position /= "00" and write_counter = message_length_words-1 else
                         '0';
  write_data <= '1' when append_byte_position = "00" and write_counter < message_length_words else
                '1' when append_byte_position /= "00" and write_counter < message_length_words-1 else
                '0';

  idle <= not wrapper_busy;

  write_padding <= '1' when (write_first_length = '0' and write_second_length = '0' and write_appended_byte = '0' and write_data = '0' and idle = '0') else '0';

  message_in_sha256 <= message_in when write_data = '1' else
                       append_byte_word    when write_appended_byte = '1' else
                       append_length_word1 when write_first_length = '1' else
                       append_length_word2 when write_second_length = '1' else
                       (others => '0');

  message_in_sha256_valid <= message_in_valid when write_data = '1' else
                             wrapper_busy when write_appended_byte = '1' or write_first_length = '1' or write_second_length = '1' or write_padding = '1' else
                             '0';

  message_in_sha256_last <= '1' when write_second_length = '1' else
                            '0';


  --process (clk)
  --begin
  --  if (rising_edge(clk)) then
  --    if (rst = '1') then
  --      message_in_sha256       <= (others => '0');
  --      message_in_sha256_last  <= '0';
  --      message_in_sha256_valid <= '0';

  --    elsif (message_in_sha256_ready = '1') then  --clk enable on ready

  --      if (wrapper_busy = '1') then
  --        if (write_data = '1') then
  --          message_in_sha256       <= message_in;
  --          message_in_sha256_valid <= message_in_valid;
  --          message_in_sha256_last  <= '0';

  --        elsif (write_appended_byte = '1') then
  --          message_in_sha256       <= append_byte_word;
  --          message_in_sha256_valid <= '1';
  --          message_in_sha256_last  <= '0';

  --        elsif (write_first_length = '1') then
  --          message_in_sha256       <= append_length_word1;
  --          message_in_sha256_valid <= '1';
  --          message_in_sha256_last  <= '0';

  --        elsif (write_second_length = '1') then
  --          message_in_sha256       <= append_length_word2;
  --          message_in_sha256_valid <= '1';
  --          message_in_sha256_last  <= '1';

  --        elsif (write_padding = '1') then
  --          message_in_sha256       <= (others => '0');
  --          message_in_sha256_valid <= '1';
  --          message_in_sha256_last  <= '0';

  --        end if;
  --      else
  --        message_in_sha256       <= (others => '0');
  --        message_in_sha256_valid <= '0';
  --        message_in_sha256_last  <= '0';

  --      end if;
  --    end if;

  --  end if;
  --end process;

  message_in_ready <= message_in_sha256_ready when write_data = '1' and wrapper_busy = '1' else '0';

  sha256_fifo_1 : sha256_fifo
    port map (
      s_aclk        => clk,
      s_aresetn     => rstn,
      s_axis_tvalid => message_in_sha256_valid,
      s_axis_tready => message_in_sha256_ready,
      s_axis_tdata  => message_in_sha256,
      s_axis_tlast  => message_in_sha256_last,
      m_axis_tvalid => message_in_sha256_fifo_valid,
      m_axis_tready => message_in_sha256_fifo_ready,
      m_axis_tdata  => message_in_sha256_fifo,
      m_axis_tlast  => message_in_sha256_fifo_last);


  hash_out_length       <= const_32;
  hash_out_length_valid <= '1' when hash_out_valid_i = '1' and hash_out_valid_z = '0' else '0';

  hash_out_valid <= hash_out_valid_i;

end behavioral;
