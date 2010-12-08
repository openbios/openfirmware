purpose: Driver for EHCI USB Controller
\ See license at end of file

" ehci" encode-string " device_type" property

hex
headers

defer init-extra	' noop to init-extra
defer end-extra		' noop to end-extra

true value first-open?
0 value open-count
0 value ehci-reg
0 value op-reg-offset

: map-regs  ( -- )
   /regs my-map-in to ehci-reg
;
: unmap-regs  ( -- )
   ehci-reg  /regs  my-map-out  0 to ehci-reg
;

: ehci-reg@  ( idx -- data )  ehci-reg + rl@  ;
: ehci-reg!  ( data idx -- )  ehci-reg + rl!  ;

: ll ( idx -- )  dup h# f and 0=  if  cr 2 u.r ."   "  else  drop  then  ;
: dump-ehci  ( -- )  100 0 do  i ll i ehci-reg@ 8 u.r space 4  +loop  ;

\ Host controller capability registers
: hcsparams@  ( -- data )  4 ehci-reg@  ;
: hccparams@  ( -- data )  8 ehci-reg@  ;
: (hcsp-portroute@)  ( -- d.lo,hi )  h# c ehci-reg@  h# 10 ehci-reg@  ;
: hcsp-portroute@  ( port -- data )
   (hcsp-portroute@) rot
   dup >r 7 >  if  8 - nip  else  drop  then r>
   4 * >> h# f and
;

\ Host Controller operational registers
: op-reg@    ( idx -- data )  op-reg-offset + ehci-reg@  ;
: op-reg!    ( data idx -- )  op-reg-offset + ehci-reg!  ;

: usbcmd@    ( -- data )  0 op-reg@  ;
: usbcmd!    ( data -- )  0 op-reg!  ;
: flush-reg  ( -- )       usbcmd@ drop  ;
: usbsts@    ( -- data )  4 op-reg@  ;
: usbsts!    ( data -- )  4 op-reg! flush-reg  ;
: usbintr@   ( -- data )  8 op-reg@  ;
: usbintr!   ( data -- )  8 op-reg!  ;
: frindex@   ( -- data )  h# c op-reg@  ;
: frindex!   ( data -- )  h# c op-reg!  ;
: ctrldsseg@ ( -- data )  h# 10 op-reg@  ;
: ctrldsseg! ( data -- )  h# 10 op-reg!  ;
: periodic@  ( -- data )  h# 14 op-reg@  ;
: periodic!  ( data -- )  h# 14 op-reg!  ;
: asynclist@ ( -- data )  h# 18 op-reg@  ;
: asynclist! ( data -- )  h# 18 op-reg!  ;

: cfgflag@   ( -- data )  h# 40 op-reg@  ;
: cfgflag!   ( data -- )  h# 40 op-reg! flush-reg  ;
: portsc@    ( port -- data )  4 * h# 44 + op-reg@  ;
: portsc!    ( data port -- )  4 * h# 44 + op-reg!  flush-reg  ;

: halted?    ( -- flag )  usbsts@ h# 1000 and  ;
: halt-wait  ( -- )       begin  halted?  until  ;

: process-hc-status  ( -- )
   usbsts@ dup usbsts!		\ Clear interrupts and errors
   h# 10  and  if  " Host system error" USB_ERR_HCHALTED set-usb-error  then
;
: get-hc-status  ( -- status )
   usbsts@ dup usbsts!		\ Clear interrupts and errors
   dup h# 10  and  if  " Host system error" USB_ERR_HCHALTED set-usb-error  then
;

: doorbell-wait  ( -- )
   \ Wait until interrupt on async advance bit is set.
   \ But, some HCs fail to set the async advance bit sometimes.  Therefore,
   \ we add a timeout and clear the status all the same.
   h# 100 0  do  usbsts@ h# 20 and  if  leave  then  loop
   h# 20 usbsts!			\ Clear status
;
: ring-doorbell  ( -- )
   usbcmd@ h# 40 or usbcmd!		\ Interrupt on async advance doorbell
   usbcmd@ drop
   doorbell-wait
;

0 value dbgp-offset
0 value dbgp-bar

: debug-port-active?  ( -- flag )
   hcsparams@  h# f0.0000 and  0=  if  false exit  then
   has-dbgp-regs?  if   ( offset bar )
      to dbgp-bar  to dbgp-offset
   else                 ( )
      false exit
   then

   \ We should take dbgp-bar into account, but for now we
   \ just assume it's the same BAR as for the main registers.
   dbgp-offset ehci-reg@
   h# 1000.0000 and 0<>
;

external

: start-usb  ( -- )
   ehci-reg dup 0=  if  map-regs  then
   halted?  if  usbcmd@ 1 or usbcmd!  then
   0=  if  unmap-regs  then
;

: stop-usb   ( -- )
   ehci-reg dup 0=  if  map-regs  then
   usbcmd@ 31 invert and usbcmd!
   halt-wait
   0=  if  unmap-regs  then
;

: reset-usb  ( -- )
   ehci-reg dup 0=  if  map-regs  then  ( reg )
   debug-port-active?  if  drop exit  then   \ Don't kill the debug port!
   usbcmd@ 2 or 1 invert and usbcmd!	\ HCReset
   d# 10 0  do
      usbcmd@ 2 and  0=  ?leave
      1 ms
   loop
   0=  if  unmap-regs  then
;

: test-port-begin  ( port -- )
   ehci-reg dup 0=  if  map-regs  then
   swap dup portsc@ h# 4.0000 or swap portsc!
   0=  if  unmap-regs  then
;

: test-port-end  ( port -- )
   ehci-reg dup 0=  if  map-regs  then
   swap dup portsc@ h# 7.0000 invert and swap portsc!
   0=  if  unmap-regs  then
;

headers

: init-ehci-regs  ( -- )
   0 ctrldsseg!
   0 periodic!
   0 asynclist!
   0 usbintr!
;

: reset-port  ( port -- )
   dup portsc@ h# 100 or 4 invert and over portsc!	\ Reset port
   d# 50 ms
   dup portsc@ h# 100 invert and swap portsc!
   d# 10 ms
;

: power-port   ( port -- )  dup portsc@ h# 1000 or swap portsc!  2 ms  ;

: disown-port  ( port -- )  dup portsc@ h# 2000 or swap portsc!  ;

: #ports  ( -- n )  hcsparams@ h# f and  ;

: claim-ownership  ( -- )
   1 cfgflag!				\ Claim ownership to all ports
   3 ms					\ Give devices time to settle

   \ Power on ports if necessary
   hcsparams@ h# 10 and  if
      #ports 0  ?do
         i power-port
      loop
   then
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
