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


entity sha256 is
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

    error_out : out std_logic_vector(3 downto 0)

    );

end sha256;

architecture behavioral of sha256 is
  component sha256_6b_sub
    port (
      A : in  std_logic_vector(5 downto 0);
      B : in  std_logic_vector(5 downto 0);
      S : out std_logic_vector(5 downto 0)
      );
  end component;

  component sha256_32b_add
    port (
      A   : in  std_logic_vector(31 downto 0);
      B   : in  std_logic_vector(31 downto 0);
      CLK : in  std_logic;
      CE  : in  std_logic;
      S   : out std_logic_vector(31 downto 0)
      );
  end component;

  component sha256_k_bram
    port (
      clka  : in  std_logic;
      addra : in  std_logic_vector(5 downto 0);
      douta : out std_logic_vector(31 downto 0)
      );
  end component;

  component sha256_w_bram
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(5 downto 0);
      dina  : in  std_logic_vector(31 downto 0);
      douta : out std_logic_vector(31 downto 0);
      clkb  : in  std_logic;
      enb   : in  std_logic;
      web   : in  std_logic_vector(0 downto 0);
      addrb : in  std_logic_vector(5 downto 0);
      dinb  : in  std_logic_vector(31 downto 0);
      doutb : out std_logic_vector(31 downto 0)
      );
  end component;

  type h_array is array (7 downto 0) of std_logic_vector(31 downto 0);
  signal h_int   : h_array;
  signal h_new   : h_array;
  signal h_reset : h_array;
  signal h_start : h_array;

  signal h_new_valid : std_logic;

  signal add_valid   : std_logic;
  signal add_valid_z : std_logic;

  signal add_last   : std_logic;
  signal add_last_z : std_logic;


  -- iterate through words
  signal j_counter     : unsigned(5 downto 0);
  signal add_counter   : unsigned(2 downto 0);
  signal add_counter_z : unsigned(2 downto 0);
  signal state_counter : unsigned(2 downto 0);
  signal ones          : unsigned(5 downto 0);

  signal gen_w : std_logic;


  -- internal signals
  signal k_int   : std_logic_vector(31 downto 0);
  signal ch_int  : std_logic_vector(31 downto 0);
  signal maj_int : std_logic_vector(31 downto 0);
  signal s0_int  : std_logic_vector(31 downto 0);
  signal s1_int  : std_logic_vector(31 downto 0);

  signal w_new       : std_logic_vector(31 downto 0);
  signal w_new_valid : std_logic;

  signal w_in : std_logic_vector(31 downto 0);

  signal s1_int_valid  : std_logic;
  signal s0_int_valid  : std_logic;
  signal ch_int_valid  : std_logic;
  signal maj_int_valid : std_logic;
  signal k_int_valid   : std_logic;
  signal h_int_valid   : std_logic;

  signal s1_ch_valid  : std_logic;
  signal k_h_valid    : std_logic;
  signal T2_int_valid : std_logic;
  signal T1_int_valid : std_logic;
  signal h4_pre_valid : std_logic;
  signal h0_pre_valid : std_logic;
  signal h4_new_valid : std_logic;
  signal h0_new_valid : std_logic;

  signal s1_ch  : std_logic_vector(31 downto 0);
  signal k_h    : std_logic_vector(31 downto 0);
  signal T2_int : std_logic_vector(31 downto 0);
  signal T1_int : std_logic_vector(31 downto 0);
  signal h0_pre : std_logic_vector(31 downto 0);
  signal h4_pre : std_logic_vector(31 downto 0);
  signal h0_new : std_logic_vector(31 downto 0);
  signal h4_new : std_logic_vector(31 downto 0);


  signal sub_15_valid : std_logic;
  signal sub_16_valid : std_logic;
  signal sub_2_valid  : std_logic;
  signal sub_7_valid  : std_logic;

  signal addr_15_valid : std_logic;
  signal addr_16_valid : std_logic;
  signal addr_2_valid  : std_logic;
  signal addr_7_valid  : std_logic;

  signal Wj15_valid         : std_logic;
  signal Wj16_valid         : std_logic;
  signal Wj2_valid          : std_logic;
  signal Wj7_valid          : std_logic;
  signal lsigma0_Wj15_valid : std_logic;
  signal lsigma1_Wj2_valid  : std_logic;

  signal Wj15         : std_logic_vector(31 downto 0);
  signal Wj2          : std_logic_vector(31 downto 0);
  signal Wj16         : std_logic_vector(31 downto 0);
  signal Wj7          : std_logic_vector(31 downto 0);
  signal Wj           : std_logic_vector(31 downto 0);
  signal lsigma0_Wj15 : std_logic_vector(31 downto 0);
  signal lsigma1_Wj2  : std_logic_vector(31 downto 0);

  signal Wj15_Wj16         : std_logic_vector(31 downto 0);
  signal Wj2_Wj7           : std_logic_vector(31 downto 0);
  signal Wj15_Wj16_z       : std_logic_vector(31 downto 0);
  signal Wj15_Wj16_valid   : std_logic;
  signal Wj15_Wj16_z_valid : std_logic;
  signal Wj2_Wj7_valid     : std_logic;
  signal Wj_valid          : std_logic;

  constant const_15 : std_logic_vector(5 downto 0) := "001111";
  constant const_16 : std_logic_vector(5 downto 0) := "010000";
  constant const_2  : std_logic_vector(5 downto 0) := "000010";
  constant const_7  : std_logic_vector(5 downto 0) := "000111";
  constant const_0  : std_logic_vector(5 downto 0) := "000000";

  signal w_bram_wea   : std_logic_vector(0 downto 0);
  signal w_bram_addra : std_logic_vector(5 downto 0);
  signal w_bram_dina  : std_logic_vector(31 downto 0);
  signal w_bram_douta : std_logic_vector(31 downto 0);
  signal w_bram_web   : std_logic_vector(0 downto 0);
  signal w_bram_addrb : std_logic_vector(5 downto 0);
  signal w_bram_dinb  : std_logic_vector(31 downto 0);
  signal w_bram_doutb : std_logic_vector(31 downto 0);

  signal h_add1_A : std_logic_vector(31 downto 0);
  signal h_add1_B : std_logic_vector(31 downto 0);
  signal h_add1_S : std_logic_vector(31 downto 0);

  signal h_add2_A : std_logic_vector(31 downto 0);
  signal h_add2_B : std_logic_vector(31 downto 0);
  signal h_add2_S : std_logic_vector(31 downto 0);

  signal w_add3_A : std_logic_vector(31 downto 0);
  signal w_add3_B : std_logic_vector(31 downto 0);
  signal w_add3_S : std_logic_vector(31 downto 0);

  signal w_add4_A : std_logic_vector(31 downto 0);
  signal w_add4_B : std_logic_vector(31 downto 0);
  signal w_add4_S : std_logic_vector(31 downto 0);

  signal w_sub1_A : std_logic_vector(5 downto 0);
  signal w_sub1_B : std_logic_vector(5 downto 0);
  signal w_sub1_S : std_logic_vector(5 downto 0);

  signal w_sub2_A : std_logic_vector(5 downto 0);
  signal w_sub2_B : std_logic_vector(5 downto 0);
  signal w_sub2_S : std_logic_vector(5 downto 0);

  type state_type is (IDLE, SHA, ADD, ERR);  -- Define the states
  signal state      : state_type;
  signal state_next : state_type;

  signal sha_done  : std_logic;
  signal add_done  : std_logic;
  signal idle_done : std_logic;

  signal error_i : std_logic_vector(3 downto 0);
  signal error_l : std_logic_vector(3 downto 0);

  signal message_in_ready_i : std_logic;


  signal last_message : std_logic;

