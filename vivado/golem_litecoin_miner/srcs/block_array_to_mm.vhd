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


entity block_array_to_mm is
  generic (
    LENGTH          : integer := 16
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- addr in is on 7-bit address boundries
    -- since block_array is a 128B number
    block_array_in_addr  : in  std_logic_vector(24 downto 0);
    block_array_in       : in  block_array;
    block_array_in_valid : in  std_logic;
    block_array_in_ready : out std_logic;

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

    errors : out std_logic_vector(15 downto 0)


    );

end block_array_to_mm;

architecture behavioral of block_array_to_mm is
  component axi_mm_fifo
    port (
      s_aclk           : in  std_logic;
      s_aresetn        : in  std_logic;
      s_axi_awid       : in  std_logic_vector(5 downto 0);
      s_axi_awaddr     : in  std_logic_vector(31 downto 0);
      s_axi_awlen      : in  std_logic_vector(7 downto 0);
      s_axi_awsize     : in  std_logic_vector(2 downto 0);
      s_axi_awburst    : in  std_logic_vector(1 downto 0);
      s_axi_awlock     : in  std_logic_vector(0 downto 0);
      s_axi_awcache    : in  std_logic_vector(3 downto 0);
      s_axi_awprot     : in  std_logic_vector(2 downto 0);
      s_axi_awqos      : in  std_logic_vector(3 downto 0);
      s_axi_awregion   : in  std_logic_vector(3 downto 0);
      s_axi_awvalid    : in  std_logic;
      s_axi_awready    : out std_logic;
      s_axi_wdata      : in  std_logic_vector(63 downto 0);
      s_axi_wstrb      : in  std_logic_vector(7 downto 0);
      s_axi_wlast      : in  std_logic;
      s_axi_wvalid     : in  std_logic;
      s_axi_wready     : out std_logic;
      s_axi_bid        : out std_logic_vector(5 downto 0);
      s_axi_bresp      : out std_logic_vector(1 downto 0);
      s_axi_bvalid     : out std_logic;
      s_axi_bready     : in  std_logic;
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
      axi_aw_overflow  : out std_logic;
      axi_aw_underflow : out std_logic;
      axi_w_overflow   : out std_logic;
      axi_w_underflow  : out std_logic;
      axi_b_overflow   : out std_logic;
      axi_b_underflow  : out std_logic
      );
  end component;

  signal id_counter         : unsigned(5 downto 0);
  signal cycle_counter      : unsigned(9 downto 0);
  signal cycle_counter_busy : std_logic;

  -- internal axi-compatible 64b-wide array
  signal axi_array       : axi_array;
  signal axi_array_valid : std_logic;


  signal s_axi_awid     : std_logic_vector(5 downto 0);
  signal s_axi_awaddr   : std_logic_vector(31 downto 0);
  signal s_axi_awlen    : std_logic_vector(7 downto 0);
  signal s_axi_awsize   : std_logic_vector(2 downto 0);
  signal s_axi_awburst  : std_logic_vector(1 downto 0);
  signal s_axi_awlock   : std_logic_vector(0 downto 0);
  signal s_axi_awcache  : std_logic_vector(3 downto 0);
  signal s_axi_awprot   : std_logic_vector(2 downto 0);
  signal s_axi_awqos    : std_logic_vector(3 downto 0);
  signal s_axi_awregion : std_logic_vector(3 downto 0);
  signal s_axi_awvalid  : std_logic;
  signal s_axi_awready  : std_logic;
  signal s_axi_wdata    : std_logic_vector(63 downto 0);
  signal s_axi_wstrb    : std_logic_vector(7 downto 0);
  signal s_axi_wlast    : std_logic;
  signal s_axi_wvalid   : std_logic;
  signal s_axi_wready   : std_logic;
  signal s_axi_bid      : std_logic_vector(5 downto 0);
  signal s_axi_bresp    : std_logic_vector(1 downto 0);
  signal s_axi_bvalid   : std_logic;
  signal s_axi_bready   : std_logic;

  signal b_error       : std_logic_vector(7 downto 0);
  signal axi_overflows : std_logic_vector(5 downto 0);
  signal errors_i      : std_logic_vector(15 downto 0); -- errors internal
  signal errors_l      : std_logic_vector(15 downto 0); -- errors latched

  signal rstn : std_logic;

