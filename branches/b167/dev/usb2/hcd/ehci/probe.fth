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

external
: power-usb-ports  ( -- )  ;

: probe-usb  ( -- )
   alloc-pkt-buf
   hcsparams@ h# f and 0  ?do				\ For each port
      i portsc@ 1 and  if				\ A device is connected
         i portsc@ h# c00 and h# 400 =  if		\ A low speed device detected
	    i disown-port				\ Disown the port
         else						\ Don't know what it is
            i reset-port				\ Reset to find out
            i portsc@ 4 and  0=  if			\ A full speed device detected
	       i disown-port				\ Disown the port
            else					\ A high speed device detected
               i ['] make-root-hub-node catch  if	\ Process high speed device
                  ." Failed to probe root port " i .d cr
               then
            then
         then
      then
   loop
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
