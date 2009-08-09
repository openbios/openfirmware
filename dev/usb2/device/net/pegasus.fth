purpose: Pegasus II USB ethernet driver
\ See license at end of file

headers

1 value phyid

h# f0 constant GET_REG
h# f1 constant SET_REG

\ Select register definitions
: ec0        0   ;
: ec1        1   ;
: ec2        2   ;
: gpio10c h# 7e  ;
: gpio32c h# 7f  ;
: phya    h# 25  ;
: phydl   h# 26  ;
: phydh   h# 27  ;
: phyac   h# 28  ;

: error?  ( flag -- )  ?dup if  ." usb error: " . cr  abort  then  ;

\ Read system registers

: pg-control-get ( adr len idx value cmd -- )
   DR_IN DR_VENDOR or DR_DEVICE or swap   control-get   error? drop
;

: pg-read-regs-into-inbuf ( len index -- )
   inbuf -rot ( adr len index ) 0 GET_REG pg-control-get ( actual )
;

\ Read registers into memory array
: pg-read-regs ( adr len index -- )
   over >r                 ( adr len index  r: len )
   pg-read-regs-into-inbuf ( adr  r: len )
   inbuf swap r>           ( inbuf adr len )
   move
;

\ Read `len'-byte integer value
: pg-read-reg  ( index len -- u )  0 inbuf !  swap pg-read-regs-into-inbuf  inbuf @  ;
: pg-reg-c@    ( index -- u )      1 pg-read-reg  ;
: pg-reg-w@    ( index -- u )      2 pg-read-reg  ;
: pg-reg-@     ( index -- u )      4 pg-read-reg  ;

\ Write system registers

: pg-control-set ( adr len idx value cmd -- )
   DR_OUT DR_VENDOR or DR_DEVICE or swap   control-set   error?
;

: pg-set-regs  ( adr len index -- )  2 pick @ SET_REG pg-control-set  ;

: pg-write-reg ( u index len -- )
   rot outbuf !      ( index len )
   outbuf swap  rot  ( adr len index )
   pg-set-regs
;

: pg-reg-c! ( u index -- ) 1 pg-write-reg ;
: pg-reg-w! ( u index -- ) 2 pg-write-reg ;
: pg-reg-!  ( u index -- ) 4 pg-write-reg ;

\ Read and write PHY registers. These are read indirectly through
\ system registers.

: pg-mii-start-read  ( index -- )
   h# 40 or  d# 24 lshift  phyid or
   phya pg-reg-!
;

: pg-mii-start-write  ( u index -- )
   d# 24 lshift  swap d# 8 lshift or  phyid h# 10 or
   phyac pg-reg-!
;

: pg-mii-done?      ( -- )  phyac pg-reg-c@  h# 80 and 0<>  ;
: pg-mii-wait-done  ( -- )  begin  pg-mii-done?  until  ;

: pg-mii-execute-read   ( index -- u )  pg-mii-start-read   pg-mii-wait-done  ;
: pg-mii-execute-write  ( u index -- )  pg-mii-start-write  pg-mii-wait-done  ;

: pg-mii-data@  ( -- )  phydl pg-reg-w@  ;

: pg-mii@  ( index -- u )  pg-mii-execute-read  pg-mii-data@  ;

: pg-mii!  ( u index -- )  pg-mii-execute-write  ;

\ initialization & interface

: pg-get-mac-address ( -- adr len )
   mac-adr /mac-adr h# 10 pg-read-regs
   mac-adr /mac-adr
;

: pg-link-up?  ( -- flag )  1 pg-mii@  4 and 0<>  ;

: pg-reset-mac   ( -- )  8 ec1 pg-reg-c!  ;
: pg-mac-reset?  ( -- )  ec1 pg-reg-c@  8 and  0=  ;

: pg-init-mac ( -- )
   pg-reset-mac  begin  pg-mac-reset?  until
   h# 26 gpio32c pg-reg-c!
   h# 26 gpio10c pg-reg-c!
   h# 24 gpio10c pg-reg-c!
   h# 26 gpio10c pg-reg-c!
;

: setup-pegasus-II ( -- )
   0 h# 1d pg-reg-c!          \ reserved
   2 h# 7b pg-reg-c!          \ internal phy control - enable phy
;

: pg-sync-link-status  ( -- )
   \ Delayed loop until link-up is detected.
   5 0 do  pg-link-up? if  unloop exit  then  d# 1000 ms  loop
;

: pg-init-nic ( -- )
   true to length-header?
   init-buf
   1 set-config  error?
   pg-get-mac-address  2drop
   pg-init-mac
   setup-pegasus-II
   pg-sync-link-status
;

: pg-start-nic ( -- )
   \ force 100Mbps full-duplex
   h# 0130c9 ec0 3 pg-write-reg
;

: pg-stop-nic ( -- )
   0 ec0 2 pg-write-reg
;

\ Process the length header that's inlined after the frame
: pg-unwrap-msg  ( adr len -- adr len  )
   over + 4 -           ( len-adr )
   le-w@  h# fff and    ( len )
   8 -                  ( len )
;

: init-pegasus  ( -- )
   ['] pg-init-nic  to init-nic
   ['] pg-link-up?  to link-up?
   ['] pg-start-nic to start-nic
   ['] pg-stop-nic  to stop-nic
   ['] pg-get-mac-address to get-mac-address
   ['] pg-unwrap-msg to unwrap-msg
;

: init  ( -- )  init  vid pid pegasus?  if  init-pegasus  then  ;

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie <luke@bup.co.nz>
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
