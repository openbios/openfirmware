purpose: ATH9K tx code
\ See license at end of file

headers
hex

\ tx data structures

0 constant data-qcu
8 constant cab-qcu
9 constant beacon-qcu

: qreg@   ( reg q -- val )  2 << + reg@  ;
: qreg!   ( val reg q -- )  2 << + reg!  ;
: qreg@!  ( val mask reg q -- )  2 << + reg@!  ;

struct
   /n field >rs-tries
   /n field >rs-rate
   /n field >rs-chain
   /n field >rs-duration
   /n field >rs-flags
   /n field >rs-idx
constant /rate-series

0 value rseries

create noack-series   1 , 1b , 3 , 0 , 0 ,  0 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,

create nondata-series a , 1b , 3 , 0 , 0 ,  0 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,

create data-series    4 ,  c , 3 , 0 , 0 ,  b ,
                      4 ,  8 , 3 , 0 , 1 ,  a ,
                      4 ,  d , 3 , 0 , 1 ,  9 ,
                      8 ,  9 , 3 , 0 , 1 ,  8 ,

create beacon-series  1 , 1b , 3 , 0 , 0 ,  0 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,
                      0 ,  0 , 0 , 0 , 0 , -1 ,

\ >rs-flags bit definitions
1 constant RS_RTS_CTS  \ program RTS/CTS rate and enable either RTS or CTS
2 constant RS_2040     \ 40MHz width
4 constant RS_HALFGI
8 constant RS_STBC

: 'series    ( adr idx -- adr[idx] )  /rate-series * +  ;
: rs-tries@  ( adr idx -- tries )  'series >rs-tries @  ;
: rs-rate@   ( adr idx -- rate )   'series >rs-rate  @  ;
: rs-dur@    ( adr idx -- dur )    'series >rs-duration @  ;
: rs-flags@  ( adr idx -- flags )  'series >rs-flags @  ;
: rs-chain@  ( adr idx -- chain )  'series >rs-chain @  ;
: rs-idx@    ( adr idx -- br-idx ) 'series >rs-idx   @  ;
: rs-tries!  ( tries adr idx -- )  'series >rs-tries !  ;
: rs-rate!   ( rate  adr idx -- )  'series >rs-rate  !  ;
: rs-dur!    ( dur   adr idx -- )  'series >rs-duration !  ;
: rs-flags!  ( flags adr idx -- )  'series >rs-flags !  ;
: rs-chain!  ( chain adr idx -- )  'series >rs-chain !  ;
: rs-idx!    ( br-idx adr idx -- ) 'series >rs-idx   !  ;

false value noack?
0 value fctl
0 value rtsctsrate
0 value data-rtsctsrate
0 value txd-flag
: idx>hw-val  ( idx -- hw-val )
   'legacy-rates preamble  if  >br-hw-val-short  else  >br-hw-val  then  @
;
: find-next-lower-rate  ( idx -- idx | -1 )
   dup -1 =  if  exit  then     ( -1 )
   1-  begin                    ( idx-1 )
      dup 'legacy-rates >br-bitrate @ is-common-rate?  if  exit  then
      1-
   0<  until                    ( -1 )
;
: do-one-rate  ( idx -- -1 )  drop -1  ;
: (setup-data-series)  ( -- )
   data-series /rate-series 4 * erase
   currate 4 0  do
      dup data-series i rs-idx!
      dup -1 <>  if
         dup idx>hw-val dup to data-rtsctsrate data-series i rs-rate!
         txchainmask data-series i rs-chain!
         i  if  1 data-series i rs-flags!  then
         i 3 =  if  8  else  4  then  data-series i rs-tries!
         find-next-lower-rate
noop
      then
   loop  drop
;
: setup-series  ( -- )
   curchan is-5GHz?  if  1  else  0  then
   dup noack-series   0 rs-idx!
   dup nondata-series 0 rs-idx!
   idx>hw-val dup noack-series   0 rs-rate!
                  nondata-series 0 rs-rate!
   txchainmask noack-series   0 rs-chain!
   txchainmask nondata-series 0 rs-chain!
   txchainmask beacon-series  0 rs-chain!
   (setup-data-series)
;
' setup-series to setup-data-series

