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


entity mm_to_block_array is
  generic (
    LENGTH : integer := 16
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- addr in is on 7-bit address boundries
    -- since block_array is a 128B number
    -- request block array
    block_array_in_addr  : in  std_logic_vector(24 downto 0);
    block_array_in_valid : in  std_logic;
    block_array_in_ready : out std_logic;

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
    m_axi_rvalid   : in  std_logic;


    -- returned block array
    block_array_out       : out block_array;
    block_array_out_valid : out std_logic;

    errors : out std_logic_vector(15 downto 0)


    );

end mm_to_block_array;

architecture behavioral of mm_to_block_array is

  component axi_mm_fifo_rd
    port (
      s_aclk           : in  std_logic;
      s_aresetn        : in  std_logic;
      s_axi_arid       : in  std_logic_vector(5 downto 0);
      s_axi_araddr     : in  std_logic_vector(31 downto 0);
      s_axi_arlen      : in  std_logic_vector(7 downto 0);
      s_axi_arsize     : in  std_logic_vector(2 downto 0);
      s_axi_arburst    : in  std_logic_vector(1 downto 0);
      s_axi_arlock     : in  std_logic_vector(0 downto 0);
      s_axi_arcache    : in  std_logic_vector(3 downto 0);
      s_axi_arprot     : in  std_logic_vector(2 downto 0);
      s_axi_arqos      : in  std_logic_vector(3 downto 0);
      s_axi_arregion   : in  std_logic_vector(3 downto 0);
      s_axi_arvalid    : in  std_logic;
      s_axi_arready    : out std_logic;
      s_axi_rid        : out std_logic_vector(5 downto 0);
      s_axi_rdata      : out std_logic_vector(63 downto 0);
      s_axi_rresp      : out std_logic_vector(1 downto 0);
      s_axi_rlast      : out std_logic;
      s_axi_rvalid     : out std_logic;
      s_axi_rready     : in  std_logic;
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
      m_axi_rid        : in  std_logic_vector(5 downto 0);
      m_axi_rdata      : in  std_logic_vector(63 downto 0);
      m_axi_rresp      : in  std_logic_vector(1 downto 0);
      m_axi_rlast      : in  std_logic;
      m_axi_rvalid     : in  std_logic;
      m_axi_rready     : out std_logic;
      axi_ar_overflow  : out std_logic;
      axi_ar_underflow : out std_logic;
      axi_r_overflow   : out std_logic;
      axi_r_underflow  : out std_logic
      );
  end component;

  signal id_counter    : unsigned(5 downto 0);
  signal cycle_counter : unsigned(9 downto 0);

  -- internal axi-compatible 64b-wide array
  signal axi_array_int       : axi_array;
  signal axi_array_int_valid : std_logic;

  signal s_axi_arid     : std_logic_vector(5 downto 0);
  signal s_axi_araddr   : std_logic_vector(31 downto 0);
  signal s_axi_arlen    : std_logic_vector(7 downto 0);
  signal s_axi_arsize   : std_logic_vector(2 downto 0);
  signal s_axi_arburst  : std_logic_vector(1 downto 0);
  signal s_axi_arlock   : std_logic_vector(0 downto 0);
  signal s_axi_arcache  : std_logic_vector(3 downto 0);
  signal s_axi_arprot   : std_logic_vector(2 downto 0);
  signal s_axi_arqos    : std_logic_vector(3 downto 0);
  signal s_axi_arregion : std_logic_vector(3 downto 0);
  signal s_axi_arvalid  : std_logic;
  signal s_axi_arready  : std_logic;
  signal s_axi_rid      : std_logic_vector(5 downto 0);
  signal s_axi_rdata    : std_logic_vector(63 downto 0);
  signal s_axi_rresp    : std_logic_vector(1 downto 0);
  signal s_axi_rlast    : std_logic;
  signal s_axi_rvalid   : std_logic;
  signal s_axi_rready   : std_logic;

  signal b_error       : std_logic_vector(7 downto 0);
  signal axi_overflows : std_logic_vector(3 downto 0);
  signal errors_i      : std_logic_vector(15 downto 0);  -- errors internal
  signal errors_l      : std_logic_vector(15 downto 0);  -- errors latched

  signal rstn : std_logic;

