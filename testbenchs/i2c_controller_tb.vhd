library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_tb is
end i2c_tb;

architecture testbench of i2c_tb is

    constant DEVICE_ADDR : std_logic_vector(6 downto 0) := "1110000";
    
    constant CLOCK_PERIOD_5MHz : time := 200 ns;

    constant SCL_PERIOD_LOW_400kHz  : time  := 1.3 us + 0.3 us;  -- 1.3 is the min required
    constant SCL_PERIOD_HIGH_400kHz : time  := 0.6 us + 0.3 us;  -- 0.6 is the min required
    constant I2C_START_HOLD_TIME    : time  := 0.6 us;
    constant SDA_DATA_HOLD_TIME     : time := 0 ns;

    constant I2C_MODE_WRITE : std_logic := '0';
    constant I2C_MODE_READ  : std_logic := '1';
    
    signal CLK, SRST : std_logic := '0';
    signal SDA, SCL : std_logic := 'Z';
    signal DATA_OUT : std_logic_vector(7 downto 0) := (others => '0');

    signal sda_dis, scl_dis  : std_logic := '1';
    signal sda_data, scl_data : std_logic;
    signal addresing : std_logic_vector(7 downto 0) := DEVICE_ADDR & I2C_MODE_READ;

begin

DUT:
entity Work.i2c
  generic map(
      DEVICE_ADDR   => DEVICE_ADDR
  )
  port map(
      CLK   => CLK,
      SRST  => SRST,
      SDA   => SDA,
      SCL   => SCL,
      DATA_OUT => DATA_OUT
  );

  CLK <= not CLK after (CLOCK_PERIOD_5MHz/2);
    
  
    SDA <= '1' when sda_dis = '1' else '0';
    SCL <= '1' when scl_dis = '1' else '0';
    
    process
    begin
        SRST <= '1';

        sda_dis <= '1';
        scl_dis <= '1';

        wait for CLOCK_PERIOD_5MHz*5.5;
        SRST <= '0';

        -- Generate Start condition
        sda_dis <= '0';  
        wait for (I2C_START_HOLD_TIME); 
        scl_dis <= '0';  

        for idx in 0 to 7 loop
            wait for (SDA_DATA_HOLD_TIME); 

            sda_dis <= addresing(7 - idx);
            wait for (SCL_PERIOD_LOW_400kHz);
            scl_dis <= '1';
            wait for (SCL_PERIOD_HIGH_400kHz);
            scl_dis <= '0';
        end loop;

        -- Stop condition
        scl_dis <= '1';
        wait for (SCL_PERIOD_HIGH_400kHz);
        sda_dis <= '1';  

        report "SIMULATION END!"
        severity failure;

    end process;

end testbench ; -- testbench