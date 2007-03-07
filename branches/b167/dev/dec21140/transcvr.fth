\ See license at end of file

headerless

\ MII Management Registers
0 constant phy-control-reg
1 constant phy-status-reg
2 constant phy-id1
3 constant phy-id2
4 constant phy-anar
5 constant phy-anlpar
6 constant phy-aner

\ Control register bit definitions
h# 8000 constant phy-reset
h# 4000 constant phy-loopback
h# 2000 constant phy-speed-100
0       constant phy-speed-10
h# 1000 constant phy-an-enable
h# 0800 constant phy-powerdown
h# 0400 constant phy-isolate
h# 0200 constant phy-an-restart
h# 0100 constant phy-duplex

\ Value of PHY id for Quality SemiConductor PHY QS6612
h# 0181.4411 constant qsm-id

\ Status Register bit definitions
h#    4 constant phy-link-up
h#    8 constant phy-an-able
h#   20 constant phy-an-complete
h# 1800 constant phy-10bt-able
h# e000 constant phy-100bt-able

\ Autonegotiation advertisement register bit definitions
h#   21 constant anar-10-simplex
h#   81 constant anar-100-simplex
h#   a1 constant anar-all-simplex
h#  1e1 constant anar-all-duplex

\ Autonegotiation expansion register bit definitions
h#    1 constant aner-lp-an-able
h#   10 constant aner-mlf

\ Autonegotiation Link Partner Ability register bit masks
h#  380 constant anlpar-100bt-able
h#   60 constant anlpar-10bt-able

\ Transceiver check codes
0  constant xcvr-link-up
-1 constant xcvr-link-down
-2 constant xcvr-not-found

\ Constants for xvcr speeds
d# 100 constant c-speed-100
d#  10 constant c-speed-10

headers
false instance value link-up-seen?
0     instance value an-completed?
0     instance value user-speed

headerless

: phy-control-reg!  ( data -- )
   phy-control-reg mii-write
;

: phy-control-reg@  ( -- data )
   phy-control-reg mii-read
;

: phy-status-reg@  ( -- data )
   phy-status-reg mii-read
;

: disable-auto-nego  ( -- )
   andv 2 =  if  ." Disabling AN. " cr  then
   phy-control-reg@  phy-an-enable invert  and
   phy-control-reg!
;

: enable-auto-nego  ( -- )
   phy-control-reg@  phy-an-enable phy-an-restart or  or
   phy-control-reg!
;

: enable-xcvr-10  ( -- )
   phy-control-reg@
   phy-speed-100 invert  and  phy-control-reg!
   2 ms
;

: enable-xcvr-100  ( -- )
   phy-control-reg@
   phy-speed-100 or  phy-control-reg!
   2 ms
;

: force-link-down  ( -- )
   phy-control-reg@  phy-loopback or  phy-control-reg!
   d# 1000 ms
   phy-control-reg@  phy-loopback invert  and  phy-control-reg!
;

: set-half-duplex-mode  ( -- )
   phy-control-reg@
   phy-duplex invert and  phy-control-reg!
;

external
: reset-transceiver  ( -- failed? )
   phy-powerdown phy-control-reg! 
   d# 256 ms
   phy-control-reg@  phy-powerdown invert and  phy-control-reg!
   phy-reset phy-control-reg!
   d# 500 set-hm-timeout
   begin
      phy-control-reg@  phy-reset and
   while
      hm-timeout?  if  ." Cannot reset transceiver!" cr true exit  then
   repeat
   set-half-duplex-mode
   enable-xcvr-10
   false
;

headers
: link-state-down?  ( speed -- down? )
   disable-auto-nego
   force-link-down
   false to link-up-seen?
                             ( speed )
   phy-status-reg@ drop        \ Drop the first dummy read.
   phy-status-reg@
   over c-speed-100 =  if
      \ see if xcvr is capable of this speed, 100Mbps, based on PHY basic status reg
      phy-100bt-able and 0=  if
         drop
         xcvr-link-down exit  ( down )
      then
      dsdv 2 =  if ." 100 Mbps "  then
   else
      \ see if xcvr is capable of this speed, 10Mbps, based on bmsr
      phy-10bt-able  and 0=  if
         drop
         xcvr-link-down exit  ( down )
      then
      dsdv 2 =  if ." 10 Mbps "  then
   then
   \ enable speed
           ( speed )
   c-speed-100 =  if
      enable-xcvr-100
   else
      enable-xcvr-10
   then
   d# 50 ms     \ Delay for a while.
   d# 2000 set-hm-timeout   \ Two seconds timeout
   phy-status-reg@ drop     \ Drop the first dummy read.
   begin
      phy-status-reg@  phy-link-up and  0=
   while
      hm-timeout?  if
         \ put the link in 10 Mbps mode or else
         \ it may adversely affect the subnet.
         enable-xcvr-10
         xcvr-link-down exit
      then
   repeat
   xcvr-link-up
   true to link-up-seen?
