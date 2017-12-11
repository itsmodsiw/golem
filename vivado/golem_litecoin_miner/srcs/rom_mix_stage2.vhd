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


entity rom_mix_stage2 is
  generic (
    BLOCK_SIZE        : integer := 8;   --max 128
    BLOCK_SIZE_LOG2   : integer := 3;   --max 7
    NUM_ROUNDS        : integer := 8;
    N_DIFFICULTY_LOG2 : integer := 10
    );
  port (
    clk : in std_logic;
    rst : in std_logic;
    busy : out std_logic;


    block_array_in       : in  block_array;
    block_array_in_valid : in  std_logic;
    block_array_in_ready : out std_logic;

    block_array_out       : out block_array;
    block_array_out_valid : out std_logic;

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
    m_axi_rstrb    : in  std_logic_vector(7 downto 0);
    m_axi_rlast    : in  std_logic;
    m_axi_rready   : out std_logic;
    m_axi_rid      : in  std_logic_vector(5 downto 0);
    m_axi_rresp    : in  std_logic_vector(1 downto 0);
    m_axi_rvalid   : in  std_logic;

    errors : out std_logic_vector(15 downto 0);

    block_mix_in       : out  block_array;
    block_mix_in_valid : out  std_logic;
    block_mix_in_ready : in std_logic;

    block_mix_out       : in block_array;
    block_mix_out_valid : in std_logic


    );

end rom_mix_stage2;

architecture behavioral of rom_mix_stage2 is
  component mm_to_block_array is
    generic (
      LENGTH : integer);
    port (
      clk                   : in  std_logic;
      rst                   : in  std_logic;
      block_array_in_addr   : in  std_logic_vector(24 downto 0);
      block_array_in_valid  : in  std_logic;
      block_array_in_ready  : out std_logic;
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
      block_array_out       : out block_array;
      block_array_out_valid : out std_logic;
      errors                : out std_logic_vector(15 downto 0));
  end component mm_to_block_array;

  signal ones : unsigned(31 downto 0);

  signal x_int       : block_array;
  signal x_int_valid : std_logic;
  signal x_int_addr  : std_logic_vector(24 downto 0);

  signal v_int       : block_array;
  signal v_int_valid : std_logic;

  signal t_int       : block_array;
  signal t_int_valid : std_logic;

  signal x_int_new       : block_array;
  signal x_int_new_valid : std_logic;


  signal rom_mix_busy : std_logic;
  signal rom_mix_done : std_logic;

  signal n_counter : unsigned(24 downto 0);



begin

  ones <= (others => '1');

  busy <= rom_mix_busy;

  -- initialise x_int;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        x_int       <= (others => (others => (others => '0')));
        x_int_valid <= '0';

        n_counter <= (others => '0');

        rom_mix_busy <= '0';
        rom_mix_done <= '0';

      else
        -- if valid block array is received, initialise it
        x_int_valid  <= '0';
        rom_mix_done <= '0';

        if (block_array_in_valid = '1') then
          -- x_int becomes last block
          x_int       <= block_array_in;
          x_int_valid <= '1';

          n_counter    <= (others => '0');
          rom_mix_busy <= '1';

        end if;

        -- perform another round
        if (x_int_new_valid = '1') then
          x_int <= x_int_new;

          if (n_counter(N_DIFFICULTY_LOG2-1 downto 0) /= ones(N_DIFFICULTY_LOG2-1 downto 0)) then
            n_counter   <= n_counter + "1";
            x_int_valid <= '1';

          else
            n_counter    <= (others => '0');
            -- done
            rom_mix_done <= '1';

          end if;

        end if;

        -- if done, clear busy
        if (rom_mix_done = '1') then
          rom_mix_busy <= '0';

        end if;

      end if;
    end if;
  end process;

  -- create address
  x_int_addr(N_DIFFICULTY_LOG2-1 downto 0) <= x_int(BLOCK_SIZE*2-1)(0)(N_DIFFICULTY_LOG2-1 downto 0);
  x_int_addr(24 downto N_DIFFICULTY_LOG2)  <= (others => '0');


  -- get the block from memory
  mm_to_block_array_i : mm_to_block_array
    generic map (
      LENGTH => 16)
    port map (
      clk                   => clk,
      rst                   => rst,
      block_array_in_addr   => x_int_addr,
      block_array_in_valid  => x_int_valid,
      block_array_in_ready  => open,
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
      m_axi_rid             => m_axi_rid,
      m_axi_rresp           => m_axi_rresp,
      m_axi_rvalid          => m_axi_rvalid,
      m_axi_rready          => m_axi_rready,
      block_array_out       => v_int,
      block_array_out_valid => v_int_valid,
      errors                => errors);

  -- after it's retrieved, xor the retrieved block (v) with the internal block
  -- (x).
  t_int       <= x_int xor v_int;
  t_int_valid <= v_int_valid;

  -- perform a blockmix on the result

  block_mix_in <= t_int;
  block_mix_in_valid <= t_int_valid;

  x_int_new <= block_mix_out;
  x_int_new_valid <= block_mix_out_valid;

  -- drive outputs
  block_array_out       <= x_int;
  block_array_out_valid <= rom_mix_done;


end behavioral;
