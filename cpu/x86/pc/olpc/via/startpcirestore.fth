\ Restore PCI config registers

8000.0000 6010 config-wl  \ BAR 0
8000.1000 6014 config-wl  \ BAR 1
8000.2000 6018 config-wl  \ BAR 2
     0016 6004 config-ww  \ Enables
       0a 603c config-wb  \ Interrupt line

   \ This is a workaround for an odd problem with the Via Vx855 chip.
   \ You have to tell it once to use 1.8 V, otherwise when you tell it
   \ it to use 3.3V, it will use 1.8 V instead!  You only have to
   \ do this 1.8V thing once after power-up to fix it until the
   \ next power cycle.  The "fix" survives resets; it takes a power
   \ cycle to break it again.

\ First 1.8V
0a # al mov  al 8000.0029 #) mov
             al 8000.1029 #) mov
             al 8000.2029 #) mov

\ Then 3.3V
0e # al mov  al 8000.0029 #) mov
             al 8000.1029 #) mov
             al 8000.2029 #) mov

\ Then power on
0f # al mov  al 8000.0029 #) mov
             al 8000.1029 #) mov
             al 8000.2029 #) mov

        f9 6099 config-wb  \ Two SD slots (correct for XP, wrong for Linux)
        d# 10000 wait-us   \ 10 ms delay to let power come on
        80 6088 config-wb  \ Set timeout clock 0:33Mhz
        00 6089 config-wb  \ Set max clock to 33Mhz

\       \ Enable System Management Mode, assuming that the in-memory data structures are already set up
\       21  383 config-wb  \ Enable A/Bxxxx range as memory instead of frame buffer (with fxxxx region R/O)
\       3b  386 config-wb  \ 01 bit enables compatible SMM
\       3b 8fe6 config-wb  \ 02 bit enables high SMM

\ acpi-io-base h# 2c + # dx mov  dx al in  h# 01 # al or  al dx out  \ Global SMI enable
\ acpi-io-base h# 2a + # dx mov  dx al in  h# 40 # al or  al dx out  \ Enable SMI on access to software SMI register
\ 0  acpi-io-base h# 2a +  port-wb   \ Trigger SMI; the "relocate the SMI base" handler is already installed

\       20  383 config-wb  \ Restore A/Bxxxx range to its normal frame buffer usage

\     \ Enable Real Mode gateway using System Management Mode
\      0030 885e config-ww  \ PCS3 I/O Port address (port 30)
\        f7 8864 config-wb  \ f* sets PCS3 decode length to 16 bytes (ports 30-3f)
\        03 8866 config-wb  \ 02 bit enables PCS3 decoding
\        64 88e5 config-wb  \ 04 bit enables PCS1

\ acpi-io-base h# 2b + # dx mov  dx al in  h# 80 # al or  al dx out  \ Enable SMI on GPIO Range 1 access
\ acpi-io-base h# 4 + # dx mov  dx al in  h# 01 # al or  al dx out  \ Enable SCI
