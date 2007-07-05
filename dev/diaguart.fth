purpose: Diagnostic (before console installation) access to serial port
copyright: Copyright 1994 Firmworks  All Rights Reserved

headerless
d# 1843200 constant uart-clock-frequency

[ifndef] uart@
h# 3f8 value uart-base	\ Virtual address of UART; set later

: uart@  ( reg# -- byte )  uart-base +  pc@  ;	\ Read from a UART register
: uart!  ( byte reg# -- )  uart-base +  pc!  ;	\ Write to a UART register
[then]

: baud  ( baud-rate -- )
   uart-clock-frequency d# 16 /  swap rounded-/    ( baud-rate-divisor )

   begin  5 uart@ h# 40 and  until		\ Wait until transmit done

   3 uart@  dup >r  h# 80 or  3 uart!		\ divisor latch access bit on
   dup h# ff and  0 uart!  8 >> 1 uart!		\ Write lsb and msb
   r> 3 uart!					\ Restore old state
;

: inituarts  ( -- )
   3 3 uart!  		\ 8 bits, no parity
   7 2 uart!		\ Clear and enable FIFOs
\   d# 38400 baud
   d# 9600 baud
;

: ukey?    ( -- flag )  5 uart@      1 and  0<>  ;  \ Test for rcv character
: uemit?   ( -- flag )  5 uart@  h# 20 and  0<>  ;  \ Test for xmit ready
: ubreak?  ( -- flag )  5 uart@  h# 10 and  0<>  ;  \ Test for received break
: clear-break   ( -- )  5 uart@  drop  ;	    \ Clear break indication

: ukey   ( -- char )  begin  ukey?   until  0 uart@  ;  \ Receive a character
: uemit  ( char -- )  begin  uemit?  until  0 uart!  ;  \ Transmit a character
headers
