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


entity scrypt_wrapper is
  generic (
    N_DIFFICULTY_LOG2 : integer := 10);
  port (
    clk : in std_logic;
    rst : in std_logic;

    message_in           : in  std_logic_vector(31 downto 0);
    message_in_max_nonce : in  std_logic_vector(31 downto 0);
    message_in_valid     : in  std_logic;
    message_in_last      : in  std_logic;
    message_in_ready     : out std_logic;

    target_in       : in  std_logic_vector(31 downto 0);
    target_in_valid : in  std_logic;
    target_in_last  : in  std_logic;
    target_in_ready : out std_logic;

    hash_out       : out std_logic_vector(31 downto 0);
    hash_out_valid : out std_logic;
    hash_out_last  : out std_logic;
    hash_out_ready : in  std_logic;

    m_axi_awid     : out std_logic_vector(5 downto 0);
    m_axi_awaddr   : out std_logic_vector(31 downto 0);
    m_axi_awlen    : out std_logic_vector(7 downto 0);
    m_axi_awsize   : out std_logic_vector(2 downto 0);
    m_axi_awburst  : out std_logic_vector(1 downto 0);
    m_axi_awlock   : out std_logic_vector(0 downto 0);
    m_axi_awcache  : out std_logic_vector(3 downto 0);
    m_axi_awprot   : out std_logic_vector(2 downto 0);
    m_axi_awqos    : out std_logic_vector(3 downto 0);
    m_axi_awregion : out std_logic_vector(3 downto 0);
    m_axi_awvalid  : out std_logic;
    m_axi_awready  : in  std_logic;
    m_axi_wdata    : out std_logic_vector(63 downto 0);
    m_axi_wstrb    : out std_logic_vector(7 downto 0);
    m_axi_wlast    : out std_logic;
    m_axi_wvalid   : out std_logic;
    m_axi_wready   : in  std_logic;
    m_axi_bid      : in  std_logic_vector(5 downto 0);
    m_axi_bresp    : in  std_logic_vector(1 downto 0);
    m_axi_bvalid   : in  std_logic;
    m_axi_bready   : out std_logic;
    m_axi_arid     : out std_logic_vector(5 downto 0);
    m_axi_araddr   : out std_logic_vector(31 downto 0);
    m_axi_arlen    : out std_logic_vector(7 downto 0);
    m_axi_arsize   : out std_logic_vector(2 downto 0);
    m_axi_arburst  : out std_logic_vector(1 downto 0);
    m_axi_arlock   : out std_logic_vector(0 downto 0);
    m_axi_arcache  : out std_logic_vector(3 downto 0);
    m_axi_arprot   : out std_logic_vector(2 downto 0);
    m_axi_arqos    : out std_logic_vector(3 downto 0);
    m_axi_arregion : out std_logic_vector(3 downto 0);
    m_axi_arvalid  : out std_logic;
    m_axi_arready  : in  std_logic;
    m_axi_rdata    : in  std_logic_vector(63 downto 0);
    m_axi_rlast    : in  std_logic;
    m_axi_rready   : out std_logic;
    m_axi_rid      : in  std_logic_vector(5 downto 0);
    m_axi_rresp    : in  std_logic_vector(1 downto 0);
    m_axi_rvalid   : in  std_logic

    );

end scrypt_wrapper;

