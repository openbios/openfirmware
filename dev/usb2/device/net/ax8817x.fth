purpose: AX8817X based ethernet driver
\ See license at end of file

headers
hex

\ Other values:
\ DLink DUB-E100 USB Ethernet 0x009f9d9f
\ Hawking UF200 USB Ethernet  0x001f1d1f


h# 0013.0103 value ax8817x-gpio		\ GPIO toggle values
\ This may need to optimized at some point
: ax88772?  ( -- flag )
   " vendor-id" get-my-property  if  false exit  then  ( adr len )
   decode-int  nip nip  h# 13b1  =    \ Vendor ID for Linksys USB200M rev 2
;

0 value ax8817x-pid			\ PHY id

h# 06 constant AX_CMD_SET_SW_MII
h# 07 constant AX_CMD_READ_MII_REG
h# 08 constant AX_CMD_WRITE_MII_REG
h# 0a constant AX_CMD_SET_HW_MII
h# 0b constant AX_CMD_READ_EEPROM
h# 0c constant AX_CMD_WRITE_EEPROM
h# 10 constant AX_CMD_WRITE_RX_CTL
h# 11 constant AX_CMD_READ_IPG012
h# 12 constant AX_CMD_WRITE_IPG0
h# 13 constant AX_CMD_WRITE_IPG1
h# 14 constant AX_CMD_WRITE_IPG2
h# 16 constant AX_CMD_WRITE_MULTI_FILTER
h# 17 constant AX_CMD_READ_NODE_ID
h# 19 constant AX_CMD_READ_PHY_ID
h# 1b constant AX_CMD_WRITE_MEDIUM_MODE
h# 1c constant AX_CMD_READ_MONITOR_MODE
h# 1d constant AX_CMD_WRITE_MONITOR_MODE
h# 1f constant AX_CMD_WRITE_GPIOS

h# 20 constant AX_CMD_SW_RESET
h# 21 constant AX_CMD_SW_PHY_STATUS
h# 22 constant AX_CMD_SW_PHY_SELECT
h# 13 constant AX88772_CMD_READ_NODE_ID

h# 01 constant AX_MONITOR_MODE
h# 02 constant AX_MONITOR_LINK
h# 04 constant AX_MONITOR_MAGIC
h# 10 constant AX_MONITOR_HSFS

d# 08 constant AX_MCAST_FILTER_SIZE
d# 64 constant AX_MAX_MCAST

6 buffer: ax8817x-buf

: ax8817x-control-set  ( adr len idx value cmd -- usberr )
   DR_OUT DR_VENDOR or DR_DEVICE or swap control-set
;
: ax8817x-control-get  ( adr len idx value cmd -- actual usberr )
   DR_IN DR_VENDOR or DR_DEVICE or swap control-get
;

: ax8817x-write-gpio  ( value -- )
   >r 0 0 0 r> AX_CMD_WRITE_GPIOS ax8817x-control-set drop
;

: ax8817x-toggle-gpio  ( -- )
   ax88772?  if
      h# b0  ax8817x-write-gpio  5 ms
   else
      ax8817x-gpio lbsplit drop			( lo m.lo m.hi )
      ax8817x-write-gpio  5 ms			( lo m.lo )
      ax8817x-write-gpio  5 ms			( lo )
      ax8817x-write-gpio  5 ms			( )
   then
;

: ax8817x-get-mac-address  ( -- )	\ Read the MAC address from the EEPROM
   ax8817x-buf 6 0 0
   ax88772?  if  h# 13  else  h# 17  then   \ AX_CMD_READ_NODE_ID , in two versions
   ax8817x-control-get  2drop
   ax8817x-buf mac-adr /mac-adr move
;

: ax88772-sw-reset  ( flags -- )  AX_CMD_SW_RESET control!  ;

