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


entity scrypt_tb is
end scrypt_tb;

architecture behavioral of scrypt_tb is

  constant N_DIFFICULTY_LOG2 : integer := 4;

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
      hash_out         : out std_logic_vector(255 downto 0);
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

  component sdram_mem is
    port (
      S_AXI_ACLK    : in  std_logic;
      S_AXI_ARESETN : in  std_logic;
      S_AXI_AWID    : in  std_logic_vector(5 downto 0);
      S_AXI_AWADDR  : in  std_logic_vector(31 downto 0);
      S_AXI_AWLEN   : in  std_logic_vector(7 downto 0);
      S_AXI_AWSIZE  : in  std_logic_vector(2 downto 0);
      S_AXI_AWBURST : in  std_logic_vector(1 downto 0);
      S_AXI_AWCACHE : in  std_logic_vector(3 downto 0);
      S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
      S_AXI_AWVALID : in  std_logic;
      S_AXI_AWREADY : out std_logic;
      S_AXI_WDATA   : in  std_logic_vector(63 downto 0);
      S_AXI_WSTRB   : in  std_logic_vector(7 downto 0);
      S_AXI_WLAST   : in  std_logic;
      S_AXI_WVALID  : in  std_logic;
      S_AXI_WREADY  : out std_logic;
      S_AXI_BID     : out std_logic_vector(5 downto 0);
      S_AXI_BRESP   : out std_logic_vector(1 downto 0);
      S_AXI_BVALID  : out std_logic;
      S_AXI_BREADY  : in  std_logic;
      S_AXI_ARADDR  : in  std_logic_vector(31 downto 0);
      S_AXI_ARLEN   : in  std_logic_vector(7 downto 0);
      S_AXI_ARSIZE  : in  std_logic_vector(2 downto 0);
      S_AXI_ARBURST : in  std_logic_vector(1 downto 0);
      S_AXI_ARCACHE : in  std_logic_vector(3 downto 0);
      S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
      S_AXI_ARVALID : in  std_logic;
      S_AXI_ARREADY : out std_logic;
      S_AXI_RDATA   : out std_logic_vector(63 downto 0);
      S_AXI_RLAST   : out std_logic;
      S_AXI_RREADY  : in  std_logic;
      S_AXI_RRESP   : out std_logic_vector(1 downto 0);
      S_AXI_RVALID  : out std_logic);

  end component sdram_mem;


  signal clk  : std_logic := '1';
  signal rst  : std_logic := '1';
  signal rstn : std_logic := '0';

  signal errors_stage1 : std_logic_vector(15 downto 0);
  signal errors_stage2 : std_logic_vector(15 downto 0);

  constant C_BLOCK_LENGTH : integer               := 20;
  constant START_COUNT       : unsigned(31 downto 0) := to_unsigned(100, 32);

  signal block_in_counter : unsigned(31 downto 0);
  signal start_counter    : unsigned(31 downto 0);

  signal block_in_busy : std_logic;

  signal block_array_in        : block_array;
  signal block_array_in_4B     : std_logic_vector(31 downto 0);
  signal block_array_in_valid  : std_logic := '0';
  signal block_array_in_ready  : std_logic;
  signal block_array_in_last   : std_logic;
  signal block_array_out       : block_array;
  signal block_array_out_4B    : std_logic_vector(31 downto 0);
  signal block_array_out_valid : std_logic;
  signal block_array_out_last  : std_logic;
  signal block_array_out_ready : std_logic;

  signal block_array_expected    : block_array;
  signal block_array_error_valid : std_logic;

  type block_error is array (1 downto 0) of std_logic_vector(15 downto 0);

  signal block_array_error : block_error;

  signal fail_flag : std_logic;
  signal pass_flag : std_logic;

  signal cycle_counter : unsigned(31 downto 0);

  constant CLK_PERIOD : time := 8 ns;

  signal m_axi_arid     : std_logic_vector(5 downto 0);
  signal m_axi_araddr   : std_logic_vector(31 downto 0);
  signal m_axi_arlen    : std_logic_vector(7 downto 0);
  signal m_axi_arsize   : std_logic_vector(2 downto 0);
  signal m_axi_arburst  : std_logic_vector(1 downto 0);
  signal m_axi_arlock   : std_logic_vector(0 downto 0);
  signal m_axi_arcache  : std_logic_vector(3 downto 0);
  signal m_axi_arprot   : std_logic_vector(2 downto 0);
  signal m_axi_arqos    : std_logic_vector(3 downto 0);
  signal m_axi_arregion : std_logic_vector(3 downto 0);
  signal m_axi_arvalid  : std_logic;
  signal m_axi_arready  : std_logic;
  signal m_axi_rdata    : std_logic_vector(63 downto 0);
  signal m_axi_rlast    : std_logic;
  signal m_axi_rready   : std_logic;
  signal m_axi_rid      : std_logic_vector(5 downto 0);
  signal m_axi_rresp    : std_logic_vector(1 downto 0);
  signal m_axi_rvalid   : std_logic;

  signal m_axi_awid     : std_logic_vector(5 downto 0);
  signal m_axi_awaddr   : std_logic_vector(31 downto 0);
  signal m_axi_awlen    : std_logic_vector(7 downto 0);
  signal m_axi_awsize   : std_logic_vector(2 downto 0);
  signal m_axi_awburst  : std_logic_vector(1 downto 0);
  signal m_axi_awlock   : std_logic_vector(0 downto 0);
  signal m_axi_awcache  : std_logic_vector(3 downto 0);
  signal m_axi_awprot   : std_logic_vector(2 downto 0);
  signal m_axi_awqos    : std_logic_vector(3 downto 0);
  signal m_axi_awregion : std_logic_vector(3 downto 0);
  signal m_axi_awvalid  : std_logic;
  signal m_axi_awready  : std_logic;
  signal m_axi_wdata    : std_logic_vector(63 downto 0);
  signal m_axi_wstrb    : std_logic_vector(7 downto 0);
  signal m_axi_wlast    : std_logic;
  signal m_axi_wvalid   : std_logic;
  signal m_axi_wready   : std_logic;
  signal m_axi_bid      : std_logic_vector(5 downto 0);
  signal m_axi_bresp    : std_logic_vector(1 downto 0);
  signal m_axi_bvalid   : std_logic;
  signal m_axi_bready   : std_logic;