architecture behavioral of scrypt_wrapper is

  component scrypt is
    generic (
      N_DIFFICULTY_LOG2 : integer);
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
      m_axi_awid       : out std_logic_vector(5 downto 0);
      m_axi_awaddr     : out std_logic_vector(31 downto 0);
      m_axi_awlen      : out std_logic_vector(7 downto 0);
      m_axi_awsize     : out std_logic_vector(2 downto 0);
      m_axi_awburst    : out std_logic_vector(1 downto 0);
      m_axi_awlock     : out std_logic_vector(0 downto 0);
      m_axi_awcache    : out std_logic_vector(3 downto 0);
      m_axi_awprot     : out std_logic_vector(2 downto 0);
      m_axi_awqos      : out std_logic_vector(3 downto 0);
      m_axi_awregion   : out std_logic_vector(3 downto 0);
      m_axi_awvalid    : out std_logic;
      m_axi_awready    : in  std_logic;
      m_axi_wdata      : out std_logic_vector(63 downto 0);
      m_axi_wstrb      : out std_logic_vector(7 downto 0);
      m_axi_wlast      : out std_logic;
      m_axi_wvalid     : out std_logic;
      m_axi_wready     : in  std_logic;
      m_axi_bid        : in  std_logic_vector(5 downto 0);
      m_axi_bresp      : in  std_logic_vector(1 downto 0);
      m_axi_bvalid     : in  std_logic;
      m_axi_bready     : out std_logic;
      m_axi_arid       : out std_logic_vector(5 downto 0);
      m_axi_araddr     : out std_logic_vector(31 downto 0);
      m_axi_arlen      : out std_logic_vector(7 downto 0);
      m_axi_arsize     : out std_logic_vector(2 downto 0);
      m_axi_arburst    : out std_logic_vector(1 downto 0);
      m_axi_arlock     : out std_logic_vector(0 downto 0);
      m_axi_arcache    : out std_logic_vector(3 downto 0);
      m_axi_arprot     : out std_logic_vector(2 downto 0);
      m_axi_arqos      : out std_logic_vector(3 downto 0);
      m_axi_arregion   : out std_logic_vector(3 downto 0);
      m_axi_arvalid    : out std_logic;
      m_axi_arready    : in  std_logic;
      m_axi_rdata      : in  std_logic_vector(63 downto 0);
      m_axi_rlast      : in  std_logic;
      m_axi_rready     : out std_logic;
      m_axi_rid        : in  std_logic_vector(5 downto 0);
      m_axi_rresp      : in  std_logic_vector(1 downto 0);
      m_axi_rvalid     : in  std_logic;
      error_out        : out std_logic_vector(3 downto 0));
  end component scrypt;

  component axis_addr_gen is
    port (
      clk            : in  std_logic;
      rst            : in  std_logic;
      snoop_valid    : in  std_logic;
      snoop_last     : in  std_logic;
      snoop_ready    : in  std_logic;
      addr_count_out : out std_logic_vector(31 downto 0));
  end component axis_addr_gen;

  component scrypt_message_RAM
    port (
      clka  : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(4 downto 0);
      dina  : in  std_logic_vector(31 downto 0);
      clkb  : in  std_logic;
      addrb : in  std_logic_vector(4 downto 0);
      doutb : out std_logic_vector(31 downto 0)
      );
  end component;

  signal target_out       : std_logic_vector(31 downto 0);
  signal target_out_count : std_logic_vector(31 downto 0);
  signal target_out_count_z : std_logic_vector(31 downto 0);

  signal scrypt_busy : std_logic;

  signal nonce_count : unsigned(31 downto 0);
  signal nonce_max   : unsigned(31 downto 0);
  signal nonce_last  : std_logic;

  signal next_message_write : std_logic;
  signal next_message_valid : std_logic;
  signal next_message_last  : std_logic;
  signal next_message_addr  : std_logic_vector(7 downto 0);
  signal next_message       : std_logic_vector(31 downto 0);


  signal message_in_count : std_logic_vector(31 downto 0);
  signal target_in_count  : std_logic_vector(31 downto 0);

  signal scrypt_message_in       : std_logic_vector(31 downto 0);
  signal scrypt_message_in_valid : std_logic;
  signal scrypt_message_in_last  : std_logic;
  signal scrypt_message_in_ready : std_logic;

  signal scrypt_hash_out         : std_logic_vector(31 downto 0);
  signal scrypt_hash_out_z       : std_logic_vector(31 downto 0);
  signal scrypt_hash_out_valid   : std_logic;
  signal scrypt_hash_out_valid_z : std_logic;
  signal scrypt_hash_out_last    : std_logic;
  signal scrypt_hash_out_ready   : std_logic;

  signal message_in_ready_i : std_logic;
  signal message_in_wea     : std_logic_vector(0 downto 0);

  signal target_in_ready_i : std_logic;
  signal target_in_wea     : std_logic_vector(0 downto 0);

  signal below_target : std_logic;


