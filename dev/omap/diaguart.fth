purpose: Diagnostic (before console installation) access to serial port
\ See license at end of file

\ For the OMAP's UART

d# 48000000 constant uart-clock-frequency

[ifndef] uart@

h# 49020000 value uart-base \ Virtual address of UART; set later
: uart@  ( reg# -- byte )  /l* uart-base + l@  ; \ Read from a UART register
: uart!  ( byte reg# -- )  /l* uart-base + l!  ; \ Write from a UART register

[then]

: baud  ( baud-rate -- )
   uart-clock-frequency d# 16 /  swap rounded-/    ( baud-rate-divisor )

   begin  5 uart@ h# 40 and  until		\ Wait until transmit done

   3 uart@  dup >r  h# 80 or  3 uart!		\ divisor latch access bit on
   dup h# ff and  0 uart!  8 >> 1 uart!		\ Write lsb and msb
   r> 3 uart!					\ Restore old state
;

: inituarts  ( -- )
\   3 3 uart!  		\ 8 bits, no parity
\   7 2 uart!		\ Clear and enable FIFOs
\   d# 38400 baud
\   d# 9600 baud
\    d# 115200 baud
;

: ukey?    ( -- flag )  5 uart@      1 and  0<>  ;  \ Test for rcv character
: uemit?   ( -- flag )  5 uart@  h# 20 and  0<>  ;  \ Test for xmit ready
: ubreak?  ( -- flag )  5 uart@  h# 10 and  0<>  ;  \ Test for received break
: clear-break   ( -- )  5 uart@  drop  ;	    \ Clear break indication

: ukey   ( -- char )  begin  ukey?   until  0 uart@  ;  \ Receive a character
: uemit  ( char -- )  begin  uemit?  until  0 uart!  ;  \ Transmit a character

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