begin

  -- The signal names and other naming conventions used in this file
  -- are taken from this document.
  -- http://www.iwar.org.uk/comsec/resources/cipher/sha256-384-512.pdf
  -- see section 2.

  ones <= (others => '1');


  -- initial values for h
  --h_reset(0) <= X"67e6096a";
  --h_reset(1) <= X"85ae67bb";
  --h_reset(2) <= X"72f36e3c";
  --h_reset(3) <= X"3af54fa5";
  --h_reset(4) <= X"7f520e51";
  --h_reset(5) <= X"8c68059b";
  --h_reset(6) <= X"abd9831f";
  --h_reset(7) <= X"19cde05b";
  h_reset(0) <= X"6a09e667";
  h_reset(1) <= X"bb67ae85";
  h_reset(2) <= X"3c6ef372";
  h_reset(3) <= X"a54ff53a";
  h_reset(4) <= X"510e527f";
  h_reset(5) <= X"9b05688c";
  h_reset(6) <= X"1f83d9ab";
  h_reset(7) <= X"5be0cd19";

  -- indicate when w must be generated
  gen_w <= '1' when j_counter > 15 else '0';

  -- state switch conditions
  -- SHA:
  -- 1) new h has been generated
  -- 2) h iteration is the last one
  -- 3) the last part of the message has been received
  sha_done <= '1' when h_new_valid = '1' and j_counter = ones else '0';

  -- ADD:
  -- 1) iteration is the last one
  add_done <= '1' when add_counter = 7 else '0';

  -- IDLE:
  -- 1) input message is valid
  idle_done <= '1' when message_in_valid = '1' else '0';

  -- state machine
  state_machine : process(state, idle_done, sha_done, add_done, last_message)
  begin  -- process state_machine
    case state is
      when IDLE =>
        if (idle_done = '1') then
          state_next <= SHA;

        else
          state_next <= IDLE;

        end if;

      when SHA =>
        if (sha_done = '1') then
          state_next <= ADD;

        else
          state_next <= SHA;

        end if;

      when ADD =>
        if (add_done = '1' and last_message = '1') then
          state_next <= IDLE;
        elsif (add_done = '1') then
          state_next <= SHA;
        else
          state_next <= ADD;
        end if;


      when ERR =>
        state_next <= ERR;

      when others =>
        state_next <= ERR;

    end case;
  end process state_machine;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        state <= IDLE;

      else
        -- if an error occurs, switch status.
        if (error_l = "0000") then
          state <= state_next;
        else
          state <= ERR;
        end if;

      end if;
    end if;
  end process;

  -- counters: keep track of how much has been processed
  -- and what is still to be done
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        h_int <= (others => (others => '0'));

        j_counter     <= (others => '0');
        state_counter <= (others => '0');
        add_counter   <= (others => '0');
        add_counter_z <= (others => '0');

      else
        add_counter_z <= add_counter;

        -- when entering a new transaction, reset internal variables
        if (state = IDLE and state_next = SHA) then
          -- initialise h
          h_int     <= h_reset;
          j_counter <= (others => '0');


        -- clear variables for state when it's done and prepare for next
        elsif (state = SHA and state_next = ADD) then
          j_counter     <= (others => '0');
          state_counter <= (others => '0');

          -- update internal h
          h_int <= h_new;

        -- while processing, increment counters
        elsif (state = SHA and state_next = SHA) then
          if (h_new_valid = '1') then
            state_counter <= (others => '0');
            j_counter     <= j_counter + 1;

            -- update internal h
            h_int <= h_new;

          else
            state_counter <= state_counter + 1;

          end if;

        -- clear variables for state when it's done and prepare for next
        elsif (state = ADD and state_next = IDLE) then
          add_counter <= (others => '0');

        -- prepare for next block of sha
        elsif (state = ADD and state_next = SHA) then
          -- reset h
          h_int       <= h_reset;
          add_counter <= (others => '0');


        elsif (state = ADD and state_next = ADD) then
          -- only incrememnt counter if ready
          if (hash_out_ready = '1') then
            add_counter <= add_counter + 1;
          end if;

        end if;

      end if;
    end if;
  end process;