begin
  target_in_ready  <= target_in_ready_i;
  message_in_ready <= message_in_ready_i;


  -- First, store the message and the target in BRAM

  -- MESSAGE

  -- always '1' for now
  message_in_ready_i <= '1';
  message_in_wea(0)  <= message_in_valid and message_in_ready_i;

  -- These generate BRAM addresses for the input axis signals for easy BRAM writes
  -- output signals are sync'd to input (valid on same cc)
  axis_addr_gen_message_in : axis_addr_gen
    port map (
      clk            => clk,
      rst            => rst,
      snoop_valid    => message_in_valid,
      snoop_last     => message_in_last,
      snoop_ready    => message_in_ready_i,
      addr_count_out => message_in_count);

  scrypt_message_RAM_message : scrypt_message_RAM
    port map (
      clka  => clk,
      wea   => message_in_wea,
      addra => message_in_count(4 downto 0),
      dina  => message_in,
      clkb  => clk,
      addrb => next_message_addr(4 downto 0),
      doutb => next_message);

  -- TARGET

  target_in_ready_i <= '1';
  target_in_wea(0)  <= target_in_valid and target_in_ready_i;

  axis_addr_gen_target_in : axis_addr_gen
    port map (
      clk            => clk,
      rst            => rst,
      snoop_valid    => target_in_valid,
      snoop_last     => target_in_last,
      snoop_ready    => target_in_ready_i,
      addr_count_out => target_in_count);

  scrypt_message_RAM_target : scrypt_message_RAM
    port map (
      clka  => clk,
      wea   => target_in_wea,
      addra => target_in_count(4 downto 0),
      dina  => target_in,
      clkb  => clk,
      addrb => target_out_count(4 downto 0),
      doutb => target_out);

  -- NONCE GENERATION is next

  -- Count nonce
  -- When input message is received, remember the input nonce
  -- It's in the last cc of the message
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        nonce_count <= (others => '0');
        nonce_max   <= (others => '0');
        nonce_last  <= '0';

      else
        -- first, remember the nonce received when the first message is received
        if (message_in_valid = '1' and message_in_last = '1' and message_in_ready_i = '1') then
          nonce_count <= unsigned(message_in);
          -- At the same time, remember the nonce_max
          nonce_max   <= unsigned(message_in_max_nonce);
        end if;

        -- Each time an output hash is created, increment the nonce.
        if (scrypt_hash_out_valid = '1' and scrypt_hash_out_last = '1' and scrypt_hash_out_ready = '1') then
          nonce_count <= nonce_count + 1;

        end if;

        -- generate the nonce_last flag
        -- This flag indicates that the current calculation is the last one
        -- when this is set, don't perform any more hashes after this one.
        if (nonce_count = nonce_max) then
          nonce_last <= '1';

        else
          nonce_last <= '0';

        end if;

      end if;
    end if;
  end process;

  -- scrypt busy signal
  -- generate a busy to indicate that the scrypt is busy processing
  -- this signal starts at 0
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        scrypt_busy        <= '0';
        next_message_write <= '0';
        next_message_valid <= '0';
        next_message_last  <= '0';

        next_message_addr <= (others => '0');

      else
        next_message_valid <= next_message_write;
        if (next_message_addr = std_logic_vector(to_unsigned(19, 8))) then
          next_message_last <= '1';

        else
          next_message_last <= '0';

        end if;

        -- if not busy, then the first input message
        if (scrypt_busy = '0' and message_in_valid = '1' and message_in_last = '1' and message_in_ready_i = '1') then
          scrypt_busy <= '1';

          -- start by writing the next message
          next_message_write <= '1';
          next_message_addr  <= (others => '0');

        end if;

        if (next_message_write = '1') then
          if (next_message_addr < std_logic_vector(to_unsigned(19, 8))) then
            next_message_addr <= std_logic_vector(unsigned(next_message_addr) + 1);
          else
            next_message_addr  <= (others => '0');
            next_message_write <= '0';

          end if;
        end if;


        if (scrypt_busy = '1' and scrypt_hash_out_valid = '1' and scrypt_hash_out_last = '1' and scrypt_hash_out_ready = '1' and nonce_last = '1') then
          scrypt_busy <= '0';

        -- nonce_last isn't set, then get another hash and nonce
        elsif (scrypt_busy = '1' and scrypt_hash_out_valid = '1' and scrypt_hash_out_last = '1' and scrypt_hash_out_ready = '1') then
          next_message_write <= '1';
          next_message_addr  <= (others => '0');

        end if;

      end if;
    end if;
  end process;

  -- instead of using the last datacycle, replace it with the nonce
  scrypt_message_in       <= next_message when next_message_last = '0' else std_logic_vector(nonce_count);
  scrypt_message_in_valid <= next_message_valid;
  scrypt_message_in_last  <= next_message_last;

  scrypt_hash_out_ready <= '1';

  scrypt_1 : scrypt
    generic map (
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk              => clk,
      rst              => rst,
      message_in       => scrypt_message_in,
      message_in_valid => scrypt_message_in_valid,
      message_in_last  => scrypt_message_in_last,
      message_in_ready => scrypt_message_in_ready,
      hash_out         => scrypt_hash_out,
      hash_out_valid   => scrypt_hash_out_valid,
      hash_out_last    => scrypt_hash_out_last,
      hash_out_ready   => scrypt_hash_out_ready,
      m_axi_awid       => m_axi_awid,
      m_axi_awaddr     => m_axi_awaddr,
      m_axi_awlen      => m_axi_awlen,
      m_axi_awsize     => m_axi_awsize,
      m_axi_awburst    => m_axi_awburst,
      m_axi_awlock     => m_axi_awlock,
      m_axi_awcache    => m_axi_awcache,
      m_axi_awprot     => m_axi_awprot,
      m_axi_awqos      => m_axi_awqos,
      m_axi_awregion   => m_axi_awregion,
      m_axi_awvalid    => m_axi_awvalid,
      m_axi_awready    => m_axi_awready,
      m_axi_wdata      => m_axi_wdata,
      m_axi_wstrb      => m_axi_wstrb,
      m_axi_wlast      => m_axi_wlast,
      m_axi_wvalid     => m_axi_wvalid,
      m_axi_wready     => m_axi_wready,
      m_axi_bid        => m_axi_bid,
      m_axi_bresp      => m_axi_bresp,
      m_axi_bvalid     => m_axi_bvalid,
      m_axi_bready     => m_axi_bready,
      m_axi_arid       => m_axi_arid,
      m_axi_araddr     => m_axi_araddr,
      m_axi_arlen      => m_axi_arlen,
      m_axi_arsize     => m_axi_arsize,
      m_axi_arburst    => m_axi_arburst,
      m_axi_arlock     => m_axi_arlock,
      m_axi_arcache    => m_axi_arcache,
      m_axi_arprot     => m_axi_arprot,
      m_axi_arqos      => m_axi_arqos,
      m_axi_arregion   => m_axi_arregion,
      m_axi_arvalid    => m_axi_arvalid,
      m_axi_arready    => m_axi_arready,
      m_axi_rdata      => m_axi_rdata,
      m_axi_rlast      => m_axi_rlast,
      m_axi_rready     => m_axi_rready,
      m_axi_rid        => m_axi_rid,
      m_axi_rresp      => m_axi_rresp,
      m_axi_rvalid     => m_axi_rvalid,
      error_out        => open);


  -- This generates the hash out address for easy target lookup
  axis_addr_gen_hash_out : axis_addr_gen
    port map (
      clk            => clk,
      rst            => rst,
      snoop_valid    => scrypt_hash_out_valid,
      snoop_last     => scrypt_hash_out_last,
      snoop_ready    => scrypt_hash_out_ready,
      addr_count_out => target_out_count);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        scrypt_hash_out_z       <= (others => '0');
        scrypt_hash_out_valid_z <= '0';
        target_out_count_z <= (others => '0');


        below_target <= '0';

      else
        scrypt_hash_out_z       <= scrypt_hash_out;
        scrypt_hash_out_valid_z <= scrypt_hash_out_valid;
        target_out_count_z <= target_out_count;

        if ((scrypt_hash_out_z < target_out) and (target_out_count_z = X"00000000") and (scrypt_hash_out_valid_z = '1')) then
          below_target <= '1';
        else
          below_target <= '0';

        end if;
      end if;
    end if;
  end process;


end behavioral;
