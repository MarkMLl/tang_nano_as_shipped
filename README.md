# tang_nano_as_shipped
A close approximation of the demo code on Sipeed Tang Nano boards as shipped.

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

The serial interface chip on the Tang Nano board is underpowered, and grossly inadequate when plugged directly into a modern computer. Assume that for reliable operation you need a USB v1 hub, although many other cheap hubs have such poor performance that they might be suitable.

I can't speak for Windows, but on Linux you need to add (or enable the lines in) two additional configuration files before plugging the board in:

<pre>/etc/modprobe.d/tang-nano.conf
# Blacklisted to allow the Gowin programmer to run.

blacklist ftdi_sio</pre>

and

<pre>/etc/udev/rules.d/51-tang-nano.rules
# Remember to  udevadm control --reload  and to blacklist/remove the ftdi_sio the module.

KERNEL=="ttyUSB*", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", GROUP="plugdev", MODE:="0660"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", ATTRS{product}=="Sipeed-Debug", GROUP="plugdev", MODE="0660"

# NOTE: This illicitly uses an FTDI identifier, so should be left disabled.</pre>

If you don't have those, don't reload the udev rules, or don't remove ftdi_sio after adding/enabling the files, the Gowin programmer will attempt to run rmmod to remove ftdi_sio... this will of course fail for an unprivileged user.

So to wrap up, I say again: TWO configuration files, RELOAD udev, and BLACKLIST ftdi_sio.
