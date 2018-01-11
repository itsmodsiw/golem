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


entity scrypt is
  generic (
    N_DIFFICULTY_LOG2 : integer := 10);
  port (
    clk : in std_logic;
    rst : in std_logic;

    message_in       : in  std_logic_vector(31 downto 0);
    message_in_valid : in  std_logic;
    message_in_last  : in  std_logic;
    message_in_ready : out std_logic;

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
    m_axi_rvalid   : in  std_logic;

    error_out : out std_logic_vector(3 downto 0)

    );

end scrypt;

architecture behavioral of scrypt is

  component pbkdf_hmac_sha256 is
    port (
      clk                      : in  std_logic;
      rst                      : in  std_logic;
      iteration                : in  std_logic_vector(31 downto 0);
      iteration_valid          : in  std_logic;
      password_in_length       : in  std_logic_vector(63 downto 0);
      password_in_length_valid : in  std_logic;
      password_in              : in  std_logic_vector(31 downto 0);
      password_in_valid        : in  std_logic;
      password_in_last         : in  std_logic;
      password_in_ready        : out std_logic;
      salt_in_length           : in  std_logic_vector(63 downto 0);
      salt_in_length_valid     : in  std_logic;
      salt_in                  : in  std_logic_vector(31 downto 0);
      salt_in_valid            : in  std_logic;
      salt_in_last             : in  std_logic;
      salt_in_ready            : out std_logic;
      hash_out_length          : out std_logic_vector(63 downto 0);
      hash_out_length_valid    : out std_logic;
      hash_out                 : out std_logic_vector(31 downto 0);
      hash_out_valid           : out std_logic;
      hash_out_last            : out std_logic;
      hash_out_ready           : in  std_logic;
      error_out                : out std_logic_vector(3 downto 0));
  end component pbkdf_hmac_sha256;

  component rom_mix is
    generic (
      N_DIFFICULTY_LOG2 : integer);
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
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
      errors_1              : out std_logic_vector(15 downto 0);
      errors_2              : out std_logic_vector(15 downto 0));
  end component rom_mix;

  signal start_valid                 : std_logic;
  signal block_start_valid           : std_logic;
  signal message_in_ready_password_1 : std_logic;
  signal message_in_ready_password_2 : std_logic;
  signal message_in_ready_salt       : std_logic;
  signal message_in_valid_z          : std_logic;
  signal message_in_valid_salt       : std_logic;
  signal message_in_valid_password_1 : std_logic;
  signal message_in_valid_password_2 : std_logic;
  signal block_array_out_valid_z     : std_logic;

  signal block_array_in        : std_logic_vector(31 downto 0);
  signal block_array_in_swp    : std_logic_vector(31 downto 0);
  signal block_array_in_valid  : std_logic;
  signal block_array_in_last   : std_logic;
  signal block_array_in_ready  : std_logic;
  signal block_array_out       : std_logic_vector(31 downto 0);
  signal block_array_out_swp   : std_logic_vector(31 downto 0);
  signal block_array_out_valid : std_logic;
  signal block_array_out_last  : std_logic;
  signal block_array_out_ready : std_logic;
  signal errors_1              : std_logic_vector(15 downto 0);
  signal errors_2              : std_logic_vector(15 downto 0);


