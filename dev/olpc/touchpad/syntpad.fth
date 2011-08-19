\ See license at end of file
\ Add this code to the existing mouse driver

h# f800 constant red
h# 07e0 constant green
h# 001f constant blue
h# ffe0 constant yellow
h# f81f constant magenta
h# 07ff constant cyan
h# ffff constant white
h# 0000 constant black

variable pixcolor

h# 4 value y-offset
0 value screen-w
0 value screen-h
0 value /line
2 value /pixel


\ This program depends on the following routines from the
\ existing Open Firmware mouse driver:

\ open            initializes the port and resets the device
\ mouse2:1        command e7
\ stream-on       command f4
\ stream-mode     command ea,f4
\ mouse-status    command e9 and reads 3 response bytes
\ stream-poll?    ( -- false | dx dy buttons true )

variable ptr

\ The Synaptics touchpad version is 64.02.30

: touchpad-id  ( -- n )
   mouse2:1 mouse2:1 mouse2:1 mouse-status  ( 30 02 64 )
   0 bljoin
;

\ Put the device into streaming mode and enable it
: start  ( -- )
   stream-mode
;

0 value hw-cursor?
defer move-hw-cursor  ( x y -- )
' 2drop to move-hw-cursor
0 0 2value saved-cursor-fgbg

: setup-hw-cursor  ( -- )
   " cursor-xy!" screen-ih ihandle>phandle  find-method  if
      to move-hw-cursor
      " cursor-fgbg@" $call-screen  to saved-cursor-fgbg
      arrow-cursor h# ff00ff h# 00ff00  " set-cursor-image" $call-screen
      true to hw-cursor?
   else
      false to hw-cursor?
   then
;

\ The following code receives and decodes touchpad packets

: show-packets  ( adr len -- )
   push-hex
   bounds  ?do
      i 6  bounds  ?do  i c@  3 u.r  loop  cr
   6 +loop
   pop-base
;
: last-10  ( -- )
   ptr @  load-base -  d# 60  >  if
      ptr @  d# 60 -  d# 60
   else
      load-base  ptr @  over -
   then
   show-packets
;

variable mouse-x
variable mouse-y

: mouse-xy  ( -- x y )  mouse-x @  mouse-y @  ;

: clipx  ( delta -- x )  mouse-x @ +  0 max  screen-w 1- min  dup mouse-x !  ;
: clipy  ( delta -- y )  mouse-y @ +  0 max  screen-h 1- min  dup mouse-y !  ;

: rel>abs  ( dy dy buttons -- x y buttons )
   >r                                ( dx dy )
   swap clipx  swap negate clipy     ( x y )
   r>                                ( buttons )
;

\ Try to receive a mouse report packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: pad?  ( -- false | x y buttons true )
   stream-poll?   if    ( dx dy buttons )
      rel>abs true
   else
      false
   then
;

\ Display raw data from the device, stopping when a key is typed.
: show-pad  ( -- )
   start
   begin
      pad?  if  . . . cr  then
   key? until
;

: button  ( color x -- )
   screen-h d# 50 -  d# 200  d# 30  fill-rectangle-noff
;
d# 300 d# 300 2constant target-wh
: left-target   ( -- x y w h )  0 0  target-wh  ;
: right-target  ( -- x y w h )  screen-w screen-h  target-wh  xy-  target-wh  ;
false value left-hit?
false value right-hit?
: inside?  ( mouse-x,y  x y w h -- flag )
   >r >r         ( mouse-x mouse-y  x y  r: h w )
   xy-           ( dx dy )
   swap r> u<    ( dy x-inside? )
   swap r> u<    ( x-inside? y-inside? )
   and           ( flag )
;

: draw-left-target  ( -- )  green  left-target   fill-rectangle-noff  ;
: draw-right-target ( -- )  red    right-target  fill-rectangle-noff  ;
: ?hit-target  ( but -- but )
   dup 1 and  if  \ Left                          ( but )
      mouse-xy  left-target  inside?  if          ( but )
         yellow left-target  fill-rectangle-noff  ( but )
         true to left-hit?                        ( but )
         exit
      then                                        ( but )
   then                                           ( but )
   dup 4 and  if  \ Right                         ( but )
      mouse-xy  right-target  inside?  if         ( but )
         yellow right-target  fill-rectangle-noff ( but )
         true to right-hit?                       ( but )
         exit
      then                                        ( but )
   then                                           ( but )
;

: track-init  ( -- )
   " dimensions" $call-screen  to screen-h  to screen-w
   screen-w 2/ mouse-x !  screen-h 2/ mouse-y !
   screen-ih package( bytes/line )package  to /line
   load-base ptr !
   setup-hw-cursor
;

: dot  ( x y -- )
   swap screen-w 3 - min  swap y-offset + screen-h 3 - min  ( x' y' )
   2dup move-hw-cursor                      ( )
   pixcolor @  -rot   3 3                   ( color x y w h )
   fill-rectangle-noff                      ( )
;

: restore-bg  ( -- )
   background  0 0  screen-w screen-h  fill-rectangle-noff
;
: background  ( -- )
   black  0 0  screen-w screen-h  fill-rectangle-noff
   final-test?  if
      false to left-hit?
      false to right-hit?
      draw-left-target
      draw-right-target
   else
      0 d# 27 at-xy  ." Touchpad test.  Both buttons clears screen.  Type a key to exit"
   then
   mouse-xy dot
;

: track  ( x y buttons -- )
   cyan  pixcolor !               ( x y but )

   dup 5 and 5 =  if  background  load-base ptr !  then

   final-test?  if                ( x y but )
      ?hit-target                 ( x y but )
   else                           ( x y but )
      dup  1 and  if  green  else  black  then  d# 100 button
      dup  4 and  if  red    else  black  then  d# 350 button  ( x y but )
   then                           ( x y but )
   drop                           ( x y )

   dot
;

: handle-key  ( -- exit? )
   key upc  case
      [char] P  of
         cursor-on
         cr last-10
         key drop
         background
         false
      endof

      [char] S  of  suspend stream-on false  endof

      ( key )  true swap
   endcase
;

false value selftest-failed?  \ Success/failure flag for final test mode
: exit-test?  ( -- flag )
   final-test?  if                    ( )
      \ If the targets have been hit, we exit with successa
      left-hit? right-hit? and  if    ( )
         false to selftest-failed?    ( )
         true                         ( flag )
         exit
      then                            ( )

      \ Otherwise we give the tester a chance to bail out by typing a key,
      \ thus indicating failure
      key?  0=  if  false exit  then  ( )
      key drop                        ( )
      true to selftest-failed?        ( )
      true                            ( flag )
      exit
   then                               ( )

   \ If not final test mode, we only exit via a key - no targets
   key?  if  handle-key  else  false  then  ( exit ? )
;
: selftest  ( -- error? )
   open  0=  if  ." PS/2 Mouse (trackpad) open failed"  true exit  then

   \ Being able to open the touchpad is good enough in SMT mode
   smt-test?  if  close false exit  then

   final-test? 0=  if
      ." Touchpad test will start in 4 seconds" cr
      d# 4000 ms
   then

   cursor-off  track-init  start

   \ Consume already-queued keys to prevent premature exit
   begin  key?  while  key drop  repeat

   background
   begin
      ['] pad? catch  ?dup  if  .error  close true exit  then
      if  track  then
   exit-test?  until

   hw-cursor?  if
      " cursor-off" $call-screen
      saved-cursor-fgbg " cursor-fgbg!" $call-screen
   then
   close
   cursor-on
   restore-bg page
   final-test?  if  selftest-failed?  else  false  then
;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
