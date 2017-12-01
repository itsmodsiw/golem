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
use IEEE.std_logic_unsigned.all;

package common is

  type word_array is array (15 downto 0) of std_logic_vector(31 downto 0);
  type block_array is array (15 downto 0) of word_array;


  -- axi 64b compatible array
  type axi_array is array (127 downto 0) of std_logic_vector(63 downto 0);

  function "xor" (l, r : word_array) return word_array;
  function "xor" (l, r : block_array) return block_array;

  function to_axi_array (arg   : block_array) return axi_array;
  function to_block_array (arg : axi_array) return block_array;

end common;

package body common is
  -- custom types function definitions
  ---------------------------------------------------------------------
  -- xor
  -------------------------------------------------------------------
  function "xor" (l, r : word_array) return word_array is
    variable result : word_array;
  begin
    if (l'length /= r'length) then
      assert false
        report "arguments of overloaded 'xor' operator are not of the same length"
        severity failure;
    else
      for i in result'range loop
        result(i) := l(i) xor r(i);
      end loop;
    end if;
    return result;
  end "xor";
  ---------------------------------------------------------------------
  -- xor
  -------------------------------------------------------------------
  function "xor" (l, r : block_array) return block_array is
    variable result : block_array;
  begin
    if (l'length /= r'length) then
      assert false
        report "arguments of overloaded 'xor' operator are not of the same length"
        severity failure;
    else
      for j in result'range loop
        for i in result(0)'range loop
          result(j)(i) := l(j)(i) xor r(j)(i);
        end loop;
      end loop;
    end if;
    return result;
  end "xor";

  function to_axi_array (arg : block_array) return axi_array is
    variable result : axi_array;
  begin
    for j in arg'range loop
      for i in (arg(0)'length/2)-1 downto 0 loop
        result((j*(arg(0)'length/2))+i) := arg(j)((i*2)+1) & arg(j)(i*2);
      end loop;
    end loop;
    return result;
  end to_axi_array;

  function to_block_array (arg : axi_array) return block_array is
    variable result : block_array;
  begin
    for j in result'range loop
      for i in (result(0)'length/2)-1 downto 0 loop
        result(j)(i*2)     := arg((j*(result(0)'length/2))+i)(31 downto 0);
        result(j)((i*2)+1) := arg((j*(result(0)'length/2))+i)(63 downto 32);
      end loop;
    end loop;
    return result;
  end to_block_array;

end common;
