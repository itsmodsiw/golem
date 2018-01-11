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


entity rom_mix is
  generic (
    N_DIFFICULTY_LOG2 : integer := 10
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    block_array_in       : in  std_logic_vector(31 downto 0);
    block_array_in_valid : in  std_logic;
    block_array_in_last  : in  std_logic;
    block_array_in_ready : out std_logic;

    block_array_out       : out std_logic_vector(31 downto 0);
    block_array_out_valid : out std_logic;
    block_array_out_last  : out std_logic;
    block_array_out_ready : in  std_logic;

    -- axi memory bus write
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

    -- axi memory bus read
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

    errors_1 : out std_logic_vector(15 downto 0);
    errors_2 : out std_logic_vector(15 downto 0)

    );

end rom_mix;

architecture behavioral of rom_mix is
  component rom_mix_stage1 is
    generic (
      N_DIFFICULTY_LOG2 : integer);
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
      busy                  : out std_logic;
      block_array_in        : in  std_logic_vector(31 downto 0);
      block_array_in_valid  : in  std_logic;
      block_array_in_last   : in  std_logic;
      block_array_in_ready  : out std_logic;
      block_array_out       : out std_logic_vector(31 downto 0);
      block_array_out_valid : out std_logic;
      block_array_out_last  : out std_logic;
      block_array_out_ready : in  std_logic;
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
      errors                : out std_logic_vector(15 downto 0);
      block_mix_in          : out block_array;
      block_mix_in_valid    : out std_logic;
      block_mix_in_ready    : in  std_logic;
      block_mix_out         : in  block_array;
      block_mix_out_valid   : in  std_logic);
  end component rom_mix_stage1;

  component rom_mix_stage2 is
    generic (
      N_DIFFICULTY_LOG2 : integer);
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
      busy                  : out std_logic;
      block_array_in        : in  std_logic_vector(31 downto 0);
      block_array_in_valid  : in  std_logic;
      block_array_in_last   : in  std_logic;
      block_array_in_ready  : out std_logic;
      block_array_out       : out std_logic_vector(31 downto 0);
      block_array_out_valid : out std_logic;
      block_array_out_last  : out std_logic;
      block_array_out_ready : in  std_logic;
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
      m_axi_rlast           : in  std_logic;
      m_axi_rready          : out std_logic;
      m_axi_rid             : in  std_logic_vector(5 downto 0);
      m_axi_rresp           : in  std_logic_vector(1 downto 0);
      m_axi_rvalid          : in  std_logic;
      errors                : out std_logic_vector(15 downto 0);
      block_mix_in          : out block_array;
      block_mix_in_valid    : out std_logic;
      block_mix_in_ready    : in  std_logic;
      block_mix_out         : in  block_array;
      block_mix_out_valid   : in  std_logic);
  end component rom_mix_stage2;


  component block_mix is
    port (
      clk : in std_logic;
      rst : in std_logic;

      block_array_in       : in  block_array;
      block_array_in_valid : in  std_logic;
      block_array_in_ready : out std_logic;

      block_array_out       : out block_array;
      block_array_out_valid : out std_logic


      );

  end component;

  signal x_int       : std_logic_vector(31 downto 0);
  signal x_int_valid : std_logic;
  signal x_int_ready : std_logic;
  signal x_int_last  : std_logic;

  signal busy_1 : std_logic;
  signal busy_2 : std_logic;


  signal block_mix_in_1        : block_array;
  signal block_mix_in_1_valid  : std_logic;
  signal block_mix_in_1_ready  : std_logic;
  signal block_mix_out_1       : block_array;
  signal block_mix_out_1_valid : std_logic;

  signal block_mix_in_2        : block_array;
  signal block_mix_in_2_valid  : std_logic;
  signal block_mix_in_2_ready  : std_logic;
  signal block_mix_out_2       : block_array;
  signal block_mix_out_2_valid : std_logic;

  signal block_mix_in        : block_array;
  signal block_mix_in_valid  : std_logic;
  signal block_mix_in_ready  : std_logic;
  signal block_mix_out       : block_array;
  signal block_mix_out_valid : std_logic;


  signal block_array_in_ready_i  : std_logic;
  signal block_array_out_i       : std_logic_vector(31 downto 0);
  signal block_array_out_valid_i : std_logic;
  signal block_array_out_last_i  : std_logic;