: setup-rseries  ( framelen -- )
   \ Determine the series and the rtsctsrate to use
   noack?  if
      noack-series  dup 0 rs-rate@  0
   else
      fctl c and 8 =  if
         data-series  data-rtsctsrate  1
      else
         nondata-series  dup 0 rs-rate@  0
      then 
   then  to txd-flag  to rtsctsrate  to rseries

   \ Compute tx duration per valid entry in the series
   4 0  do                    ( framelen )
      rseries i rs-idx@ dup -1 =  if  drop leave  then
      'legacy-rates >br-bitrate @ d# 100 * over preamble ( framelen kbps framelen shortpre? )
      curchan is-2GHz?  if
         rseries i rs-idx@ 'legacy-rates >br-flags @ br-erp-g and
         if  WLAN_RC_PHY_OFDM  else  WLAN_RC_PHY_CCK  then
      else
         WLAN_RC_PHY_OFDM
      then
      compute-txtime                          ( framelen duration )
      rseries i rs-dur!                       ( framelen )
   loop  drop
;

struct
   4 field >tx-info
   4 field >tx-link
   4 field >tx-buf0
   4 field >tx-len0
   6 4 * +            \ buf1-3, len1-3
   4 field >tx-ctl10
   4 field >tx-ctl11
   4 field >tx-ctl12
   4 field >tx-ctl13
   4 field >tx-ctl14
   4 field >tx-ctl15
   4 field >tx-ctl16
   4 field >tx-ctl17
   4 field >tx-ctl18
   4 field >tx-ctl19
   4 field >tx-ctl20
   4 field >tx-ctl21
   4 field >tx-ctl22
   d# 128 round-up
constant /tx-desc
d# 2 constant #tx-descs
#tx-descs /tx-desc * constant /tx-descs
0 value beacon-desc   0 value beacon-desc-phy
0 value tx-desc       0 value tx-desc-phy
0 value /beacon

struct
   4 field >txs-info
   4 field >txs-s1
   4 field >txs-s2
   4 field >txs-s3
   4 field >txs-s4
   4 field >txs-s5
   4 field >txs-s6
   4 field >txs-s7
   4 field >txs-s8
constant /txs-desc
d# 64 constant #txs-desc
#txs-desc /txs-desc * constant /txs-ring
0 value txs-start   0 value txs-start-phy
0 value txs-end     0 value txs-end-phy
0 value txs-cur

/rx-buf /tx-desc + constant /tx-buf
0 value tx-beacon   0 value tx-beacon-phy

: txs>phy   ( virt -- phys )  txs-start - txs-start-phy +  ;
: txs>virt  ( phys -- virt )  txs-start-phy - txs-start +  ;

\ In the ideal world where the hardware works properly, txs-cur++ is ok.
: txs-cur++  ( -- )  
   txs-cur /txs-desc +  dup txs-end >=  if  drop txs-start  then
   to txs-cur
;
\ In the real world where the hardware does not always advance the status ring, we
\ have to sync our view with its view and clear memory between its pointer and ours.
: clear-txs  ( htxs -- )
   txs-cur over >  if         \ Ring wrapped around
      txs-cur txs-end over - erase
      txs-start tuck - erase
   else
      txs-cur tuck - erase
   then
;
: sync-txs-cur  ( -- )
   838 reg@  txs>virt dup clear-txs  to txs-cur
;

: free-txs-ring  ( -- )
   txs-start 0=  if  exit  then
   txs-start txs-start-phy /txs-ring dma-map-out
   txs-start /txs-ring dma-free
   0 to txs-start
;
: alloc-txs-ring  ( -- )
   txs-start  if  exit  then
   /txs-ring dma-alloc to txs-start
   txs-start /txs-ring erase
   txs-start /txs-ring false dma-map-in to txs-start-phy
   txs-start /txs-ring + to txs-end
   txs-start-phy /txs-ring + to txs-end-phy
;
: free-tx-desc  ( -- )
   tx-desc 0=  if  exit  then
   tx-desc tx-desc-phy /tx-descs dma-map-out
   tx-desc /tx-descs dma-free
   0 to tx-desc
;
: alloc-tx-desc  ( -- )
   tx-desc  if  exit  then
   /tx-descs dma-alloc to tx-desc
   tx-desc /tx-descs erase
   tx-desc /tx-descs false dma-map-in to tx-desc-phy
;
: free-beacon-buf  ( -- )
   tx-beacon 0=  if  exit  then
   tx-beacon tx-beacon-phy /tx-buf dma-map-out
   tx-beacon /tx-buf dma-free
   0 to tx-beacon
;
: alloc-beacon-buf  ( -- )
   tx-beacon  if  exit  then
   /tx-buf dma-alloc to tx-beacon
   tx-beacon /tx-buf erase
   tx-beacon /tx-buf false dma-map-in to tx-beacon-phy
;
: free-tx-bufs  ( -- )
   free-txs-ring
   free-tx-desc
   free-beacon-buf
