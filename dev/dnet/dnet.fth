purpose: Driver for DAVE Ethernet FPGA (Lattice IP)
\ See license at end of file

" ethernet" name
" Lattice,tri-speed-eth" encode-string " compatible" property
" network" device-type

h#   100000 constant /irq-regs \ Total size of adapter’s register bank
h# 10000000 constant /mac-regs \ Total size of adapter’s register bank

\ Define "reg" property
\ PCI Configuration Space
my-address my-space encode-phys 0 encode-int encode+ 0 encode-int encode+

\ Memory Space Base Address Register 10
my-address my-space h# 0200.0010 or encode-phys  encode+
0 encode-int encode+  /irq-regs encode-int encode+

\ Memory Space Base Address Register 14
my-address my-space h# 0200.0014 or encode-phys  encode+
0 encode-int encode+  /mac-regs encode-int encode+

\ \ PCI Expansion ROM - not present
\ my-address my-space h# 200.0030 or encode-phys encode+
\ 0 encode-int encode+ h# 10.0000 encode-int encode+

" reg" property

0 instance value chip
: map-regs  ( -- )
   h# 0040.0000 0  my-space h# 14 +  h# 0200.0000 or  h# 1000
   " map-in" $call-parent to chip
   2 my-space 4 + " config-w!" $call-parent
;
: unmap-regs  ( -- )
   0 my-space 4 + " config-w!" $call-parent
   chip h# 1000 " map-out" $call-parent
;
: reg@  ( offset -- l )  chip + rl@  ;
: reg!  ( l offset -- )  chip + rl!  ;

: rx-cmd-fifo@   ( -- l )  0 reg@  ;
: rx-data-fifo@  ( -- l )  4 reg@  ;
: tx-cmd-fifo!   ( l -- )  8 reg!  ;
: tx-data-fifo!  ( l -- )  h# c reg!  ;

: capa@       ( -- l )  h# 100 reg@  ;

1 constant mdio
2 constant irq
4 constant gigabit
8 constant dma
h# 10 constant rmii

: intr-src@   ( -- l )  h# 104 reg@  ;
: intr-src!   ( l -- )  h# 104 reg!  ;
: intr-enb@   ( -- l )  h# 108 reg@  ;
: intr-enb!   ( l -- )  h# 108 reg!  ;

4 constant tx-dat-ae
h# 10 constant tx-fifo-f
h# 100 constant rx-cmd-af
h# 200 constant rx-cmd-ff
h# 400 constant rx-data-af
h# 1000 constant tx-smry
h# 2000 constant rx-smry
h# 4000 constant glob-enb
h# 8000 constant phy

: rx-status@  ( -- l )  h# 10c reg@  ;
: rx-status!  ( l -- )  h# 10c reg!  ;

1 constant stat-rx-cmd-af
2 constant stat-rx-cmd-ff
4 constant stat-rx-data-f

: tx-status@  ( -- l )  h# 110 reg@  ;
: tx-status!  ( l -- )  h# 110 reg!  ;

4 constant stat-tx-data-ae
h# 10 constant stat-tx-fifo-f

: rx-fifo-th@  ( -- l )  h# 11c reg@  ;
: rx-fifo-th!  ( l -- )  h# 11c reg!  ;
: tx-fifo-th@  ( -- l )  h# 120 reg@  ;
: tx-fifo-th!  ( l -- )  h# 120 reg!  ;
: sys-ctl@     ( -- l )  h# 124 reg@  ;
: sys-ctl!     ( l -- )  h# 124 reg!  ;

8 constant rx-flush
h# 10 constant tx-flush

