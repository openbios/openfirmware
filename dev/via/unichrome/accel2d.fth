\ See license at end of file
purpose: Via Unichrome graphics acceleration

alias depth+ wa+

: mmio@  ( offset -- l )  mmio-base + rl@  ;
: mmio!  ( l offset -- )  mmio-base + rl!  ;

\ Do this once
: gp-setup  ( -- )
   0 h# 14 mmio!  \ Destination map base - beginning of frame buffer
   0 h# 1c mmio!  \ Source map base - beginning of frame buffer
   bytes/line 3 rshift  dup wljoin  8 mmio!  \ Dest and src pitch
   depth  case
      8      of      0 endof  \  8-bpp 3:3:2
      d# 16  of h# 100 endof  \ 16-bpp 5:6:5
      d# 32  of h# 300 endof  \ 32-bpp 8:8:8:8
   endcase
   4 mmio!   \ Mode
;

: wait-done  ( -- )
   begin  h# 400 mmio@ h# 10002 and  0= until
;
: wh!  ( w h -- )
   swap 1- swap 1- wljoin  h# c mmio!  ( src-x,y dst-x,y )  \ Set width and height
;
: dst!  ( x y -- )  wljoin  h# 10 mmio!  ;
: src!  ( x y -- )  wljoin  h# 18 mmio!  ;   
: pattern!  ( color -- )  h# 58 mmio!  ;

\ This one is a big win compared to doing it with the CPU
\ Scrolling the whole screen takes about 3.4 mS (GP) or 74 mS (CPU)
: gp-move  ( src-x,y dst-x,y w,h -- )
   wh!  dst!  src!                     ( )
   h# cc.00.00.01 0 mmio!              ( )          \ Perform BLT Output = source
   wait-done
;

\ gp-fill takes 2/3 as long wfill, and about the same time as lfill
\ gp-fill of the entire OLPC screen takes 2 mS; one character row 120 uS
: gp-fill  ( color dst-x,y w,h -- )
   wh!  dst!  pattern!
   h# f0.00.20.01 0 mmio!  \ Output = pattern
   wait-done
;

\ some tests
1 [if]
: gp-fill-screen  ( color -- )
   0 0   screen-width screen-height  gp-fill
;
: gp-scroll-screen  ( -- )
   0 char-height   0 0  screen-width    ( src-x,y  dst-x,y  )
   screen-height char-height -   gp-move
;
: gp-fill-last-line  ( color -- )
   bg  0 screen-height char-height -  screen-width char-height  gp-fill
;
[then]

: rc>pixels  ( r c -- x y )  swap char-width *  swap char-height *  ;
: +window    ( x y -- x' y' )  window-left 2/ window-top d+  ;
: rc>window  ( r c -- x y )  rc>pixels +window  ;

: accel-delete-lines ( delta-#lines -- )
   >r                                  ( r: delta-#lines )
   0  line# r@ +   rc>window           ( src-x,y r: delta )
   0  line#        rc>window           ( src-x,y dst-x,y r: delta )
   #columns  #lines r@ -  rc>pixels    ( src-x,y dst-x,y w,h r: delta )
   gp-move                             ( r: delta )
   screen-background                   ( color r: delta )
   0  #lines r@ -  rc>window           ( color dst-x,y r: delta )
   #columns  r>    rc>pixels           ( color dst-x,y w,h )
   gp-fill
;

: accel-install  ( -- )
   gp-setup
   ['] accel-delete-lines is delete-lines
;
' accel-install is gp-install

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