-- k bram instance
  sha256_k_bram_1 : sha256_k_bram
    port map (
      clka  => clk,
      addra => std_logic_vector(j_counter),
      douta => k_int);                  -- get k for each word.


-- MAIN PROCESSING PART
-- There are TWO main sections to this
-- They each operate in parallel, and then are combined on the w_new_valid clockcycle
-- They are as follows
---- The LOGICAL FUNCTION section, which calculates everything but Wj
---- The WJ section, which calculates Wj.


-- LOGICAL FUNCTION SECTON
-- generate logical functions
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        s0_int  <= (others => '0');
        s1_int  <= (others => '0');
        maj_int <= (others => '0');
        ch_int  <= (others => '0');

      else
        -- usigma = upper case sigma

        s0_int  <= usigma0(h_int(0));                  --a
        maj_int <= maj(h_int(0), h_int(1), h_int(2));  --a b c

        s1_int <= usigma1(h_int(4));                 --e
        ch_int <= ch(h_int(4), h_int(5), h_int(6));  -- e f g

      end if;
    end if;
  end process;

-- A whole bunch of additions need to occur now
-- T1 = s1_int + ch_int + k_int + h_int(7)
-- T2 = s0_int + maj_int

-- T1 usually includes Wj but it is excluded here because it's not ready yet.
-- Pre-add everything (which creates the _pre signals)
-- And then when wj is valid, add it in to create the _new signals

