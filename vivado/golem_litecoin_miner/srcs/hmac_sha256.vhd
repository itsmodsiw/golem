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


entity hmac_sha256 is
  port (
    clk : in std_logic;
    rst : in std_logic;

    key_in_length       : in std_logic_vector(63 downto 0);
    key_in_length_valid : in std_logic;

    key_in       : in  std_logic_vector(31 downto 0);
    key_in_valid : in  std_logic;
    key_in_last  : in  std_logic;
    key_in_ready : out std_logic;

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

end hmac_sha256;

architecture behavioral of hmac_sha256 is

  component hmac_sha256_shorten is
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
      key_in_length         : in  std_logic_vector(63 downto 0);
      key_in_length_valid   : in  std_logic;
      key_in                : in  std_logic_vector(31 downto 0);
      key_in_valid          : in  std_logic;
      key_in_last           : in  std_logic;
      key_in_ready          : out std_logic;
      hash_out_length       : out std_logic_vector(63 downto 0);
      hash_out_length_valid : out std_logic;
      hash_out              : out std_logic_vector(31 downto 0);
      hash_out_valid        : out std_logic;
      hash_out_last         : out std_logic;
      hash_out_ready        : in  std_logic;
      error_out             : out std_logic_vector(3 downto 0));
  end component hmac_sha256_shorten;

  component hmac_sha256_pad is
    port (
      clk                  : in  std_logic;
      rst                  : in  std_logic;
      key_in_length        : in  std_logic_vector(63 downto 0);
      key_in_length_valid  : in  std_logic;
      key_in               : in  std_logic_vector(31 downto 0);
      key_in_valid         : in  std_logic;
      key_in_last          : in  std_logic;
      key_in_ready         : out std_logic;
      key_out_length       : out std_logic_vector(63 downto 0);
      key_out_length_valid : out std_logic;
      key_out              : out std_logic_vector(31 downto 0);
      key_out_valid        : out std_logic;
      key_out_last         : out std_logic;
      key_out_ready        : in  std_logic;
      error_out            : out std_logic_vector(3 downto 0));
  end component hmac_sha256_pad;

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

  component hmac_add64
    port (
      A   : in  std_logic_vector(63 downto 0);
      CLK : in  std_logic;
      S   : out std_logic_vector(63 downto 0)
      );
  end component;

  component hmac_key_fifo
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

  signal key_out_pad_length       : std_logic_vector(63 downto 0);
  signal key_out_pad_length_valid : std_logic;
  signal key_out_pad              : std_logic_vector(31 downto 0);
  signal key_out_pad_valid        : std_logic;
  signal key_out_pad_last         : std_logic;
  signal key_out_pad_ready        : std_logic;
  signal error_out_pad            : std_logic_vector(3 downto 0);

  signal hash_out_short_length       : std_logic_vector(63 downto 0);
  signal hash_out_short_length_valid : std_logic;
  signal hash_out_short              : std_logic_vector(31 downto 0);
  signal hash_out_short_valid        : std_logic;
  signal hash_out_short_last         : std_logic;
  signal hash_out_short_ready        : std_logic;
  signal error_out_short             : std_logic_vector(3 downto 0);

  signal key_in_inner_length       : std_logic_vector(63 downto 0);
  signal key_in_inner_length_valid : std_logic;
  signal key_in_inner              : std_logic_vector(31 downto 0);
  signal key_in_inner_valid        : std_logic;
  signal key_in_inner_last         : std_logic;
  signal key_in_inner_ready        : std_logic;
  signal key_in_outer_length       : std_logic_vector(63 downto 0);
  signal key_in_outer_length_valid : std_logic;
  signal key_in_outer              : std_logic_vector(31 downto 0);
  signal key_in_outer_valid        : std_logic;
  signal key_in_outer_last         : std_logic;
  signal key_in_outer_ready        : std_logic;

  signal hash_out_inner_length       : std_logic_vector(63 downto 0);
  signal hash_out_inner_length_valid : std_logic;
  signal hash_out_inner              : std_logic_vector(31 downto 0);
  signal hash_out_inner_valid        : std_logic;
  signal hash_out_inner_last         : std_logic;
  signal hash_out_inner_ready        : std_logic;
  signal hash_out_outer_length       : std_logic_vector(63 downto 0);
  signal hash_out_outer_length_valid : std_logic;
  signal hash_out_outer              : std_logic_vector(31 downto 0);
  signal hash_out_outer_valid        : std_logic;
  signal hash_out_outer_last         : std_logic;
  signal hash_out_outer_ready        : std_logic;

  signal error_out_inner : std_logic_vector(3 downto 0);
  signal error_out_outer : std_logic_vector(3 downto 0);


  constant outer_key_pad : std_logic_vector(31 downto 0) := X"5C5C5C5C";
  constant inner_key_pad : std_logic_vector(31 downto 0) := X"36363636";

  signal inner_counter : unsigned(63 downto 0);

  signal message_length       : std_logic_vector(63 downto 0);
  signal message_length_valid : std_logic;

  signal inner_length       : std_logic_vector(63 downto 0);
  signal inner_length_valid : std_logic;
  signal outer_length       : std_logic_vector(63 downto 0);

  signal message_in_ready_i : std_logic;
  signal rstn               : std_logic;

  signal key_fifo_in_valid : std_logic;
  signal key_fifo_in_ready : std_logic;
  signal key_fifo_in_data  : std_logic_vector(31 downto 0);
  signal key_fifo_in_last  : std_logic;

  signal key_fifo_out_ready_i : std_logic;
  signal key_fifo_out_valid   : std_logic;
  signal key_fifo_out_ready   : std_logic;
  signal key_fifo_out_data    : std_logic_vector(31 downto 0);
  signal key_fifo_out_last    : std_logic;

  signal key_in_ready_i       : std_logic;
  signal key_in_ready_shorten : std_logic;

  signal hmac_busy : std_logic;

