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


entity axis_addr_gen is
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- axis snoop
    snoop_valid     : in  std_logic;
    snoop_last      : in  std_logic;
    snoop_ready     : in std_logic;

    addr_count_out : out std_logic_vector(31 downto 0)

    );

end axis_addr_gen;

architecture behavioral of axis_addr_gen is

  signal addr_count : unsigned(31 downto 0);

begin

  -- count the hash out clockcycles.
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        addr_count <= (others => '0');

      else
        if (snoop_valid = '1' and snoop_last = '1' and snoop_ready = '1') then
          addr_count <= (others => '0');

        elsif (snoop_valid = '1' and snoop_ready = '1') then
          addr_count <= addr_count + 1;

        end if;
      end if;
    end if;
  end process;

  addr_count_out <= std_logic_vector(addr_count);

end behavioral;