--
-- 8 additions occur using 2 adders over 4 clock cycles
-- Adder A and B
-- stage 1-4
--
-- T1 first:
-- T1 = s1_int + ch_int + k_int + h_int(7)
--        -- Adder A--     -- Adder B --     stage 1
--              -- Adder B --                stage 2
--
-- Then T2:
--  T2 = s0_int + maj_int
--        -- Adder A--                       stage 2

-- So by Stage 3, we have T1 and T2 calculated
-- Use these to calculare the pre-h values
-- h0_pre = T1 + T2
--        -- Adder A --                      stage 3
--
-- h4_pre = h(3) + T1
--        -- Adder B --                      stage 3

-- now Wj is calculated,
-- so add Wj to these values to get the final h0 and h4
-- h0_new = h0_pre + w_new
--          -- Adder A --                    stage 4
--
-- h4_new = h4_pre + w_new
--          -- Adder B --                    stage 4

-- this mechanism operates on the ASSUMPTION that w_new_valid will be asserted
-- during stage 4. That is, at the same time as h0_pre_valid and h4_pre_valid
-- as such, check for that here.

  error_i(0) <= '1' when h0_pre_valid = '1' and w_new_valid = '0' else '0';
  error_i(1) <= '1' when h4_pre_valid = '1' and w_new_valid = '0' else '0';

  -- indicate error state
  error_i(2) <= '1' when state = ERR else '0';

  -- others unused for now
  error_i(3) <= '0';

  -- register all these errors so that they remain high even if the error goes
  -- away. Do this on a bit-by-bit basis so that if another subsequent error occurs, it
  -- gets stored too.

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        error_l <= (others => '0');

      else
        for j in 3 downto 0 loop
          -- register on a bit-by-bit basis
          if (error_i(j) = '1') then
            error_l(j) <= '1';

          end if;
        end loop;  -- j
      end if;
    end if;
  end process;

  error_out <= error_l;

-- generate the valids for the first 2 stages of adders
-- these will ripple down through the rest

-- This calculation can be shifted relative to the Wj section
-- by changing which state_counter value it starts at.
-- These valids ripple down the entire calculation.

-- stage 1 variables
  s1_int_valid <= '1' when state_counter = "001" and state = SHA else '0';
  ch_int_valid <= '1' when state_counter = "001" and state = SHA else '0';
  k_int_valid  <= '1' when state_counter = "001" and state = SHA else '0';
  h_int_valid  <= '1' when state_counter = "001" and state = SHA else '0';

