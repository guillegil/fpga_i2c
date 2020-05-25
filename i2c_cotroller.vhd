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
      DATA_OUT :  out std_logic_vector(15 downto 0)
  ) ;
end i2c;

architecture rtl of i2c is

    constant WORD_LENGTH    : integer := 8;
    constant MAX_REG_LENGTH : integer := 16;

    -- Test registers
    signal iReg1, iReg2 : std_logic_vector(WORD_LENGTH - 1 downto 0) := (others => '0');
    signal iReg3, iReg4 : std_logic_vector(2*WORD_LENGTH - 1 downto 0) := (others => '0');

    type states is (IDLE, GET_DEVICE_ADDR, SEND_ACK, REGISTER_DATA, RELASE_LINE, GET_DATA);
    signal current_state, next_state : states := IDLE;
    signal last_state, last_next_state : states := IDLE;

    signal sda_reg, scl_reg : std_logic_vector(1 downto 0);
    signal sda_dis_reg, scl_dis_reg, sda_dis_next, scl_dis_next : std_logic := '0';
    signal start_condition, stop_condition : std_logic := '0';
    signal data_avaliable : std_logic := '0';
    signal data_ready     : std_logic := '0';
    signal mode_reg, mode_next : std_logic := '0';

    signal byte_reg, byte_next : std_logic_vector(7 downto 0) := (others => '0');
    signal byte_buffer         : std_logic_vector(7 downto 0) := (others => '0');
    signal data_reg, data_next : std_logic_vector(2*WORD_LENGTH - 1 downto 0) := (others => '0');
    signal data_count_reg, data_count_next : integer range 0 to 8 := 0;
    
begin

    sda_reg <= SDA & sda_reg(1) when rising_edge(CLK);
    scl_reg <= SCL & scl_reg(1) when rising_edge(CLK);

    -- HIGH to LOW transition on the SDA line when SCL is high
    start_condition <= (not(sda_reg(1)) and sda_reg(0)) and scl_reg(0);

    -- LOW to HIGH transition on the SDA line when SCL is high 
    stop_condition  <= (not(sda_reg(0)) and sda_reg(1)) and scl_reg(0); 
    data_avaliable <= not(scl_reg(0)) and scl_reg(1);
    data_ready <= not(scl_reg(1)) and scl_reg(0);

    sda_dis_reg <= sda_dis_next when rising_edge(CLK);
    scl_dis_reg <= scl_dis_next when rising_edge(CLK);

    -- State register
    process
    begin
        wait until rising_edge(CLK);
        if SRST = '1' then
            current_state <= IDLE;
            last_state <= IDLE;
        else
            current_state <= next_state;   
            last_state <= last_next_state;
        end if;
    end process;

    byte_reg <= byte_next when rising_edge(CLK);
    data_reg <= data_next when rising_edge(CLK);
    data_count_reg <= data_count_next when rising_edge(CLK);
    mode_reg <= mode_next when rising_edge(CLK);

    process(current_state, sda_reg, sda_dis_reg, scl_dis_next, data_avaliable, start_condition, stop_condition, data_ready, data_count_reg, byte_reg, data_reg)
    begin
        next_state <= current_state;
        byte_next <= byte_reg;
        data_count_next <= data_count_reg;
        data_next <= data_reg;

        sda_dis_next <= sda_dis_reg;
        scl_dis_next <= scl_dis_reg;
        

        case current_state is
        when IDLE =>
            sda_dis_next <= '1';
            scl_dis_next <= '1';
            data_count_next <= 0;
            data_next <= (others => '0');
            byte_buffer <= (others => '0');
            
            if start_condition = '1' then
                next_state <= GET_DEVICE_ADDR;
                byte_next <= (others => '0');
            end if;
        when GET_DEVICE_ADDR =>
            if data_count_reg = 8 then
                data_count_next <= 0;
                if byte_reg(7 downto 1) = DEVICE_ADDR then
                    next_state <= SEND_ACK; 
                    mode_next <= byte_reg(0);
                    byte_next <= (others => '0');
                else
                    next_state <= IDLE;
                end if;
            else
                if data_avaliable = '1' then
                    byte_next <= byte_reg(6 downto 0) & sda_reg(0);
                    data_count_next <= data_count_reg + 1;
                end if;
            end if;
        when REGISTER_DATA =>
            data_next <= data_reg(WORD_LENGTH - 1 downto 0) & byte_reg;
            next_state <= SEND_ACK;
        when SEND_ACK =>
            if data_ready = '1' then
                next_state <= RELASE_LINE;
            end if;
        when RELASE_LINE => 
            sda_dis_next <= '0';
            if data_ready = '1' then
                next_state <= GET_DATA; 
            end if;
        when GET_DATA =>
            sda_dis_next <= '1';
           
            if data_count_reg = 8 then
                data_count_next <= 0;
                next_state <= REGISTER_DATA;            
            else
                if data_avaliable = '1' then
                    byte_next <= byte_reg(6 downto 0) & sda_reg(0);
                    data_count_next <= data_count_reg + 1; 
                end if;
            end if;
            
            if stop_condition = '1' then
                next_state <= IDLE;
            end if;
            
        when others =>
            next_state <= current_state;
            byte_next <= byte_reg;
            data_count_next <= data_count_reg;
        end case;

    end process;

    SDA <= 'Z' when sda_dis_reg = '1' else '0';
    SCL <= 'Z' when scl_dis_reg = '1' else '0';

    process
    begin
        wait until rising_edge(CLK);
        if stop_condition = '1' then
            DATA_OUT <= data_reg;
        end if;
    end process;

end rtl ; -- rtl