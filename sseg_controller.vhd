library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--SSEG_CONTROLLER_Inst:
--entity Work.sseg_controller 
--    generic map(
--        CLK_FREQUENCY_HZ    => CLK_FREQUENCY_HZ
--    )
--    port map(
--        CLK     => CLK,
--        DATA    => DATA,
--        CAT     => CAT,
--        AN      => AN
--    );


entity sseg_controller is
    generic(
        CLK_FREQUENCY_HZ    : integer := 50000000
    );
    port(
        CLK     : in std_logic;
        DATA    : in std_logic_vector(15 downto 0);
        CAT     : out std_logic_vector(7 downto 0);
        AN      : out std_logic_vector(3 downto 0)
    );
end sseg_controller;

architecture rtl of sseg_controller is

    constant UNDERSCORE : std_logic_vector(6 downto 0) := "1110111";  

    constant ZERO   : std_logic_vector(6 downto 0) := "1000000"; 
    constant ONE    : std_logic_vector(6 downto 0) := "1111001"; 
    constant TWO    : std_logic_vector(6 downto 0) := "0100100"; 
    constant THREE  : std_logic_vector(6 downto 0) := "0110000"; 
    constant FOUR   : std_logic_vector(6 downto 0) := "0011001"; 
    constant FIVE   : std_logic_vector(6 downto 0) := "0010010"; 
    constant SIX    : std_logic_vector(6 downto 0) := "0000010"; 
    constant SEVEN  : std_logic_vector(6 downto 0) := "1111000"; 
    constant EIGHT  : std_logic_vector(6 downto 0) := "0000000"; 
    constant NINE   : std_logic_vector(6 downto 0) := "0011000"; 
    constant A      : std_logic_vector(6 downto 0) := "0001000"; 
    constant B      : std_logic_vector(6 downto 0) := "0000011"; 
    constant C      : std_logic_vector(6 downto 0) := "1000110"; 
    constant D      : std_logic_vector(6 downto 0) := "0100001"; 
    constant E      : std_logic_vector(6 downto 0) := "0000110"; 
    constant F      : std_logic_vector(6 downto 0) := "0001110"; 

    constant REFRESH_COUNT_PERIOD : integer := (CLK_FREQUENCY_HZ * 8) / 1000; 
    constant DIGIT_PERIOD         : integer := (REFRESH_COUNT_PERIOD / 4);

    function log2(num: natural) return natural is
        variable val : integer := 0;
    begin
        for idx in 0 to 32 loop
            if (2**idx >= num) then
                val := idx;
                exit;
            end if;
        end loop;
        
        return val;        
    end function;

    -- frc: Free Running Counter
    signal frc_reg, frc_next : unsigned(log2(DIGIT_PERIOD) - 1 downto 0) := (others => '0');
    
    -- signal anodes : std_logic_vector(3 downto 0) := (others => '0');
    signal anodes : std_logic_vector(3 downto 0) := (others => '0');
    signal cathodes : std_logic_vector(6 downto 0) := (others => '0');
    
    signal sel    : std_logic_vector(1 downto 0) := (others => '0');
    signal din0, din1, din2, din3 : std_logic_vector(3 downto 0) := (others => '0');
    signal hex  : std_logic_vector(3 downto 0) := (others => '0');
    
begin
    
    frc_reg <= frc_reg + 1 when rising_edge(CLK);
    
    sel <= std_logic_vector(frc_reg(log2(DIGIT_PERIOD) - 1 downto log2(DIGIT_PERIOD) - 2));
    
    din0 <= DATA(3 downto 0);
    din1 <= DATA(7 downto 4);
    din2 <= DATA(11 downto 8);
    din3 <= DATA(15 downto 12);

ANODE_SELECTOR:  
    with sel select anodes <=
        "1110" when "00",
        "1101" when "01",
        "1011" when "10",
        "0111" when "11",
        "0110" when others;
        
INPUT_SELECTOR:
    with sel select hex <=
        din0 when "00",
        din1 when "01",
        din2 when "10",
        din3 when "11",
        din0 when others;
    
DECODER:
    with hex select cathodes <= 
        ZERO       when "0000",
        ONE        when "0001",
        TWO        when "0010",
        THREE      when "0011",
        FOUR       when "0100",
        FIVE       when "0101",
        SIX        when "0110",
        SEVEN      when "0111",
        EIGHT      when "1000",
        NINE       when "1001",
        A          when "1010",
        B          when "1011",
        C          when "1100",
        D          when "1101",
        E          when "1110",
        F          when "1111",
        UNDERSCORE when others;
        
    CAT <= '1' & cathodes;
    AN  <= anodes;
    

end rtl;
