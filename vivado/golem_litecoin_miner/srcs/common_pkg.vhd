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


  function "xor" (l, r : word_array) return word_array;
  function "xor" (l, r : block_array) return block_array;


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

end common;
