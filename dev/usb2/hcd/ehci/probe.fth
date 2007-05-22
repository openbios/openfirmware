purpose: EHCI USB Controller probe
\ See license at end of file

hex
headers

: retry-set-address  ( dev -- error? )
   d# 200 ms
   d# 5  0  do
      dup  set-address  0=  if  drop false  unloop exit  then
      d# 1000
   loop   
   drop true
;

: make-root-hub-node  ( port -- )
   ok-to-add-device? 0=  if  drop exit  then		\ Can't add another device

   new-address				( port dev )
   speed-high over di-speed!		( port dev )

   0 set-target				( port dev )	\ Address it as device 0

   dup retry-set-address  if  2drop exit  then ( port dev )	\ Assign it usb addr dev
\ d# 4000 ms
\   dup set-address  if  2drop exit  then ( port dev )	\ Assign it usb addr dev

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

: probe-root-hub  ( -- )
   \ Set active-package so device nodes can be added and removed
   my-self ihandle>phandle push-package

   alloc-pkt-buf
   #ports 0  ?do			        \ For each port
      i portsc@ 2 and  if			\ Connection changed
         i rm-obsolete-children			\ Remove obsolete device nodes
         i probe-root-hub-port			\ Probe it
         i portsc@ i portsc!			\ Clear connection change bit
      then
   loop
   free-pkt-buf

   pop-package
;

: open  ( -- flag )
   parse-my-args
   open-count 0=  if
      map-regs
      first-open?  if
         false to first-open?
         0 ehci-reg@  h# ff and to op-reg-offset
         reset-usb
         init-ehci-regs
         start-usb
         claim-ownership
         init-struct
         init-extra
      then
      alloc-dma-buf

      probe-root-hub
   then
   open-count 1+ to open-count
   true
;

: resume  ( -- )
   init-ehci-regs
   start-usb
   claim-ownership
   framelist-phys periodic!
;

: close  ( -- )
   open-count 1- to open-count
   end-extra
   open-count 0=  if  free-dma-buf unmap-regs  then
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
