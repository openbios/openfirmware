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

: probe-usb  ( -- )
   \ Open OHCI so it will claim USB 1 devices that the EHCI controller disowns
   " /usb@f,4" select-dev
   delete-my-children
   " stagger-power" eval  \ Get the devices going
   d# 500 ms

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

stand-init: USB setup
   \ Set up an address routing to the USB Option Controller
   h# efc00000.efc00001. h# 5100.0029 wrmsr
   h# 400000ef.c00fffff. h# 5101.0020 wrmsr
   h# 00000002.efc00000. h# 5120.000b wrmsr
[ifdef] virtual-mode
   h# efc00000 dup h# 1000 -1 mmu-map
[then]
   \ Configure the assignment of 2 USB Power Enable pins to USB ports
   \ to correspond to the way they are wired on the board.
   \ USB port 1 is PWR_EN2, USB ports 2-4 are PWR_EN1
   h# 3ab h# efc00000 l!
   2 h# efc00004 l!
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
