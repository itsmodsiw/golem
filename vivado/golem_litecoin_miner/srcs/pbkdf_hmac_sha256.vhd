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


entity pbkdf_hmac_sha256 is
  port (
    clk : in std_logic;
    rst : in std_logic;

    iteration       : in std_logic_vector(31 downto 0);
    iteration_valid : in std_logic;

    -- maps to sha key
    password_in_length       : in std_logic_vector(63 downto 0);
    password_in_length_valid : in std_logic;

    password_in       : in  std_logic_vector(31 downto 0);
    password_in_valid : in  std_logic;
    password_in_last  : in  std_logic;
    password_in_ready : out std_logic;

    -- maps to sha message
    salt_in_length       : in std_logic_vector(63 downto 0);
    salt_in_length_valid : in std_logic;

    salt_in       : in  std_logic_vector(31 downto 0);
    salt_in_valid : in  std_logic;
    salt_in_last  : in  std_logic;
    salt_in_ready : out std_logic;

    hash_out_length       : out std_logic_vector(63 downto 0);
    hash_out_length_valid : out std_logic;

    hash_out       : out std_logic_vector(31 downto 0);
    hash_out_valid : out std_logic;
    hash_out_last  : out std_logic;
    hash_out_ready : in  std_logic;


    error_out : out std_logic_vector(3 downto 0)

    );

end pbkdf_hmac_sha256;

architecture behavioral of pbkdf_hmac_sha256 is

  constant LATENCY_BEFORE_START : integer := 2;

  -- this is fixed at c=1 iteration
  component pbkdf_function is
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
  end component pbkdf_function;

  component pbkf_4B_ram
    port (
      clka  : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(7 downto 0);
      dina  : in  std_logic_vector(32 downto 0);
      clkb  : in  std_logic;
      enb   : in  std_logic;
      addrb : in  std_logic_vector(7 downto 0);
      doutb : out std_logic_vector(32 downto 0)
      );
  end component;

  component pbkdf_fifo
    port (
      s_aclk        : in  std_logic;
      s_aresetn     : in  std_logic;
      s_axis_tvalid : in  std_logic;
      s_axis_tready : out std_logic;
      s_axis_tdata  : in  std_logic_vector(31 downto 0);
      s_axis_tlast  : in  std_logic;
      m_axis_tvalid : out std_logic;
      m_axis_tready : in  std_logic;
      m_axis_tdata  : out std_logic_vector(31 downto 0);
      m_axis_tlast  : out std_logic
      );
  end component;

  signal password_in_length_i       : std_logic_vector(63 downto 0);
  signal password_in_length_valid_i : std_logic;
  signal password_in_fifo_in        : std_logic_vector(31 downto 0);
  signal password_in_valid_fifo_in  : std_logic;
  signal password_in_last_fifo_in   : std_logic;
  signal password_in_ready_fifo_in  : std_logic;
  signal password_in_fifo_out       : std_logic_vector(31 downto 0);
  signal password_in_valid_fifo_out : std_logic;
  signal password_in_last_fifo_out  : std_logic;
  signal password_in_ready_fifo_out : std_logic;

  signal salt_in_length_i       : std_logic_vector(63 downto 0);
  signal salt_in_length_valid_i : std_logic;
  signal salt_in_fifo_in        : std_logic_vector(31 downto 0);
  signal salt_in_valid_fifo_in  : std_logic;
  signal salt_in_last_fifo_in   : std_logic;
  signal salt_in_ready_fifo_in  : std_logic;
  signal salt_in_fifo_out       : std_logic_vector(31 downto 0);
  signal salt_in_valid_fifo_out : std_logic;
  signal salt_in_last_fifo_out  : std_logic;
  signal salt_in_ready_fifo_out : std_logic;

  signal wea_salt   : std_logic_vector(0 downto 0);
  signal addra_salt : std_logic_vector(7 downto 0);
  signal dina_salt  : std_logic_vector(32 downto 0);
  signal enb_salt   : std_logic;
  signal addrb_salt : std_logic_vector(7 downto 0);
  signal doutb_salt : std_logic_vector(32 downto 0);

  signal wea_password   : std_logic_vector(0 downto 0);
  signal addra_password : std_logic_vector(7 downto 0);
  signal dina_password  : std_logic_vector(32 downto 0);
  signal enb_password   : std_logic;
  signal addrb_password : std_logic_vector(7 downto 0);
  signal doutb_password : std_logic_vector(32 downto 0);


  signal addra_salt_counter     : unsigned(7 downto 0);
  signal addra_password_counter : unsigned(7 downto 0);
  signal addra_salt_max         : unsigned(7 downto 0);
  signal addra_password_max     : unsigned(7 downto 0);
  signal addrb_salt_counter     : unsigned(7 downto 0);
  signal addrb_password_counter : unsigned(7 downto 0);
  signal addrb_salt_max         : unsigned(7 downto 0);
  signal addrb_password_max     : unsigned(7 downto 0);


  signal iteration_counter       : std_logic_vector(31 downto 0);
  signal iteration_max           : std_logic_vector(31 downto 0);
  signal iteration_counter_valid : std_logic;
  signal iteration_counter_busy  : std_logic;

  signal data_received : std_logic_vector(3 downto 0);

  signal salt_read_done      : std_logic;
  signal password_read_done  : std_logic;
  signal salt_write_done     : std_logic;
  signal password_write_done : std_logic;


  signal bram_read_salt     : std_logic;
  signal bram_read_password : std_logic;

  signal rstn : std_logic;

  signal hash_out_valid_i : std_logic;
  signal hash_out_last_i  : std_logic;
  signal hash_out_ready_i : std_logic;

