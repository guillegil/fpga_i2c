library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- I2C_Inst:
-- entity Work.i2c
--   generic map(
--       DEVICE_ADDR   => DEVICE_ADDR
--   )
--   port map(
--       CLK   => CLK,
--       SRST  => SRST,
--       SDA   => SDA,
--       SCL   => SCL,
--       DATA_OUT => DATA_OUT
--   );

entity i2c is
  generic(
      DEVICE_ADDR   : std_logic_vector(6 downto 0) := "0000000"
  );
  port (
      CLK   : in std_logic;
      SRST  : in std_logic;
      SDA   : inout std_logic;
      SCL   : inout std_logic;
      DATA_OUT :  out std_logic_vector(7 downto 0)
  ) ;
end i2c;

architecture rtl of i2c is

    constant WORD_LENGTH : integer := 8;

    signal iReg1, iReg2 : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal iReg3, iReg4 : std_logic_vector(2*WORD_LENGTH - 1 downto 0) := (others => '0');

    type states is (IDLE, CHECK_ADDR, WAIT_REG_ADDR, DATA, STOP);
    signal current_state, next_state : states := IDLE;

    signal sda_reg, scl_reg : std_logic_vector(1 downto 0);
    signal start_condition, stop_condition : std_logic := '0';
    signal data_avaliable : std_logic := '0';
    signal data_ready     : std_logic_vector(1 downto 0) := (others => '0');
    signal mode_reg, mode_next : std_logic := '0';

    signal data_reg, data_next : std_logic_vector(7 downto 0) := (others => '0');
    signal addr : std_logic_vector(6 downto 0) := (others => '0');

    signal data_count_reg, data_count_next : integer range 0 to 8 := 0;
begin

    sda_reg <= SDA & sda_reg(1) when rising_edge(CLK);
    scl_reg <= SCL & scl_reg(1) when rising_edge(CLK);

    -- HIGH to LOW transition on the SDA line when SCL is high
    start_condition <= (not(sda_reg(1)) and sda_reg(0)) and scl_reg(0);

    -- LOW to HIGH transition on the SDA line when SCL is high 
    stop_condition  <= (not(sda_reg(0)) and sda_reg(1)) and scl_reg(0); 
    data_avaliable <= not(scl_reg(0)) and scl_reg(1);

    -- State register
    process
    begin
        wait until rising_edge(CLK);
        if SRST = '1' then
            current_state <= IDLE;
        else
            current_state <= next_state;   
        end if;
    end process;

    data_reg <= data_next when rising_edge(CLK);
    data_count_reg <= data_count_next when rising_edge(CLK);
    mode_reg <= mode_next when rising_edge(CLK);

    process(current_state, sda_reg, data_avaliable, data_count_reg, data_reg, data_ready)
    begin
        next_state <= current_state;
        data_next <= data_reg;
        data_count_next <= data_count_reg;

        case current_state is
        when IDLE =>
            if start_condition = '1' then
                next_state <= CHECK_ADDR;
            end if;
        when CHECK_ADDR =>
            if data_count_reg = 8 then
                data_count_next <= 0;
                if data_reg(7 downto 1) = DEVICE_ADDR then
                    -- TODO next_state
                    data_count_next <= 0;
                    next_state <= WAIT_REG_ADDR; -- DELETE, This only for early test
                    mode_next <= data_reg(0);
                else
                    next_state <= IDLE;
                end if;
            else
                if data_avaliable = '1' then
                    data_next <= data_reg(6 downto 0) & sda_reg(0);
                    data_count_next <= data_count_reg + 1;
                end if;
            end if;
        when WAIT_REG_ADDR =>
        when STOP =>
        when others =>
            next_state <= current_state;
            data_next <= data_reg;
            data_count_next <= data_count_reg;
        end case;

    end process;

    SDA <= 'Z';
    SCL <= 'Z';

    DATA_OUT <= data_reg;

end rtl ; -- rtl