;

headerless
: get-link-status   ( speed -- down? )
   link-state-down? dup  if
      diagnostic-mode?  if  ." Link Down." cr  then
   else
      diagnostic-mode?  if ." Link Up." cr  then
   then
;

external
: transfer-speed=100  ( -- )
   d# 100 encode-int " transfer-speed" property
;

: transfer-speed=10  ( -- )
   d# 10 encode-int " transfer-speed" property
;

headerless
0 constant c-speed-auto

: init-user-speed  ( -- )
   c-speed-auto to user-speed
   " transfer-speed" get-my-property  0=  if  ( )
      decode-int nip nip                      ( speed )
      case                                    ( speed )
         c-speed-10   of  c-speed-10   endof  ( speed )
         c-speed-100  of  c-speed-100  endof  ( speed )
         ( otherwise )
         c-speed-auto  swap                   ( speed n )
      endcase  to user-speed                  ( )
   then
;

headerless
xcvr-link-down instance value an-xcvr-link-status
0 instance              value my-anar

: set-an-link-down  ( -- )
   false to link-up-seen?
   xcvr-link-down  to an-xcvr-link-status
;

: set-an-link-up  ( -- )
   andv 2 =  if  ." setting an-link-up. " cr  then
   true to link-up-seen?
   xcvr-link-up  to an-xcvr-link-status
;

0 instance value an-speed
: get-speed-from-anlpar  ( -- )
   0 to an-speed
   phy-anlpar mii-read
   dup anlpar-100bt-able and
   my-anar and  if      ( anlpar )
      drop d# 100       ( speed )
   else                 ( anlpar )
      anlpar-10bt-able and  my-anar and  if
         d# 10          ( speed )
      else
         diagnostic-mode?  if
            ." System and Net incompatible for Communicating. " cr
         then
         set-an-link-down
         exit           ( )
      then
   then
   to an-speed          (  )
   dsdv 2 =  if  an-speed .d ." Mbps " then
;

: set-an-link-status  ( -- )
   d# 2000 set-hm-timeout                  \ Two seconds timeout
   phy-status-reg@ drop        \ Drop the first dummy read.
   begin
      d# 2 ms phy-status-reg@ phy-link-up and  0=
   while
      hm-timeout?  if
         diagnostic-mode?  if
            ." Timeout reading Link status. "
            ." Check cable and try again. " cr
         then
         set-an-link-down exit
      then
   repeat
   set-an-link-up
   d# 80 ms
;

: get-an-link-speed  ( aner --  )
   set-an-link-down
   set-an-link-status  ( aner )

   an-xcvr-link-status xcvr-link-up <>  if     ( aner )
      drop  set-an-link-down exit
   then
   ( aner )
   aner-lp-an-able and  if     ( )
      andv 2 =  if  ." Link Partner is AN-able " cr ( XXX )  then
      get-speed-from-anlpar
   else  ( )
      \ for Link partners not AutoNego capable external xcvrs
      get-speed-from-anlpar
   then
   true to an-completed?
;

: check-aner  ( -- )
   phy-aner mii-read   ( ANER )
   dup aner-mlf and  if
      diagnostic-mode?  if
         ." Multiple link fault while doing AutoNegotiation. " cr
      then
      drop
      set-an-link-down
      false to an-completed?
   else
      get-an-link-speed   ( )
   then
;

: publish-anar  ( -- )
   phy-status-reg@ drop   \ drop xcvr status reg.
   phy-aner mii-read drop   \ read ANER
   phy-anar mii-read drop
   \ publish our capabilities as 10 and/or 100Base half duplex
   my-anar phy-anar mii-write  2 ms
