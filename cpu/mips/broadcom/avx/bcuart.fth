purpose: Diagnostic (before console installation) access to serial port
copyright: Copyright 2001 Firmworks  All Rights Reserved

headerless

: uart@  ( reg# -- byte )  uart-base +  c@  ;	\ Read from a UART register
: uart!  ( byte reg# -- )  uart-base +  c!  ;	\ Write to a UART register

: baud  ( baud-rate -- )  drop  ;

: inituarts  ( -- )
;

: ukey?    ( -- flag )  3 uart@  4 and  0<>  ;  \ Test for rcv character
: uemit?   ( -- flag )  5 uart@  1 and  0<>  ;  \ Test for xmit ready
: ubreak?  ( -- flag )  false  ;
: clear-break   ( -- )  ;

: ukey   ( -- char )  begin  ukey?   until  2 uart@  ;  \ Receive a character
: uemit  ( char -- )  begin  uemit?  until  4 uart!  ;  \ Transmit a character
headers
