purpose: Driver for USB 2.0 Debug Device via EHCI Debug Port

\ USB PID values:
\ Token:      out     e1  in    69  sof   a5  setup 2d
\ Data:       data0   c3  data1 4b  data2 87  mdata 0f
\ Handshake:  ack     d2  nak   5a  stall 1e  nyet  96
\ Special:    pre/err 3c  split 78  ping  b4  reserved/unused f0

0 value ehci-cfg     \ Set to known value to skip search
0 value dbgp-offset  \ Set to known value to skip search
0 value dbgp-bar     \ Base address register that maps the DBGP

0 value ebase
0 value dbgp-base

\ Only look on the main PCI host bridge ...
: slot,fn>  ( slot fn -- cfg-base )  swap d# 11 lshift  swap 8 lshift or  ;
: find-ehci  ( -- )
   ehci-cfg  if  exit  then
   d# 32 0  do  \ Scan all slot
      i 0 slot,fn> config-l@  h# ffff.ffff <>  if
         8 0  do
            j i slot,fn> 8 + config-l@  ( class )
            h# ffffff00 and  h# 0c032000 =  if  ( )
               j i slot,fn> to ehci-cfg         ( )
               unloop unloop exit
            then
         loop
      then
   loop
   true abort" Can't find EHCI"
