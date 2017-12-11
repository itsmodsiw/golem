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
  type block_array is array (1 downto 0) of word_array;


  -- axi 64b compatible array
  type axi_array is array (15 downto 0) of std_logic_vector(63 downto 0);
  type axi_array_64B is array (7 downto 0) of std_logic_vector(63 downto 0);

  function "xor" (l, r : word_array) return word_array;
  function "xor" (l, r : block_array) return block_array;
  function "ror" (ARG  : std_logic_vector; COUNT : integer) return std_logic_vector;
  function "srl" (ARG  : std_logic_vector; COUNT : integer) return std_logic_vector;

  function to_axi_array (arg   : block_array) return axi_array;
  function to_axi_array (arg   : word_array) return axi_array_64B;
  function to_block_array (arg : axi_array) return block_array;
  function to_word_array (arg  : axi_array_64B) return word_array;

  --sha256 functions
  function ch (x  : std_logic_vector; y  : std_logic_vector; z  : std_logic_vector) return std_logic_vector;
  function maj (x  : std_logic_vector; y  : std_logic_vector; z  : std_logic_vector) return std_logic_vector;
  --lowercase sigma
  function lsigma0 (x  : std_logic_vector) return std_logic_vector;
  function lsigma1 (x  : std_logic_vector) return std_logic_vector;
  -- uppercase sigma
  function usigma0 (x  : std_logic_vector) return std_logic_vector;
  function usigma1 (x  : std_logic_vector) return std_logic_vector;

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

  function XROR (ARG : std_logic_vector; COUNT : natural) return std_logic_vector
  is
    constant ARG_L                       : integer                          := ARG'length-1;
    alias XARG                           : std_logic_vector(ARG_L downto 0) is ARG;
    variable RESULT                      : std_logic_vector(ARG_L downto 0) := XARG;
    variable COUNTM                      : integer;
    -- Exemplar synthesis directives :
    attribute SYNTHESIS_RETURN of RESULT : variable is "ROR";
  begin
    COUNTM := COUNT mod (ARG_L + 1);
    if COUNTM /= 0 then
      RESULT(ARG_L-COUNTM downto 0)       := XARG(ARG_L downto COUNTM);
      RESULT(ARG_L downto ARG_L-COUNTM+1) := XARG(COUNTM-1 downto 0);
    end if;
    return RESULT;
  end XROR;

  function ROTATE_RIGHT (ARG : std_logic_vector; COUNT : natural) return std_logic_vector is
  -- Exemplar directives are in XROR
  begin
    return XROR(ARG, COUNT);
  end ROTATE_RIGHT;

  function "ror" (ARG : std_logic_vector; COUNT : integer) return std_logic_vector is
    -- Exemplar synthesis directives :
    variable RESULT                      : std_logic_vector (ARG'length-1 downto 0);
    attribute SYNTHESIS_RETURN of RESULT : variable is "ROR";
  begin
    return ROTATE_RIGHT(ARG, COUNT);
  end "ror";

  function XSRL (ARG : std_logic_vector; COUNT : natural) return std_logic_vector
  is
    constant ARG_L                       : integer                          := ARG'length-1;
    alias XARG                           : std_logic_vector(ARG_L downto 0) is ARG;
    variable RESULT                      : std_logic_vector(ARG_L downto 0) := (others => '0');
    -- Exemplar synthesis directives :
    attribute SYNTHESIS_RETURN of RESULT : variable is "SRL";
  begin
    if COUNT <= ARG_L then
      RESULT(ARG_L-COUNT downto 0) := XARG(ARG_L downto COUNT);
    end if;
    return RESULT;
  end XSRL;

  -- Id: S.2
  function SHIFT_RIGHT (ARG : std_logic_vector; COUNT : natural) return std_logic_vector is
  -- Exemplar directives are in XSRL
  begin
    return XSRL(ARG, COUNT);
  end SHIFT_RIGHT;

  function "srl" (ARG : std_logic_vector; COUNT : integer) return std_logic_vector is
    -- Exemplar synthesis directives :
    variable RESULT                      : std_logic_vector (ARG'length-1 downto 0);
    attribute SYNTHESIS_RETURN of RESULT : variable is "SRL";
  begin
    return SHIFT_RIGHT(ARG, COUNT);
  end "srl";

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

  function to_axi_array (arg : word_array) return axi_array_64B is
    variable result : axi_array_64B;
  begin
    for i in (arg'length/2)-1 downto 0 loop
      result(((arg(0)'length/2))+i) := arg((i*2)+1) & arg(i*2);
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

  function to_word_array (arg : axi_array_64B) return word_array is
    variable result : word_array;
  begin
    for i in (result'length/2)-1 downto 0 loop
      result(i*2)     := arg(((result(0)'length/2))+i)(31 downto 0);
      result((i*2)+1) := arg(((result(0)'length/2))+i)(63 downto 32);
    end loop;
    return result;
  end to_word_array;

  function ch (x  : std_logic_vector; y  : std_logic_vector; z  : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length-1 downto 0);
  begin
    result := (x and y) xor ((not x) and z);
    return result;
  end ch;

  function maj (x  : std_logic_vector; y  : std_logic_vector; z  : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length-1 downto 0);
  begin
    result := (x and y) xor (x and z) xor (y and z);
    return result;
  end maj;

  function lsigma0 (x  : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length-1 downto 0);
  begin
    result := (x ror 7) xor (x ror 18) xor (x srl 3);
    return result;
  end lsigma0;

  function lsigma1 (x  : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length-1 downto 0);
  begin
    result := (x ror 17) xor (x ror 19) xor (x srl 10);
    return result;
  end lsigma1;

  function usigma0 (x  : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length-1 downto 0);
  begin
    result := (x ror 2) xor (x ror 13) xor (x ror 22);
    return result;
  end usigma0;

  function usigma1 (x  : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(x'length-1 downto 0);
  begin
    result := (x ror 6) xor (x ror 11) xor (x ror 25);
    return result;
  end usigma1;

end common;
