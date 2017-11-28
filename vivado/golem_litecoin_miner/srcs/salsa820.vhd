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


entity salsa820 is
  generic (
    NUM_ROUNDS : integer := 8
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    word_in       : in  word_array;
    word_in_valid : in  std_logic;
    word_in_ready : out std_logic;

    word_out       : out word_array;
    word_out_valid : out std_logic);

end salsa820;

architecture behavioral of salsa820 is


  component salsa_32b_add
    port (
      A   : in  std_logic_vector(31 downto 0);
      B   : in  std_logic_vector(31 downto 0);
      CLK : in  std_logic;
      S   : out std_logic_vector(31 downto 0)
      );
  end component;


  signal word_in_orig : word_array;
  signal word_final   : word_array;
  signal word_out_i   : word_array;

  signal x_int       : word_array;
  signal x_int_valid : std_logic;

  signal x_int_add       : word_array;
  signal x_int_add_valid : std_logic;

  signal x_int_rot       : word_array;
  signal x_int_rot_valid : std_logic;

  signal x_int_new       : word_array;
  signal x_int_new_valid : std_logic;

  signal add_stage_1      : std_logic;
  signal add_stage_2      : std_logic;
  signal add_stage_3      : std_logic;
  signal add_stage_4      : std_logic;
  signal add_stage_1_done : std_logic;
  signal add_stage_2_done : std_logic;
  signal add_stage_3_done : std_logic;
  signal add_stage_4_done : std_logic;

  signal salsa_busy : std_logic;
  signal salsa_done : std_logic;

  signal A_A : std_logic_vector(31 downto 0);
  signal A_B : std_logic_vector(31 downto 0);
  signal A_S : std_logic_vector(31 downto 0);
  signal B_A : std_logic_vector(31 downto 0);
  signal B_B : std_logic_vector(31 downto 0);
  signal B_S : std_logic_vector(31 downto 0);
  signal C_A : std_logic_vector(31 downto 0);
  signal C_B : std_logic_vector(31 downto 0);
  signal C_S : std_logic_vector(31 downto 0);
  signal D_A : std_logic_vector(31 downto 0);
  signal D_B : std_logic_vector(31 downto 0);
  signal D_S : std_logic_vector(31 downto 0);


  -- [1:0] is quarter-cycles (4 of them)
  -- [4:2] is cycles (8 of them)
  signal qcycle_counter : unsigned(7 downto 0);

  constant QCYCLE_COUNTER_MAX : unsigned(7 downto 0) := to_unsigned((NUM_ROUNDS*4)-1, 8);

  -- four initial constants
  constant C1 : std_logic_vector(31 downto 0) := X"61707865";
  constant C2 : std_logic_vector(31 downto 0) := X"3320646e";
  constant C3 : std_logic_vector(31 downto 0) := X"79622d32";
  constant C4 : std_logic_vector(31 downto 0) := X"6b206574";


  -- The addition operations are applied on fixed positions of the matrix
  -- They are as follows
  constant A_y  : integer := 4;
  constant A_x1 : integer := 0;
  constant A_x2 : integer := 12;

  constant B_y  : integer := 9;
  constant B_x1 : integer := 5;
  constant B_x2 : integer := 1;

  constant C_y  : integer := 14;
  constant C_x1 : integer := 10;
  constant C_x2 : integer := 6;

  constant D_y  : integer := 3;
  constant D_x1 : integer := 15;
  constant D_x2 : integer := 11;