begin
  rstn <= not rst;


  --
  -- remember the iteration max

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        iteration_max           <= (others => '0');
        iteration_counter_valid <= '0';
        iteration_counter       <= (0 => '1',others => '0');
        iteration_counter_busy  <= '0';

        addra_salt_counter     <= (others => '0');
        addra_password_counter <= (others => '0');
        addra_salt_max         <= (others => '0');
        addra_password_max     <= (others => '0');

      else
        iteration_counter_valid <= '0';

        if (wea_salt = "1") then

          if (salt_in_last = '1') then
            addra_salt_counter <= (others => '0');
            addra_salt_max     <= addra_salt_counter;

          else
            addra_salt_counter <= addra_salt_counter + 1;

          end if;

        end if;

        if (wea_password = "1") then

          if (password_in_last = '1') then
            addra_password_counter <= (others => '0');
            addra_password_max     <= addra_password_counter;

          else
            addra_password_counter <= addra_password_counter + 1;

          end if;

        end if;

        if (iteration_valid = '1' and iteration_counter_busy = '0') then
          iteration_max           <= iteration;
          iteration_counter       <= (0 => '1',others => '0');
          iteration_counter_valid <= '1';
          iteration_counter_busy  <= '1';

        end if;

        -- if valid hash is produced, increment iteration_counter
        if (hash_out_valid_i = '1' and hash_out_last_i = '1' and hash_out_ready_i = '1') then
          if (unsigned(iteration_counter) < unsigned(iteration_max)) then
            iteration_counter       <= std_logic_vector(unsigned(iteration_counter) + 1);
            iteration_counter_valid <= '1';
          else

            iteration_counter      <= (0 => '1',others => '0');
            iteration_counter_busy <= '0';

          end if;
        end if;

      end if;
    end if;
  end process;

  addrb_salt_max     <= addra_salt_max;
  addrb_password_max <= addra_password_max;

  wea_salt(0) <= salt_in_valid and not salt_write_done;
  addra_salt  <= std_logic_vector(addra_salt_counter);
  dina_salt   <= salt_in_last & salt_in;

  enb_salt   <= bram_read_salt;
  addrb_salt <= std_logic_vector(addrb_salt_counter);

