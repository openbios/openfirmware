purpose: Driver for UHCI USB Controller
\ See license at end of file

hex
headers

defer end-extra			' noop to end-extra

true value first-open?
0 value open-count
0 value uhci-reg

h# 400 constant /regs

\ Configuration space registers
my-address my-space          encode-phys
                           0 encode-int  encode+  0     encode-int encode+
\ UHCI operational registers
0 0    my-space  0100.0020 + encode-phys encode+
                           0 encode-int  encode+  /regs encode-int encode+
" reg" property

: map-regs  ( -- )
   4 my-w@  h# 17 or  4 my-w!
   0 0 my-space h# 0100.0020 + /regs  map-in to uhci-reg
;

: unmap-regs  ( -- )
   4 my-w@  7 invert and  4 my-w!
   uhci-reg  /regs  map-out  0 to uhci-reg
;

: uhci-b@  ( idx -- data )  uhci-reg + rb@  ;
: uhci-b!  ( data idx -- )  uhci-reg + rb!  ;
: uhci-w@  ( idx -- data )  uhci-reg + rw@  ;
: uhci-w!  ( data idx -- )  uhci-reg + rw!  ;
: uhci-l@  ( idx -- data )  uhci-reg + rl@  ;
: uhci-l!  ( data idx -- )  uhci-reg + rl!  ;

: usbcmd@     ( -- data )   0 uhci-w@  ;
: usbcmd!     ( data -- )   0 uhci-w!  ;
: usbsts@     ( -- data )   2 uhci-w@  ;
: usbsts!     ( data -- )   2 uhci-w!  ;
: usbintr@    ( -- data )   4 uhci-w@  ;
: usbintr!    ( data -- )   4 uhci-w!  ;
: frnum@      ( -- data )   6 uhci-w@  ;
: frnum!      ( data -- )   6 uhci-w!  ;
: flbaseadd@  ( -- data )   8 uhci-l@  ;
: flbaseadd!  ( data -- )   8 uhci-l!  ;
: sof@        ( -- data )   c uhci-b@  ;
: sof!        ( data -- )   c uhci-b!  ;
: portsc@     ( port -- data )  2* 10 + uhci-w@  ;
: portsc!     ( data port -- )  2* 10 + uhci-w!  ;

: ?disable-smis  ( -- )
   0 my-l@ h# 27c88086 =  if   h# af00 h# 80 my-w!  then
;

: reset-usb  ( -- )
   uhci-reg dup 0=  if  map-regs  then
   4 usbcmd!			\ Global reset
   50 ms
   0 usbcmd!
   10 ms

   2 usbcmd!			\ Host reset
   d# 10 0  do
      usbcmd@ 2 and  0=  ?leave
      1 ms
   loop
   0=  if  unmap-regs  then
;

: (process-hc-status)  ( -- )
   usbsts@ dup h# 3e and usbsts!	\ Clear errors and interrupts
   38 and ?dup  if
      usbcmd@ 1 or usbcmd!		\ Exit halted state
      dup 20 and  if  " Host controller halted"  USB_ERR_HCHALTED set-usb-error  then
      dup 10 and  if  " Host controller process error"  USB_ERR_HCERROR set-usb-error  then
           8 and  if  " Host system error"  USB_ERR_HOSTERROR set-usb-error  then
   then
;
' (process-hc-status) to process-hc-status

external
\ Kick the USB controller into operation mode.
: start-usb     ( -- )
   0 frnum!			\ Start at frame 0
   framelist-phys flbaseadd!
   h# c1 usbcmd!		\ Run, Config, Max Packet=64
;
: stop-usb  ( -- )  h# c0 usbcmd!  ;
: suspend-usb   ( -- )  ;

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