;

: publish-anar-x  ( speed -- )
   force-link-down
   \ advertise only one speed
   d# 100 =  if  anar-100-simplex  else  anar-10-simplex  then
   to my-anar
   publish-anar
;

: set-anar-all  ( -- )
   anar-all-duplex to my-anar
;

: setup-for-autonego  ( -- )
   publish-anar       \ publish our capabilites, half duplex
   \ restart autonegotiation
   enable-auto-nego
   d# 5000 set-hm-timeout  \
   begin
      d# 20 ms
      phy-status-reg@
      phy-an-complete and
      hm-timeout? or
   until
   hm-timeout?  if
      diagnostic-mode?  if
         ." Timeout waiting for AutoNegotiation Status to be updated. " cr
      then
   then

;

\ Do speed selection using auto negotiation.
: do-an-ss  ( -- link-status )
   \ 15 sec. timeout on entire process of auto-negotiation
   d# 15000 set-an-timeout
   false to an-completed?
   begin
      setup-for-autonego ( )
      check-aner         ( )
      an-completed? an-timeout? or
   until
   an-timeout?  if
      diagnostic-mode?  if
         ." AutoNegotiation Timeout. " cr
         ." Check Cable or Contact your System Administrator. " cr
      then
      set-an-link-down
   then
   an-xcvr-link-status
;

headers
: autonego-speed-select?  ( -- link-status )
   false to an-completed?
   do-an-ss
   diagnostic-mode? if
      link-up-seen?  if  ." Link Up. " else ." Link Down."  then  cr
   then
;

headerless
\ The auto-selection protocol is to set to 100 BaseT, check if link is up,
\ if so, use the 100 BaseT; if link is down, try to set to 10 BaseT, check
\ if link is up, if so, use the 10 BaseT; if link is down, then complain it.
: speed-select?  ( -- down? )
   c-speed-100 link-state-down?  if
      c-speed-10 get-link-status
   else
      xcvr-link-up
   then
;

: setup-speed?  ( -- down? )
   disable-auto-nego
   user-speed  if
      user-speed get-link-status
   else
      speed-select?
   then
;

: setup-autonego-speed?  ( -- down? )
   user-speed c-speed-100 =  if
      d# 100 publish-anar-x
      c-speed-100
      get-link-status
   else
      user-speed c-speed-10 =  if
         d# 10 publish-anar-x
         c-speed-10
         get-link-status
      else
         set-anar-all autonego-speed-select?
      then
   then
;

defer setup-link-speed?
false value use-force-speed?

\ Don't use autonegotiation for determining speed
: speed-set  ( -- )
   ['] setup-speed? to setup-link-speed?
;

: setup-speed-selection  ( -- )
   use-force-speed?  if
      speed-set
   else
      ['] setup-autonego-speed? to setup-link-speed?
   then
;

external
: force-speeds  ( -- )
   true to use-force-speed?
   speed-set
;

headers

defer reset-net  ( -- ok? )

: setup-xcvr-speed?  ( -- failed? )
\ Return 0: OK, -1: Link Down, -2: No xcvr.
   xcvr-present?  if
      diagnostic-mode?  if  ." Using Onboard transceiver - "  then
      reset-transceiver drop
      setup-link-speed?
      \ Disable data scrambling for a short time to enable us to work with
      \ hubs which have buggy National PHYs.
      d# 31 mii-read dup  1 or  d# 31 mii-write  1 ms  d# 31 mii-write
   else
      ." No Transceiver Found. "  xcvr-not-found
   then

;

: make-max-frame-size-prop  ( -- )
   user-speed c-speed-auto =  if
      an-speed
   else
      user-speed
   then
   c-speed-100 =  if  h# 4000  else  d# 1518  then
   " max-frame-size" get-my-property  0=  if  ( n adr len )
      decode-int nip nip                      ( n n1 )
      over =  if  drop exit  then             ( n )
   then                                       ( n )
   encode-int " max-frame-size" property      ( )
;

\ Don't be called by open, because we want to be able to select-dev even
\ the cable or transceiver is not connected.
: setup-mii?  ( -- failed )
   init-user-speed
   setup-speed-selection
   setup-xcvr-speed?
   make-max-frame-size-prop
;

headers
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
