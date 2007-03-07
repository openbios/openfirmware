\ See license at end of file
purpose: Cyrix 5530 I/O Companion driver

hex headers

" 5530" device-name
" io-companion" device-type
" cx5530" model
" cx5530" encode-string  " compatible" property

: +int   ( $1 n -- $2 )   encode-int encode+  ;

\ Configuration space registers
my-address my-space        encode-phys          0 +int      0 +int

" reg" property

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( offset -- l )  my-space +  " config-l!" $call-parent  ;

: map-in   " map-in"  $call-parent  ;
: map-out  " map-out" $call-parent  ;

: map-regs  ( -- )  ;
: unmap-regs  ( -- )  ;

external

: flash-rw  ( -- )  52 my-b@  2 or  52 my-b!  ;

: flash-ro  ( -- )  52 my-b@  fd and  52 my-b!  ;

: warm-reset  ( -- )  44 my-b@  1 or  44 my-b!  ;

: open  ( -- ok? )  true  ;

: close  ( -- )  ;

headers

: init-5530  ( -- )
   81 40 my-b!				\ enable PCI intr, burst cycles
   10 41 my-b!				\ enable X-bus write buffers
   0c 42 my-b!				\ allow PCI xtrans without X-bus arbitration,
					\ enable HOLD_REQ#
   47 43 my-b!				\ enable SA[23:20], enable PCI retry,
					\ enable USB ports
   7b 50 my-b!				\ setup PIT control and ISA clock divisor
   44 51 my-b!				\ ISA I/O recovery
   98 52 my-b!				\ ??? GPIO, A20# and port 92 enable
					\ or 04 to enable 512k rom
   00 53 my-b!				\ disable SMI on A20# toggle
   00 58 my-b!				\ disable RTC and keyboard accesses
   03 5a my-b!				\ ??? positive decode of ports 60,64,70,71
					\ subtractive decode of COMs, floppy
   18 5b my-b!				\ subtractive decode of LPTs and ROM
					\ positive decode of IDE
					\ disable ports 62 and 66
   02b8 70 my-w!			\ GPCS IO base for I2C controller
   e1 72 my-b!				\ GPCS#
   18 80 my-b!				\ disable SMI stuff
					\ enable video and IRQ speedup
   00 81 my-b!				\ disable SMI idle timers
   00 82 my-b!				\ disable SMI traps
   00 83 my-b!				\ disable SMI stuff
   00 89 my-b!				\ disable timer reload
   00 8b my-b!				\ disable timer reload
   14 90 my-b!				\ ??? GPIO
   00 92 my-b!				\ ??? GPIO
   00 93 my-b!				\ SMI device control
   00 96 my-b!				\ disable supend modulation
   00 97 my-b!				\ SMI GPIO control
   00 bc my-b!				\ PLL delay

;

: route-interrupts  ( -- )
   a9 5c my-b!				\ INTA# and INTB# connect to IRQ
   fb 5d my-b!				\ INTC# and INTD# connect to IRQ

		\ Making IRQs 3 and 4 level-sensitive doesn't appear to work
   40 4d0 pc!				\ IRQ 6 level sensitive for I2C
\  8e 4d1 pc!				\ IRQs 9,10,11,15 level sensitive
    0 4d1 pc!	\ Defer setting PCI IRQs to level-sensitive until
		\ it is known which are used (pcinode.fth will do it)
;

: init  ( -- )
   make-properties
   0 my-l@ h# 1001078 =  if  init-5530 route-interrupts  then
;
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
