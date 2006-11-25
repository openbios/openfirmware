purpose: Driver for Asix AX8817X and AX88772-based network interfaces
\ See license at end of file

headers
hex

\ Other values - set in init-ax:
\ DLink DUB-E100 USB Ethernet 0x009f9d9f
\ Hawking UF200 USB Ethernet  0x001f1d1f

h# 0013.0103 value ax-gpio		\ GPIO toggle values

\ This may need to optimized at some point
: ax88772?  ( -- flag )
   pid vid wljoin   case                          ( vid.pid )
      h# 13b1.0018  of  true exit  endof  \ ID for Linksys USB200M rev 2
      h# 2001.3c05  of  true exit  endof  \ ID for D-Link DUB-E100 rev B
      h# 07d1.3c05  of  true exit  endof  \ Alternate ID for D-Link DUB-E100 rev B
   endcase
   false
;

0 value phyid			\ PHY id

\ Command codes that we don't use, for reference
\ h# 0b constant AX_CMD_READ_EEPROM
\ h# 0c constant AX_CMD_WRITE_EEPROM
\ h# 16 constant AX_CMD_WRITE_MULTI_FILTER
\ h# 1b constant AX_CMD_WRITE_MEDIUM_MODE
\ h# 1c constant AX_CMD_READ_MONITOR_MODE
\ h# 1d constant AX_CMD_WRITE_MONITOR_MODE
\ h# 21 constant AX_CMD_SW_PHY_STATUS
\ h# 22 constant AX_CMD_SW_PHY_SELECT

\ d# 08 constant AX_MCAST_FILTER_SIZE
\ d# 64 constant AX_MAX_MCAST

\ h# 01 constant AX_MONITOR_MODE
\ h# 02 constant AX_MONITOR_LINK
\ h# 04 constant AX_MONITOR_MAGIC
\ h# 10 constant AX_MONITOR_HSFS


6 buffer: ax-buf

: ax-control-set  ( adr len idx value cmd -- )
   DR_OUT DR_VENDOR or DR_DEVICE or swap control-set  drop
;
: control!  ( value cmd -- )  \ For the common case where adr len and idx are 0
   >r >r  0 0 0  r> r>  ax-control-set
;
: ax-control-get  ( adr len idx value cmd -- )
   DR_IN DR_VENDOR or DR_DEVICE or swap control-get  2drop
;

\ This isn't really necessary because all the important information in the
\ EEPROM (node id, phyid, descriptors) can be accessed via other commands
: ax-eeprom@  ( index -- w ) 
   >r ax-buf 2  0  r> h# b  ax-control-get
   ax-buf le-w@
;

: ax-write-gpio  ( value -- )  h# 1f control!  ;  \ AX_CMD_WRITE_GPIOS

: ax-toggle-gpio  ( -- )
   ax88772?  if
      h# b0  ax-write-gpio  5 ms
   else
      ax-gpio lbsplit drop			( lo m.lo m.hi )
      ax-write-gpio  5 ms			( lo m.lo )
      ax-write-gpio  5 ms			( lo )
      ax-write-gpio  5 ms			( )
   then
;

: ax-get-mac-address  ( -- adr len )	\ Read the MAC address from the EEPROM
   mac-adr /mac-adr  0 0                        ( adr len idx value )
   ax88772?  if  h# 13  else  h# 17  then   \ AX_CMD_READ_NODE_ID , in two versions
   ax-control-get
   mac-adr /mac-adr
;

\ SW reset bits:
\ 01 - RR - Set then reset to clear bulk-in frame length error
\ 02 - RT - Set then reset to clear bulk-out frame length error
\ 04 - PRTE - 1: tri-state external phy reset, so it can be controlled
\      by an external pull-up or pull-down.  0: drive it actively.
\ 08 - PRL - External PHYRST_N pin. 1: high 0: low
\ 10 - BZ - Set to 1 to force BulkIn to return a 0-length USB packet
\ 20 - IPRL - internal phy reset.  0: Assert   1: release
\ 40 - IPPD - internal phy power.  0: Power On 1: Power off

: ax-sw-reset  ( flags -- )  h# 20 control!  ;  \ AX_CMD_SW_RESET (88772 only)

: ax-set-ipg  ( -- )
   ax-buf 3  0 0  h# 11  ax-control-get  \ AX_CMD_READ_IPG012
   ax88772?  if
      ax-buf     3 0 0 h# 12 ax-control-set  \ AX_CMD_WRITE_IPG0
   else
      ax-buf     1 0 0 h# 12 ax-control-set   \ AX_CMD_WRITE_IPG0
      ax-buf 1+  1 0 0 h# 13 ax-control-set   \ AX_CMD_WRITE_IPG1
      ax-buf 2 + 1 0 0 h# 14 ax-control-set   \ AX_CMD_WRITE_IPG2
   then
;

: ax-mii-sw  ( -- )  0 6 control!  ;  \ AX_CMD_SET_SW_MII  Enter S/W MII mode
: ax-mii-hw  ( -- )  0 h# a control!  ;	\ AX_CMD_SET_HW_MII Enter H/W MII mode

: ax-mii@  ( reg -- w )
   ax-buf 2 rot phyid 7 ax-control-get  \ AX_CMD_READ_MII_REG
   ax-buf le-w@
