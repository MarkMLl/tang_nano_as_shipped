-- *****************************************************************************
--                                                                            
-- When I wrote this, I had not been able to find the source of the bitstream 
-- which is preloaded onto the Sipeed Tang Nano "Little Bee" demo board (it   
-- has since turned up, the link in Sipeed's documentation was broken). This  
-- is notable for                                                             
--                                                                            
--       * Cycling its LEDs in the sequence off-G-B-R by sequencing each low  
--       * Cycle time is measured to be 4.19 seconds                          
--       * Low time for each LED is 1.048 seconds (4.192 / 4)                 
--       * Button B pressed (high) forces reset with all LEDs off (high)      
--                                                                            
-- This is an attempt to reconstitute the missing project. It borrows heavily 
-- from https://github.com/andrsmllr/tang_nano_devbrd but chops out stuff     
-- which isn't strictly necessary and attempts to indicate what imports (in   
-- particular the clocks) actually are in terms of files.        MarkMLl      
--                                                                            
-- *****************************************************************************

LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY gowin_osc;
USE gowin_osc.Gowin_OSC_div96;
LIBRARY gowin_rpll;
USE gowin_rpll.Gowin_rPLL;

ENTITY tang_nano_top IS

PORT(XTAL_IN    : IN STD_LOGIC;
     USER_BTN_A : IN STD_LOGIC;
     USER_BTN_B : IN STD_LOGIC;
     LED_R      : OUT STD_LOGIC;
     LED_G      : OUT STD_LOGIC;
     LED_B      : OUT STD_LOGIC);
END tang_nano_top;

-- The LED signals could be conveniently redefined as a three-bit register.   
-- I've left them like this since that's how they're defined in the donor     
-- project, although I have corrected their order so that the sequence is the 
-- more conventional off-R-G-B, and used button A to reverse the sequence.    

ARCHITECTURE tang_nano_top_arch OF tang_nano_top IS BEGIN

  PROCESS(XTAL_IN, USER_BTN_A, USER_BTN_B) BEGIN





-- REMAINDER TO BE DONE.

-- This is obviously incomplete, but serves as a convenient check that Gowin's
-- own synthesis software really does handle VHDL as well as Verilog.



  END PROCESS;
END tang_nano_top_arch;
