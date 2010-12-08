purpose: USB Hub Probing Code
\ See license at end of file

hex

[ifndef] set-usb20-char
: set-usb20-char  ( port dev -- )  2drop  ;
[then]

: power-hub-port   ( port -- )      PORT_POWER  DR_PORT set-feature drop  ;
: reset-hub-port   ( dev port -- )  PORT_RESET  DR_PORT set-feature drop  d# 20 ms  ;

: probe-hub-port  ( hub-dev port -- )
   swap set-target			( port )
   dup reset-hub-port			( port )

   gen-desc-buf 4 2 pick DR_PORT get-status nip  if
      ." Failed to get port status for port " u. cr
      exit
   then					( port )

   gen-desc-buf c@ 1 and 0=  if	 drop exit  then	\ No device connected
   ok-to-add-device?     0=  if  drop exit  then	\ Can't add another device

   new-address				( port dev )
   gen-desc-buf le-w@ h# 600 and 9 >> over di-speed!
					( port dev )
   2dup set-usb20-char			( port dev )

   0 set-target				( port dev )	\ Address it as device 0
   dup set-address  if  2drop exit  then ( port dev )	\ Assign it usb addr dev
   dup set-target			( port dev )	\ Address it as device dev
   make-device-node			( )
;

external
: probe-hub  ( dev -- )
   dup set-target			( hub-dev )
   gen-desc-buf 8 0 0 HUB DR_HUB get-desc nip  if
      ." Failed to get hub descriptor" cr
      exit
   then

   gen-desc-buf dup 5 + c@ swap		( hub-dev #2ms adr )
   2 + c@ 1+				( hub-dev #2ms #ports )

   " configuration#" get-int-property set-config	( hub-dev #2ms #ports usberr )
   if  2drop  ." Failed to set config for hub at " u. cr exit  then

   tuck  1  ?do  i power-hub-port  loop  2* ms
					( hub-dev #ports )
   " usb-delay" ['] evaluate catch  if  ( hub-dev #ports x x )
      2drop  d# 100                     ( hub-dev #ports ms )
   then                                 ( hub-dev #ports ms )
   ms

   ( hub-dev #ports ) 1  ?do
      dup i ['] probe-hub-port  catch  if
         2drop
         ." Failed to probe hub port " i u. cr
      then
   loop  drop
;

: probe-hub-xt  ( -- adr )  ['] probe-hub  ;

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
