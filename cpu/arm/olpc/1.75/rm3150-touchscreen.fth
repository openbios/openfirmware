\ See license at end of file
purpose: Driver and diagnostic for Raydium RM-3150 Multitouch I2C Touchscreen

0 0  " 4,60"  " /twsi" begin-package
my-space encode-int  my-address encode-int encode+  " reg" property
" touchscreen" name

: ts-b!  ( b reg# -- )  " smbus-b!" $call-parent  ;
: ts-b@  ( reg# -- b )  " smbus-b@" $call-parent  ;

d# 896 constant touchscreen-max-x
d# 672 constant touchscreen-max-y

: 4b>xy  ( x.hi x.lo  y.hi y.lo -- x y )  swap bwjoin >r  swap bwjoin r>  ;

: touchscreen-present?  ( -- flag )
   h# a ['] ts-b@ catch  if            ( x )   
      drop false exit                  ( -- false )
   then                                ( max-x.hi )
   \ It would be nice to read all four bytes in one SMBUS transaction,
   \ but that doesn't work for these register locations - the first
   \ one reads correctly, and subsequent ones read as 0.  You must
   \ read them individually to get the right answer.
   h# b ts-b@  h# c ts-b@  h# d ts-b@  ( max-x.hi max-x.lo max-y.hi max-y.lo )
   4b>xy                               ( max-x max-y )
   touchscreen-max-y =                 ( max-y flag )
   swap touchscreen-max-x =  and       ( flag' )
;

: open  ( -- okay? )
   my-unit " set-address" $call-parent
   touchscreen-present?  dup  if   ( okay? )
      0 1 ts-b!                    ( okay? )  \ Set to polled mode
   then                            ( okay? )
;
: close  ( -- )
   h# 82 1 ts-b!  \ Restore default interrupt mode
;

: pad-events  ( -- n*[ x.hi x.lo y.hi y.lo z ]  #contacts )
   d# 99 gpio-pin@  if  false exit  then
   h# 10 ts-b@   h# 7f and  >r                        ( r: #contacts )
   r@  if                                             ( r: #contacts )
      h# 11 1  r@ 5 *  " smbus-out-in" $call-parent   ( n*[ x.hi x.lo y.hi y.lo z ]  r: #contacts )
   then                                               ( n*[ x.hi x.lo y.hi y.lo z ]  r: #contacts )
   r>                                                 ( n*[ x.hi x.lo y.hi y.lo z ]  #contacts )
;

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


variable ptr

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

: scale-xy  ( x y -- x' y' )
   swap screen-w touchscreen-max-x */
   swap screen-h touchscreen-max-y */
;

0 [if]
\ Try to receive a mouse report packet.  If one arrives within
\ 20 milliseconds, return true and the decoded information.
\ Otherwise return false.
: pad?  ( -- false | x y z down? contact# true )
   get-touch?   if            ( x dy buttons )
      2>r >r scale-xy r> 2r>  ( x' y' z down? contact# )
      true
   else
      false
   then
;

\ Display raw data from the device, stopping when a key is typed.
: show-pad  ( -- )
   begin
      pad?  if  . . . . . cr  then
   key? until
;
[then]

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

: ?hit-target  ( -- )
   pixcolor @  cyan =   if  \ touch1              ( x y )
      2dup  left-target  inside?  if              ( x y )
         yellow left-target  fill-rectangle-noff  ( x y )
         true to left-hit?                        ( x y )
         exit
      then                                        ( x y )
   then                                           ( x y )
   pixcolor @ yellow =  if  \ touch2              ( x y )
      2dup  right-target  inside?  if             ( x y )
         yellow right-target  fill-rectangle-noff ( x y )
         true to right-hit?                       ( x y )
         exit
      then                                        ( x y )
   then                                           ( x y )
;

: track-init  ( -- )
   " dimensions" $call-screen  to screen-h  to screen-w
   screen-ih package( bytes/line )package  to /line
   load-base ptr !
;

: dot  ( x y -- )
   swap screen-w 3 - min  swap y-offset + screen-h 3 - min  ( x' y' )
   pixcolor @  -rot   3 3                   ( color x y w h )
   fill-rectangle-noff                      ( )
;

: background  ( -- )
   black  0 0  screen-w screen-h  fill-rectangle-noff
   final-test?  if
      false to left-hit?
      false to right-hit?
      draw-left-target
      draw-right-target
   else
      0 d# 27 at-xy  ." Touchscreen test.  Type a key to exit" cr
   then
;

: *3/5  ( n -- n' )  3 5 */  ;
: dimmer  ( color -- color' )
   565>rgb rot *3/5 rot *3/5 rot *3/5 rgb>565
;

: setcolor  ( contact# -- )
   case
      0  of  cyan    endof
      1  of  yellow  endof
      2  of  magenta endof
      3  of  blue    endof
      4  of  red     endof
      5  of  green   endof
      6  of  cyan    dimmer  endof
      7  of  yellow  dimmer  endof
      8  of  magenta dimmer  endof
      9  of  blue    dimmer  endof
  d# 10  of  red     dimmer  endof
  d# 11  of  green   dimmer  endof
      ( default )  white swap
   endcase

   pixcolor !         
;
0 value pressure

: track-n  ( .. xhi xlo yhi ylo z  #contacts -- )
   ?dup 0=  if  exit  then     ( .. xhi xlo yhi ylo z  #contacts -- )
   1-  0  swap  do             ( .. xhi xlo yhi ylo z )
      i setcolor               ( .. xhi xlo yhi ylo z )
      to pressure              ( .. xhi xlo yhi ylo )
      4b>xy  scale-xy          ( .. x y )

      final-test?  if          ( .. x y )
         ?hit-target           ( .. x y )
      then                     ( .. x y )
      dot
   -1 +loop
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

: discard-n  ( .. #events -- )   5 *  0  ?do  drop  loop  ;

: selftest  ( -- error? )
   open  0=  if
\     ." Touchscreen open failed"  true exit
      ." No touchscreen present" cr  false exit
   then

   \ Being able to open the touchpad is good enough in SMT mode
   smt-test?  if  close false exit  then

   final-test? 0=  if
      ." Touchscreen test will start in 4 seconds" cr
      d# 4000 ms
   then

   cursor-off  track-init

   \ Consume already-queued keys to prevent premature exit
   begin  key?  while  key drop  repeat

   \ Consume already-queued trackpad events to prevent premature exit
   begin  pad-events  ?dup  while  discard-n  repeat

   background
   begin
      ['] pad-events catch  ?dup  if  .error  close true exit  then
      track-n
   exit-test?  until

   close
   cursor-on
   page
   final-test?  if  selftest-failed?  else  false  then
;


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
