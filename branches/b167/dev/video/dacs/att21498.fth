\ See license at end of file
purpose: Initialize ATT RAMDAC

\ AT&T 21498 DAC initialization

\ This DAC does not have the indexed registers like the TI or IBM DACs,
\ though it does have indexed registers. Instead of direct access the
\ these regsisters, you have to run a magic sequence through it to get
\ to the indexed registers, init them, them go back to normal mode.

\ This init sequence will also startup the 505 DAC used by #9 in one
\ of their GXE boards. Not pretty, but otherwise harmless...

: init-att-dac ( -- )

   ( starting here is what the book says to do... )

   0 8 rs!		\ Reset backdoor state machine
   5 0 do 6 rs@ drop loop
   0 8 rs!		\ Reset backdoor again
   4 0 do 6 rs@ drop loop
   1 6 rs!		\ Enable indexing

   ( End of book init routine )

   0  8 rs!		\ Set index to 0
   ff 6 rs!		\ Set pixel mask to FF

   1  8 rs!		\ Set index to 1
   2  6 rs!		\ Set to 8 bit/pixel mode

   1  8 rs!		\ Now disable indexing
   6 rs@ drop
   0 6 rs!

\   2 cr0!   \ 8 bits/pixel (h#f0=00)  PowerOn (h#08 bit=0)  8not6 (2 bit)
   ff  rmr!           \ Pixel read mask register - unmask all pixel bits

   true to 6-bit-primaries?	\ Six bit DAC
;

: use-att-dac  ( -- )		\ Selects AT&T DAC init method
   ['] init-att-dac to init-dac
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
