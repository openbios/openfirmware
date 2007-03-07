\ See license at end of file
purpose: Initialize Cyrix 5520 I/O Companion

hex
headers

: init-5520  ( -- )
   81 40 my-b!				\ enable PCI intr, burst cycles
   10 41 my-b!				\ enable PERR#
   09 42 my-b!				\ enable video and clock mapping
   01 43 my-b!				\ enable USB ports
   44 51 my-b!				\ ISA I/O recovery
   98 52 my-b!				\ ??? GPIO, A20# and port 92 enable
   03 53 my-b!				\ ??? enable SMI on A20# toggle
					\ doc says it has to be 3.  But SMI?
   06 54 my-b!				\ codec=ad1819
   00 58 my-b!				\ disable RTC and keyboard accesses
   03 5a my-b!				\ positive decode of ports 60,64,70,71
					\ subtractive decode of ports COMs, floppy
   18 5b my-b!				\ subtractive decode of ROM, LPTs
					\ positive decode of IDE
					\ disable ports 62 and 66
   9a 5c my-b!				\ INTA# and INTB# connect to IRQ
   bf 5d my-b!				\ INTC# and INTD# connect to IRQ
   01 5e my-b!				\ enable audio
   43 60 my-b!				\ enable ide and bus mastering
   99 62 my-b!				\ pri ide 8-bit timing
   99 63 my-b!				\ sec ide 8-bit timing
   02 64 my-b!				\ pri ide ch 0 16-bit read timing
   d5 65 my-b!				\ pri ide ch 1 16-bit read timing
   02 66 my-b!				\ pri ide ch 0 16-bit write timing
   d5 67 my-b!				\ pri ide ch 1 16-bit write timing
   d5 68 my-b!				\ sec ide ch 0 16-bit read timing
   01 69 my-b!				\ sec ide ch 1 16-bit read timing
   d5 6a my-b!				\ sec ide ch 0 16-bit write timing
   02 6b my-b!				\ sec ide ch 1 16-bit write timing
   0200 70 my-w!			\ ??? GPCS IO base
   81 72 my-b!				\ ??? GPCS#
   00 80 my-b!				\ disable SMI stuff
   00 81 my-b!				\ disable SMI idle timers
   00 82 my-b!				\ disable SMI traps
   00 83 my-b!				\ disable SMI stuff
   00 89 my-b!				\ disable timer 1 reload
   00 90 my-b!				\ ??? GPIO
   00 91 my-b!				\ ??? GPIO
   00 92 my-b!				\ ??? GPIO
   00 93 my-b!				\ SMI device control
   00 97 my-b!				\ SMI GPIO control
   00 aa my-b!				\ GPIO
   00 ab my-b!				\ GPIO

   map-regs

   02eb.7fff e00 video-l!		\ audio cfg reg 1
   ff2a.492c e04 video-l!		\ audio cfg reg 2
   04e1.32d2 e08 video-l!		\ clk_32k cfg reg 1
   f7b7.b292 e0c video-l!		\ clk_32k cfg reg 2
   30e2.c57f e10 video-l!		\ s clock pll control reg
[ifdef] 640x480
   3796.32ff
[else]
   2758.5d7f
[then]
   dup 4000.0000 or e14 video-l!	\ reset dot clock
             e14 video-l!		\ set dot clock
   0000.69cd e18 video-l!		\ control 0
   000a.381a e1c video-l!		\ control 1
   23d8.ddff e24 video-l!		\ usb pll control reg

   unmap-regs
;

\ init-5520
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
