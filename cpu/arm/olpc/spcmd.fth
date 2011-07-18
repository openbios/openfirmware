\ See license at end of file
purpose: Communication protocol for application processor to security processor

\ Interface from pckbd.fth to i8042.fth:
\   set-port  ( port# -- )  \ Selects keyboard (port#=0) or mouse (port#=1)
\   get-data  ( -- data | -1 )  \ Returns a keyboard or mouse byte, or -1 if none after one second
\   get-data?  ( -- false | data true )  \ Non-blocking version of get-data
\   clear-out-buf  ( -- )  \ Drains pending data, waiting until 120 ms elapses with no data.  Built from get-data?
\   put-get-data  ( cmd -- data | -1 )   \ Sends cmd and waits for one response byte
\         Used only by "echo?", which is not called on OLPC.
\   put-data  ( data -- )  \ Sends a byte to the keyboard or mouse
\         Used only by "cmd".  "cmd" is used by set-scan-set, default-disable-kbd, enable-scan, set-leds, toggle-leds,
\         kbd-reset, (obsolete) olpc-set-ec-keymap.  set-scan-set is used only by commented-out code guarded by
\         the non-defined ifdef "fix-keyboard".  default-disable-kbd is called only by get-initial-state (NC on OLPC).
\         enable-scan is NC on OLPC.  set-leds is called by toggle-leds with is called when you press numlock or
\         scrolllock or capslock, none of which the OLPC keyboard has.

0 0  " d4290000"  " /" begin-package   	\ AP-SP interface the WTM command queue

headerless

" ap-sp"     device-name

0 0 encode-bytes
   " olpc,ap-sp"  encode-string encode+
" compatible" property

my-address      my-space  h# 1000  encode-reg
" reg" property

1 " #address-cells"  integer-property
0 " #size-cells"     integer-property

: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;

\ Channel#(port#) Meaning
\ 0              Keyboard
\ 1              Touchpad

2 constant #ports
#ports constant #queues

d# 64 constant /q

0 value queue#
#queues /n* buffer: heads  : head  ( -- adr )  heads queue# na+  ;
#queues /n* buffer: tails  : tail  ( -- adr )  tails queue# na+  ;

#queues /q * buffer: qs    : q  ( adr -- )  qs queue# /q * +  ;

/q 1- value   q-end

: init-queues  ( -- )
   #queues  0  do
      i to queue#
      0 head !  0 tail !   /q 1- to q-end
   loop
;
: inc-q-ptr  ( pointer-addr -- )
   dup @ q-end >=  if  0 swap !  else  /c swap +!  then
;

false value locked?		  \ Interrupt lockout for get-scan

: lock    ( -- )  true  to locked?  ;
: unlock  ( -- )  false to locked?  ;

: select-queue  ( channel# -- error? )
   to queue#
   queue# #queues >=
;

: enque  ( new-entry channel# -- )
   select-queue  if  drop exit  then   ( new-entry )
   tail @  head @  2dup >  if  - q-end  else  1-  then  ( new-entry tail head )
   <>  if  q tail @ ca+ c!  tail inc-q-ptr  else  drop  then
;

: deque?  ( channel# -- false | entry true )
   lock
   select-queue  if  unlock false exit  then
   head @  tail @  <>  if
      q head @ ca+ c@   head inc-q-ptr  true
   else
      false
   then
   unlock
;

0 value reg-base
: reg@  ( offset -- l )  reg-base + rl@  ;
: reg!  ( l offset -- )  reg-base + rl!  ;

: data?  ( -- flag )  h# c8 reg@ 1 and  ;
: send-rdy  ( -- )  h# ff00 h# 40 reg!  ;

: poll  ( -- )
   begin  data?  while
      h# 80 reg@ wbsplit enque
      1 h# c8 reg!
      send-rdy
   repeat
;

0 instance value port#
: set-port  ( port# -- )  to port#  ;
: get-data?  ( -- false | data true )
   locked?  if  false exit  then
   lock
   port# deque?     ( false | data true )
   poll
   unlock
;
: get-data  ( -- data | -1 )  \ Wait for data from our device
   d# 1000 0  do
      get-data?  if  unloop exit  then		( data )
      1 ms
   loop
   true \ abort" Timeout waiting for data from device" 
;
\ Wait until the device stops sending data
: clear-out-buf  ( -- )  begin  d# 120 ms  get-data?  while  drop  repeat  ;

0 value open-count
: open  ( -- flag )
   open-count  0=  if
      my-address my-space  h# 1000  " map-in" $call-parent  is reg-base
      data? 0=  if  send-rdy  then
   then
   open-count 1+ to open-count
   true
;
: close  ( -- )
   open-count 1 =  if
      reg-base h# 1000  " map-out" $call-parent  0 is reg-base
   then
   open-count 1- 0 max to open-count
;

: put-data  ( byte -- )
   get-msecs  d# 100 +        ( byte time-limit )
   begin                      ( byte time-limit )
      dup get-msecs - 0<  if  ( byte time-limit )
	 2drop exit           ( -- )
      then                    ( byte time-limit )
      h# c4 reg@  7 and 0=    ( byte time-limit flag ) 
   until                      ( byte time-limit )
   drop                       ( byte )
   port# bwjoin h# 40 reg!    ( )
;
: put-get-data  ( cmd -- data | -1 )  put-data get-data  ;

new-device
   " "  " 0" set-args
   fload ${BP}/dev/pckbd.fth
finish-device

new-device
   " "  " 1" set-args
   fload ${BP}/dev/ps2mouse.fth
finish-device

end-package

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