begin

  rstn <= not rst;

  -- ADDRESS

  -- first drive constant values:
  s_axi_arsize   <= "011";              --64b transfer
  s_axi_arburst  <= "01";               --burst type 1 (incremental)
  s_axi_arlock   <= "0";                --unused
  s_axi_arcache  <= "0000";             --unused
  s_axi_arprot   <= "000";              --unused
  s_axi_arqos    <= "0000";             --unused
  s_axi_arregion <= "0000";             --unused


  -- when valid sample is received, perform address write
  -- on the high-performance bus, the ready is guarenteed to be valid
  -- so no need to check ready here
  -- The fifo is used to ensure this further. It also should remain constantly
  -- ready.
  -- An additional layer of error checking is also included.

  s_axi_araddr(31 downto 7) <= block_array_in_addr;
  s_axi_araddr(6 downto 0)  <= "0000000";

  s_axi_arvalid <= block_array_in_valid;

  -- 128B write = transaction length of 16
  s_axi_arlen <= std_logic_vector(to_unsigned(LENGTH, 8));

  -- keep track of transaction ID
  s_axi_arid <= std_logic_vector(id_counter);

  -- DATA
  -- always ready
  s_axi_rready <= '1';


  -- mux data into register
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        axi_array_int       <= (others => (others => '0'));
        axi_array_int_valid <= '0';


      else
        axi_array_int_valid <= '0';

        for i in 0 to LENGTH-1 loop
          if (cycle_counter = i) then
            axi_array_int(i) <= s_axi_rdata;

          end if;
        end loop;  -- i

        if (cycle_counter = LENGTH-1) then
          axi_array_int_valid <= '1';

        end if;
      end if;
    end if;
  end process;

  -- generate cycle counter
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        cycle_counter <= (others => '0');

      else
        if (s_axi_rvalid = '1' and s_axi_rready = '1') then
          cycle_counter <= (others => '0');

        end if;

        if (s_axi_rvalid = '1' and s_axi_rready = '1') then
          if (s_axi_rlast = '0') then
            cycle_counter <= cycle_counter + "1";

          else
            --clear on last cycle
            cycle_counter <= (others => '0');

          end if;
        end if;
      end if;
    end if;
  end process;


  block_array_in_ready <= not (s_axi_rvalid and s_axi_rready);

  -- generate transaction counter
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        id_counter <= (others => '0');

      else
        -- increment id counter when last
        if (s_axi_rvalid = '1' and s_axi_rready = '1' and s_axi_rlast = '1') then
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
  -- check response
  -- check if the bresp is non-zero
  -- on error, also supply the transaction id
  b_error <= m_axi_rid & s_axi_rresp when (s_axi_rvalid = '1' and s_axi_rresp /= "00") else (others => '0');

  -- feed entire axi bus into bus fifo.
  -- the fifo absorbs any holdups on the bus and cleans up the handshaking.
  -- all that's required is that the fifo is monitored so it doesn't overflow

  axi_mm_fifo_rd_i : axi_mm_fifo_rd
    port map (
      s_aclk           => clk,
      s_aresetn        => rstn,
      s_axi_arid       => s_axi_arid,
      s_axi_araddr     => s_axi_araddr,
      s_axi_arlen      => s_axi_arlen,
      s_axi_arsize     => s_axi_arsize,
      s_axi_arburst    => s_axi_arburst,
      s_axi_arlock     => s_axi_arlock,
      s_axi_arcache    => s_axi_arcache,
      s_axi_arprot     => s_axi_arprot,
      s_axi_arqos      => s_axi_arqos,
      s_axi_arregion   => s_axi_arregion,
      s_axi_arvalid    => s_axi_arvalid,
      s_axi_arready    => s_axi_arready,
      s_axi_rid        => s_axi_rid,
      s_axi_rdata      => s_axi_rdata,
      s_axi_rresp      => s_axi_rresp,
      s_axi_rlast      => s_axi_rlast,
      s_axi_rvalid     => s_axi_rvalid,
      s_axi_rready     => s_axi_rready,
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
      m_axi_rid        => m_axi_rid,
      m_axi_rdata      => m_axi_rdata,
      m_axi_rresp      => m_axi_rresp,
      m_axi_rlast      => m_axi_rlast,
      m_axi_rvalid     => m_axi_rvalid,
      m_axi_rready     => m_axi_rready,
      axi_ar_overflow  => axi_overflows(0),
      axi_ar_underflow => axi_overflows(1),
      axi_r_overflow   => axi_overflows(2),
      axi_r_underflow  => axi_overflows(3)
      );


  errors_i(7 downto 0)   <= b_error;        -- axi b response errors
  errors_i(11 downto 8)  <= axi_overflows;  -- axi fifo overflow errors
  errors_i(13 downto 12) <= "00";           -- unused


  -- generate ready errors
  -- if I drive arvalid when it's not ready

  errors_i(14) <= '1' when s_axi_arvalid = '1' and s_axi_arready = '0';
  errors_i(15) <= '0';                  --unused

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

  -- cast and drive results
  block_array_out <= to_block_array(axi_array_int);
  block_array_out_valid <= axi_array_int_valid;


end behavioral;