begin

  --generate ready

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        block_array_in_ready_i <= '1';

      else
        -- de-assert ready when valid data received
        if (block_array_in_valid = '1' and block_array_in_last = '1' and block_array_in_ready_i = '1') then
          block_array_in_ready_i <= '0';

        end if;

        -- assert again when done.
        if (block_array_out_valid_i = '1' and block_array_out_last_i = '1' and block_array_out_ready = '1' and block_array_in_ready_i = '0') then
          block_array_in_ready_i <= '1';

        end if;


      end if;
    end if;
  end process;

  block_array_in_ready <= block_array_in_ready_i;


  rom_mix_stage1_i : rom_mix_stage1
    generic map (
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk                   => clk,
      rst                   => rst,
      busy                  => busy_1,
      block_array_in        => block_array_in,
      block_array_in_valid  => block_array_in_valid,
      block_array_in_ready  => open,
      block_array_in_last   => block_array_in_last,
      block_array_out       => x_int,
      block_array_out_valid => x_int_valid,
      block_array_out_last  => x_int_last,
      block_array_out_ready => x_int_ready,
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
      errors                => errors_1,
      block_mix_in          => block_mix_in_1,
      block_mix_in_valid    => block_mix_in_1_valid,
      block_mix_in_ready    => block_mix_in_1_ready,
      block_mix_out         => block_mix_out_1,
      block_mix_out_valid   => block_mix_out_1_valid

      );

  rom_mix_stage2_i : rom_mix_stage2
    generic map (
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk                   => clk,
      rst                   => rst,
      busy                  => busy_2,
      block_array_in        => x_int,
      block_array_in_valid  => x_int_valid,
      block_array_in_ready  => x_int_ready,
      block_array_in_last   => x_int_last,
      block_array_out       => block_array_out_i,
      block_array_out_valid => block_array_out_valid_i,
      block_array_out_last  => block_array_out_last_i,
      block_array_out_ready => block_array_out_ready,
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
      m_axi_rlast           => m_axi_rlast,
      m_axi_rready          => m_axi_rready,
      m_axi_rid             => m_axi_rid,
      m_axi_rresp           => m_axi_rresp,
      m_axi_rvalid          => m_axi_rvalid,
      errors                => errors_2,
      block_mix_in          => block_mix_in_2,
      block_mix_in_valid    => block_mix_in_2_valid,
      block_mix_in_ready    => block_mix_in_2_ready,
      block_mix_out         => block_mix_out_2,
      block_mix_out_valid   => block_mix_out_2_valid

      );


  block_mix_i : block_mix
    port map (
      clk                  => clk,
      rst                  => rst,
      block_array_in       => block_mix_in,
      block_array_in_valid => block_mix_in_valid,
      block_array_in_ready => block_mix_in_ready,

      block_array_out       => block_mix_out,
      block_array_out_valid => block_mix_out_valid

      );

  -- mux blockmix
  block_mix_in       <= block_mix_in_1       when (busy_1 = '1') else block_mix_in_2;
  block_mix_in_valid <= block_mix_in_1_valid when (busy_1 = '1') else block_mix_in_2_valid;

  block_mix_in_1_ready  <= block_mix_in_ready  when (busy_1 = '1') else '0';
  block_mix_out_1       <= block_mix_out;
  block_mix_out_1_valid <= block_mix_out_valid when (busy_1 = '1') else '0';

  block_mix_in_2_ready  <= block_mix_in_ready  when (busy_2 = '1') else '0';
  block_mix_out_2       <= block_mix_out;
  block_mix_out_2_valid <= block_mix_out_valid when (busy_2 = '1') else '0';

  block_array_out       <= block_array_out_i;
  block_array_out_valid <= block_array_out_valid_i;
  block_array_out_last  <= block_array_out_last_i;

end behavioral;
