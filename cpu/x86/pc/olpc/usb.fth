purpose: USB elaborations for the OLPC platform
\ See license at end of file

0 config-int usb-delay  \ Milliseconds to wait before set-address

devalias usb1 /usb@f,4
devalias usb2 /usb@f,5
devalias u    /usb/disk
devalias net  /usb/wlan

\ If there is a USB ethernet adapter, use it as the default net device.
: report-net  ( -- )
   " /usb/ethernet" 2dup  find-package  if  ( name$ phandle )
      drop                                  ( name$ )
     " net" 2swap $devalias                 ( )
   else                                     ( name$ )
      2drop                                 ( )
   then
;

[ifdef] notdef   \ We have the graphical penguin
: linux-logo  ( -- )
   " penguin.txt" find-drop-in  if  page type  then
;
[then]

\ Like $show-devs, but ignores pagination keystrokes
: $nopage-show-devs  ( nodename$ -- )
   ['] exit? behavior >r  ['] false to exit?
   $show-devs
   r> to exit?
;

: probe-usb  ( -- )
   ." USB2 devices:" cr
   " /usb@f,5" open-dev  ?dup  if  close-dev  then
   " /usb@f,5" $nopage-show-devs

   ." USB1 devices:" cr
   " /usb@f,4" open-dev  ?dup  if  close-dev  then
   " /usb@f,4" $nopage-show-devs

   report-disk
   report-net
   report-keyboard
;
alias probe-usb2 probe-usb
alias p2 probe-usb2

: ?usb-keyboard  ( -- )
   " keyboard" expand-alias  if   ( devspec$ )
      drop " /usb"  comp  0=  if  ( )
         red-letters  ." Using USB keyboard." cr  black-letters
         " keyboard" input
      then
   then
;

\ Unlink every node whose phys.hi component matches port
: port-match?  ( port -- flag )
   get-unit  if  drop false exit  then
   get-encoded-int =
;
: rm-usb-children  ( port -- )
   device-context? 0=  if  drop exit  then
   also                             ( port )
   'child                           ( port prev )
   first-child  begin while         ( port prev )
      over port-match?  if          ( port prev )
         'peer link@  over link!    ( port prev )      \ Disconnect
      else                          ( port prev )
         drop 'peer                 ( port prev' )
      then                          ( port prev )
   next-child  repeat               ( port prev )
   2drop                            ( )
   previous definitions
;

0 value usb-power-done-time

\ This version assumes that power has been applied already, and
\ all we have to do is wait enough time for the devices to be ready.
: wait-usb-power  ( -- )
   begin  usb-power-done-time get-msecs - 0<=  until    ( )
;

: usb-quiet  ( -- )
   [ ' go-hook behavior compile, ]    \ Chain to old behavior
   " usb1" " reset-usb" execute-device-method
   " usb2" " reset-usb" execute-device-method
;
' usb-quiet to go-hook

0 0 " " " /" begin-package
   " prober" device-name
   : open
      " /usb@f,5" open-dev  ?dup  if  close-dev  then
      " /usb@f,4" open-dev  ?dup  if  close-dev  then
      report-disk
      report-net
      report-keyboard
      false
   ;
   : close ;
end-package

stand-init: USB setup
   \ Set up an address routing to the USB Option Controller
   h# efc00000.efc00001. h# 5100.0029 wrmsr
   h# 400000ef.c00fffff. h# 5101.0020 wrmsr
   h# 00000002.efc00000. h# 5120.000b wrmsr
[ifdef] virtual-mode
   h# efc00000 h# 1000 0 mmu-claim drop  \ UOC
   h# efc00000 dup h# 1000 -1 mmu-map    \ UOC
   h# fe01a000 h# 1000 0 mmu-claim drop  \ OHCI
   h# fe01a000 dup h# 1000 -1 mmu-map    \ OHCI
[then]
   \ Configure the assignment of 2 USB Power Enable pins to USB ports
   \ to correspond to the way they are wired on the board.
   \ USB port 1 is PWR_EN2, USB ports 2-4 are PWR_EN1
   usb-port-power-map h# efc00000 l!
   2 h# efc00004 l!
   h#       1 h# fe01a008 l!   \ Reset OHCI host controller
   h# 1e.0000 h# fe01a04c l!   \ Configure ports for individual power
   h#     100 h# fe01a058 l!   \ Power-on ports 2 and 3
   d# 10 ms                    \ Stagger for glitch-prevention
   h#     100 h# fe01a054 l!   \ Power-on port 1
   h#     100 h# fe01a05c l!   \ Power-on port 3
   h#     100 h# fe01a060 l!   \ Power-on port 4
   get-msecs d# 1000 +  to usb-power-done-time
;


\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
