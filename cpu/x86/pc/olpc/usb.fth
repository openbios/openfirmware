purpose: USB elaborations for the OLPC platform
\ See license at end of file

\ If there is a PCI ethernet adapter, use it as the default net device,
\ otherwise use any ethernet that can be found in the device tree.
: report-net  ( -- )
   " /usb/ethernet" 2dup  find-package  if  ( name$ phandle )
      drop                                  ( name$ )
   else                                     ( name$ )
      2drop  " /ethernet"                   ( name$' )
   then                                     ( name$ )
   " net" 2swap $devalias                   ( )
;

[ifdef] notdef   \ We have the graphical penguin
: linux-logo  ( -- )
   " penguin.txt" find-drop-in  if  page type  then
;
[then]

: (probe-usb2)
   " /usb@f,5" select-dev
   delete-my-children
   " probe-usb" eval  \ EHCI probe
   unselect
   ." USB2 devices:" cr
   " show-devs /usb@f,5" eval
;
: probe-usb2  ( -- )
   (probe-usb2)
   report-disk
;
alias p2 probe-usb2

0 value usb-power-on-time

: probe-usb  ( -- )
   \ Open OHCI so it will claim USB 1 devices that the EHCI controller disowns
   " /usb@f,4" select-dev
   delete-my-children
   usb-power-on-time d# 1000 +  " wait-after-power" eval

   (probe-usb2)           \ First dibs to EHCI/USB2

   " probe-usb" eval  \ OHCI probe
   unselect
   ." USB1 devices:" cr
   " no-page  show-devs /usb@f,4  page-mode" eval

   report-disk
   report-net
   report-keyboard
;

: ?usb-keyboard  ( -- )
   " keyboard" expand-alias  if   ( devspec$ )
      drop " /usb"  comp  0=  if  ( )
         red-letters  ." Using USB keyboard." cr  black-letters
         " keyboard" input
      then
   then
;

100 buffer: usbpwd		0 value /usbpwd
: $hold  ( adr len -- )
   dup  if  bounds swap 1-  ?do  i c@ hold  -1 +loop  else  2drop  then
;
: rm-usb-child  ( $ phandle -- )  -rot type ."  removed" cr  delete-package  ;
: make-usb$  ( port func -- $ )
   <# u#s drop ascii , hold u#s drop " /@" $hold usbpwd /usbpwd $hold 0 u#>
;
: rm-usb-children  ( port -- )
   device-context? 0=  if  drop exit  then
   pwd$ dup to /usbpwd  usbpwd swap move
   h# f 0  do				\ Find all the functions at the port
      dup i make-usb$ 2dup locate-device 0=  if  rm-usb-child  else  2drop leave then
   loop  drop
;

: reprobe-usb  ( -- )
   ." USB2 devices:" cr
   " /usb@f,5" select-dev  ['] rm-usb-children " reprobe-usb" evaluate  unselect
   " no-page show-devs /usb@f,5" evaluate
   ." USB1 devices:" cr
   " /usb@f,4" select-dev  ['] rm-usb-children " reprobe-usb" evaluate  unselect
   " show-devs /usb@f,4  page-mode" evaluate
   report-disk
   report-net
   report-keyboard
;

stand-init: USB setup
   \ Set up an address routing to the USB Option Controller
   h# efc00000.efc00001. h# 5100.0029 wrmsr
   h# 400000ef.c00fffff. h# 5101.0020 wrmsr
   h# 00000002.efc00000. h# 5120.000b wrmsr
[ifdef] virtual-mode
   h# efc00000 dup h# 1000 -1 mmu-map  \ UOC
   h# fe01a000 dup h# 1000 -1 mmu-map  \ OHCI
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
   get-msecs to usb-power-on-time
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