;
: init-tx-bufs  ( -- )
   alloc-txs-ring
   txs-start to txs-cur
   alloc-tx-desc
   alloc-beacon-buf
   tx-desc     /tx-desc +  to beacon-desc
   tx-desc-phy /tx-desc +  to beacon-desc-phy
;

: set-txs-ring  ( -- )
   txs-start-phy 830 reg!
   txs-end-phy   834 reg!
;
' set-txs-ring to reset-txstatus-ring

: fill-txd-11n  ( keytype type key pwr flen desc -- )
   >r
   ( flen ) swap ( pwr ) d# 16 << or  3 pick ( keytype )  if  4000.0000 or  then
   100.0000 or r@ >tx-ctl11 le-l!
   \ type: 0-normal, 1-atim, 2-pspoll, 3-beacon, 4-probe resp, 5-chirp, 6-grp-poll
   ( key ) 7f and d# 13 <<  swap 
   ( type ) dup d# 20 <<  swap 3 =  if  100.0000 or  then  or
   r@ >tx-ctl12 le-l@ or  r@ >tx-ctl12 le-l!
   \ XXX If both us and AP supports LDPC, ctl17 |= 8000.0000
   \ keytype: 0-none, 1-wep, 2-aes, 3-tkip
   ( keytype ) d# 26 <<  r@ >tx-ctl17 le-l!
   2000.0000 r> >tx-ctl19 le-l!
;

: fill-txd-rate  ( ctsrate series flag desc -- )
   >r
   r@ >tx-ctl11 le-l@ 8040.0000 invert and
   swap ?dup  if  1 =  if  40.0000 or  else  80.0000 or  then  then
   r@ >tx-ctl11 le-l!

   dup  0 rs-tries@  d# 16 <<        ( ctrrate series tries )
   over 1 rs-tries@  d# 20 <<  or    ( ctrrate series tries' )
   over 2 rs-tries@  d# 24 <<  or    ( ctrrate series tries' )
   over 3 rs-tries@  d# 28 <<  or    ( ctrrate series tries' )
   r@ >tx-ctl13 le-l!                ( ctrrate series )

   dup  0 rs-rate@ 
   over 1 rs-rate@  d#  8 <<  or
   over 2 rs-rate@  d# 16 <<  or
   over 3 rs-rate@  d# 24 <<  or
   r@ >tx-ctl14 le-l!

   dup  0 rs-dur@  over   0 rs-flags@ 1 and  if  8000 or  then
   over 1 rs-dur@  2 pick 1 rs-flags@ 1 and  if  8000 or  then
   wljoin  r@ >tx-ctl15 le-l!
   dup  2 rs-dur@  over   2 rs-flags@ 1 and  if  8000 or  then
   over 3 rs-dur@  2 pick 3 rs-flags@ 1 and  if  8000 or  then
   wljoin  r@ >tx-ctl16 le-l!

   dup  0 rs-chain@  d#  2 <<        ( ctrrate series chain )
   over 1 rs-chain@  d#  7 << or     ( ctrrate series chain' )
   over 2 rs-chain@  d# 12 << or     ( ctrrate series chain' )
   over 3 rs-chain@  d# 17 << or     ( ctrrate series chain' )
   nip swap d# 20 << or  r> >tx-ctl18 le-l!
;
: chksum-tx-desc  ( desc -- chksum )
   0  d# 10 0  do  over i la+ le-l@ +  loop  nip
   lwsplit + ffff and
;
: fill-txd  ( noack? len padr qcu desc -- )
   >r  
   ( qcu )  8 << ATHEROS_ID d# 16 << or c017 or r@ >tx-info le-l!
   ( padr ) r@ >tx-buf0 le-l!
   ( len )  d# 16 << r@ >tx-len0 le-l!
   r@ chksum-tx-desc r@ >tx-ctl10 le-l!
   ( noack? ) 1 and d# 24 << r> >tx-ctl12 le-l!
;

: (xmit)  ( padr qcu -- )  sync-txs-cur 2 << 800 + reg!  ;

: key-type  ( -- keytype keyidx )
   wep-enabled?  if  1 wep-idx exit  then
   pkey-enabled?  if  pkey-tkip?  if  3  else  2  then  pair-idx  exit  then
   0 0 exit
;

