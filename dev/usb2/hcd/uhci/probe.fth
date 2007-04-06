purpose: UHCI USB Controller probe
\ See license at end of file

hex
headers

: reset-root-hub-port  ( port -- )
   dup >r portsc@ fff5 and 200 or r@ portsc!	\ Reset port
   10 ms
   r@ portsc@ fff5 and 200 invert and r@ portsc!
   10 ms
   r@ portsc@ fff5 and 4 or r@ portsc!		\ Enable port
   20 ms
   r@ portsc@ a or r> portsc!			\ Clear status
;

: probe-root-hub-port  ( port -- )
   dup portsc@ 1 and 0=  if  drop exit  then		\ No device-connected
   ok-to-add-device? 0=  if  drop exit  then		\ Can't add another device

   new-address				( port dev )
   over portsc@ 100 and  if  speed-low  else  speed-full  then
   over di-speed!			( port dev )

   0 set-target				( port dev )    \ Address it as device 0
   dup set-address  if  2drop exit  then ( port dev )	\ Assign it usb addr dev
   dup set-target			( port dev )    \ Address it as device dev
   make-device-node			( )
;

external
: power-usb-ports  ( -- )  ;

: probe-usb  ( -- )
   alloc-pkt-buf
   2 0  do
      i reset-root-hub-port
      i ['] probe-root-hub-port catch  if
         drop ." Failed to probe root port " i .d cr
      then
      i portsc@ i portsc!			\ Clear change bits
   loop
   free-pkt-buf
;

: reprobe-usb  ( -- )
   alloc-pkt-buf
   2 0  do
      i portsc@ h# a and  if
         i rm-obsolete-children			\ Remove obsolete device nodes
         i reset-root-hub-port
         i ['] probe-root-hub-port catch  if
            drop ." Failed to probe root port " i .d cr
         then
         i portsc@ i portsc!			\ Clear change bits
      then
   loop
   free-pkt-buf
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
