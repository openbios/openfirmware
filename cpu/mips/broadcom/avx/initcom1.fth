purpose: Initialize COM1 for startup messages
copyright: Copyright 2001 Firmworks  All Rights Reserved

transient
: isa-c!  ( data isa-adr -- )  \ t0: uart-base
   swap " t1 set" evaluate
   " t1 t0 rot sb" evaluate
;
resident

\ Initialize the 16552 COM1 serial port with 14.318MHz clock
label init-com1  ( -- )  \ Destroys t0 and t1

[ifndef] for-bcm93730
   uart-base t0 set
   h#  3 h# 3fc isa-c!       \ RTS and DTR on
   h# 80 h# 3fb isa-c!       \ Enable divisor latch
   h# 5d h# 3f8 isa-c!       \ Baud rate divisor low - 9600 baud
   h#  0 h# 3f9 isa-c!       \ Baud rate divisor high - 9600 baud
   h#  3 h# 3fb isa-c!       \ 8 bits, no parity
[then]

   ra jr  nop
end-code