begin

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


  block_array_in(0)  <= X"00000041";
  block_array_in(1)  <= X"00000042";
  block_array_in(2)  <= X"00000043";
  block_array_in(3)  <= X"00000044";
  block_array_in(4)  <= X"00000045";
  block_array_in(5)  <= X"00000046";
  block_array_in(6)  <= X"00000047";
  block_array_in(7)  <= X"00000048";
  block_array_in(8)  <= X"00000049";
  block_array_in(9)  <= X"0000004A";
  block_array_in(10) <= X"0000004B";
  block_array_in(11) <= X"0000004C";
  block_array_in(12) <= X"0000004D";
  block_array_in(13) <= X"0000004E";
  block_array_in(14) <= X"0000004F";
  block_array_in(15) <= X"00000050";
  block_array_in(16) <= X"00000051";
  block_array_in(17) <= X"00000052";
  block_array_in(18) <= X"00000053";
  block_array_in(19) <= X"00000018";



  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        start_counter     <= (others => '0');

        block_array_in_valid <= '0';

        block_in_busy <= '0';
        block_in_counter     <= (others => '0');

      else

        if (block_in_busy = '0') then
          if (start_counter < START_COUNT) then
            start_counter <= start_counter + 1;
          else
            block_in_busy        <= '1';
            block_array_in_valid <= '1';
            start_counter        <= (others => '0');

          end if;
        end if;

        if (block_in_busy = '1' and block_array_in_ready = '1') then
          if (block_in_counter < to_unsigned(C_BLOCK_LENGTH-1, 32)) then
            block_in_counter <= block_in_counter + 1;

          else
            block_in_counter     <= (others => '0');
            block_array_in_valid <= '0';

          end if;

        end if;


        --if hash out, clear busies
        if (block_array_out_valid = '1' and block_array_out_last = '1' and block_array_out_ready = '1') then
          block_in_busy <= '0';

        end if;

      end if;
    end if;
  end process;

  block_array_in_last <= '1' when block_in_counter = to_unsigned(C_BLOCK_LENGTH-1, 32) else '0';

  block_in_gen : for i in 0 to C_BLOCK_LENGTH-1 generate
    block_array_in_4B <= block_array_in(i) when (block_in_counter = i) else (others => 'Z');

  end generate block_in_gen;

  block_array_out_ready <= '1';

  -- uut
  scrypt_1: entity work.scrypt
    generic map (
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk              => clk,
      rst              => rst,
      message_in       => block_array_in_4B,
      message_in_valid => block_array_in_valid,
      message_in_last  => block_array_in_last,
      message_in_ready => block_array_in_ready,
      hash_out         => block_array_out_4B,
      hash_out_valid   => block_array_out_valid,
      hash_out_last    => block_array_out_last,
      hash_out_ready   => block_array_out_ready,
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


  -- check block_array out.
  block_array_expected(0)  <= X"02D607D2";
  block_array_expected(1)  <= X"5A41D58D";
  block_array_expected(2)  <= X"FE968209";
  block_array_expected(3)  <= X"D7B660B2";
  block_array_expected(4)  <= X"93F03ABD";
  block_array_expected(5)  <= X"7C9BB078";
  block_array_expected(6)  <= X"F030B7DA";
  block_array_expected(7)  <= X"E06D7A73";
  block_array_expected(8)  <= X"C00B2D87";
  block_array_expected(9)  <= X"A298D4E9";
  block_array_expected(10) <= X"20BD2952";
  block_array_expected(11) <= X"3508AE12";
  block_array_expected(12) <= X"BC655315";
  block_array_expected(13) <= X"960DB0DE";
  block_array_expected(14) <= X"21B9A2C7";
  block_array_expected(15) <= X"595C5ED6";
  block_array_expected(16) <= X"A5790009";
  block_array_expected(17) <= X"D61373C7";
  block_array_expected(18) <= X"DF6B64CA";
  block_array_expected(19) <= X"454688EE";
  block_array_expected(20) <= X"EDFE6CB7";
  block_array_expected(21) <= X"132A6DF9";
  block_array_expected(22) <= X"25914C9B";
  block_array_expected(23) <= X"790458EE";
  block_array_expected(24) <= X"2A68800C";
  block_array_expected(25) <= X"9EE4FD15";
  block_array_expected(26) <= X"A8E8B35B";
  block_array_expected(27) <= X"CADAD4BE";
  block_array_expected(28) <= X"B6CFE430";
  block_array_expected(29) <= X"E433B530";
  block_array_expected(30) <= X"9C81651F";
  block_array_expected(31) <= X"4CAC36A7";


  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        block_array_error       <= (others => (others => '0'));
        block_array_error_valid <= '0';

      else
        block_array_error_valid <= block_array_out_valid;

        for j in 0 to 1 loop
          for i in 0 to 15 loop
            if (block_array_out(j)(i) = block_array_expected(j)(i)) then
              block_array_error(j)(i) <= '0';
            else
              block_array_error(j)(i) <= '1';
            end if;
          end loop;
        end loop;
      end if;
    end if;
  end process;

  pass_flag <= '1' when block_array_error(0) = X"0000" and block_array_error(1) = X"0000" and block_array_error_valid = '1'    else '0';
  fail_flag <= '1' when (block_array_error(0) /= X"0000" or block_array_error(1) /= X"0000") and block_array_error_valid = '1' else '0';


  -- AXI memory interface for simulation
  sdram_mem_1 : sdram_mem
    port map (
      S_AXI_ACLK    => clk,
      S_AXI_ARESETN => rstn,
      S_AXI_AWID    => M_AXI_AWID,
      S_AXI_AWADDR  => M_AXI_AWADDR,
      S_AXI_AWLEN   => M_AXI_AWLEN,
      S_AXI_AWSIZE  => M_AXI_AWSIZE,
      S_AXI_AWBURST => M_AXI_AWBURST,
      S_AXI_AWCACHE => M_AXI_AWCACHE,
      S_AXI_AWPROT  => M_AXI_AWPROT,
      S_AXI_AWVALID => M_AXI_AWVALID,
      S_AXI_AWREADY => M_AXI_AWREADY,
      S_AXI_WDATA   => M_AXI_WDATA,
      S_AXI_WSTRB   => M_AXI_WSTRB,
      S_AXI_WLAST   => M_AXI_WLAST,
      S_AXI_WVALID  => M_AXI_WVALID,
      S_AXI_WREADY  => M_AXI_WREADY,
      S_AXI_BID     => M_AXI_BID,
      S_AXI_BRESP   => M_AXI_BRESP,
      S_AXI_BVALID  => M_AXI_BVALID,
      S_AXI_BREADY  => M_AXI_BREADY,
      S_AXI_ARADDR  => M_AXI_ARADDR,
      S_AXI_ARLEN   => M_AXI_ARLEN,
      S_AXI_ARSIZE  => M_AXI_ARSIZE,
      S_AXI_ARBURST => M_AXI_ARBURST,
      S_AXI_ARCACHE => M_AXI_ARCACHE,
      S_AXI_ARPROT  => M_AXI_ARPROT,
      S_AXI_ARVALID => M_AXI_ARVALID,
      S_AXI_ARREADY => M_AXI_ARREADY,
      S_AXI_RDATA   => M_AXI_RDATA,
      S_AXI_RLAST   => M_AXI_RLAST,
      S_AXI_RREADY  => M_AXI_RREADY,
      S_AXI_RRESP   => M_AXI_RRESP,
      S_AXI_RVALID  => M_AXI_RVALID);

end behavioral;
