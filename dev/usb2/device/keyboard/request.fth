purpose: USB HID requests
\ See license at end of file

hex
headers

\ >dr-request constants specific to HID
h# 01 constant GET_REPORT
h# 02 constant GET_IDLE
h# 03 constant GET_PROTOCOL
h# 09 constant SET_REPORT
h# 0a constant SET_IDLE
h# 0b constant SET_PROTOCOL

\ >dr-value constants specific to HID
h# 0100 constant REPORT_IN
h# 0200 constant REPORT_OUT
h# 0300 constant REPORT_FEATURE

\ Keyboard report and LED buffers
8 constant /kbd-buf
1 constant /led-buf
0 value kbd-buf
0 value led-buf

: init-kbd-buf  ( -- )
   kbd-buf 0=  if
      /kbd-buf /led-buf + dma-alloc
      dup to kbd-buf /kbd-buf + to led-buf
   then
;
: free-kbd-buf  ( -- )
   kbd-buf  if
      kbd-buf /kbd-buf /led-buf + dma-free
      0 to kbd-buf 0 to led-buf
   then
;

: set-boot-protocol  ( -- error? )
   0 0 my-address ( interface ) 0 DR_HIDD DR_OUT or SET_PROTOCOL
   control-set-nostat
;

: set-idle  ( ms -- error? )
   >r 0 0 my-address ( interface ) r> 4 / 8 << ( 4ms ) DR_HIDD DR_OUT or SET_IDLE 
   control-set-nostat
;

\ Key modifiers

0 value    led-state
1 constant led-mask-num-lock
2 constant led-mask-caps-lock
4 constant led-mask-scroll-lock

: numlk?        ( -- flag )  led-state led-mask-num-lock    and  0<>  ;
: caps-lock?    ( -- flag )  led-state led-mask-caps-lock   and  0<>  ;
: scroll-lock?  ( -- flag )  led-state led-mask-scroll-lock and  0<>  ;


\ Keyboard LEDs

: (set-leds)  ( led -- )
   led-buf c!
   led-buf /led-buf my-address ( interface ) REPORT_OUT DR_HIDD DR_OUT or SET_REPORT
   control-set-nostat  drop
;
: set-leds     ( led-mask -- )  dup to led-state (set-leds)  ;
: toggle-leds  ( led-mask -- )  led-state xor    set-leds    ;


\ Retrieve usb keyboard report data.

: begin-scan  ( -- )
   kbd-buf /kbd-buf intr-in-pipe intr-in-interval  begin-intr-in
;
: end-scan  ( -- )  end-intr-in  ;

: get-data?  ( adr len -- actual )
   intr-in?  if  nip nip restart-intr-in exit  then	\ USB error; restart
   ?dup  if				( adr len actual )
      min tuck kbd-buf -rot move	( actual )
      restart-intr-in			( actual )
   else
      2drop 0				( actual )
   then
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
