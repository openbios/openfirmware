purpose: Driver for the 16550-style UART on the Cobalt Raq2
\ See license at end of file

hex

h# 1c8003f8 kseg1 + constant uart

: uart!  ( val reg# -- )  uart +  rb!  ;
: uart@  ( reg# -- val )  uart +  rb@  ;

: line-stat@  ( -- n )  5 uart@  ;

\ Test for rcv character.
: ukey?    ( -- flag )  line-stat@  1 and  0<>  ;
: uemit?   ( -- flag )  line-stat@  h# 20 and  0<>  ;  \ Test for xmit ready

: ukey   ( -- char )  begin  ukey?   until  0 uart@  ;  \ Receive a character
: uemit  ( char -- )  begin  uemit?  until  0 uart!  ;  \ Transmit a character

: ubreak?  ( -- false )  ;
: clear-break   ( -- )  ;	       \ Clear break indication

: inituarts  ( -- )
[ifdef] notdef
   3 3 uart!  		\ 8 bits, no parity
   7 2 uart!		\ Clear and enable FIFOs
\  d#  9600 baud
\  d# 19200 baud
\  d# 38400 baud
   d# 115200 baud
[then]
;


\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