: ax8817x-set-ipg  ( -- )
   ax88772?  if
      ax8817x-buf     3 0 0 AX_CMD_WRITE_IPG0 ax8817x-control-set  drop
   else
      ax8817x-buf     3 0 0 AX_CMD_READ_IPG012 ax8817x-control-get  2drop
      ax8817x-buf     1 0 0 AX_CMD_WRITE_IPG0 ax8817x-control-set  drop
      ax8817x-buf 1+  1 0 0 AX_CMD_WRITE_IPG1 ax8817x-control-set  drop
      ax8817x-buf 2 + 1 0 0 AX_CMD_WRITE_IPG2 ax8817x-control-set  drop
   then
;

: ax8817x-mii-sw  ( -- )
   0 0 0 0 AX_CMD_SET_SW_MII ax8817x-control-set  drop	\ Enter S/W MII mode
;
: ax8817x-mii-hw  ( -- )
   0 0 0 0 AX_CMD_SET_HW_MII ax8817x-control-set  drop	\ Enter H/W MII mode   
;
: ax8817x-mii@  ( reg -- w )
   ax8817x-buf 2 rot ax8817x-pid AX_CMD_READ_MII_REG ax8817x-control-get  2drop
   ax8817x-buf le-w@
;
: ax8817x-mii!  ( w reg -- )
   swap ax8817x-buf le-w!
   ax8817x-buf 2 rot ax8817x-pid AX_CMD_WRITE_MII_REG ax8817x-control-set  drop
;

: ax8817x-get-pid  ( -- )
   ax8817x-buf 2 0 0 AX_CMD_READ_PHY_ID ax8817x-control-get  2drop
   ax8817x-buf 1+ c@ h# 3f and to ax8817x-pid
;

: ax8817x-link-up?  ( -- up? )
   ax8817x-mii-sw
   1 ax8817x-mii@ 4 and			\ BMSR_LSTATUS=1 => link is up
   ax8817x-mii-hw
;

: ax8817x-init-mii  ( -- )
   ax8817x-mii-sw
   h# 8000 0 ax8817x-mii!		\ BMCR reset
   h# 05e1 4 ax8817x-mii!		\ Advertise 10/100, half/full/full pause
   h# 1200 0 ax8817x-mii!		\ Enable auto neg & restart
   ax8817x-mii-hw
;

\ I have a wait here because it takes a while for BMSR_LSTATUS to be set if
\ there is connection.  And because if I don't do it here and now, the current
\ and subsequent opens would fail.  I haven't figured out why yet.  It appears
\ to be ok if one waits prior to finishing up open.

: ax8817x-auto-neg-wait  ( -- )
   \ Empirically, at loop count d# 137-139, if connected, link-up? returns true.
   \ But, I've seen loop count as high as d# 1020 in Longmont.
   \ I increase the loop count in case the partner is slow in negotiating.
   \ And if there's no connection at all, let's not wait too long.
   d# 2000 0  do  ax8817x-link-up? ?leave  1 ms  loop
;

: ax8817x-init-nic  ( -- )		\ Per ax8817x_bind
   ax8817x-toggle-gpio
   0 0 0 h# 80 AX_CMD_WRITE_RX_CTL ax8817x-control-set  drop
   ax8817x-get-mac-address
   ax8817x-set-ipg
   ax8817x-get-pid
   ax8817x-init-mii
   ax8817x-auto-neg-wait
;

: ax8817x-start-nic  ( -- )
   0 0 0
   my-args  " promiscuous" $=  if  h# 8d  else  h# 8c  then
   AX_CMD_WRITE_RX_CTL ax8817x-control-set drop
;

: init-ax8817x  ( -- )
   ['] ax8817x-init-nic to init-nic
   ['] ax8817x-link-up? to link-up?
   ['] ax8817x-start-nic to start-nic
   ['] ax8817x-get-mac-address to get-mac-address
   vid h# 2001 =  pid h# 1a00 = and  if  h# 009f.9d9f to ax8817x-gpio  then
   vid h# 07b8 =  pid h# 420a = and  if  h# 001f.1d1f to ax8817x-gpio  then
;

: init  ( -- )
   init
   vid pid net-ax8817x?  if  init-ax8817x  then
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