-- stage 2 variables
  s0_int_valid  <= '1' when state_counter = "010" and state = SHA else '0';
  maj_int_valid <= '1' when state_counter = "010" and state = SHA else '0';


  sha256_32b_add_1 : sha256_32b_add
    port map (
      A   => h_add1_A,
      B   => h_add1_B,
      CLK => clk,
      CE  => '1',
      S   => h_add1_S);

  h_add1_A <= s1_int when s1_int_valid = '1' else
              maj_int when maj_int_valid = '1' else
              T1_int  when T1_int_valid = '1' else
              h0_pre  when h0_pre_valid = '1' else
              (others => '0');

  h_add1_B <= ch_int when ch_int_valid = '1' else
              s0_int when s0_int_valid = '1' else
              T2_int when T2_int_valid = '1' else
              w_new  when w_new_valid = '1' else  --  WJ result comes in here
              (others => '0');

  s1_ch  <= h_add1_S;
  T2_int <= h_add1_S;
  h0_pre <= h_add1_S;
  h0_new <= h_add1_S;



  sha256_32b_add_2 : sha256_32b_add
    port map (
      A   => h_add2_A,
      B   => h_add2_B,
      CLK => clk,
      CE  => '1',
      S   => h_add2_S);


  h_add2_A <= k_int when k_int_valid = '1' else
              s1_ch  when s1_ch_valid = '1' else
              T1_int when T1_int_valid = '1' else
              h4_pre when h4_pre_valid = '1' else
              (others => '0');

  h_add2_B <= h_int(7) when h_int_valid = '1' else
              k_h      when k_h_valid = '1' else
              h_int(3) when T1_int_valid = '1' else  -- this h_int(3) doesn't
                                                     -- have a valid, so use
                                        -- its partner's valid (T1_int)
              w_new    when w_new_valid = '1'  else  --  WJ result comes in here
              (others => '0');

  k_h    <= h_add2_S;
  T1_int <= h_add2_S;
  h4_pre <= h_add2_S;
  h4_new <= h_add2_S;

-- generate valids;
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        s1_ch_valid  <= '0';
        k_h_valid    <= '0';
        T2_int_valid <= '0';
        T1_int_valid <= '0';
        h4_pre_valid <= '0';
        h0_pre_valid <= '0';
        h4_new_valid <= '0';
        h0_new_valid <= '0';
      else
        s1_ch_valid  <= s1_int_valid and ch_int_valid;
        k_h_valid    <= k_int_valid and h_int_valid;
        T2_int_valid <= maj_int_valid and s0_int_valid;
        T1_int_valid <= s1_ch_valid and k_h_valid;
        h4_pre_valid <= T1_int_valid;   --h_int(3) doesn't have a valid.
        h0_pre_valid <= T1_int_valid and T2_int_valid;
        h4_new_valid <= h4_pre_valid and w_new_valid;
        h0_new_valid <= h0_pre_valid and w_new_valid;

      end if;
    end if;
  end process;

-- new h
  h_new(0) <= h0_new;
  h_new(1) <= h_int(0);
  h_new(2) <= h_int(1);
  h_new(3) <= h_int(2);
  h_new(4) <= h4_new;
  h_new(5) <= h_int(4);
  h_new(6) <= h_int(5);
  h_new(7) <= h_int(6);

  h_new_valid <= h4_new_valid and h0_new_valid;

-- WJ SECTION

  sha256_w_bram_1 : sha256_w_bram
    port map (
      clka  => clk,
      ena   => '1',
      wea   => w_bram_wea,
      addra => w_bram_addra,
      dina  => w_bram_dina,
      douta => w_bram_douta,
      clkb  => clk,
      enb   => '1',
      web   => w_bram_web,
      addrb => w_bram_addrb,
      dinb  => w_bram_dinb,
      doutb => w_bram_doutb);


-- get w_values. 4 of them are required:
-- these are retrieved in pairs
-- 15 and 16 on the first cc
-- 7 and 2 on the second cc

-- j_counter = j
-- j-15
-- j-16
-- j-2
-- j-7



-- generate the valids
-- only start off this process if gen_w is valid
-- all other valids ripple down from these

-- bram port a
  sub_15_valid <= '1' when state_counter = "000" and state = SHA else '0';
  sub_2_valid  <= '1' when state_counter = "001" and state = SHA else '0';

-- bram port b
  sub_16_valid <= '1' when state_counter = "000" and state = SHA else '0';
  sub_7_valid  <= '1' when state_counter = "001" and state = SHA else '0';

