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

: probe-usb  ( -- )
   ." USB2 devices:" cr
   " /usb@1d,7" open-dev  ?dup  if  close-dev  then
   " /usb" $nopage-show-devs

   ." USB1 devices:" cr
   " /usb@1d,3" open-dev  ?dup  if  close-dev  then
   " /usb@1d,3" $nopage-show-devs
   " /usb@1d,2" open-dev  ?dup  if  close-dev  then
   " /usb@1d,2" $nopage-show-devs
   " /usb@1d,1" open-dev  ?dup  if  close-dev  then
   " /usb@1d,1" $nopage-show-devs
   " /usb@1d,0" open-dev  ?dup  if  close-dev  then
   " /usb@1d,0" $nopage-show-devs
;
alias p2 probe-usb

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

: usb-quiet  ( -- )
   [ ' go-hook behavior compile, ]    \ Chain to old behavior
   " usb1" " reset-usb" execute-device-method drop
   " usb2" " reset-usb" execute-device-method drop
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