begin

  -- this is a 3-way axi-stream split
  -- performed as follows:
  -- 1) Ready is the OR of all three destination readies.
  -- 2) A new valid for each destination is generated using the source valid and the two
  -- other destination readies. This ensures that all destinations are ready,
  -- and that all destinations receive valid data only when the others receive
  -- it too.
  -- Ready generation:
  message_in_ready <= message_in_ready_password_1 and message_in_ready_password_2 and message_in_ready_salt;

  -- Valid generation
  message_in_valid_salt       <= message_in_valid and message_in_ready_password_1 and message_in_ready_password_2;
  message_in_valid_password_1 <= message_in_valid and message_in_ready_salt and message_in_ready_password_2;
  message_in_valid_password_2 <= message_in_valid and message_in_ready_salt and message_in_ready_password_1;

  start_valid       <= message_in_valid and not message_in_valid_z;
  block_start_valid <= block_array_out_valid and not block_array_out_valid_z;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        message_in_valid_z      <= '0';
        block_array_out_valid_z <= '0';

      else
        message_in_valid_z      <= message_in_valid;
        block_array_out_valid_z <= block_array_out_valid;

      end if;
    end if;
  end process;

  pbkdf_hmac_sha256_1 : pbkdf_hmac_sha256
    port map (
      clk                      => clk,
      rst                      => rst,
      iteration                => std_logic_vector(to_unsigned(4, 32)),
      iteration_valid          => start_valid,
      password_in_length       => std_logic_vector(to_unsigned(80, 64)),
      password_in_length_valid => start_valid,
      password_in              => message_in,
      password_in_valid        => message_in_valid_password_1,
      password_in_last         => message_in_last,
      password_in_ready        => message_in_ready_password_1,
      salt_in_length           => std_logic_vector(to_unsigned(80, 64)),
      salt_in_length_valid     => start_valid,
      salt_in                  => message_in,
      salt_in_valid            => message_in_valid_salt,
      salt_in_last             => message_in_last,
      salt_in_ready            => message_in_ready_salt,
      hash_out_length          => open,
      hash_out_length_valid    => open,
      hash_out                 => block_array_in,
      hash_out_valid           => block_array_in_valid,
      hash_out_last            => block_array_in_last,
      hash_out_ready           => block_array_in_ready,
      error_out                => open);

  -- endian swap on data
  block_array_in_swp(31 downto 24) <= block_array_in(7 downto 0);
  block_array_in_swp(23 downto 16) <= block_array_in(15 downto 8);
  block_array_in_swp(15 downto 8)  <= block_array_in(23 downto 16);
  block_array_in_swp(7 downto 0)   <= block_array_in(31 downto 24);



  rom_mix_1 : rom_mix
    generic map (
      N_DIFFICULTY_LOG2 => N_DIFFICULTY_LOG2)
    port map (
      clk                   => clk,
      rst                   => rst,
      block_array_in        => block_array_in_swp,
      block_array_in_valid  => block_array_in_valid,
      block_array_in_last   => block_array_in_last,
      block_array_in_ready  => block_array_in_ready,
      block_array_out       => block_array_out,
      block_array_out_valid => block_array_out_valid,
      block_array_out_last  => block_array_out_last,
      block_array_out_ready => block_array_out_ready,
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
      errors_1              => errors_1,
      errors_2              => errors_2);

  -- endian swap on data
  block_array_out_swp(31 downto 24) <= block_array_out(7 downto 0);
  block_array_out_swp(23 downto 16) <= block_array_out(15 downto 8);
  block_array_out_swp(15 downto 8)  <= block_array_out(23 downto 16);
  block_array_out_swp(7 downto 0)   <= block_array_out(31 downto 24);

  pbkdf_hmac_sha256_2 : pbkdf_hmac_sha256
    port map (
      clk                      => clk,
      rst                      => rst,
      iteration                => std_logic_vector(to_unsigned(1, 32)),
      iteration_valid          => start_valid,
      password_in_length       => std_logic_vector(to_unsigned(80, 64)),
      password_in_length_valid => start_valid,
      password_in              => message_in,
      password_in_valid        => message_in_valid_password_2,
      password_in_last         => message_in_last,
      password_in_ready        => message_in_ready_password_2,
      salt_in_length           => std_logic_vector(to_unsigned(128, 64)),
      salt_in_length_valid     => block_start_valid,
      salt_in                  => block_array_out_swp,
      salt_in_valid            => block_array_out_valid,
      salt_in_last             => block_array_out_last,
      salt_in_ready            => block_array_out_ready,
      hash_out_length          => open,
      hash_out_length_valid    => open,
      hash_out                 => hash_out,
      hash_out_valid           => hash_out_valid,
      hash_out_last            => hash_out_last,
      hash_out_ready           => hash_out_ready,
      error_out                => open);

end behavioral;