;
: find-dbgp-regs  ( -- )
   dbgp-offset  if  exit  then  \ Don't search if known
   ehci-cfg h# 34 + config-l@    ( capability-ptr )
   begin  dup  while             ( cap-offset )
      ehci-cfg +                 ( cfg-adr )
      dup config-b@ h# 0a =  if  ( cfg-adr )
         2+ config-w@            ( dbgp-ptr )
         dup h# 1fff and to dbgp-offset  ( )
         d# 13 rshift  7 and  1- /l* h# 10 +  to dbgp-bar
         exit
      then                       ( cfg-adr )
      1+ config-b@               ( cap-offset' )
   repeat                        ( cap-offset )
   true abort" Can't find debug port registers"
;

: find-dbgp-controller  ( -- )
   find-ehci
   find-dbgp-regs

   ehci-cfg 4 +  dup config-w@  2 or  swap config-w!  \ Enable memory access
   ebase 0=  if
      ehci-cfg dbgp-bar + config-l@ ( map-it ) to ebase     \ Get the BAR
   then
   dbgp-base 0=  if
      ebase dbgp-offset + to dbgp-base
   then
;

: pscbase  ( port# -- adr )  /l* h# 44 +  ebase c@ +  ebase +  ;
: psc@  ( port# -- 0 )  pscbase l@  ;  : psc!  ( val port# -- )  pscbase l!  ;
: rstport  ( port# -- )
   dup psc@ h# 100 or  4 invert and  over psc!
   d# 100 ms
   dup psc@ h# 100 invert and  swap psc!
   d# 10 ms
;

: +dbgp  ( reg# -- adr )  dbgp-offset +  ebase +  ;
: dbgp-l! dbgp-base + l!  ;  : dbgp-b! dbgp-base + c!  ;
: dbgp-l@ dbgp-base + l@  ;  : dbgp-b@ dbgp-base + c@  ;

: disable-dbgp  ( -- )       \ Disable the debug port
   dbgp-base  if
      0 0 dbgp-l!  d# 10 ms
   then
;

: grab-dbgp  ( -- )
   find-dbgp-controller
   
   disable-dbgp
   0 rstport                   \ Put the debug port in probe state
   h# 5001.0400 0 dbgp-l!      \ Enable the debug port
   d# 10 ms
   0 dbgp-l@ h# 1000.0000 and 0=  abort" Can't enable debug port"
   0 psc@ 4 invert and 0 psc!  \ Detach the normal EHCI host controller
;

: wait-done  ( -- finished? )
   begin  2 dbgp-b@  1 and  until
   1 2 dbgp-b!                     \ Turn off the done bit
   0 dbgp-b@ h# 40 and  if         \ Error
      0 dbgp-l@ 7 rshift 7 and
      case
         1 of  ." DBGP USB hardware error" cr  endof
         2 of  ." DBGP transacation error" cr  endof
      endcase
      abort
   then
;
: data-toggle  ( -- )  5 dbgp-b@  h# 88 xor  5 dbgp-b!  ;
: acked?  ( -- flag )
   6 dbgp-b@  ( received-PID )
   case
      \ Toggle DATA0 to DATA1 on an ACK
      h# d2 of  data-toggle  true  endof       \ ACK
      h# 96 of  data-toggle  true  endof       \ NYET (perhaps initiate slowdown)
      h# 1e of  true abort" DBGP stall"  endof \ STALL
      ( default )  false swap                  \ Probably NAK
   endcase
;

: dbgp-rcv  ( -- )
   h# 69 4 dbgp-b!  \ IN PID
   h# 20 0 dbgp-b!  \ Go, Read#
   wait-done
;

: dbgp-send  ( size -- )
   h# 30 or
   begin  dup 0 dbgp-b!  wait-done  acked?  until  ( control-val )
   drop
;

0 value dbgp-in
0 value dbgp-out

: set-dev  ( device -- )  h# 11 dbgp-b!  ;
: set-endpoint  ( ep -- )  h# 10 dbgp-b!  ;
: control-out  ( data1 data0 -- )
   0 set-endpoint        \ Control endpoint
   8 dbgp-l!             \ wValue.bRequest.bRequestType
   h# c dbgp-l!          \ wSize.wIndex
   h# c3.2d 4 dbgp-l!    \ DATA0.SETUP
   8 dbgp-send           \ Setup + Data
   dbgp-rcv              \ Status 
;
: debug-mode  ( -- )
   0 h# 0006.03.00 control-out   \ size0.index0 DEBUG_MODE(6).SET_FEATURE(3).REQUESTTYPE_OUT(0)
;
: force-dbgp-adr  ( -- error? )
   0 h# 007f.05.00 control-out   \ size0.index0 NewAddress.SET_ADDRESS(5).REQUESTTYPE_OUT(0)
   h# 7f set-dev
;

: get-dbgp-desc  ( -- )
   0 set-endpoint                \ Control endpoint
   h# 0a00.06.80 8 dbgp-l!       \ USB_DT_DEBUG<<8(a00).GET_DESCRIPTOR(6).REQUESTTYPE_IN(80)
   h# 0004.0000  h# c dbgp-l!    \ SIZE(4).Index(0)
   h#      c3.2d 4 dbgp-l!       \ DATA0.SETUP   
   8 dbgp-send                   \ Setup
   dbgp-rcv                      \ In
   h#      4b.e1 4 dbgp-l!       \ Status (DATA1.OUT)
   0 dbgp-send                   \ Setup
;
: find-dbgp-device  ( -- )
   d# 80 0 do
      i set-dev
      ['] get-dbgp-desc catch  0=  if
         8 dbgp-l@ lbsplit to dbgp-out  to dbgp-in  2drop
         unloop exit
      then
   loop
   true abort" No Debug Device"
;

true value dbgp-off?
: uemit  ( char -- )
   dbgp-off?  if  drop exit  then
   dbgp-out set-endpoint   \ Bulk out endpoint
   8 dbgp-l!               \ char
   h# e1 4 dbgp-b!         \ OUT
   1 dbgp-send
;

0 value nkeys
0 value k0
0 value k1
: pullkey  ( -- char )
   nkeys 1- 0 max  to nkeys
   k0 lbsplit  k1 lbsplit  0 bljoin to k1  bljoin to k0  ( char )
;

: ukey?  ( -- flag )
   dbgp-off?  if  false exit  then
   nkeys  if  true exit  then
   dbgp-in set-endpoint  \ Bulk in endpoint
   dbgp-rcv
   6 dbgp-b@  ( received-PID )
   dup h# c3 =  swap h# 4b =  or  if
      0 dbgp-b@  to nkeys
      8 dbgp-l@ to k0
      h# c dbgp-l@ to k1
      nkeys 0<>
   else
      false
   then
;
: ukey  ( -- char )
   dbgp-off?  if  0 exit  then
   nkeys  if  pullkey  exit  then
   begin  ukey?  until
   pullkey
;

: dbgp-io  ( -- )
   ['] uemit is (emit
   ['] ukey  is (key
   ['] ukey? is key?
   ['] default-type is (type
   ['] emit1 is emit
   ['] type1 is type
;

: init-dbgp  ( -- )
   grab-dbgp         \ Attach the debug host controller
   find-dbgp-device
   force-dbgp-adr
   debug-mode
;
: dbgp-off  ( -- )
   true to dbgp-off?  \ Make the uemit routines do nothing
   disable-dbgp
;

: inituarts
   ['] init-dbgp catch to dbgp-off?
   \ Leave the EHCI debug port off if a Debug Device wasn't attached
   dbgp-off?  dbgp-base 0<>  and  if  disable-dbgp   then
;

: start-dbgp  ( -- )
   init-dbgp
   dbgp-io
;

[ifdef] notdef
Sending bytes via debug port, assuming it's already inited.

   ( char in al ) 
   dbgp_adr #  bp  mov
   al  8 [bp]  mov   \ char
   OUT_ENDP #  h# 10 [bp]  byte mov  \ endpoint
   h# e1 #  4 [bp]  byte mov       \ OUT token
   begin
      h# 31 #  0 [bp]  byte mov    \ Go, write, 1 char
      begin  1 #  2 [bp]  byte tst  0<> until  \ Wait for DONE
      1 #  2 [bp]  byte  mov       \ Clear done bit
      h# 40 #  0 [bp]  byte tst    \ Check error bit
      0<>  if                      \ Error
         al al cmp                 \ Force loop exit
      else                         \ Not error
         6 [bp]  al  mov           \ Get PID
         h# d2 #  al  cmp          \ Compare to ACK
         0<>  if                   \ Not ACK
            h# 96 #  al  cmp       \ Compare to NYET
         then
      then                         \ Z will be set for exit
   0= until

Receiving bytes via debug port, assuming it's already inited.
  
   dbgp_adr #  bp  mov
   IN_ENDP #  h# 10 [bp]  byte mov  \ endpoint
   h# 69 #  4 [bp]  byte mov        \ IN token
   h# 20 #  0 [bp]  byte mov        \ Go, read
   begin  1 #  2 [bp]  byte tst  0<> until  \ Wait for DONE
   1 #  2 [bp]  byte  mov           \ Clear done bit
   h# 40 #  0 [bp]  byte tst        \ Check error bit
   0<>  if                          \ Error
      clrc
   else
      6 [bp]  al  mov               \ Get PID
      h# c3 #  al  cmp   0=  if     \ Compare to DATA0
         8 [bp]  al mov
         setc
      else
         h# c3 #  al  cmp   0=  if  \ Compare to DATA1
            8 [bp]  al mov
            setc
         else
            clrc
         then
      then
   then
   \ Carry set if got a char, and char in al

[then]
