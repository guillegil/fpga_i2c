library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_tb is
end i2c_tb;

architecture testbench of i2c_tb is

    constant ADDR : std_logic_vector(6 downto 0) := "1110000";
    constant DEVICE_ADDR        : std_logic_vector(6 downto 0) := "HHH0000";

    constant CLOCK_PERIOD_50MHz : time := 20 ns;

    constant SCL_PERIOD_LOW_400kHz  : time  := 1.3 us + 0.3 us;  -- (t_LOW)  -- 1.3 is the min required
    constant SCL_PERIOD_HIGH_400kHz : time  := 0.6 us + 0.3 us;  -- (t_HIGH) -- 0.6 is the min required
    constant I2C_START_HOLD_TIME    : time  := 0.6 us;           -- (t_HD;STA)
    constant SDA_DATA_HOLD_TIME     : time  := 0 ns;             -- (t_HD;DAT)
    constant SDA_DATA_VALID_TIME_400kHz    : time  := 0.9 us;    -- (t_VD;DAT)
    constant SDA_ACK_VALID_TIME_400kHZ     : time  := 0.9 us;    -- (t_VD;ACK) 
    constant SCL_STOP_SETUP_TIME_400kHz    : time  := 0.6 us;    -- (t_SU;STO)

    constant I2C_MODE_WRITE : std_logic := '0';
    constant I2C_MODE_READ  : std_logic := '1';
    
    signal CLK, SRST : std_logic := '0';
    signal SDA, SCL  : std_logic := 'Z';
    signal DATA_OUT  : std_logic_vector(15 downto 0) := (others => '0');

    signal sda_dis, scl_dis   : std_logic := '1';
    signal sda_data, scl_data : std_logic;
    signal addresing : std_logic_vector(7 downto 0) := ADDR & I2C_MODE_READ;
    
    type test_vector_t is array(0 to 1) of std_logic_vector(7 downto 0);
    constant test_vector : test_vector_t := (
        x"83",
        x"9A"
    );

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

  CLK <= not CLK after (CLOCK_PERIOD_50MHz/2);
    
    SDA <= 'H' when sda_dis = '1' else '0';
    SCL <= 'H' when scl_dis = '1' else '0';

    process
    begin
        SRST <= '1';

        sda_dis <= '1';
        scl_dis <= '1';

        wait for CLOCK_PERIOD_50MHz*5.5;
        SRST <= '0';

        -- ------------------------
        --    Addressing Device
        -- ------------------------

        -- Generate Start condition
        sda_dis <= '0';  
        wait for (I2C_START_HOLD_TIME); 
        scl_dis <= '0';  

        for idx in 0 to 7 loop
            wait for (SDA_DATA_HOLD_TIME); 
            wait for (SDA_DATA_VALID_TIME_400kHz);
            
            sda_dis <= addresing(7 - idx);
            
            wait for (SCL_PERIOD_LOW_400kHz - SDA_DATA_HOLD_TIME - SDA_DATA_VALID_TIME_400kHz);
            scl_dis <= '1';
            wait for (SCL_PERIOD_HIGH_400kHz);
            scl_dis <= '0';
            
        end loop;

        sda_dis <= '1';
        wait for (SDA_DATA_HOLD_TIME);
        wait for (SDA_ACK_VALID_TIME_400kHZ);

        -- Ninth pulse for ACK
        wait for (SCL_PERIOD_LOW_400kHz - SDA_DATA_HOLD_TIME - SDA_ACK_VALID_TIME_400kHZ);
        scl_dis <= '1';
        wait for (SCL_PERIOD_HIGH_400kHz/2);

        assert SDA = '0'
        report "ACK 1 hasn't been asserted low by the slave";

        wait for (SCL_PERIOD_HIGH_400kHz/2);
        scl_dis <= '0';
        sda_dis <= '0'; -- Keep the line busy

        -- ------------------------
        --       First byte
        -- ------------------------

        for idx in 0 to 7 loop
            wait for (SDA_DATA_HOLD_TIME); 
            wait for (SDA_DATA_VALID_TIME_400kHz);

            sda_dis <= test_vector(1)(7 - idx);
            wait for (SCL_PERIOD_LOW_400kHz - SDA_DATA_HOLD_TIME - SDA_DATA_VALID_TIME_400kHz);
            scl_dis <= '1';
            wait for (SCL_PERIOD_HIGH_400kHz);
            scl_dis <= '0';
        end loop;
        
        sda_dis <= '1';
        wait for (SDA_DATA_HOLD_TIME);
        wait for (SDA_ACK_VALID_TIME_400kHZ);

        -- Ninth pulse for ACK
        wait for (SCL_PERIOD_LOW_400kHz - SDA_DATA_HOLD_TIME - SDA_ACK_VALID_TIME_400kHZ);
        scl_dis <= '1';
        wait for (SCL_PERIOD_HIGH_400kHz/2);

        assert SDA = '0'
        report "ACK 2 hasn't been asserted low by the slave";

        wait for (SCL_PERIOD_HIGH_400kHz/2);
        scl_dis <= '0';
        sda_dis <= '0'; -- Keep the line busy

        -- ------------------------
        --       Second byte
        -- ------------------------

        for idx in 0 to 7 loop
            wait for (SDA_DATA_HOLD_TIME); 
            wait for (SDA_DATA_VALID_TIME_400kHz);

            sda_dis <= test_vector(0)(7 - idx);
            wait for (SCL_PERIOD_LOW_400kHz - SDA_DATA_HOLD_TIME - SDA_DATA_VALID_TIME_400kHz);
            scl_dis <= '1';
            wait for (SCL_PERIOD_HIGH_400kHz);
            scl_dis <= '0';
        end loop;
        
        sda_dis <= '1';
        wait for (SDA_DATA_HOLD_TIME);
        wait for (SDA_ACK_VALID_TIME_400kHZ);

        -- Ninth pulse for ACK
        wait for (SCL_PERIOD_LOW_400kHz - SDA_DATA_HOLD_TIME - SDA_ACK_VALID_TIME_400kHZ);
        scl_dis <= '1';
        wait for (SCL_PERIOD_HIGH_400kHz/2);

        assert SDA = '0'
        report "ACK 3 hasn't been asserted low by the slave";

        wait for (SCL_PERIOD_HIGH_400kHz/2);
        scl_dis <= '0';
        sda_dis <= '0';


        -- Stop condition
        wait for (SDA_DATA_HOLD_TIME); 
        wait for (SDA_DATA_VALID_TIME_400kHz);
        
        scl_dis <= '1';

        wait for (SCL_STOP_SETUP_TIME_400kHz);
        sda_dis <= '1';



        report "SIMULATION END!"
        severity failure;

    end process; 

end testbench ; -- testbench