-- store the input password and salt in bram
  pbkf_4B_ram_salt : pbkf_4B_ram
    port map (
      clka  => clk,
      wea   => wea_salt,
      addra => addra_salt,
      dina  => dina_salt,
      clkb  => clk,
      enb   => enb_salt,
      addrb => addrb_salt,
      doutb => doutb_salt);

  wea_password(0) <= password_in_valid and not password_write_done;
  addra_password  <= std_logic_vector(addra_password_counter);
  dina_password   <= password_in_last & password_in;

  enb_password   <= bram_read_password;
  addrb_password <= std_logic_vector(addrb_password_counter);

  pbkf_4B_ram_password : pbkf_4B_ram
    port map (
      clka  => clk,
      wea   => wea_password,
      addra => addra_password,
      dina  => dina_password,
      clkb  => clk,
      enb   => enb_password,
      addrb => addrb_password,
      doutb => doutb_password);

  -- when both lasts are written, prepare to start processing
  -- remember the iteration max
  data_received(0) <= password_write_done and salt_write_done and not salt_read_done and not password_read_done;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        salt_write_done     <= '0';
        password_write_done <= '0';
        salt_read_done      <= '0';
        password_read_done  <= '0';

        data_received(3 downto 1) <= (others => '0');
        bram_read_salt            <= '0';
        bram_read_password        <= '0';

        addrb_salt_counter     <= (others => '0');
        addrb_password_counter <= (others => '0');

      else
        -- delay data received
        data_received(3 downto 1) <= data_received(2 downto 0);


        if(password_in_valid = '1' and password_in_last = '1') then
          password_write_done <= '1';

        end if;

        if(salt_in_valid = '1' and salt_in_last = '1') then
          salt_write_done <= '1';

        end if;

        -- there's a latency between the data being written and the processing
        -- LATENCY_BEFORE_START
        -- because the BRAM has a latency before the data is available on the b
        -- bus for reading. In this case it's 2, but can be asjusted in the
        -- constant if required.

        if (data_received(LATENCY_BEFORE_START) = '1' and salt_read_done = '0' and password_read_done = '0') then
          bram_read_salt     <= '1';
          bram_read_password <= '1';

        end if;

        -- only advance counter if ready.
        if (bram_read_salt = '1' and salt_read_done = '0') then
          if (addrb_salt_counter = addrb_salt_max) then
            addrb_salt_counter <= (others => '0');
            bram_read_salt     <= '0';
            salt_read_done     <= '1';

          else
            addrb_salt_counter <= addrb_salt_counter + 1;

          end if;
        end if;

        if (bram_read_password = '1' and password_read_done = '0') then
          if (addrb_password_counter = addrb_password_max) then
            addrb_password_counter <= (others => '0');
            bram_read_password     <= '0';
            password_read_done     <= '1';

          else
            addrb_password_counter <= addrb_password_counter + 1;

          end if;
        end if;


        -- if hash is done, clear all
        if (hash_out_valid_i = '1' and hash_out_last_i = '1' and hash_out_ready_i = '1') then
          salt_read_done     <= '0';
          password_read_done <= '0';

          data_received(3 downto 1) <= (others => '0');
          bram_read_salt            <= '0';
          bram_read_password        <= '0';

          addrb_salt_counter     <= (others => '0');
          addrb_password_counter <= (others => '0');

          if (unsigned(iteration_counter) = unsigned(iteration_max)) then
            -- clear write dones
            salt_write_done     <= '0';
            password_write_done <= '0';

          end if;

        end if;

      end if;
    end if;
  end process;

  -- now for the BRAM read counters;
  salt_in_fifo_in      <= doutb_salt(31 downto 0);
  salt_in_last_fifo_in <= doutb_salt(32);

  password_in_fifo_in      <= doutb_password(31 downto 0);
  password_in_last_fifo_in <= doutb_password(32);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        salt_in_length_valid_i <= '0';
        salt_in_length_i       <= (others => '0');
        salt_in_valid_fifo_in  <= '0';

        password_in_length_valid_i <= '0';
        password_in_length_i       <= (others => '0');
        password_in_valid_fifo_in  <= '0';

      else

        password_in_valid_fifo_in <= bram_read_password;
        salt_in_valid_fifo_in     <= bram_read_salt;

        if (addrb_password_counter = 0) then
          password_in_length_valid_i <= bram_read_password;

        else
          password_in_length_valid_i <= '0';

        end if;

        if (addrb_salt_counter = 0) then
          salt_in_length_valid_i <= bram_read_salt;

        else
          salt_in_length_valid_i <= '0';

        end if;

        if (salt_in_length_valid = '1') then
          salt_in_length_i <= salt_in_length;

        end if;

        if (password_in_length_valid = '1') then
          password_in_length_i <= password_in_length;

        end if;


      end if;
    end if;
  end process;

  pbkdf_fifo_salt : pbkdf_fifo
    port map (
      s_aclk        => clk,
      s_aresetn     => rstn,
      s_axis_tvalid => salt_in_valid_fifo_in,
      s_axis_tready => salt_in_ready_fifo_in,
      s_axis_tdata  => salt_in_fifo_in,
      s_axis_tlast  => salt_in_last_fifo_in,
      m_axis_tvalid => salt_in_valid_fifo_out,
      m_axis_tready => salt_in_ready_fifo_out,
      m_axis_tdata  => salt_in_fifo_out,
      m_axis_tlast  => salt_in_last_fifo_out);

  pbkdf_fifo_password : pbkdf_fifo
    port map (
      s_aclk        => clk,
      s_aresetn     => rstn,
      s_axis_tvalid => password_in_valid_fifo_in,
      s_axis_tready => password_in_ready_fifo_in,
      s_axis_tdata  => password_in_fifo_in,
      s_axis_tlast  => password_in_last_fifo_in,
      m_axis_tvalid => password_in_valid_fifo_out,
      m_axis_tready => password_in_ready_fifo_out,
      m_axis_tdata  => password_in_fifo_out,
      m_axis_tlast  => password_in_last_fifo_out);

  pbkdf_function_1 : pbkdf_function
    port map (
      clk                      => clk,
      rst                      => rst,
      iteration                => iteration_counter,
      iteration_valid          => iteration_counter_valid,
      password_in_length       => password_in_length_i,
      password_in_length_valid => password_in_length_valid_i,
      password_in              => password_in_fifo_out,
      password_in_valid        => password_in_valid_fifo_out,
      password_in_last         => password_in_last_fifo_out,
      password_in_ready        => password_in_ready_fifo_out,
      salt_in_length           => salt_in_length_i,
      salt_in_length_valid     => salt_in_length_valid_i,
      salt_in                  => salt_in_fifo_out,
      salt_in_valid            => salt_in_valid_fifo_out,
      salt_in_last             => salt_in_last_fifo_out,
      salt_in_ready            => salt_in_ready_fifo_out,
      hash_out_length          => hash_out_length,
      hash_out_length_valid    => hash_out_length_valid,
      hash_out                 => hash_out,
      hash_out_valid           => hash_out_valid_i,
      hash_out_last            => hash_out_last_i,
      hash_out_ready           => hash_out_ready_i,
      error_out                => error_out);

  password_in_ready <= not password_write_done;
  salt_in_ready     <= not salt_write_done;

  hash_out_valid   <= hash_out_valid_i;
  -- only drive last on the last iteration
  hash_out_last    <= hash_out_last_i when unsigned(iteration_counter) = unsigned(iteration_max) else '0';
  hash_out_ready_i <= hash_out_ready;


end behavioral;
