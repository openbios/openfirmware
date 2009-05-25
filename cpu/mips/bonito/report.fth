also forth definitions
[ifdef] debug-reset
: ?report  ( char -- )
   " isa-io-base d# 16 >> t0 lui" evaluate
   " begin   t0 h# 3fd t1 lbu   t1 h# 20 t1 andi  t1 0 <> until  nop" evaluate
   ( char )  " t1 set   t1 t0 h# 3f8 sb  " evaluate
;
[else]
: ?report  ( char -- )  drop  ;
[then]

: putbyte ( $a0 -- )
   " $a0 h# f $a0 andi  $a0 h# 30 $a0 addi" evaluate
   " begin   t0 h# 3fd t1 lbu   t1 h# 20 t1 andi  t1 0 <> until  nop" evaluate
   " $a0 t0 h# 3f8 sb  " evaluate
   " begin   t0 h# 3fd t1 lbu   t1 h# 20 t1 andi  t1 0 <> until  nop" evaluate
;
: dot ( a0 -- )
   " isa-io-base t0 set  $a0 t2 move" evaluate
   " t2 d# 28 $a0 srl  putbyte" evaluate
   " t2 d# 24 $a0 srl  putbyte" evaluate
   " t2 d# 20 $a0 srl  putbyte" evaluate
   " t2 d# 16 $a0 srl  putbyte" evaluate
   " t2 d# 12 $a0 srl  putbyte" evaluate
   " t2 d#  8 $a0 srl  putbyte" evaluate
   " t2 d#  4 $a0 srl  putbyte" evaluate
   " t2 0     $a0 srl  putbyte" evaluate
;
previous definitions