-- 15 and 16 are valid on 000
-- 7 and 2 are valid on 001

-- 1cc latency through bram read
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        Wj15_valid <= '0';
        Wj16_valid <= '0';
        Wj7_valid  <= '0';
        Wj2_valid  <= '0';

      else

        Wj15_valid <= addr_15_valid;
        Wj16_valid <= addr_16_valid;
        Wj7_valid  <= addr_7_valid;
        Wj2_valid  <= addr_2_valid;

      end if;
    end if;
  end process;

-- subtract constants from j_counter to generate the addresses for the bram
-- since we're calculating j-16, it's assumed that j>=16
-- the gen_w is that mask.
-- if j < 16, then subtract 0.
-- In the case where j < 16, the Wj value is taken from the input message in
-- any case. See W_IN SECTION at end.

  sha256_6b_sub_1 : sha256_6b_sub
    port map (
      A => w_sub1_A,
      B => w_sub1_B,
      S => w_sub1_S);

  w_sub1_A <= std_logic_vector(j_counter);
  w_sub1_B <= const_15 when sub_15_valid = '1' and gen_w = '1' else  --15
              const_2 when sub_2_valid = '1' and gen_w = '1' else    -- 2
              const_0;                                               -- 0

-- no latency through subtract
  addr_15_valid <= sub_15_valid;
  addr_2_valid  <= sub_2_valid;

-- BRAM port A reads the 15 and 2 addresses
  w_bram_addra <= w_sub1_S;

-- 15 and 2 are read here
  Wj15 <= w_bram_douta;
  Wj2  <= w_bram_douta;


  sha256_6b_sub_2 : sha256_6b_sub
    port map (
      A => w_sub2_A,
      B => w_sub2_B,
      S => w_sub2_S);

  w_sub2_A <= std_logic_vector(j_counter);
  w_sub2_B <= const_16 when sub_16_valid = '1' and gen_w = '1' else  --16
              const_7 when sub_7_valid = '1' and gen_w = '1' else    -- 7
              const_0;                                               -- 0


  addr_16_valid <= sub_16_valid;
  addr_7_valid  <= sub_7_valid;

-- bram port b reads the 16 and 7 addresses
  w_bram_addrb <= w_sub2_S;

-- 16 and 7 are read here
  Wj16 <= w_bram_doutb;
  Wj7  <= w_bram_doutb;

-- write only when Wj is valid
  w_bram_wea(0) <= w_new_valid;
  w_bram_dina   <= w_new;

-- never write channel b
  w_bram_web  <= "0";
  w_bram_dinb <= (others => '0');

-- use the bram reads to calculate the lsigma functions
-- lsigma0(x) =  (x ror 7) xor  (x ror 18) xor  (x srl 3)
-- lsigma1(x) =  (x ror 17) xor  (x ror 19) xor  (x srl 10)
-- we want lsigma0(Wj-15) and lsigma1(Wj-2)
  lsigma0_Wj15 <= ((Wj15 ror 7) xor (Wj15 ror 18) xor (Wj15 srl 3));
  lsigma1_Wj2  <= ((Wj2 ror 17) xor (Wj2 ror 19) xor (Wj2 srl 10));

  lsigma0_Wj15_valid <= Wj15_valid;
  lsigma1_Wj2_valid  <= Wj2_valid;

-- now it's necessary to add together the following
-- lsigma0_Wj15 + Wj16 + lsigma1_Wj2 + Wj7
-- this generates Wj
--
-- perform this addition over 3cc with a single adder
-- lsigma0_Wj15 + Wj16 + lsigma1_Wj2 + Wj7
--  --   stage 1 --        -- stage 2 --
--           ----  stage 3   ----

-- store the stage 1 result for 1cc while the stage 2 calculation is in progress.

