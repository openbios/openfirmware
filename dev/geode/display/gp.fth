purpose: Geode LX graphics acceleration
\ See license at end of file

alias depth+ wa+

: dst!  ( x y -- )  bytes/line * swap depth+ 0 gp!  ;
: src!  ( x y -- )  bytes/line * swap depth+ 4 gp!  ;
: stride!  ( dst-stride src-stride -- )  wljoin  8 gp!  ;
: wh!  ( width height -- )  swap wljoin h# c gp!  ;
\ : fg!  ( foreground-color -- )  h# 10 gp!  ;
\ : bg!  ( background-color -- )  h# 14 gp!  ;
: pattern!  ( color pat# -- )  h# 18 swap la+ gp!  ;
: ropmode!  ( mode -- )  h# 38 gp!  ;
: blt!  ( blt -- )  h# 40 gp!  ;
: offset!  ( ch3 src dst -- )
   h# ffc0.0000 and                         ( ch3 src dst' )
   swap h# ffc0.0000 and  d# 10 rshift or   ( ch3 src+dst )
   swap h# ffc0.0000 and  d# 20 rshift or   ( ch3+src+dst )
   h# 4c gp!
;

\ Ready to accept a command
: gp-wait-ready  ( -- )  begin  h# 44 gp@  4 and 0=  until  ;

\ Finished with all the queued-up commands
: gp-wait-done   ( -- )  begin  h# 44 gp@  1 and 0=  until  ;

0 instance value rop-high

\ Do this once
: gp-setup  ( -- )
   frame-buffer-adr >physical  dup dup offset!
   bytes/line dup stride!
   depth  case
      8      of            0 endof  \  8-bpp 3:3:2
      d# 16  of h# 6000.0000 endof  \ 16-bpp 5:6:5
      d# 32  of h# 8000.0000 endof  \ 32-bpp 8:8:8:8
   endcase
   to rop-high
;

\ This one is a big win compared to doing it with the CPU
\ Scrolling the whole screen takes about 3.4 mS (GP) or 74 mS (CPU)
: gp-move  ( src-x,y dst-x,y w,h -- )
   gp-wait-ready
   wh!  dst!  src!
   h# cc rop-high or  ropmode!  \ Output = source
   1 blt!      \ Source data from framebuffer
   gp-wait-done
;

\ gp-fill takes 2/3 as long wfill, and about the same time as lfill
\ gp-fill of the entire OLPC screen takes 2 mS; one character row 120 uS
: gp-fill  ( color dst-x,y w,h -- )
   gp-wait-ready
   wh!  dst!  0 pattern!
   h# f0 rop-high or  ropmode!  \ Output = pattern
   h# 0 blt!   \ No source or destination data from framebuffer
   gp-wait-done
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

: fbgeode-delete-lines ( delta-#lines -- )
   >r                           ( r: delta-#lines )
   0  line# r@ +   rc>window    ( src-x,y r: delta )
   0  line#        rc>window    ( src-x,y dst-x,y r: delta )
   #columns  #lines r@ -  rc>pixels    ( src-x,y dst-x,y w,h r: delta )
   gp-move                      ( r: delta )
   screen-background            ( color r: delta )
   0  #lines r@ -  rc>window    ( color dst-x,y r: delta )
   #columns  r>    rc>pixels    ( color dst-x,y w,h )
   gp-fill
;

: gp-install  ( -- )
   gp-setup
   ['] fbgeode-delete-lines is delete-lines
;

: display-install  ( -- )
   init-all
   default-font set-font
   width  height                           ( width height )
   over char-width / over char-height /    ( width height rows cols )
   /scanline depth fb-install gp-install   ( )
   init-hook
;

: display-selftest  ( -- failed? )  false  ;

' display-install  is-install
' display-remove   is-remove
' display-selftest is-selftest

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
