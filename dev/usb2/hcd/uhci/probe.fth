purpose: UHCI USB Controller probe
\ See license at end of file

hex
headers

: probe-root-hub-port  ( port -- )
   \ Reset the port to perform connection status and speed detection
   dup reset-port				( port )
   dup portsc@ 1 and 0=  if  drop exit  then	( port )	\ No device-connected

   dup portsc@ 100 and  if  speed-low  else  speed-full  then	( port speed )

   \ hub-port and hub-speed are irrelevant for UHCI (USB 1.1)
   0 0							( port speed hub-port hub-dev )

   \ Execute setup-new-node in root context and make-device-node in hub node context
   setup-new-node  if  execute  then			( )
;

external
: power-ports  ( -- )  ;

: probe-root-hub  ( -- )
   \ Set active-package so device nodes can be added and removed
   my-self ihandle>phandle push-package

   alloc-pkt-buf
   2 0  do
      i portsc@ h# a and  if
\        i rm-obsolete-children			\ Remove obsolete device nodes
         i ['] probe-root-hub-port catch  if
            drop ." Failed to probe root port " i .d cr
         then
         i portsc@ i portsc!			\ Clear change bits
      else
         i port-is-hub?  if     ( phandle )     \ Already-connected hub?
            reprobe-hub-node                    \ Check for changes on its ports
         then
      then
   loop
   free-pkt-buf

   pop-package
;

: do-resume  ( -- )
   init-struct
   start-usb
;

\ This is a sneaky way to determine if the hardware has been turned off without the software's knowledge
: suspended?  ( -- flag )  flbaseadd@ 0=  framelist-phys 0<>  and  ;

: open  ( -- flag )
   parse-my-args
   open-count 0=  if
      map-regs
      first-open?  if
         false to first-open?
         ?disable-smis
         reset-usb
         init-lists
         do-resume
      then

      suspended?  if  do-resume  then

      alloc-dma-buf

      probe-root-hub
   then
   open-count 1+ to open-count
   true
;

: close  ( -- )
   open-count 1- to open-count
   end-extra
   open-count 0=  if  free-dma-buf  then  \ Don't unmap
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
