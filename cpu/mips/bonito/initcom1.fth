purpose: Initialize COM1 for startup messages
copyright: Copyright 2001 Firmworks  All Rights Reserved

transient
: isa-c!  ( data isa-adr -- )  \ t0: isa-io-base
   swap " t1 set" evaluate
   " t1 t0 rot sb" evaluate
;
resident

\ Initialize the 8250 (or compatible) COM1 serial port.
label init-com1  ( -- )  \ Destroys t0 and t1
   isa-io-base d# 16 >> t0 lui

  \ SIOA
   h#  3 h# 3fc isa-c!       \ RTS and DTR on
   h# 80 h# 3fb isa-c!       \ Enable divisor latch
   h#  c h# 3f8 isa-c!       \ Baud rate divisor low - 9600 baud
   h#  0 h# 3f9 isa-c!       \ Baud rate divisor high - 9600 baud
   h#  3 h# 3fb isa-c!       \ 8 bits, no parity

   ra jr  nop
end-code
