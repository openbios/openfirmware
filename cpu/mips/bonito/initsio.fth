purpose: Initialize SuperI/O for startup messages
copyright: Copyright 2001 Firmworks  All Rights Reserved

transient
: sio-c!  ( data reg -- )  \ t0: isa-io-base
   ( reg ) " t1 set" evaluate
   " t1 t0 h# 15c sb" evaluate
   ( data ) " t1 set" evaluate
   " t1 t0 h# 15d sb" evaluate
;
resident

label init-sio  ( -- )   \ Destroys: t0 and t1
   isa-io-base d# 16 >> t0 lui

   h# 06 h# 07 sio-c!	\ Select com1
   h# 03 h# 60 sio-c!	\ At port 3f8
   h# f8 h# 61 sio-c!
   h# 01 h# 30 sio-c!	\ Turn it on

   ra jr  nop
end-code

