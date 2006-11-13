\ See license at end of file
purpose: Use the CT65550 bit blit hardware to accelerate some functions

\ TODO: implement erase-lines, insert-characters, delete-characters,
\ draw-character, and perhaps fill/draw/read-rectangle using the blitter.

0 value blitter-base
: br@  ( reg# -- n )  blitter-base swap la+ rl@  ;
: br!  ( n reg# -- )  blitter-base swap la+ rl!  ;

: wait-not-busy  ( -- )
   begin  4 br@  h# 8000.0000 and  0= until
;
: window-width  ( -- #bytes )  char-width #columns *  ;
: >offset  ( row# -- offset )
   char-height *                        ( line-offset )
   window-top +                         ( top-line# )
   window-width *                       ( top-byte# )
   window-left +
;

: move-up  ( src-row# dst-row# #rows -- )
   wait-not-busy
   h# cc  4 br!		\ Move starting at ULHC
   char-height * >r
   >offset  7 br!
   >offset  6 br!
   window-width  r>  wljoin  8 br!
;

: +lrhc  ( ulhc #lines -- lrhc )  window-width * +  1-  ;
: move-down  ( src-row# dst-row# #rows -- )
   wait-not-busy
   h# 3cc  4 br!		\ Move starting at LRHC
   char-height *  >r                      ( src-row# dst-row# r: #lines )
   >offset r@ +lrhc 7 br!
   >offset r@ +lrhc 6 br!
   window-width  r> wljoin  8 br!
;

: rows>bytes  ( #rows -- #bytes )  char-height *  window-width *  ;
: erase-lines  ( row# #rows -- )
   wait-not-busy
   swap >offset frame-buffer-adr +   ( #rows line-adr )
   swap rows>bytes background-color fill
;

: set-br-width  ( -- )  /scanline dup wljoin  0 br!  ;

: blit-insert-lines  ( #rows -- )
   >r
   set-br-width
   line#          ( src-line# )
   line# r@ +     ( src-line# dst-line# )
   #lines line# -  r@ - move-down      ( )
   line#  r>  erase-lines
;

: blit-delete-lines  ( #rows -- )
   >r
   set-br-width
   line# r@ +     ( src-line# )
   line#          ( src-line# dst-line# )
   #lines line# -  r@ - move-up       ( )
   #lines r@ -   r>  erase-lines
;

\ blit-flip-screen isn't the same a "invert-screen", because the latter is
\ supposed to affect only pixels of the foreground or background colors.
: blit-flip-screen  ( -- )
   wait-not-busy
   set-br-width
   h# 55  4 br!		\ Invert screen (notD)
   0 7 br!
   window-width  #lines char-height *  wljoin  8 br!
;

: blit-blink-screen  ( -- )
   blit-flip-screen  d# 10 ms  blit-flip-screen
   wait-not-busy
;

: install-blitter  ( -- )
   h# 40.0000 0 my-space h# 200.0010 + h# 2c  map-in  to blitter-base

   2 h# 20 xr!  0 h# 20 xr!    \ Reset blitter, set to 8 bpp
   ['] blit-delete-lines to delete-lines
   ['] blit-insert-lines to insert-lines
   ['] blit-blink-screen to blink-screen
;
: remove-blitter  ( -- )  blitter-base  h# 2c  map-out  ;

[ifdef] test-me
: zap
   frame-buffer-adr /fb a fill
   frame-buffer-adr /fb bounds do 0 i c! 281 +loop
;
init-blitter
: dr  2c 0 do i 3 u.r i blit@ 9 u.r cr 4 +loop  ;
[then]
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
