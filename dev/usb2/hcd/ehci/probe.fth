purpose: EHCI USB Controller probe
\ See license at end of file

hex
headers

: make-root-hub-node  ( port -- )
   ok-to-add-device? 0=  if  drop exit  then		\ Can't add another device

   0 set-target				( port )	\ Address it as device 0

   speed-high 0 di-speed!     \ Use high speed for getting the device descriptor
   \ Some devices (e.g. Lexar USB-to-SD) don't work unless you do this first
   dev-desc-buf h# 40 get-cfg-desc drop

   new-address				( port dev )
   speed-high over di-speed!		( port dev )

   0 set-target				( port dev )	\ Address it as device 0

   dup set-address  if			( port dev )	\ Assign it usb addr dev
      ." Retrying with a delay" cr
      over reset-port  d# 5000 ms
      dup set-address  if		( port dev )	\ Assign it usb addr dev
         2drop exit
      then
   then ( port dev )

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

: grab-controller  ( -- error? )
   hccparams@ 8 rshift h# ff and  dup  if    ( config-adr )
      dup my-l@  h# 10001 =  if              ( config-adr )
         h# 100.0000 over my-l!              ( config-adr )  \ Ask for it
         true                                ( config-adr error? )
         d# 100 0  do                        ( config-adr error? )
            over my-l@ h# 101.0000 and  h# 100.0000 =  if
               \ Turn off SMIs in Legacy Support Extended CSR
               h# e000.0000 h# 6c my-l!      ( config-adr error? )
               0 my-l@ h# 27cc8086 =  if
                  h# ffff.0000  h# 70  my-l!  \ Clear EHCI Intel special SMIs
               then
               0= leave                      ( config-adr error?' )
            then                             ( config-adr error? )
            d# 10 ms                         ( config-adr error? )
         loop                                ( config-adr error? )
         nip exit
      then                                   ( config-adr )
   then                                      ( config-adr )
   drop                                      ( )
   false
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
      alloc-dma-buf
      first-open?  if
         false to first-open?
         grab-controller  if
            ." Can't take control of EHCI from underlying BIOS" cr
            free-dma-buf unmap-regs
            false exit
         then
         0 ehci-reg@  h# ff and to op-reg-offset
         reset-usb
         init-ehci-regs
         start-usb
         claim-ownership
         init-struct
         init-extra
      then
      probe-root-hub
   then
   open-count 1+ to open-count
   true
;

: do-resume  ( -- )
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
