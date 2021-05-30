/******************************************************************************/
/*                                                                            */
/* When I wrote this, I had not been able to find the source of the bitstream */
/* which is preloaded onto the Sipeed Tang Nano "Little Bee" demo board (it   */
/* has since turned up, the link in Sipeed's documentation was broken). This  */
/* is distinguished by                                                        */
/*                                                                            */
/*       * Cycling its LEDs in the sequence off-G-B-R by sequencing each low  */
/*       * Cycle time is measured to be 4.19 seconds                          */
/*       * Low time for each LED is 1.048 seconds (4.192 / 4)                 */
/*       * Button B pressed (high) forces reset with all LEDs off (high)      */
/*                                                                            */
/* This is an attempt to reconstitute the missing project. It borrows heavily */
/* from https://github.com/andrsmllr/tang_nano_devbrd but chops out stuff     */
/* which isn't strictly necessary and attempts to indicate what imports (in   */
/* particular the clocks) actually are in terms of files.        MarkMLl      */
/*                                                                            */
/* Verilog -> VHDL assisted by https://github.com/PacoReinaCampo/verilog2vhdl */
/*                                                                            */
/******************************************************************************/

`timescale 1 ns / 1 ps

module tang_nano_top
(
    input  wire       XTAL_IN,
    input  wire       USER_BTN_A,
    input  wire       USER_BTN_B,
    output reg        LED_R,
    output reg        LED_G,
    output reg        LED_B
);

/* The LED signals could be conveniently redefined as a three-bit register.   */
/* I've left them like this since that's how they're defined in the donor     */
/* project, although I have corrected their order so that the sequence is the */
/* more conventional off-R-G-B, and used button A to reverse the sequence.    */

initial begin
    LED_R      <= 1'b1;
    LED_G      <= 1'b1;
    LED_B      <= 1'b1;
end

assign rstn = USER_BTN_B;
assign reverse = USER_BTN_A;

/* The physical clock is a 24MHz crystal module.                              */

assign clk_24M = XTAL_IN;

/******************************************************************************/
/*                                                                            */
/* Verilog is an ALGOL-60 (rather than Pascal) derivative and as such "types" */
/* appear before "names". The "types" in the cases below are modules which    */
/* have been pulled in from files which have to be explicitly added to the    */
/* project, in the current project these are Verilog (.v) files in the        */
/* gowin_osc and gowin_rpll directories together with the associated .ipc (IP */
/* configuration?) and .mod files. The imported .v files themselves make use  */
/* of OSCH and rPLL modules, these appear to be declared (complete with       */
/* definitive parameter names) in IDE/bin/prim_syn.v plus an associated       */
/* primitive.xml presumably for the IDE; there are also related files in      */
/* IDE/simlib/gw1n etc. The lowest level of definition is buried in .so files */
/* (presumably .dll libraries in the case of Windows) in IDE/ipcore/OSC and   */
/* IDE/ipcore/rPLL, but note that the doc directory for each module includes  */
/* a *help.html file which has a comprehensive description of each parameter  */
/* plus in some cases links to PDF files hosted by the device manufacturer.   */
/*                                                                            */
/******************************************************************************/

/* On-Chip Oscillator 2.5 MHz (240 MHz / 96). *********************************/

/* The gowin_osc module specifies .FREQ_DIV = 96                              */

wire clk_2M5;
Gowin_OSC_div96 Gowin_OSC_div96_inst (.oscout(clk_2M5));

/* On-Chip PLL 108 MHz (24MHz * 9). *******************************************/

/* The gowin_rpll module specifies .FBDIV_SEL = 8 i.e. a 0..8 counter in the  */
/* feedback path hence a multiplier of 9.                                     */

wire clk_108M;
wire pll_lock;
wire pll_reset = 1'b0;

Gowin_rPLL Gowin_rPLL_inst(
    .clkout(clk_108M),
    .lock(pll_lock),
    .reset(pll_reset),
    .clkin(clk_24M));

/* Hence there are three potential clocks:                                    */
/*                                                                            */
/*       * clk_24M  Physical 24MHz crystal module                             */
/*       * clk_108M 24MHz * 9 -> 108MHz                                       */
/*       * clk_2M5  24MHz / 96 -> 2.5MHz                                      */
/*                                                                            */
/* Uncomment one assign/parameter pair below to feed one of the clocks into a */
/* 32-bit prescaler, in the general case the output of this might be taken    */
/* from the counter MSB so would not have an even mark/space ratio due to the */
/* arbitrary preload value.                                                   */

/* NOTE THAT in Verilog the prescaler clock and preload can be defined in the */
/* same place, while in VHDL they're separate. In the latter case, look for   */
/* BOTH instances of this comment and ensure that what follows is consistent. */

parameter preload =  32'd12_576_000;     assign clk_prescale = clk_24M;
// parameter preload = 32'd56_592_000;      assign clk_prescale = clk_108M;
// parameter preload = 32'd1_310_000;       assign clk_prescale = clk_2M5;         

reg [31:0] prescaler = 0;
reg [0:0] clk_final = 1'b0;

always @ (posedge clk_prescale)
begin
    if (prescaler == 32'd0) begin
        prescaler <= preload;
        clk_final <= ~clk_final; // Ignore "Can't calculate relationship" warning here.
    end else begin
        prescaler <= prescaler - 1;
    end
end

/* Two-bit counter for LED cycling. *******************************************/

/* If the prescaler output were uneven this counter would smooth it.          */

reg [1:0] cnt = 0;

always @ (posedge clk_final, negedge rstn)
begin
    if (rstn == 1'b0) begin
        cnt <= 2'd0;
    end else begin
      if ( reverse == 1'b0) begin
        cnt <= cnt - 2'b1;
      end else begin
        cnt <= cnt + 2'b1;
      end
    end
end

/* One-of-four decoder for the final outputs. *********************************/

always @ (*)
begin
    case(cnt)
        0: begin
               LED_R = 1'b1;
               LED_G = 1'b1;
               LED_B = 1'b1;
           end
        1: begin
               LED_R = 1'b0;
               LED_G = 1'b1;
               LED_B = 1'b1;
           end
        2: begin
               LED_R = 1'b1;
               LED_G = 1'b0;
               LED_B = 1'b1;
           end
        3: begin
               LED_R = 1'b1;
               LED_G = 1'b1;
               LED_B = 1'b0;
           end
    endcase
end

endmodule
