purpose: Display test
\ See license at end of file

dev /display

d# 100 constant bar-int
h# 7 constant test-colors16-mask
create test-colors16
\  white  magenta   yellow  red     green    blue    cyan    black
   ffff w, f81f w,  ffe0 w, f800 w, 07e0 w,  001f w, 07ff w, 0000 w,

: fill-rect  ( -- )  " fill-rectangle" $call-screen  ;

: whole-screen  ( -- x y w h )  0 0 dimensions  ;

: black-screen  ( -- )  0  whole-screen  fill-rect  ;

: test-color16  ( n -- color )
   test-colors16 swap bar-int / test-colors16-mask and wa+ w@
;
: .horizontal-bars16  ( -- )
   dimensions				( width height )
   0  ?do				( width )
      i test-color16 0 i 3 pick bar-int fill-rect
   bar-int +loop  drop
;
: .vertical-bars16  ( -- )
   dimensions				( width height )
   swap 0  ?do				( height )
      i test-color16 i 0 bar-int 4 pick fill-rect
   bar-int +loop  drop
;

instance variable rn            	\ Random number
d# 5,000 constant burnin-time		\ 5 seconds

: random  ( -- n )
   rn @  d# 1103515245 *  d# 12345 +   h# 7FFFFFFF and  dup rn !
;

: randomize-color  ( -- c )
   random h# 1f and d# 11 <<
   random h# 3f and d#  5 << or
   random h# 1f and          or
;
: randomize-xy  ( -- x y )
   dimensions				( width height )
   random 3ff and min swap		( y width )
   random 7ff and min swap		( x y )
;
: randomize-wh  ( x y -- w h )
   dimensions				( x y width height )
   rot - -rot				( max-h x width )
   swap - swap				( max-w max-h )
   randomize-xy				( max-w max-h w h )
   rot min -rot min swap		( w' h' )
;
: .random-rect  ( -- )
   randomize-color			( c )
   randomize-xy				( c x y )
   2dup randomize-wh			( c x y w h )
   " fill-rectangle" $call-screen	( )
;

: random-selftest  ( -- )
   get-msecs rn !
   get-msecs burnin-time +    ( limit )
   begin
      get-msecs over u<       ( limit reached? )
   while                      ( limit )
      .random-rect            ( limit )
      key?  if  key 2drop exit  then
   repeat                     ( limit )
   drop
;

0 value xbias
0 value ybias
0 value hstripe
0 value vstripe
: set-stripes  ( -- )
   width  d# 256 /  to hstripe
   height d# 256 /  to vstripe
   width  hstripe d# 256 * -  to xbias
   height vstripe d# 256 * -  to ybias
;
: gvsr  ( -- )
   set-stripes  black-screen   ( )
   d# 256 0  do                ( )
      d# 256 0  do             ( )
         i j 0 rgb>565         ( color )
         hstripe i * xbias +   ( color x )
         vstripe j * ybias +   ( color x y )
         hstripe vstripe       ( color x y )
         fill-rect
      loop
   loop
;
: gvsb  ( -- )
   set-stripes  black-screen   ( )
   d# 256 0  do                ( )
      d# 256 0  do             ( )
         0 j i rgb>565         ( color )
         hstripe i * xbias +   ( color x )
         vstripe j * ybias +   ( color x y )
         hstripe vstripe       ( color x y )
         fill-rect
      loop
   loop
;
: hgradient  ( -- )
   set-stripes  black-screen   ( )
   d# 256 0  do                ( )
      i i i rgb>565            ( color )
      hstripe i * xbias +  0   ( color x y )
      hstripe  height          ( color x y sw h )
      fill-rect                ( )
   loop                        ( )
;

: vgradient  ( -- )
   set-stripes  black-screen   ( )
   d# 256 0  do                ( )
      i i i rgb>565            ( color )
      0  vstripe i * ybias +   ( color x y )
      width  vstripe           ( color x y w sh )
      fill-rect                ( )
   loop                        ( )
;


h# ff h# ff h# ff rgb>565 constant white-color

: hline  ( y -- )  >r  white-color  0 r>  width  1  fill-rect  ;
: vline  ( y -- )  >r  white-color  r> 0  1 height  fill-rect  ;

: crosshatch  ( -- )
   black-screen
   height  0  do  i hline  d# 10 +loop
   width   0  do  i vline  d# 10 +loop
;
: short-wait  ( -- )  d# 500 ms  ;
: brightness-ramp  ( -- )
   0  h# 0f  do  i bright!  short-wait  -1 +loop
   backlight-off  short-wait  backlight-on
   h# f bright!
;

: red-screen  ( -- )
   load-base  whole-screen  " read-rectangle" $call-screen
   h# ff 00 00 rgb>565 whole-screen fill-rect
   d# 1000 ms
   load-base  whole-screen  fill-rect
;
: wait  ( -- )
   d# 1000 ms
   0 set-source \ Freeze image
   d# 1000 ms
   1 set-source \ Unfreeze image
   d# 1000 ms
;

warning @ warning off
: selftest  ( -- error? )
   depth d# 16 <>  if  false exit  then
   .horizontal-bars16   wait
   .vertical-bars16     wait
   gvsr                 wait
   gvsb                 wait
   hgradient            wait
   vgradient            wait
   crosshatch           wait
   brightness-ramp

   burnin-time d# 5000 >  if
      ." Press a key to stop early." cr
      d# 1000 ms
   then
   random-selftest
   confirm-selftest?
;
warning !

device-end

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
