purpose: USB elaborations for the BIOS loaded OFW
\ See license at end of file

0 config-int usb-delay  \ Milliseconds to wait before set-address

devalias u    /usb/disk

\ Like $show-devs, but ignores pagination keystrokes
: $nopage-show-devs  ( nodename$ -- )
   ['] exit? behavior >r  ['] false to exit?
   $show-devs
   r> to exit?
;

: (probe-usb2)  ( -- )
   " device_type" get-property  if  exit  then
[ifdef] use-usb-debug-port
   \ I haven't figured out how to turn on the EHCI cleanly
   \ when the Debug Port is running
   dbgp-off
[then]
   get-encoded-string  " ehci" $=  if
      pwd$ open-dev  ?dup  if  close-dev  then
   then
;
: (show-usb2)  ( -- )
   " device_type" get-property  if  exit  then
   get-encoded-string  " ehci" $=  if
      pwd$ $nopage-show-devs
   then
;
: (probe-usb1)  ( -- )
   " device_type" get-property  if  exit  then
   get-encoded-string  2dup " uhci" $= >r  " ohci" $= r> or  if
      pwd$ open-dev  ?dup  if  close-dev  then
   then
;
: (show-usb1)  ( -- )
   " device_type" get-property  if  exit  then
   get-encoded-string  2dup " uhci" $= >r  " ohci" $= r> or  if
      pwd$ $nopage-show-devs
   then
;

: probe-usb  ( -- )
   ." USB2 devices:" cr
   " /" ['] (probe-usb2) scan-subtree
   " /" ['] (show-usb2) scan-subtree

   ." USB1 devices:" cr
   " /" ['] (probe-usb1) scan-subtree
   " /" ['] (show-usb1) scan-subtree

   report-disk
   report-net
   report-keyboard
;
alias p2 probe-usb

: ?usb-keyboard  ( -- )
   " usb-keyboard" expand-alias  if   ( devspec$ )
      drop " /usb"  comp  0=  if      ( )
         " usb-keyboard" open-dev add-input
         exit
      then
   else                               ( devspec$ )
      2drop
   then
   " /usb/serial" open-dev  ?dup  if
      add-input
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

: usb-quiet  ( -- )
   [ ' go-hook behavior compile, ]    \ Chain to old behavior
   " /usb@10,0" " reset-usb" execute-device-method drop
   " /usb@10,1" " reset-usb" execute-device-method drop
   " /usb@10,2" " reset-usb" execute-device-method drop
   " /usb@10,4" " reset-usb" execute-device-method drop
;
' usb-quiet to go-hook

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