: (xmit-data)  ( -- )  tx-desc-phy data-qcu (xmit)  ;
: xmit-data  ( adr len -- )
   2dup >r dup le-w@ to fctl                ( adr len adr )  ( R: len )
   4 + c@ 1 and dup to noack? -rot          ( noack? adr len )  ( R: len )
   tuck false dma-map-in                    ( noack? len padr )  ( R: len )
   data-qcu tx-desc fill-txd                ( )  ( R: len )
   r> 4 +  fctl 4000 and  if                \ Compute framelen, add ICV or MIC len
       wep-enabled?  if  4 +  then
       pkey-enabled?  if  pkey-tkip?  if  d# 12  else  8  then  +  then
   then  >r                                 ( )  ( R: flen )
   key-type 0 swap d# 63 r@ tx-desc fill-txd-11n  ( )  ( R: flen )
   r> setup-rseries                         ( )
   rtsctsrate rseries txd-flag tx-desc fill-txd-rate  ( )
   (xmit-data)
;

: (xmit-cab)  ( -- )  tx-desc-phy cab-qcu (xmit)  ;
: xmit-cab  ( adr len -- )
   dup >r true -rot                         ( noack? adr len )  ( R: len )
   tuck false dma-map-in                    ( noack? len padr )  ( R: len )
   cab-qcu tx-desc fill-txd                 ( )  ( R: len )
   0 0 0 d# 63 r> 4 + tx-desc fill-txd-11n  ( )
   0 beacon-series 0 tx-desc fill-txd-rate  ( )
   (xmit-cab)
;

\ XXX beacon-qcu fails for some reason.  It used to work.
: (xmit-beacon)  ( -- )  beacon-desc-phy beacon-qcu (xmit)  ;
: xmit-beacon  ( -- )
   true /beacon tx-beacon-phy beacon-qcu beacon-desc fill-txd
   0 3 0 d# 63 /beacon 4 + beacon-desc fill-txd-11n
   0 beacon-series 0 beacon-desc fill-txd-rate
   (xmit-beacon)
;

\ XXX hard code
: hard-code-beacon  ( -- )
   " dummy-ap" dup to /ssid ssid swap move
   broadcast-mac$ 2dup 0 h# 80 set-802.11n-mgr-hdr

   0 +xl        0 +xl  \ 8-byte timestamp
   d# 100         +xw  \ Beacon interval
   411            +xw  \ Capability mask

   0              +xb  \ element ID = SSID
   ssid$ dup      +xb  \ length  ( adr len )
   ( adr len )    +x$  \ SSID

   1              +xb  \ element ID = Supported rates
   8              +xb  \ length
   2     +xb  4     +xb  d# 11 +xb  d# 22 +xb  \ 1 2 5.5 11 Mb/sec
   d# 12 +xb  d# 18 +xb  d# 24 +xb  d# 36 +xb  \ 6 9 12 18 Mb/sec
   
   3              +xb  \ element ID = DS parameter set
   1              +xb  \ length
   d# 11          +xb  \ Channel number

   5              +xb  \ element ID = TIM (Traffic Indicator Map) parameter set
   4              +xb  \ length
   0              +xb  \ DTIM Count
   1              +xb  \ DTIM Period
   0              +xb  \ Bitmap control
   0              +xb  \ Bitmap

   7              +xb  \ element ID = country
   6              +xb  \ length
   " US "         +x$  \ Country string
   1              +xb  \ First channel
   d# 11          +xb  \ Number of channels
   12             +xb  \ Max transmit power

   d# 42          +xb  \ element ID = ERP info
   1              +xb  \ length
   0              +xb  \ no non-ERP stations, do not use protection, short or long preambles

   d# 50          +xb  \ element ID = Extended supported rates
   4              +xb  \ length
   d# 48 +xb  d# 72 +xb  d# 96 +xb  d# 108 +xb  \ 24 36 48 54 Mb/sec

   \ XXX HT capabilities, HT Information, Overlap BSS Scan, Extended Capabilities

   /x to /beacon
   packet-buf tx-beacon /beacon move
;

