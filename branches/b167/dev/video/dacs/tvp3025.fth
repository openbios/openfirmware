\ See license at end of file
purpose: Initialize tvp3025 RAMDAC

hex
headerless

\ The tvp3025 DAC has 5 RS address lines. RS4 selects between 3025 mode (=0)
\ and Brooktree emulation (=1). However, if only using the 3025 mode, only
\ RS[2:0] are used which allows this DAC to be used with controllers that only
\ provide three RS address outputs. The calling method must define idac@ and idac!
\ properly so that indexed access will work properly

\ For the 3025, the basic register map is:
\	Address (RS=)	Port
\		0	Palette Address register (write)
\		1	Palette data register
\		2	Pixel mask register
\		3	Palette address register (read)
\		6	Indexed address register
\		7	Indexed data register

\ TI DAC Setup for tvp3025



: init-tvp3025-dac  ( -- )

   ff  rmr!		\ Pixel read mask register - unmask all pixel bits
   1c 1e idac!          \ (10) Use PSEL  (0c) 8 bits/color
   00 1d idac!          \ (not 20) disable sync on IOG, others at default values
    1 29 idac!          \ (not 8) SCLK not used
;

: use-tvp3025-dac  ( -- )
   ['] init-tvp3025-dac to init-dac
   6 to dac-index-adr
   7 to dac-data-adr
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