begin

  rstn <= not rst;

  -- prep data
  axi_array       <= to_axi_array(block_array_in);
  axi_array_valid <= block_array_in_valid;


  -- ADDRESS

  -- first drive constant values:
  s_axi_awsize   <= "011";              --64b transfer
  s_axi_awburst  <= "01";               --burst type 1 (incremental)
  s_axi_awlock   <= "0";                --unused
  s_axi_awcache  <= "0000";             --unused
  s_axi_awprot   <= "000";              --unused
  s_axi_awqos    <= "0000";             --unused
  s_axi_awregion <= "0000";             --unused


  -- when valid sample is received, perform address write
  -- on the high-performance bus, the ready is guarenteed to be valid
  -- so no need to check ready here
  -- The fifo is used to ensure this further. It also should remain constantly
  -- ready.
  -- An additional layer of error checking is also included.

  s_axi_awaddr(31 downto 7) <= block_array_in_addr;
  s_axi_awaddr(6 downto 0)  <= "0000000";

  s_axi_awvalid <= block_array_in_valid;

  -- 128B write = transaction length of 16
  s_axi_awlen <= std_logic_vector(to_unsigned(LENGTH, 8));

  -- keep track of transaction ID
  s_axi_awid <= std_logic_vector(id_counter);

  -- DATA

  s_axi_wstrb  <= "11111111";           -- all bytes valid
  s_axi_wvalid <= cycle_counter_busy;
  s_axi_wlast  <= '1' when cycle_counter = LENGTH-1 else '0';

  -- mux data onto axi bus
  mux_data : for i in 0 to LENGTH-1 generate

    s_axi_wdata <= axi_array(i) when (cycle_counter = i) else (others => 'Z');

  end generate mux_data;


  -- create cycle counter for transaction

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        cycle_counter      <= (others => '0');
        cycle_counter_busy <= '0';

      else
        if (block_array_in_valid = '1') then
          cycle_counter      <= (others => '0');
          cycle_counter_busy <= '1';

        end if;

        if (cycle_counter_busy = '1') then
          if (cycle_counter < LENGTH-1) then
            cycle_counter <= cycle_counter + "1";

          else
            cycle_counter_busy <= '0';
            cycle_counter      <= (others => '0');

          end if;

        end if;
      end if;
    end if;
  end process;


  block_array_in_ready <= not cycle_counter_busy;

  -- generate transaction counter
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        id_counter <= (others => '0');

      else
        -- increment id counter when last
        if (cycle_counter = LENGTH-1) then
          if id_counter < 63 then
            id_counter <= id_counter + "1";

          else
            id_counter <= (others => '0');

          end if;

        end if;

      end if;
    end if;
  end process;

  -- B BUS
  -- always ready
  s_axi_bready <= '1';

  -- check response
  -- check if the bresp is non-zero
  -- on error, also supply the transaction id
  b_error <= m_axi_bid & s_axi_bresp when (s_axi_bvalid = '1' and s_axi_bresp /= "00") else (others => '0');

  -- feed entire axi bus into bus fifo.
  -- the fifo absorbs any holdups on the bus and cleans up the handshaking.
  -- all that's required is that the fifo is monitored so it doesn't overflow

  axi_mm_fifo_i : axi_mm_fifo
    port map (
      s_aclk           => clk,
      s_aresetn        => rstn,
      s_axi_awid       => s_axi_awid,
      s_axi_awaddr     => s_axi_awaddr,
      s_axi_awlen      => s_axi_awlen,
      s_axi_awsize     => s_axi_awsize,
      s_axi_awburst    => s_axi_awburst,
      s_axi_awlock     => s_axi_awlock,
      s_axi_awcache    => s_axi_awcache,
      s_axi_awprot     => s_axi_awprot,
      s_axi_awqos      => s_axi_awqos,
      s_axi_awregion   => s_axi_awregion,
      s_axi_awvalid    => s_axi_awvalid,
      s_axi_awready    => s_axi_awready,
      s_axi_wdata      => s_axi_wdata,
      s_axi_wstrb      => s_axi_wstrb,
      s_axi_wlast      => s_axi_wlast,
      s_axi_wvalid     => s_axi_wvalid,
      s_axi_wready     => s_axi_wready,
      s_axi_bid        => s_axi_bid,
      s_axi_bresp      => s_axi_bresp,
      s_axi_bvalid     => s_axi_bvalid,
      s_axi_bready     => s_axi_bready,
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
      axi_aw_overflow  => axi_overflows(0),
      axi_aw_underflow => axi_overflows(1),
      axi_w_overflow   => axi_overflows(2),
      axi_w_underflow  => axi_overflows(3),
      axi_b_overflow   => axi_overflows(4),
      axi_b_underflow  => axi_overflows(5)
      );

  errors_i(7 downto 0)  <= b_error;        -- axi b response errors
  errors_i(13 downto 8) <= axi_overflows;  -- axi fifo overflow errors

  -- generate ready errors
  -- if I drive awvalid when it's not ready
  -- or wvalid it's not ready

  errors_i(14) <= '1' when s_axi_awvalid = '1' and s_axi_awready = '0';
  errors_i(15) <= '1' when s_axi_wvalid = '1' and s_axi_wready = '0';

  -- register all these errors so that they remain high even if the error goes
  -- away. Do this on a bit-by-bit basis so that if another subsequent error occurs, it
  -- gets stored too.

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        errors_l <= (others => '0');

      else
        for j in 15 downto 0 loop
          -- hold on a bit-by-bit basis
          if (errors_i(j) = '1') then
            errors_l(j) <= '1';

          end if;
        end loop;  -- j
      end if;
    end if;
  end process;

  errors <= errors_l;


end behavioral;