: reset-beacon-queue  ( -- )
   10.0000 1040 beacon-qcu qreg!  \ DCU IFS settings
    8.200a 1080 beacon-qcu qreg!  \ DCU retry limits
       8a0  9c0 beacon-qcu qreg!  \ QCU misc settings
   24.1002 1100 beacon-qcu qreg!  \ DCU misc settings (don't set beacon bit)
         0 10c0 beacon-qcu qreg!  \ DCU channel time settings
;
: reset-data-queue  ( -- )
   curchan is-b?  if  1f  else  f  then
   3f.fc00 or 1040 data-qcu qreg!  \ DCU IFS settings
    8.200a 1080 data-qcu qreg!     \ DCU retry limits
       800  9c0 data-qcu qreg!     \ QCU misc settings
      1002 1100 data-qcu qreg!     \ DCU misc settings (1102 to enable fragment wait)
         0 10c0 data-qcu qreg!     \ DCU channel time settings, no burst
;

: .txs  ( ok? -- )
   0=  if  txs-cur >txs-s3 @ .  then
;

d#  10 constant tx-retry-cnt
d#   1 constant tx-retry-delay-time
d# 100 constant tx-wait-delay
: tx-delay  ( -- )  tx-wait-delay us  ;
: tickle-txs  ( -- )  838 reg@ drop  ;    \ Supersition

\ Empirically, the chip does not update the status ring immediately.
\ Sometimes, a few frames later, it regurgitates the stale status descriptors.
\ To avoid waiting on the wrong location, we need to sync our pointer with
\ the hardware pointer.  We do that here and before transmit to catch as many
\ cases as possible.

\ Statistics:
\ (probe-ssid): i = 1-0x20+
\ authenticate : i = 1-0x20+, status = 1 or 102, response or no regardless of status

\ Theoretically, the code should really examine the status bits.
\ Empirically, I found them unreliable.  An ACKed packet may have the status 0x102.
\ And yet, I see the ACK and the response on the air.  So, ignore for now.

0 value isr-sp
0 value isr-s0
0 value isr-s1
0 value isr-s2
0 value isr-adr
0 value #tx-reset
0 value #tx-reseti
0 value #tx-reset-max
0 value #tx-retry
0 value debug-base
: #tx-reset++  ( -- )
   #tx-reset 1+ to #tx-reset
   #tx-reseti 1+ dup to #tx-reseti
   #tx-reset-max max to #tx-reset-max
;
: .tx-stat  ( -- )  ." #tx-reset = " #tx-reset .d cr  ;
: tx-timeout?  ( -- flag )  isr-s2 80.0000 and  ;

: init-isr-dump  ( -- )  debug-base to isr-adr  ;
: isr-dump!  ( n -- )
   debug-base  if
      isr-adr !  isr-adr na1+ to isr-adr
   else
      drop
   then
;
: isr-status@  ( -- )
   c0 reg@ to isr-sp
   c4 reg@ to isr-s0
   c8 reg@ to isr-s1
   d0 reg@ to isr-s2
   isr-s0 isr-dump!  isr-s1 isr-dump!  isr-s2 isr-dump!  64 reg@ isr-dump!
;
: tx-reset  ( -- )
   ascii r vemit  #tx-reset++
   a00 data-qcu qreg@ isr-dump! 840 reg@ isr-dump!
   reset
   a00 data-qcu qreg@ isr-dump! 840 reg@ isr-dump!
;
: tx-retry-delay  ( -- )
   queue-rx
   4 0 do -1 isr-dump! loop
   tx-retry-delay-time ms
   queue-rx
;

: (wait-tx-done)  ( -- done? )
   begin
      queue-rx    \ In case if the chip got stuck in txstat update, we won't miss rx
      tx-delay
      isr-status@
   isr-s1 ffff and ( TXERR ) isr-s0 ( TXOK ) or tx-timeout? or  until

   isr-s0
   debug?  if  txs-cur >txs-s3 le-l@ .  then
   sync-txs-cur
   queue-rx
;

: wait-tx-done  ( -- done? )
   0 to #tx-reseti
   init-isr-dump
   false tx-retry-cnt 1+ 0  do
      i to #tx-retry
      (wait-tx-done)  if  drop true leave  then
      ascii | vemit
      i tx-retry-cnt <  if
         isr-s1 ffff and 0=  if  tx-reset  then
         tx-retry-delay (xmit-data)  
      then
   loop
;

: send-beacon  ( -- done? )
   xmit-beacon (wait-tx-done)   \ No need to retry
;

: (reset-txqueue)  ( -- )
   reset-beacon-queue
   reset-data-queue
   1 a40 reg!            \ Chksum ptr & len
;
' (reset-txqueue) to reset-txqueue
' set-txs-ring to init-tx

: drain-txqueue  ( -- )
   \ Abort tx dma
   3ff 880 reg!                \ Disable tx queues
   104.0000 dup 8120 reg@!     \ Force quiet collision, Clear virtual more fragment
   40.0000 dup 8048 reg@!      \ Force RX_CLEAR high
   1000.0000 dup 10f0 reg@!    \ Ignore backoff

   d# 10 0  do
      d# 1000 0  do
         a00 j qreg@ 3 and 0=  if
            840 reg@ 1 j << and 0=  if  leave  then
         then
         5 us
      loop
   loop

   0 104.0000 8120 reg@!
   0 1000.0000 10f0 reg@!
   0 40.0000 8048 reg@!
   0 880 reg!
;
' drain-txqueue to stop-tx


\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