;
: ax-mii!  ( w reg -- )
   swap ax-buf le-w!
   ax-buf 2  rot  phyid  8 ax-control-set \ AX_CMD_WRITE_MII_REG
;

: ax-get-phyid  ( -- )
   ax-buf 2 0 0 h# 19 ax-control-get  \ AX_CMD_READ_PHY_ID
   ax-buf 1+ c@ h# 3f and to phyid
;

: ax-link-up?  ( -- up? )
   ax-mii-sw
   1 ax-mii@ 4 and			\ BMSR_LSTATUS=1 => link is up
   ax-mii-hw
;

: ax-init-mii  ( -- )
   ax-mii-sw
\   ax88772?  if
\      phyid h# 10 =  if
\         2 ax-mii@ h# 3b <>  if  ." Wrong PHY ID for ax88772" cr  then
\      else
\      then
\   then

   h# 8000 0 ax-mii!		\ BMCR reset

   ax88772?  if  h# 1e1  else  h# 5e1  then  \ No pause for 88772
   ( bits) 4 ax-mii!		\ Advertise 10/100, half/full/full pause
   h# 1200 0 ax-mii!		\ Enable auto neg & restart

   ax88772?  if
      h# 336  h# 1b  control!  \ AX_CMD_WRITE_MEDIUM_MODE
   then

   ax-mii-hw
;

\ I have a wait here because it takes a while for BMSR_LSTATUS to be set if
\ there is connection.  And because if I don't do it here and now, the current
\ and subsequent opens would fail.  I haven't figured out why yet.  It appears
\ to be ok if one waits prior to finishing up open.

: ax-auto-neg-wait  ( -- )
   \ Empirically, at loop count d# 137-139, if connected, link-up? returns true.
   \ But, I've seen loop count as high as d# 1020.
   \ I increase the loop count in case the partner is slow in negotiating.
   \ And if there's no connection at all, let's not wait too long.
   d# 2000 0  do  ax-link-up? ?leave  1 ms  loop
;

: select-phy  ( -- )
   ax88772?  if
      \ Linksys USB200M uses the built-in PHY, DLink DUB-E100 uses an external one

      \ Good for Linksys, bad for DLink DUB-E100
      \ 1 h# 22 control!  \ AX_CMD_SW_PHY_SELECT Manually select built-in PHY

      \ Good for DLink, bad for Linksys
      \ 0 h# 22 control!  \ AX_CMD_SW_PHY_SELECT Manually select external PHY

      \ Works for both Linksys USB200M and DLink DUB-E100, so long as there is
      \ a link connected.  It probably wouldn't work for Linksys if you started
      \ with the link disconnected and then tried to connect it later
      \ AX_CMD_SW_PHY_SELECT Automatically select based on link status of built-in PHY
      \ 2 h# 22 control!

      phyid  h# 10 =  if   \ Primary phy is built-in
         \ Reset internal PHY, leaving external phy reset tri-stated
         h#  4 ax-sw-reset  d# 150 ms  \ Assert internal PHY reset
         h# 24 ax-sw-reset  d# 150 ms  \ Release internal PHY reset

         1 h# 22 control!  \ AX_CMD_SW_PHY_SELECT Manually select built-in PHY

      else                 \ Primary phy is external

         \ 40: Power-down internal PHY
         \  4: Tri-state external PHY reset pin so external resistor controls it
         h# 44 ax-sw-reset

         0 h# 22 control!  \ AX_CMD_SW_PHY_SELECT Manually select external PHY
      then

      h# 40 ax-sw-reset  d# 150 ms  \ Power off internal PHY
      h#  0 ax-sw-reset  d# 150 ms  \ Power on internal PHY
      h# 28 ax-sw-reset  d# 150 ms  \ Release internal PHY, reset external one
   then
;

: rx-ctl!  ( n -- )  h# 10 control!  ;    \ AX_CMD_WRITE_RX_CTL
: ax-start-nic  ( -- )
   h# 8c  my-args  " promiscuous" $=  if  1 or  then  rx-ctl!
;
: ax-stop-nic  ( -- )  0 rx-ctl!  ;

: ax-init-nic  ( -- )		\ Per ax8817x_bind
   ax88772?  if  true to multi-packet?  then

   ax-toggle-gpio
   ax-get-phyid
   select-phy
   h# 80 rx-ctl!  \ Turn off receiver during setup
   \ ax-stop-nic
   ax-get-mac-address  2drop
   ax-set-ipg
   ax-init-mii
   ax-auto-neg-wait
   ax-start-nic
;

: init-ax  ( -- )
   ['] ax-init-nic  to init-nic
   ['] ax-link-up?  to link-up?
   ['] ax-start-nic to start-nic
   ['] ax-stop-nic  to stop-nic
   ['] ax-get-mac-address to get-mac-address
   vid h# 2001 =  pid h# 1a00 = and  if  h# 009f.9d9f to ax-gpio  then
   vid h# 07b8 =  pid h# 420a = and  if  h# 001f.1d1f to ax-gpio  then
   d# 2048 to /inbuf
   d# 2048 to /outbuf
;

: init  ( -- )
   init
   vid pid net-ax8817x?  if  init-ax  then
;

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