begin

  -- register inputs
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        x_int_valid <= '0';
        x_int       <= (others => (others => '0'));

        word_in_orig <= (others => (others => '0'));

        qcycle_counter <= (others => '0');

        add_stage_1      <= '0';
        add_stage_2      <= '0';
        add_stage_3      <= '0';
        add_stage_4      <= '0';
        add_stage_1_done <= '0';
        add_stage_2_done <= '0';
        add_stage_3_done <= '0';
        add_stage_4_done <= '0';

        salsa_busy <= '0';
        salsa_done <= '0';

      else
        x_int_valid      <= '0';
        add_stage_1      <= '0';
        add_stage_2      <= add_stage_1;
        add_stage_3      <= add_stage_2;
        add_stage_4      <= add_stage_3;
        add_stage_1_done <= add_stage_1;
        add_stage_2_done <= add_stage_2;
        add_stage_3_done <= add_stage_3;
        add_stage_4_done <= add_stage_4;

        salsa_done <= '0';

        -- salsa is done after stage 4 is done
        if (add_stage_4_done = '1') then
          salsa_done <= '1';
          salsa_busy <= '0';

        end if;

        -- New word received
        if (word_in_valid = '1' and salsa_busy = '0') then
          -- create internal array
          x_int       <= word_in;
          x_int_valid <= '1';
          salsa_busy  <= '1';

          -- remember word in
          word_in_orig <= word_in;

        end if;

        -- Quarter-cycle done
        if (x_int_new_valid = '1') then
          if (qcycle_counter(1 downto 0) = "11") then
            -- special case at end of every 4th quarter-cycle
            -- transpose matrix
            x_int(0)  <= x_int_new(0);
            x_int(1)  <= x_int_new(4);
            x_int(2)  <= x_int_new(8);
            x_int(3)  <= x_int_new(12);
            x_int(4)  <= x_int_new(1);
            x_int(5)  <= x_int_new(5);
            x_int(6)  <= x_int_new(9);
            x_int(7)  <= x_int_new(13);
            x_int(8)  <= x_int_new(2);
            x_int(9)  <= x_int_new(6);
            x_int(10) <= x_int_new(10);
            x_int(11) <= x_int_new(14);
            x_int(12) <= x_int_new(3);
            x_int(13) <= x_int_new(7);
            x_int(14) <= x_int_new(11);
            x_int(15) <= x_int_new(15);

          else
            -- otherwise, normal assignment
            x_int <= x_int_new;

          end if;

          if (qcycle_counter < qcycle_counter_max) then
            -- count quarter cycles
            qcycle_counter <= qcycle_counter + "00001";
            -- start another internal cycle
            x_int_valid    <= '1';

          else
            -- cycles done!
            qcycle_counter <= (others => '0');
            -- start add stage 1
            add_stage_1    <= '1';

          end if;
        end if;
      end if;
    end if;
  end process;

  word_out_valid <= salsa_done;
  word_out       <= word_out_i;

  word_in_ready <= not salsa_busy;

  -- The salsa is as follows:
  -- a 4x4 matrix holds the internal state of the salsa
  -- 1) 4 pairs of fixed matrix positions are added, rotated and xored together
  -- to create a new matrix.
  -- 2) The first row of the matrix then becomes the last and the addition is
  -- repeated again.
  -- 3) after 4 repeats (so the first row is back to being at the top)
  -- transpose the matrix and start again.
  -- 4) this is done 8 times because it's a 20/8 salsa

  -- 1cc latency through adds, so generate that valid
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        x_int_add_valid <= '0';

      else
        x_int_add_valid <= x_int_valid;

      end if;
    end if;
  end process;

  -- Create 4 adds in parallel. These 4 adds make up a quarter-round
  -- resource share adds with final stage (add_stage_1 and add_stage_2)
  salsa_32b_add_A : salsa_32b_add
    port map (
      A   => A_A,
      B   => A_B,
      CLK => clk,
      S   => A_S
      );

  A_A <= x_int(0) when add_stage_1 = '1' else
         x_int(4)  when add_stage_2 = '1' else
         x_int(8)  when add_stage_3 = '1' else
         x_int(12) when add_stage_4 = '1' else
         x_int(A_x1);

  A_B <= word_in_orig(0) when add_stage_1 = '1' else
         word_in_orig(4)  when add_stage_2 = '1' else
         word_in_orig(8)  when add_stage_3 = '1' else
         word_in_orig(12) when add_stage_4 = '1' else
         x_int(A_x2);

  word_final(0)  <= A_S;                -- stage1 valid
  word_final(4)  <= A_S;                -- stage2 valid
  word_final(8)  <= A_S;                -- stage3 valid
  word_final(12) <= A_S;                -- stage4 valid
  x_int_add(A_y) <= A_S;                -- otherwise valid


  salsa_32b_add_B : salsa_32b_add
    port map (
      A   => B_A,
      B   => B_B,
      CLK => clk,
      S   => B_S
      );

  B_A <= x_int(1) when add_stage_1 = '1' else
         x_int(5)  when add_stage_2 = '1' else
         x_int(9)  when add_stage_3 = '1' else
         x_int(13) when add_stage_4 = '1' else
         x_int(B_x1);

  B_B <= word_in_orig(1) when add_stage_1 = '1' else
         word_in_orig(5)  when add_stage_2 = '1' else
         word_in_orig(9)  when add_stage_3 = '1' else
         word_in_orig(13) when add_stage_4 = '1' else
         x_int(B_x2);


  word_final(1)  <= B_S;                -- stage1 valid
  word_final(5)  <= B_S;                -- stage2 valid
  word_final(9)  <= B_S;                -- stage3 valid
  word_final(13) <= B_S;                -- stage4 valid
  x_int_add(B_y) <= B_S;                -- otherwise valid

  salsa_32b_add_C : salsa_32b_add
    port map (
      A   => C_A,
      B   => C_B,
      CLK => clk,
      S   => C_S
      );

  C_A <= x_int(2) when add_stage_1 = '1' else
         x_int(6)  when add_stage_2 = '1' else
         x_int(10) when add_stage_3 = '1' else
         x_int(14) when add_stage_4 = '1' else
         x_int(C_x1);

  C_B <= word_in_orig(2) when add_stage_1 = '1' else
         word_in_orig(6)  when add_stage_2 = '1' else
         word_in_orig(10) when add_stage_3 = '1' else
         word_in_orig(14) when add_stage_4 = '1' else
         x_int(C_x2);


  word_final(2)  <= C_S;                -- stage1 valid
  word_final(6)  <= C_S;                -- stage2 valid
  word_final(10) <= C_S;                -- stage1 valid
  word_final(14) <= C_S;                -- stage2 valid
  x_int_add(C_y) <= C_S;                -- otherwise valid

  salsa_32b_add_D : salsa_32b_add
    port map (
      A   => D_A,
      B   => D_B,
      CLK => clk,
      S   => D_S
      );

  D_A <= x_int(3) when add_stage_1 = '1' else
         x_int(7)  when add_stage_2 = '1' else
         x_int(11) when add_stage_3 = '1' else
         x_int(15) when add_stage_4 = '1' else
         x_int(D_x1);

  D_B <= word_in_orig(3) when add_stage_1 = '1' else
         word_in_orig(7)  when add_stage_2 = '1' else
         word_in_orig(11) when add_stage_3 = '1' else
         word_in_orig(15) when add_stage_4 = '1' else
         x_int(D_x2);


  word_final(3)  <= D_S;                -- stage1 valid
  word_final(7)  <= D_S;                -- stage2 valid
  word_final(11) <= D_S;                -- stage3 valid
  word_final(15) <= D_S;                -- stage4 valid
  x_int_add(D_y) <= D_S;                -- otherwise valid

  -- After the add stage, rotate by the appropriate amount and bitwise-and with
  -- the original;
  -- this may/may not need to be registered, it just depends on how the timing
  -- works out. Aiming for 125Mhz so register it for now.

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        x_int_rot_valid <= '0';
        x_int_rot       <= (others => (others => '0'));


      else
        x_int_rot_valid <= x_int_add_valid;
        -- start by populating rot with the original
        x_int_rot       <= x_int;

        -- qcycle_counter keeps track of quarter cycles.
        -- rotation amount depends on which quarter-cycle we're in:
        -- 0: 7 bits
        -- 1: 9 bits
        -- 2: 13 bits
        -- 3: 18 bits

        case qcycle_counter(1 downto 0) is
          when "00" =>
            -- 7 bits
            x_int_rot(A_y) <= x_int(A_y) xor (x_int_add(A_y)(24 downto 0) & x_int_add(A_y)(31 downto 25));
            x_int_rot(B_y) <= x_int(B_y) xor (x_int_add(B_y)(24 downto 0) & x_int_add(B_y)(31 downto 25));
            x_int_rot(C_y) <= x_int(C_y) xor (x_int_add(C_y)(24 downto 0) & x_int_add(C_y)(31 downto 25));
            x_int_rot(D_y) <= x_int(D_y) xor (x_int_add(D_y)(24 downto 0) & x_int_add(D_y)(31 downto 25));
          when "01" =>
            -- 9 bits
            x_int_rot(A_y) <= x_int(A_y) xor (x_int_add(A_y)(22 downto 0) & x_int_add(A_y)(31 downto 23));
            x_int_rot(B_y) <= x_int(B_y) xor (x_int_add(B_y)(22 downto 0) & x_int_add(B_y)(31 downto 23));
            x_int_rot(C_y) <= x_int(C_y) xor (x_int_add(C_y)(22 downto 0) & x_int_add(C_y)(31 downto 23));
            x_int_rot(D_y) <= x_int(D_y) xor (x_int_add(D_y)(22 downto 0) & x_int_add(D_y)(31 downto 23));
          when "10" =>
            -- 13 bits
            x_int_rot(A_y) <= x_int(A_y) xor (x_int_add(A_y)(18 downto 0) & x_int_add(A_y)(31 downto 19));
            x_int_rot(B_y) <= x_int(B_y) xor (x_int_add(B_y)(18 downto 0) & x_int_add(B_y)(31 downto 19));
            x_int_rot(C_y) <= x_int(C_y) xor (x_int_add(C_y)(18 downto 0) & x_int_add(C_y)(31 downto 19));
            x_int_rot(D_y) <= x_int(D_y) xor (x_int_add(D_y)(18 downto 0) & x_int_add(D_y)(31 downto 19));
          when "11" =>
            -- 18 bits
            x_int_rot(A_y) <= x_int(A_y) xor (x_int_add(A_y)(13 downto 0) & x_int_add(A_y)(31 downto 14));
            x_int_rot(B_y) <= x_int(B_y) xor (x_int_add(B_y)(13 downto 0) & x_int_add(B_y)(31 downto 14));
            x_int_rot(C_y) <= x_int(C_y) xor (x_int_add(C_y)(13 downto 0) & x_int_add(C_y)(31 downto 14));
            x_int_rot(D_y) <= x_int(D_y) xor (x_int_add(D_y)(13 downto 0) & x_int_add(D_y)(31 downto 14));
          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- move first line to last
  -- shouldn't need to register this
  x_int_new_valid <= x_int_rot_valid;
  x_int_new       <= x_int_rot(3 downto 0) & x_int_rot(15 downto 4);

  -- Latch the final added word according to add stage
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        word_out_i <= (others => (others => '0'));
      else
        -- stage 1 regs are 3 downto 0
        -- stage 2 regs are 7 downto 4
        -- stage 3 regs are 11 downto 8
        -- stage 4 regs are 15 downto 12
        if (add_stage_1_done = '1') then
          word_out_i(3 downto 0) <= word_final(3 downto 0);

        elsif (add_stage_2_done = '1') then
          word_out_i(7 downto 4) <= word_final(7 downto 4);

        elsif (add_stage_3_done = '1') then
          word_out_i(11 downto 8) <= word_final(11 downto 8);

        elsif (add_stage_4_done = '1') then
          word_out_i(15 downto 12) <= word_final(15 downto 12);

        end if;
      end if;
    end if;
  end process;


end behavioral;
