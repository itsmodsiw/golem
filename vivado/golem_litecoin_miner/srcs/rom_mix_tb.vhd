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


entity rom_mix_tb is
end rom_mix_tb;

architecture behavioral of rom_mix_tb is

  constant BLOCK_SIZE        : integer := 1;  --max 128
  constant BLOCK_SIZE_LOG2   : integer := 0;  --max 7
  constant NUM_ROUNDS        : integer := 8;
  constant N_DIFFICULTY_LOG2 : integer := 4;

  component rom_mix_stage1 is
    generic (
      BLOCK_SIZE        : integer;
      BLOCK_SIZE_LOG2   : integer;
      NUM_ROUNDS        : integer;
      N_DIFFICULTY_LOG2 : integer);
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
      block_array_in        : in  block_array;
      block_array_in_valid  : in  std_logic;
      block_array_in_ready  : out std_logic;
      block_array_out       : out block_array;
      block_array_out_valid : out std_logic;
      m_axi_awid            : out std_logic_vector(5 downto 0);
      m_axi_awaddr          : out std_logic_vector(31 downto 0);
      m_axi_awlen           : out std_logic_vector(7 downto 0);
      m_axi_awsize          : out std_logic_vector(2 downto 0);
      m_axi_awburst         : out std_logic_vector(1 downto 0);
      m_axi_awlock          : out std_logic_vector(0 downto 0);
      m_axi_awcache         : out std_logic_vector(3 downto 0);
      m_axi_awprot          : out std_logic_vector(2 downto 0);
      m_axi_awqos           : out std_logic_vector(3 downto 0);
      m_axi_awregion        : out std_logic_vector(3 downto 0);
      m_axi_awvalid         : out std_logic;
      m_axi_awready         : in  std_logic;
      m_axi_wdata           : out std_logic_vector(63 downto 0);
      m_axi_wstrb           : out std_logic_vector(7 downto 0);
      m_axi_wlast           : out std_logic;
      m_axi_wvalid          : out std_logic;
      m_axi_wready          : in  std_logic;
      m_axi_bid             : in  std_logic_vector(5 downto 0);
      m_axi_bresp           : in  std_logic_vector(1 downto 0);
      m_axi_bvalid          : in  std_logic;
      m_axi_bready          : out std_logic;
      errors                : out std_logic_vector(15 downto 0));
  end component rom_mix_stage1;

  component rom_mix_stage2 is
    generic (
      BLOCK_SIZE        : integer;
      BLOCK_SIZE_LOG2   : integer;
      NUM_ROUNDS        : integer;
      N_DIFFICULTY_LOG2 : integer);
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
      block_array_in        : in  block_array;
      block_array_in_valid  : in  std_logic;
      block_array_in_ready  : out std_logic;
      block_array_out       : out block_array;
      block_array_out_valid : out std_logic;
      m_axi_arid            : out std_logic_vector(5 downto 0);
      m_axi_araddr          : out std_logic_vector(31 downto 0);
      m_axi_arlen           : out std_logic_vector(7 downto 0);
      m_axi_arsize          : out std_logic_vector(2 downto 0);
      m_axi_arburst         : out std_logic_vector(1 downto 0);
      m_axi_arlock          : out std_logic_vector(0 downto 0);
      m_axi_arcache         : out std_logic_vector(3 downto 0);
      m_axi_arprot          : out std_logic_vector(2 downto 0);
      m_axi_arqos           : out std_logic_vector(3 downto 0);
      m_axi_arregion        : out std_logic_vector(3 downto 0);
      m_axi_arvalid         : out std_logic;
      m_axi_arready         : in  std_logic;
      m_axi_rdata           : in  std_logic_vector(63 downto 0);
      m_axi_rstrb           : in  std_logic_vector(7 downto 0);
      m_axi_rlast           : in  std_logic;
      m_axi_rready          : out std_logic;
      m_axi_rid             : in  std_logic_vector(5 downto 0);
      m_axi_rresp           : in  std_logic_vector(1 downto 0);
      m_axi_rvalid          : in  std_logic;
      errors                : out std_logic_vector(15 downto 0));
  end component rom_mix_stage2;

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


  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  signal rstn : std_logic := '0';

  signal errors_stage1 : std_logic_vector(15 downto 0);
  signal errors_stage2 : std_logic_vector(15 downto 0);

  signal block_array_in_stage1        : block_array;
  signal block_array_in_stage1_valid  : std_logic := '0';
  signal block_array_in_stage1_ready  : std_logic;
  signal block_array_out_stage1       : block_array;
  signal block_array_out_stage1_valid : std_logic;

  signal block_array_in_stage2        : block_array;
  signal block_array_in_stage2_valid  : std_logic := '0';
  signal block_array_in_stage2_ready  : std_logic;
  signal block_array_out_stage2       : block_array;
  signal block_array_out_stage2_valid : std_logic;


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
  signal m_axi_rstrb    : std_logic_vector(7 downto 0);
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

  block_array_in_stage1(0)(0)  <= X"650BCEF7";
  block_array_in_stage1(0)(1)  <= X"A4722D3D";
  block_array_in_stage1(0)(2)  <= X"ABF58C10";
  block_array_in_stage1(0)(3)  <= X"DDFF12E9";
  block_array_in_stage1(0)(4)  <= X"DB167677";
  block_array_in_stage1(0)(5)  <= X"0EA727BB";
  block_array_in_stage1(0)(6)  <= X"AEF30482";
  block_array_in_stage1(0)(7)  <= X"AD6F0F2D";
  block_array_in_stage1(0)(8)  <= X"488FF689";
  block_array_in_stage1(0)(9)  <= X"7BE8D111";
  block_array_in_stage1(0)(10) <= X"40D73BCC";
  block_array_in_stage1(0)(11) <= X"29FD9F0A";
  block_array_in_stage1(0)(12) <= X"84014F09";
  block_array_in_stage1(0)(13) <= X"F3749563";
  block_array_in_stage1(0)(14) <= X"31A1E59A";
  block_array_in_stage1(0)(15) <= X"D7BC1752";


  block_array_in_stage1(1)(0)  <= X"44914989";
  block_array_in_stage1(1)(1)  <= X"22BB1372";
  block_array_in_stage1(1)(2)  <= X"4DB5256C";
  block_array_in_stage1(1)(3)  <= X"FB7063A8";
  block_array_in_stage1(1)(4)  <= X"804398CD";
  block_array_in_stage1(1)(5)  <= X"BB664637";
  block_array_in_stage1(1)(6)  <= X"BFB5FC8F";
  block_array_in_stage1(1)(7)  <= X"B054C240";
  block_array_in_stage1(1)(8)  <= X"517CD267";
  block_array_in_stage1(1)(9)  <= X"FED54ACE";
  block_array_in_stage1(1)(10) <= X"0BC929D8";
  block_array_in_stage1(1)(11) <= X"1B575A50";
  block_array_in_stage1(1)(12) <= X"AD1C4D7F";
  block_array_in_stage1(1)(13) <= X"DA3C526A";
  block_array_in_stage1(1)(14) <= X"BC670E77";
  block_array_in_stage1(1)(15) <= X"897EAFEA";


  process
  begin

    block_array_in_stage1_valid <= '0';
    wait for CLK_PERIOD*100;
    block_array_in_stage1_valid <= '1';
    wait for CLK_PERIOD;
    block_array_in_stage1_valid <= '0';
    wait;
  end process;


  -- uut
  rom_mix_stage1_i : rom_mix_stage1
    generic map (
      BLOCK_SIZE        => BLOCK_SIZE,
      BLOCK_SIZE_LOG2   => BLOCK_SIZE_LOG2,
      NUM_ROUNDS        => NUM_ROUNDS,
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk                   => clk,
      rst                   => rst,
      block_array_in        => block_array_in_stage1,
      block_array_in_valid  => block_array_in_stage1_valid,
      block_array_in_ready  => block_array_in_stage1_ready,
      block_array_out       => block_array_out_stage1,
      block_array_out_valid => block_array_out_stage1_valid,
      m_axi_awid            => m_axi_awid,
      m_axi_awaddr          => m_axi_awaddr,
      m_axi_awlen           => m_axi_awlen,
      m_axi_awsize          => m_axi_awsize,
      m_axi_awburst         => m_axi_awburst,
      m_axi_awlock          => m_axi_awlock,
      m_axi_awcache         => m_axi_awcache,
      m_axi_awprot          => m_axi_awprot,
      m_axi_awqos           => m_axi_awqos,
      m_axi_awregion        => m_axi_awregion,
      m_axi_awvalid         => m_axi_awvalid,
      m_axi_awready         => m_axi_awready,
      m_axi_wdata           => m_axi_wdata,
      m_axi_wstrb           => m_axi_wstrb,
      m_axi_wlast           => m_axi_wlast,
      m_axi_wvalid          => m_axi_wvalid,
      m_axi_wready          => m_axi_wready,
      m_axi_bid             => m_axi_bid,
      m_axi_bresp           => m_axi_bresp,
      m_axi_bvalid          => m_axi_bvalid,
      m_axi_bready          => m_axi_bready,
      errors                => errors_stage1);


  block_array_in_stage2       <= block_array_out_stage1;
  block_array_in_stage2_valid <= block_array_out_stage1_valid;


  rom_mix_stage2_1 : rom_mix_stage2
    generic map (
      BLOCK_SIZE        => BLOCK_SIZE,
      BLOCK_SIZE_LOG2   => BLOCK_SIZE_LOG2,
      NUM_ROUNDS        => NUM_ROUNDS,
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk                   => clk,
      rst                   => rst,
      block_array_in        => block_array_in_stage2,
      block_array_in_valid  => block_array_in_stage2_valid,
      block_array_in_ready  => block_array_in_stage2_ready,
      block_array_out       => block_array_out_stage2,
      block_array_out_valid => block_array_out_stage2_valid,
      m_axi_arid            => m_axi_arid,
      m_axi_araddr          => m_axi_araddr,
      m_axi_arlen           => m_axi_arlen,
      m_axi_arsize          => m_axi_arsize,
      m_axi_arburst         => m_axi_arburst,
      m_axi_arlock          => m_axi_arlock,
      m_axi_arcache         => m_axi_arcache,
      m_axi_arprot          => m_axi_arprot,
      m_axi_arqos           => m_axi_arqos,
      m_axi_arregion        => m_axi_arregion,
      m_axi_arvalid         => m_axi_arvalid,
      m_axi_arready         => m_axi_arready,
      m_axi_rdata           => m_axi_rdata,
      m_axi_rstrb           => m_axi_rstrb,
      m_axi_rlast           => m_axi_rlast,
      m_axi_rready          => m_axi_rready,
      m_axi_rid             => m_axi_rid,
      m_axi_rresp           => m_axi_rresp,
      m_axi_rvalid          => m_axi_rvalid,
      errors                => errors_stage2);


  -- check block_array out.
  block_array_expected(0)(0)  <= X"9C851FA4";
  block_array_expected(0)(1)  <= X"99CC0866";
  block_array_expected(0)(2)  <= X"CBCA813B";
  block_array_expected(0)(3)  <= X"05EF0C02";
  block_array_expected(0)(4)  <= X"81214B04";
  block_array_expected(0)(5)  <= X"7D33FDA2";
  block_array_expected(0)(6)  <= X"631C7BFD";
  block_array_expected(0)(7)  <= X"292F6896";
  block_array_expected(0)(8)  <= X"683139B4";
  block_array_expected(0)(9)  <= X"BCE6C9E3";
  block_array_expected(0)(10) <= X"B7C56BFE";
  block_array_expected(0)(11) <= X"BA966DA0";
  block_array_expected(0)(12) <= X"10CC24E4";
  block_array_expected(0)(13) <= X"5C74912C";
  block_array_expected(0)(14) <= X"3D67AD24";
  block_array_expected(0)(15) <= X"818F61C7";

  block_array_expected(1)(0)  <= X"75C9ED20";
  block_array_expected(1)(1)  <= X"A8813832";
  block_array_expected(1)(2)  <= X"4CF64005";
  block_array_expected(1)(3)  <= X"3CCD2D16";
  block_array_expected(1)(4)  <= X"FE7C0721";
  block_array_expected(1)(5)  <= X"E25F8D5F";
  block_array_expected(1)(6)  <= X"8F16A4B1";
  block_array_expected(1)(7)  <= X"B7783695";
  block_array_expected(1)(8)  <= X"803D3B7D";
  block_array_expected(1)(9)  <= X"ABE4603B";
  block_array_expected(1)(10) <= X"E5960992";
  block_array_expected(1)(11) <= X"B6534D9B";
  block_array_expected(1)(12) <= X"58222A5D";
  block_array_expected(1)(13) <= X"F5EDD577";
  block_array_expected(1)(14) <= X"F1B92C84";
  block_array_expected(1)(15) <= X"25E4EF4E";

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        block_array_error       <= (others => (others => '0'));
        block_array_error_valid <= '0';

      else
        block_array_error_valid <= block_array_out_stage2_valid;

        for j in 0 to 1 loop
          for i in 0 to 15 loop
            if (block_array_out_stage2(j)(i) = block_array_expected(j)(i)) then
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