-- state counter == 4
-- add to h (see above)


  sha256_32b_add_3 : sha256_32b_add
    port map (
      A   => w_add3_A,
      B   => w_add3_B,
      CLK => clk,
      CE  => '1',
      S   => w_add3_S);

  w_add3_A <= lsigma0_Wj15 when lsigma0_Wj15_valid = '1' else
              lsigma1_Wj2 when lsigma1_Wj2_valid = '1' else
              Wj15_Wj16_z when Wj15_Wj16_z_valid = '1' else
              (others => '0');

  w_add3_B <= Wj16 when Wj16_valid = '1' else
              Wj7     when Wj7_valid = '1' else
              Wj2_Wj7 when Wj2_Wj7_valid = '1' else
              (others => '0');

  Wj15_Wj16 <= w_add3_S;                --stage 1
  Wj2_Wj7   <= w_add3_S;                --stage 2
  Wj        <= w_add3_S;                --stage 2

-- delay Wj15_Wj16 for 1cc so that it's valid at the same time as Wj2_Wj7
-- generate valids;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        Wj15_Wj16_z       <= (others => '0');
        Wj15_Wj16_z_valid <= '0';
        Wj15_Wj16_valid   <= '0';
        Wj2_Wj7_valid     <= '0';
        Wj_valid          <= '0';

      else
        Wj15_Wj16_z       <= Wj15_Wj16;
        Wj15_Wj16_z_valid <= Wj15_Wj16_valid;
        Wj15_Wj16_valid   <= lsigma0_Wj15_valid and Wj16_valid;
        Wj2_Wj7_valid     <= lsigma1_Wj2_valid and Wj7_valid;
        Wj_valid          <= Wj15_Wj16_z_valid and Wj2_Wj7_valid;

      end if;
    end if;
  end process;

-- generate w_in
-- W_IN SECTION

-- If j < 16, then we need to get it from the message in
  --bytewise_valid
  w_in <= message_in when last_message = '0' else (others => '0');

  --byte-wise valid

  -- assert ready when message in has been used.
  -- which is the following case:
  -- Wj_valid is asserted
  -- gen_w = '0'
  -- the last message has not been received
  message_in_ready_i <= '1' when Wj_valid = '1' and gen_w = '0' and last_message = '0' else
                        '0';
  message_in_ready <= message_in_ready_i;

  -- remember when last has been received

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        last_message <= '0';

      else
        if (message_in_valid = '1' and message_in_last = '1' and message_in_ready_i = '1') then
          last_message <= '1';

        end if;

        if (add_valid_z = '1' and last_message = '1' and add_last_z = '1') then
          last_message <= '0';

        end if;
      end if;
    end if;
  end process;

-- either wj or the input message is used, depending on the gen_w flag
-- mux
  w_new <= Wj when gen_w = '1' else
           w_in;
  w_new_valid <= Wj_valid;


  -- final stage adder
  sha256_32b_add_4 : sha256_32b_add
    port map (
      A   => w_add4_A,
      B   => w_add4_B,
      CLK => clk,
      CE  => hash_out_ready,
      S   => w_add4_S);

  add_inputs : for i in 0 to 7 generate

    w_add4_A <= h_int(i)   when add_counter = i else (others => 'Z');
    w_add4_B <= h_reset(i) when add_counter = i else (others => 'Z');

  end generate add_inputs;

  add_valid <= '1' when state = ADD                     else '0';
  add_last  <= '1' when state = ADD and add_counter = 7 else '0';

  -- 1cc latency through the adder, so delay output signals
  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        add_valid_z <= '0';
        add_last_z  <= '0';


      elsif (hash_out_ready = '1') then
        -- clk-enable on ready
        add_valid_z <= add_valid;
        add_last_z  <= add_last;

      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        h_start <= h_reset;

      else

        for i in 7 downto 0 loop
          if (add_counter_z = i and add_valid_z = '1') then
            h_start(i) <= w_add4_S;

          end if;
        end loop;  -- i

        if (state = IDLE) then
          h_start <= h_reset;

        end if;
      end if;
    end if;
  end process;


  hash_out       <= w_add4_S;
  hash_out_valid <= '1' when add_valid_z = '1' and last_message = '1' else '0';
  hash_out_last  <= '1' when add_last_z = '1' and last_message = '1'  else '0';


end behavioral;
