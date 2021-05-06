# tang_nano_as_shipped
A close approximation of the demo code on Sipeed Tang Nano bboards as shipped.

<pre>/* I've not been able to find the source of the bitstream which is preloaded  */
/* onto the Sipeed Tang Nano "Little Bee" demo board. This is notable for     */
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

/* The LED signals could be conveniently redefined as a three-bit register.   */
/* I've left them like this since that's how they're defined in the donor     */
/* project, although I have corrected their order so that the sequence is the */
/* more conventional off-R-G-B, and used button A to reverse the sequence.    */</pre>