defer us-delay
: set-delay  ( -- )
   " us" $find  0=  if  2drop ['] ms  then  to us-delay
;

: be-w@  ( adr -- w )  dup 1+ c@ swap c@ bwjoin ;
: be-w!  ( w adr -- w )  >r wbsplit r@ c!  r> 1+ c!  ;

: pause-tmr@   ( -- l )  h# 128 reg@  ;
: pause-tmr!   ( l -- )  h# 128 reg!  ;
: rx-fifo-wcnt@   ( -- l )  h# 12c reg@  ;
: tx-fifo-wcnt@   ( -- l )  h# 130 reg@  ;

: tmac@  ( reg# -- w )  h# 204 reg!  1 us-delay  h# 200 reg@  ;
: tmac!  ( w reg# -- )  swap h# 200 reg!  h# 8000.0000 or  h# 204 reg!  1 us-delay  ;

: mode@  ( -- w )  0 tmac@  ;
: mode!  ( w -- )  0 tmac!  ;

\ Mode register bits
1 constant gbit-en
2 constant fc-en
4 constant rx-en
8 constant tx-en

: tx-rx-ctl@  ( -- w )  2 tmac@  ;
: tx-rx-ctl!  ( w -- )  2 tmac!  ;

\ tx-rx-ctl bits

     1 constant prms
     2 constant discard-fcs
     4 constant tx-dis-fcs
     8 constant receive-pause
h#  10 constant receive-mltcst
h#  20 constant hden
h#  40 constant drop-control
h#  80 constant receive-brdcst
h# 100 constant receive-short

: max-pkt-size@  ( -- w )  4 tmac@  ;
: max-pkt-size!  ( w -- )  4 tmac!  ;

: ipg-val@  ( -- w )  8 tmac@  ;
: ipg-val!  ( w -- )  8 tmac!  ;

: mac-addr@  ( index -- w )  /w* h# a + tmac@  ;
: mac-addr!  ( n index -- )  /w* h# a + tmac!  ;

: set-mac-addr  ( adr len -- )
   drop
   dup be-w@  0 mac-addr!  wa1+
   dup be-w@  1 mac-addr!  wa1+
       be-w@  2 mac-addr!
;
: get-mac-addr  ( adr 6 -- )
   drop
   0 mac-addr@ over be-w!  wa1+
   1 mac-addr@ over be-w!  wa1+
   2 mac-addr@ swap be-w!
;

: tx-rx-stat@  ( -- w )  h# 12 tmac@  ;
: tx-rx-stat!  ( w -- )  h# 12 tmac!  ;

\ tx-rx-stat bits

     1 constant tx-idle
     2 constant pause-frame
     4 constant crc-error
     8 constant error-frame
h#  10 constant long-frame
h#  20 constant short-frame
h#  40 constant ipg-shrink
h#  80 constant multcst-frame
h# 100 constant brdcst-frame
h# 200 constant tagged-frame
h# 400 constant rx-idle

: gmii-mng-ctl@  ( -- w )  h# 14 tmac@  ;
: gmii-mng-ctl!  ( w -- )  h# 14 tmac!  ;

\ gmii-mng-ctl bits

h# 2000 constant rw-phyreg
h# 4000 constant cmd-fin

: gmii-mng-dat@  ( -- w )  h# 16 tmac@  ;
: gmii-mng-dat!  ( w -- )  h# 16 tmac!  ;

: gmii-wait  ( -- )
   d# 100 0  do
      gmii-mng-ctl@ cmd-fin and  if  unloop exit  then
      d# 10 us-delay
   loop
   ." Lattice Ethernet - GMII_MNG_CTL stuck busy" cr
   abort
;

0 instance value phy#
: mii-read  ( reg -- w )  
   phy# bwjoin gmii-mng-ctl!  ( )
   gmii-wait gmii-mng-dat@
;
: mii-write  ( n reg -- )
   swap gmii-mng-dat!                      ( reg )
   phy# bwjoin rw-phyreg or gmii-mng-ctl!  ( )
   gmii-wait
;
: find-phy  ( -- error? )
   h# 20 0  do
     i to phy#
     2 mii-read h# ffff <>  if  false unloop exit  then
   loop
   true
;

: vlan-tag@  ( -- w )  h# 32 tmac@  ;
: vlan-tag!  ( w -- )  h# 32 tmac!  ;

: mlt-tab@   ( index -- w )  /w*  h# 32 + tmac@  ;
: mlt-tab!   ( n index -- )  /w*  h# 32 + tmac!  ;

: paus-op@  ( -- w )  h# 34 tmac@  ;
: paus-op!  ( w -- )  h# 34 tmac!  ;

: link-down  ( -- )
   mode@  rx-en tx-en or  invert and  mode!
;

: set/clear  ( val bits set? -- val' )
   if  or  else  invert and  then
;

: link-up  ( gigabit? half-duplex? -- )
   tx-rx-ctl@ hden rot set/clear tx-rx-ctl!  ( gigabit? )
   mode@  gbit-en  rot set/clear             ( mode' )
   rx-en tx-en or  or  mode!                 ( )
;

: marvell-fixup  ( -- )  h# 4148 h# 18 mii-write  ;

: reset-hw  ( -- )
   fc-en mode!
   d# 20 rx-fifo-th!
   d# 25 tx-fifo-th!
   rx-flush tx-flush or  sys-ctl!
   1 ms
   0 sys-ctl!
;

\ String comparision
: $= ( adr0 len0 adr1 len1 -- equal? )
   2 pick <> if 3drop false exit then ( adr0 len0 adr1 )
   swap comp 0=
;

\ Handle some possible argument values
0 instance value promiscuous?

0 instance value tftp-args
0 instance value tftp-len

: parse-args  ( -- )
   my-args  begin                                               ( rem$ )
      2dup to tftp-len to tftp-args                             ( rem$ )
   dup  while                                                   ( rem$ )
      ascii , left-parse-string                                 ( rem$ head$ )
      2dup  " promiscuous" $=  if  true  to promiscuous?  else  ( rem$ head$ )
\     2dup  " loopback"    $=  if  true  to loopback?     else  ( rem$ head$ )
                                   2drop 2drop exit             ( )
      then                                                      ( rem$ head$ )
      2drop                                                     ( rem$ )
   repeat                                                       ( rem$ )
   2drop                                                        ( )
;

\ Wait for autonegotiation complete.  Returns true if the link is down.
: phy-wait  ( -- error? )
   d# 500 0  do
      1 mii-read h# 20 and  if  false unloop exit  then
      1 ms
   loop
   true
;

\ Determine whether to use gigabit mode and half-duplex mode
\ based on information from the PHY

: link-type  ( -- gigabit? half-duplex? )
   \ Merge together our 1000BT capabilites and the link partner's
   9 mii-read 2 lshift  d# 10 mii-read and   ( bits )

   \ Gigabit if either 1000BT full duplex or 1000BT half duplex
   dup h# c00 and  if   \ 1000BT ?           ( bits )
      \ Half duplex if not full duplex
      true  swap h# 800 and 0=               ( gigabit? half-duplex? )
      exit
   then                                      ( bits )
   drop                                      ( )

   false                                     ( gigabit? )
   \ Merge our 10/100BT capabilities and the link partner's
   4 mii-read  5 mii-read  and               ( gigabit? bits )

   \ 100BT FD?
   dup h# 100 and  if  drop false exit  then ( gigabit? bits )

   \ 100BT HD?
   dup h#  80 and  if  drop true  exit  then ( gigabit? bits )

   \ Half duplex if not 10BT FD
   h# 40 and 0=                              ( gigabit? half-duplex? )
;

: ?marvell-fix  ( -- )
   1 mii-read h# 0141 <>  if  exit  then
   2 mii-read h# 0cc0 <>  if  exit  then
   h# 4148 h# 18 mii-write  \ LINK1000 as Link LED, TX as activity LED
;

: setup-link  ( -- okay? )
   find-phy  if
      ." Lattice Ethernet: Can't find the PHY" cr
      false exit
   then

   ?marvell-fix

   phy-wait  if  ." Link down" cr  false exit  then 

   link-type link-up
   true
;

: init-hw  ( -- )
   reset-hw

   mac-address set-mac-addr

   tx-rx-ctl@
   promiscuous?  if  prms or  then
   \ Not supporting multicast yet
   receive-pause or
   receive-brdcst or
   drop-control or
   discard-fcs or
   tx-rx-ctl!
   intr-src@ drop   \ Clear IRQs
   0 intr-enb!      \ Disable IRQs
;
: open  ( -- okay? )
   map-regs
   set-delay
   parse-args
   init-hw
   setup-link  ( okay? )
;

: close  ( -- )
   reset-hw    \ Includes the effect of link-down
   unmap-regs
;

: read  ( adr len -- actual )
   rx-fifo-wcnt@ d# 16 rshift  if    ( adr len )
      rx-cmd-fifo@ lwsplit           ( adr len actual stats )
      h# df18 and  ?dup  if          ( adr len actual error )
         ." RX packet error " .x  cr ( adr len actual )
         3drop -2 exit
      then                           ( adr len actual )
      min tuck                       ( actual' adr actual' )
      bounds  ?do  rx-data-fifo@ i l!  /l +loop
   else
      2drop -2
   then
;

d# 2048 constant dnet-fifo-size

: write  ( adr len -- actual )
   tuck                                    ( actual adr len )
   over 3 and  over 3 + + 2 rshift >r      ( actual adr len r: #words )
   dnet-fifo-size r@ -                     ( actual adr len needed r: #words )
   begin  dup tx-fifo-wcnt@ >  until       ( actual adr len needed r: #words )
   drop                                    ( actual adr len )
   over 3 and d# 16 lshift + swap          ( actual tx-cmd adr r: #words )
   3 invert and  r> /l* bounds  ?do        ( actual tx-cmd )
      i l@ tx-data-fifo!                   ( actual tx-cmd )
   /l +loop                                ( actual tx-cmd )
   tx-cmd-fifo!                            ( actual )   
;

: load  ( adr -- len )
   " obp-tftp" find-package  if      ( adr phandle )
      tftp-args tftp-len rot  open-package      ( adr ihandle|0 )
   else                              ( adr )
      0                              ( adr 0 )
   then                              ( adr ihandle|0 )

   dup  0=  if  ." Can't open obp-tftp support package" abort  then
                                     ( adr ihandle )

   >r
   " load" r@ $call-method           ( len )
   r> close-package
;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