begin

  rstn <= not rst;

  -- remember the message length
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        message_length       <= (others => '0');
        message_length_valid <= '0';
        inner_length_valid   <= '0';

        hmac_busy <= '0';

        key_in_ready_i <= '1';

      else
        message_length_valid <= '0';
        inner_length_valid   <= message_length_valid;

        if (message_in_length_valid = '1') then
          message_length       <= message_in_length;
          message_length_valid <= '1';


        end if;

        if (message_in_length_valid = '1' or key_in_length_valid = '1') then
          hmac_busy <= '1';

        end if;

        -- only allow one key last
        if (key_in_ready_i = '1' and key_in_valid = '1' and key_in_last = '1' and key_in_ready_shorten = '1') then
          key_in_ready_i <= '0';

        end if;

      end if;
    end if;
  end process;

  -- add 64 to the message length
  hmac_add64_1 : hmac_add64
    port map (
      A   => message_length,
      CLK => clk,
      S   => inner_length);

  hmac_sha256_shorten_1 : hmac_sha256_shorten
    port map (
      clk                 => clk,
      rst                 => rst,
      key_in_length       => key_in_length,
      key_in_length_valid => key_in_length_valid,
      key_in              => key_in,
      key_in_valid        => key_in_valid,
      key_in_last         => key_in_last,
      key_in_ready        => key_in_ready_shorten,

      hash_out_length       => hash_out_short_length,
      hash_out_length_valid => hash_out_short_length_valid,
      hash_out              => hash_out_short,
      hash_out_valid        => hash_out_short_valid,
      hash_out_last         => hash_out_short_last,
      hash_out_ready        => hash_out_short_ready,
      error_out             => error_out_short);

  key_in_ready <= key_in_ready_i and key_in_ready_shorten;

  hmac_sha256_pad_1 : hmac_sha256_pad
    port map (
      clk                  => clk,
      rst                  => rst,
      key_in_length        => hash_out_short_length,
      key_in_length_valid  => hash_out_short_length_valid,
      key_in               => hash_out_short,
      key_in_valid         => hash_out_short_valid,
      key_in_last          => hash_out_short_last,
      key_in_ready         => hash_out_short_ready,
      key_out_length       => key_out_pad_length,
      key_out_length_valid => key_out_pad_length_valid,
      key_out              => key_out_pad,
      key_out_valid        => key_out_pad_valid,
      key_out_last         => key_out_pad_last,
      key_out_ready        => key_out_pad_ready,
      error_out            => error_out_pad);

  -- padded output is garenteed to be 64B in length.
  --

  -- so drive key_out_pad_ready for 64B = 16 words
  -- then drive message_in_ready until the entire message is received.
  -- mux between them and use as the new input to the next hash.

  key_out_pad_ready <= key_in_inner_ready;

  sha256_wrapper_1 : sha256_wrapper
    port map (
      clk                     => clk,
      rst                     => rst,
      message_in_length       => key_in_inner_length,
      message_in_length_valid => key_in_inner_length_valid,
      message_in              => key_in_inner,
      message_in_valid        => key_in_inner_valid,
      message_in_last         => key_in_inner_last,
      message_in_ready        => key_in_inner_ready,
      hash_out_length         => hash_out_inner_length,
      hash_out_length_valid   => hash_out_inner_length_valid,
      hash_out                => hash_out_inner,
      hash_out_valid          => hash_out_inner_valid,
      hash_out_last           => hash_out_inner_last,
      hash_out_ready          => hash_out_inner_ready,
      error_out               => error_out_inner);


  key_in_inner_length       <= inner_length;
  key_in_inner_length_valid <= inner_length_valid;

  key_in_inner       <= (key_out_pad xor inner_key_pad) when key_out_pad_valid = '1' else message_in;
  key_in_inner_valid <= key_out_pad_valid or message_in_valid;
  key_in_inner_last  <= message_in_last;

  hash_out_inner_ready <= '1';


  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        message_in_ready_i <= '0';


      else
        -- drive message ready when key is done
        if (key_out_pad_valid = '1' and key_out_pad_last = '1' and key_out_pad_ready = '1') then
          message_in_ready_i <= '1';

        end if;

        -- de-latch it when message is done
        if (message_in_valid = '1' and message_in_last = '1' and message_in_ready_i = '1' and key_in_inner_ready = '1') then
          message_in_ready_i <= '0';

        end if;

      end if;
    end if;
  end process;

  message_in_ready <= message_in_ready_i and key_in_inner_ready;

  -- store key in fifo
  -- and then store message in fifo
  hmac_key_fifo_1 : hmac_key_fifo
    port map (
      s_aclk        => clk,
      s_aresetn     => rstn,
      s_axis_tvalid => key_fifo_in_valid,
      s_axis_tready => open,
      s_axis_tdata  => key_fifo_in_data,
      s_axis_tlast  => key_fifo_in_last,
      m_axis_tvalid => key_fifo_out_valid,
      m_axis_tready => key_fifo_out_ready,
      m_axis_tdata  => key_fifo_out_data,
      m_axis_tlast  => key_fifo_out_last);

  -- valids are assumed to be mutually exclusive
  key_fifo_in_data  <= (key_out_pad xor outer_key_pad) when key_out_pad_valid = '1' else hash_out_inner;
  key_fifo_in_valid <= (key_out_pad_valid and key_out_pad_ready) or (hash_out_inner_valid and hash_out_inner_ready);
  key_fifo_in_last  <= hash_out_inner_last;

  -- when inner is done, dump entire contents of fifo to the outer
  -- with a fixed length of 96 (32 is inner, 64 is key)


  sha256_wrapper_2 : sha256_wrapper
    port map (
      clk                     => clk,
      rst                     => rst,
      message_in_length       => key_in_outer_length,
      message_in_length_valid => key_in_outer_length_valid,
      message_in              => key_in_outer,
      message_in_valid        => key_in_outer_valid,
      message_in_last         => key_in_outer_last,
      message_in_ready        => key_in_outer_ready,
      hash_out_length         => hash_out_outer_length,
      hash_out_length_valid   => hash_out_outer_length_valid,
      hash_out                => hash_out_outer,
      hash_out_valid          => hash_out_outer_valid,
      hash_out_last           => hash_out_outer_last,
      hash_out_ready          => hash_out_outer_ready,
      error_out               => error_out_outer);


  -- outer length is fixed at 32 + 64 = 96
  outer_length <= std_logic_vector(to_unsigned(96, 64));

  key_in_outer_length       <= outer_length;
  key_in_outer_length_valid <= hash_out_inner_last;

  key_in_outer       <= key_fifo_out_data;
  key_in_outer_valid <= key_fifo_out_valid;
  key_in_outer_last  <= key_fifo_out_last;


  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        key_fifo_out_ready_i <= '0';


      else
        -- read from fifo when inner is done
        if (hash_out_inner_valid = '1' and hash_out_inner_last = '1' and hash_out_inner_ready = '1') then
          key_fifo_out_ready_i <= '1';

        end if;

        -- de-latch it when message is done
        if (key_fifo_out_valid = '1' and key_fifo_out_last = '1' and key_fifo_out_ready_i = '1') then
          key_fifo_out_ready_i <= '0';

        end if;

      end if;
    end if;
  end process;

  key_fifo_out_ready <= key_fifo_out_ready_i;

  hash_out_length       <= hash_out_outer_length;
  hash_out_length_valid <= hash_out_outer_length_valid;
  hash_out              <= hash_out_outer;
  hash_out_valid        <= hash_out_outer_valid;
  hash_out_last         <= hash_out_outer_last;

  hash_out_outer_ready <= hash_out_ready;

end behavioral;
