purpose: EHCI USB Controller probe
\ See license at end of file

hex
headers

: make-root-hub-node  ( port -- )
   ok-to-add-device? 0=  if  drop exit  then		\ Can't add another device

   new-address				( port dev )
   speed-high over di-speed!		( port dev )

   0 set-target				( port dev )	\ Address it as device 0
   dup set-address  if  2drop exit  then ( port dev )	\ Assign it usb addr dev
   dup set-target			( port dev )	\ Address it as device dev
   make-device-node			( )
;

: probe-root-hub-port  ( port -- )
   dup portsc@ 1 and 0=  if  drop exit  then	\ No device detected
   dup portsc@ h# c00 and h# 400 =  if		\ A low speed device detected
      dup disown-port				\ Disown the port
   else						\ Don't know what it is
      dup reset-port				\ Reset to find out
      dup portsc@ 4 and  0=  if			\ A full speed device detected
	 dup disown-port			\ Disown the port
      else					\ A high speed device detected
         dup ['] make-root-hub-node catch  if	\ Process high speed device
            drop ." Failed to probe root port " dup .d cr
         then
      then
   then  drop
;

external
: power-usb-ports  ( -- )  ;

: probe-usb  ( -- )
   alloc-pkt-buf
   hcsparams@ h# f and 0  ?do			\ For each port
      i probe-root-hub-port			\ Probe it
      i portsc@ i portsc!			\ Clear connection change bit
   loop
   free-pkt-buf
;

: reprobe-usb  ( xt -- )
   alloc-pkt-buf
   hcsparams@ h# f and 0  ?do			\ For each port
      i portsc@ 2 and  if			\ Connection changed
         i over execute				\ Remove obsolete device nodes
         i probe-root-hub-port			\ Probe it
         i portsc@ i portsc!			\ Clear connection change bit
      then
   loop  drop
   free-pkt-buf
;

headers

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
