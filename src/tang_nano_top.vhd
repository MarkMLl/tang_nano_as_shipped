-- *****************************************************************************
--
-- When I wrote this, I had not been able to find the source of the bitstream
-- which is preloaded onto the Sipeed Tang Nano "Little Bee" demo board (it
-- has since turned up, the link in Sipeed's documentation was broken). This
-- is distinguished by
--
--       * Cycling its LEDs in the sequence off-G-B-R by sequencing each low
--       * Cycle time is measured to be 4.19 seconds
--       * Low time for each LED is 1.048 seconds (4.192 / 4)
--       * Button B pressed (low) forces reset with all LEDs off (low)
--
-- This is an attempt to reconstitute the missing project. It borrows heavily
-- from https://github.com/andrsmllr/tang_nano_devbrd but chops out stuff
-- which isn't strictly necessary and attempts to indicate what imports (in
-- particular the clocks) actually are in terms of files.        MarkMLl
--
-- Verilog -> VHDL assisted by https://github.com/PacoReinaCampo/verilog2vhdl
--
-- *****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library gowin_osc;
use gowin_osc.Gowin_OSC_div96;
library gowin_rpll;
use gowin_rpll.Gowin_rPLL;

entity tang_nano_top is

  port(XTAL_IN : in std_logic;
    USER_BTN_A : in std_logic;
    USER_BTN_B : in std_logic;
    LED_R      : out std_logic := '1';
    LED_G      : out std_logic := '1';
    LED_B      : out std_logic := '1');

-- The LED signals could be conveniently redefined as a three-bit register.   
-- I've left them like this since that's how they're defined in the donor     
-- project, although I have corrected their order so that the sequence is the 
-- more conventional off-R-G-B, and used button A to reverse the sequence.    

end tang_nano_top;


architecture tang_nano_top_arch OF tang_nano_top is

  signal rstn    : std_logic;
  signal reverse : std_logic;

-- The physical clock is a 24MHz crystal module.

  signal clk_24M : std_logic;

-- *****************************************************************************
--
-- VHDL is an Ada (rather than ALGOL or Pascal) derivative and as such "types"
-- appear after "names". The "types" in the cases below are components which
-- have been pulled in from files which have to be explicitly added to the
-- project, in the current project these are Verilog (.v) files in the
-- gowin_osc and gowin_rpll directories together with the associated .ipc (IP
-- configuration?) and .mod files. The imported .v files themselves make use
-- of OSCH and rPLL modules, these appear to be declared (complete with
-- definitive parameter names) in IDE/bin/prim_syn.vhd plus an associated
-- primitive.xml presumably for the IDE; there are also related files in
-- IDE/simlib/gw1n etc. The lowest level of definition is buried in .so files
-- (presumably .dll libraries in the case of Windows) in IDE/ipcore/OSC and
-- IDE/ipcore/rPLL, but note that the doc directory for each module includes
-- a *help.html file which has a comprehensive description of each parameter
-- plus in some cases links to PDF files hosted by the device manufacturer.
--
-- *****************************************************************************

-- On-Chip Oscillator 2.5 MHz (240 MHz / 96). **********************************

-- The gowin_osc module specifies .FREQ_DIV = 96

  component Gowin_OSC_div96
    port (
      oscout : out std_logic
    );
  end component;

  signal clk_2M5 : std_logic;

-- On-Chip PLL 108 MHz (24MHz * 9). ********************************************

-- The gowin_rpll module specifies .FBDIV_SEL = 8 i.e. a 0..8 counter in the
-- feedback path hence a multiplier of 9.

  component Gowin_rPLL
    port (
      clkout : out std_logic;
      lock   : out std_logic;
      reset  : in std_logic;
      clkin  : in std_logic
    );
  end component;

  signal clk_108M  : std_logic;
  signal pll_lock  : std_logic;
  signal pll_reset : std_logic;

-- TODO : Gowin_rPLL Gowin_rPLL_inst() !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Hence there are three potential clocks:
--
--       * clk_24M  Physical 24MHz crystal module
--       * clk_108M 24MHz * 9 -> 108MHz
--       * clk_2M5  24MHz / 96 -> 2.5MHz
--
-- Uncomment one assign/parameter pair below to feed one of the clocks into a
-- 32-bit prescaler, in the general case the output of this might be taken
-- from the counter MSB so would not have an even mark/space ratio due to the
-- arbitrary preload value.

-- NOTE THAT in Verilog the prescaler clock and preload can be defined in the
-- same place, while in VHDL they're separate. In the latter case, look for
-- BOTH instances of this comment and ensure that what follows is consistent.

  constant preload : integer := 12_576_000;
--  constant preload : integer := 56_592_000;
--  constant preload : integer := 1_310_000;

  signal clk_prescale : std_logic;

  signal prescaler : integer range 0 to 16#7fff_ffff# := 0;
  signal clk_final : std_logic := '0';
  signal cnt       : integer range 0 to 3 := 0;

begin
  clk_24M <= XTAL_IN;
  rstn <= USER_BTN_B;
  reverse <= USER_BTN_A;

  Gowin_OSC_div96_inst : Gowin_OSC_div96
  port map (
    oscout => clk_2M5
  );

  pll_reset <= '0';

  Gowin_rPLL_inst : Gowin_rPLL
  port map (
    clkout => clk_108M,
    lock => pll_lock,
    reset => pll_reset,
    clkin => clk_24M
  );

-- NOTE THAT in Verilog the prescaler clock and preload can be defined in the
-- same place, while in VHDL they're separate. In the latter case, look for
-- BOTH instances of this comment and ensure that what follows is consistent.

  clk_prescale <= clk_24M;
--  clk_prescale <= clk_108M;
--  clk_prescale <= clk_2M5;
  
  prescale_counter : process (clk_prescale)
  begin
    if (rising_edge(clk_prescale)) then
      if (prescaler = 0) then
        prescaler <= preload;
        clk_final <= not clk_final; -- Ignore "Can't calculate relationship" warning here.
      else
        prescaler <= prescaler - 1;
      end if;
    end if;
  end process;

-- Two-bit counter for LED cycling. ********************************************

-- If the prescaler output were uneven this counter would smooth it.

  final_counter : process (clk_final, rstn)
  begin
    if (rstn = '0') then
      cnt <= 0;
    elsif (rising_edge(clk_final)) then
      if (reverse = '0') then
        cnt <= cnt - 1;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

-- One-of-four decoder for the final outputs. **********************************

  final_decoder : process (cnt)
  begin
    case (cnt) is
    when 0 =>
      LED_R <= '1';
      LED_G <= '1';
      LED_B <= '1';
    when 1 =>
      LED_R <= '0';
      LED_G <= '1';
      LED_B <= '1';
    when 2 =>
      LED_R <= '1';
      LED_G <= '0';
      LED_B <= '1';
    when 3 =>
      LED_R <= '1';
      LED_G <= '1';
      LED_B <= '0';
    end case;
  end process;

end tang_nano_top_arch;

