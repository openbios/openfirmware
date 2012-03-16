\ See license at end of file
purpose: Common code for touchscreen drivers and diags

" touchscreen" name

true value absolute?

0 value touchscreen-max-x
0 value touchscreen-max-y

0 value screen-w
0 value screen-h

0 value #contacts

\ External interface method
: dimensions  ( -- w h )  screen-w  screen-h  ;

0 instance value invert-x?
0 instance value invert-y?

: set-geometry  ( -- )
   " dimensions" $call-screen  to screen-h  to screen-w

   \ The "TI" tag controls the inverson of X and Y axes.
   \ If the tag is missing, axes are not inverted.  If present
   \ and the value contains either of the letters x or y, the
   \ corresponding axis is inverted.  This is primarily for
   \ development, using prototype touchscreens.
   " TI" find-tag  if     ( adr len )
      begin  dup  while   ( adr len )
         over c@  upc  [char] x =  if  true to invert-x?  then
         over c@  upc  [char] y =  if  true to invert-y?  then
         1 /string        ( adr' len' )
      repeat              ( adr len )
      2drop               ( )
   then                   ( )
;

: scale-x  ( x -- x' )
   invert-x?  if  touchscreen-max-x swap -  then
   screen-w touchscreen-max-x */
;
: scale-y  ( y -- y' )
   invert-y?  if  touchscreen-max-y swap -  then
   screen-h touchscreen-max-y */
;

: scale-xy  ( x y -- x' y' )  swap scale-x  swap scale-y  ;


h# f800 constant red
h# 07e0 constant green
h# 001f constant blue
h# ffe0 constant yellow
h# f81f constant magenta
h# 07ff constant cyan
h# ffff constant white
h# 0000 constant black

variable pixcolor

: *3/5  ( n -- n' )  3 5 */  ;
: dimmer  ( color -- color' )
   565>rgb rot *3/5 rot *3/5 rot *3/5 rgb>565
;

h# 4 value y-offset

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

: dot  ( x y -- )
   swap screen-w 3 - min  swap y-offset + screen-h 3 - min  ( x' y' )
   pixcolor @  -rot   3 3                   ( color x y w h )
   fill-rectangle-noff                      ( )
;

: undot  ( -- )  pixcolor @  dup dimmer  " replace-color" $call-screen  ;

: background  ( -- )
   black  0 0  screen-w screen-h  fill-rectangle-noff
   targets?  if
      false to left-hit?
      false to right-hit?
      draw-left-target
      draw-right-target
   else
      .tsmsg
   then
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

false value selftest-failed?  \ Success/failure flag for final test mode
: exit-test?  ( -- flag )
   targets?  if                       ( )
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
   key?  dup  if  key drop  then      ( exit? )
;

0 value pressure

\ LICENSE_BEGIN
\ Copyright (c) 2012 FirmWorks
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
