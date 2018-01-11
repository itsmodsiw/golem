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


entity rom_mix_stage1 is
  generic (
    N_DIFFICULTY_LOG2 : integer := 10
    );
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    busy : out std_logic;

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

    errors : out std_logic_vector(15 downto 0);

    block_mix_in       : out block_array;
    block_mix_in_valid : out std_logic;
    block_mix_in_ready : in  std_logic;

    block_mix_out       : in block_array;
    block_mix_out_valid : in std_logic

    );

end rom_mix_stage1;

architecture behavioral of rom_mix_stage1 is

  component block_array_to_mm is
    generic (
      LENGTH : integer);
    port (
      clk                  : in  std_logic;
      rst                  : in  std_logic;
      block_array_in_addr  : in  std_logic_vector(24 downto 0);
      block_array_in       : in  block_array;
      block_array_in_valid : in  std_logic;
      block_array_in_ready : out std_logic;
      m_axi_awid           : out std_logic_vector(5 downto 0);
      m_axi_awaddr         : out std_logic_vector(31 downto 0);
      m_axi_awlen          : out std_logic_vector(7 downto 0);
      m_axi_awsize         : out std_logic_vector(2 downto 0);
      m_axi_awburst        : out std_logic_vector(1 downto 0);
      m_axi_awlock         : out std_logic_vector(0 downto 0);
      m_axi_awcache        : out std_logic_vector(3 downto 0);
      m_axi_awprot         : out std_logic_vector(2 downto 0);
      m_axi_awqos          : out std_logic_vector(3 downto 0);
      m_axi_awregion       : out std_logic_vector(3 downto 0);
      m_axi_awvalid        : out std_logic;
      m_axi_awready        : in  std_logic;
      m_axi_wdata          : out std_logic_vector(63 downto 0);
      m_axi_wstrb          : out std_logic_vector(7 downto 0);
      m_axi_wlast          : out std_logic;
      m_axi_wvalid         : out std_logic;
      m_axi_wready         : in  std_logic;
      m_axi_bid            : in  std_logic_vector(5 downto 0);
      m_axi_bresp          : in  std_logic_vector(1 downto 0);
      m_axi_bvalid         : in  std_logic;
      m_axi_bready         : out std_logic;
      errors               : out std_logic_vector(15 downto 0));
  end component block_array_to_mm;

  signal ones : unsigned(31 downto 0);

  signal x_int       : block_array;
  signal x_int_valid : std_logic;

  signal x_int_new       : block_array;
  signal x_int_new_valid : std_logic;

  signal block_array_in_counter : unsigned(7 downto 0);
  signal block_array_out_counter : unsigned(7 downto 0);

  signal rom_mix_busy : std_logic;
  signal rom_mix_done : std_logic;
  signal rom_mix_last : std_logic;

  signal n_counter : unsigned(24 downto 0);



begin

  block_array_in_ready <= '1';


  ones <= (others => '1');

  busy <= rom_mix_busy;

  -- initialise x_int;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        x_int       <= (others => (others => '0'));
        x_int_valid <= '0';

        n_counter              <= (others => '0');
        block_array_in_counter <= (others => '0');
        block_array_out_counter <= (others => '0');


        rom_mix_busy <= '0';
        rom_mix_done <= '0';

      else
        -- if valid block array is received, initialise it
        x_int_valid  <= '0';

        if (block_array_in_valid = '1') then
          if (block_array_in_last = '1') then
            block_array_in_counter <= (others => '0');
            x_int_valid <= '1';
          else
            block_array_in_counter <= block_array_in_counter + 1;
          end if;

          for i in 31 downto 0 loop
            if (block_array_in_counter = i) then
              x_int(i) <= block_array_in;

            end if;
          end loop;  -- i

          n_counter    <= (others => '0');
          rom_mix_busy <= '1';

        end if;

        -- perform another round
        if (x_int_new_valid = '1') then
          x_int <= x_int_new;

          if (n_counter(N_DIFFICULTY_LOG2-1 downto 0) = ones(N_DIFFICULTY_LOG2-1 downto 0)) then
            n_counter    <= (others => '0');
            -- done
            rom_mix_done <= '1';

          else
            n_counter   <= n_counter + "1";
            x_int_valid <= '1';

          end if;

        end if;

        if (rom_mix_done = '1') then
          if (block_array_out_counter = 31) then
            block_array_out_counter <= (others => '0');
            rom_mix_busy <= '0';
            rom_mix_done <= '0';

          else
            block_array_out_counter <= block_array_out_counter + 1;

          end if;
        end if;
      end if;
    end if;
  end process;

  -- when it's valid, write the block to memory
  block_array_to_mm_i : block_array_to_mm
    generic map (
      LENGTH => 16)
    port map (
      clk => clk,
      rst => rst,

      block_array_in_addr  => std_logic_vector(n_counter),
      block_array_in       => x_int,
      block_array_in_valid => x_int_valid,
      block_array_in_ready => open,

      m_axi_awid     => m_axi_awid,
      m_axi_awaddr   => m_axi_awaddr,
      m_axi_awlen    => m_axi_awlen,
      m_axi_awsize   => m_axi_awsize,
      m_axi_awburst  => m_axi_awburst,
      m_axi_awlock   => m_axi_awlock,
      m_axi_awcache  => m_axi_awcache,
      m_axi_awprot   => m_axi_awprot,
      m_axi_awqos    => m_axi_awqos,
      m_axi_awregion => m_axi_awregion,
      m_axi_awvalid  => m_axi_awvalid,
      m_axi_awready  => m_axi_awready,
      m_axi_wdata    => m_axi_wdata,
      m_axi_wstrb    => m_axi_wstrb,
      m_axi_wlast    => m_axi_wlast,
      m_axi_wvalid   => m_axi_wvalid,
      m_axi_wready   => m_axi_wready,
      m_axi_bid      => m_axi_bid,
      m_axi_bresp    => m_axi_bresp,
      m_axi_bvalid   => m_axi_bvalid,
      m_axi_bready   => m_axi_bready,
      errors         => errors);


  -- at the same time, also perform a blockmix
  -- the blockmix should take longer than the mm write so can be done in parallel.
  block_mix_in       <= x_int;
  block_mix_in_valid <= x_int_valid;

  x_int_new       <= block_mix_out;
  x_int_new_valid <= block_mix_out_valid;

  gen_out: for i in 31 downto 0 generate
    block_array_out <= x_int(i) when (block_array_out_counter = i) else (others => 'Z');

  end generate gen_out;

  -- drive outputs
  block_array_out_valid <= rom_mix_done;
  block_array_out_last  <= rom_mix_done when (block_array_out_counter = 31) else '0';


end behavioral;
