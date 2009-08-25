\ See license at end of file
purpose: Mouse support for GUI

headerless

\ Current mouse cursor position

0 value xpos  0 value ypos

\ move-mouse-cursor ( x y - )
\ remove-mouse-cursor ( - )
\ poll-mouse  ( -- x y buttons )
\ get-event  ( #msecs -- false | x y buttons true )
\    0 means wait forever, buttons are ...RML
\ trackmouse ( - ) invokes 
\    defer handle-movement  ( x-abs y-abs buttons -- done? )
\ e.g.
\ ' move-cursor is handle-movement
\ mouse position is kept in values x and y

0 [if]
d# 16 constant cursor-w
d# 16 constant cursor-h

create white-bits
   80000000 ,  c0000000 ,  a0000000 ,  90000000 ,
   88000000 ,  84000000 ,  82000000 ,  81000000 ,
\  87800000 ,  b4000000 ,  d4000000 ,  92000000 ,
   87000000 ,  b4000000 ,  d2000000 ,  92000000 ,
\  8a000000 ,  09000000 ,  05000000 ,  02000000 ,
   09000000 ,  09000000 ,  05000000 ,  00000000 ,

create black-bits
   00000000 ,  00000000 ,  40000000 ,  60000000 ,
   70000000 ,  78000000 ,  7c000000 ,  7e000000 ,
\  78000000 ,  48000000 ,  08000000 ,  0c000000 ,
   78000000 ,  58000000 ,  0c000000 ,  0c000000 ,
\  04000000 ,  06000000 ,  02000000 ,  00000000 ,
   06000000 ,  06000000 ,  00000000 ,  00000000 ,
[else]
d# 17 constant cursor-w
d# 31 constant cursor-h

create white-bits
binary
   11000000000000000000000000000000 ,
   11100000000000000000000000000000 ,
   11011000000000000000000000000000 ,
   11001100000000000000000000000000 ,
   11000110000000000000000000000000 ,
   11000011000000000000000000000000 ,
   11000001100000000000000000000000 ,
   11000000110000000000000000000000 ,
   11000000011000000000000000000000 ,
   11000000001100000000000000000000 ,
   11000000000110000000000000000000 ,
   11000000000011000000000000000000 ,
   11000000000001100000000000000000 ,
   11000000000000110000000000000000 ,
   11000000000000011000000000000000 ,
   11000000000000001100000000000000 ,
   11000000000111111000000000000000 ,
   11000000000011000000000000000000 ,
   11000110000011000000000000000000 ,
   11001110000001100000000000000000 ,
   11010011000001100000000000000000 ,
   11100011000000110000000000000000 ,
   00000001100000110000000000000000 ,
   00000001100000011000000000000000 ,
   00000000110000011000000000000000 ,
   00000000110000001100000000000000 ,
   00000000011000001100000000000000 ,
   00000000011000000110000000000000 ,
   00000000001100011000000000000000 ,
   00000000000111110000000000000000 ,   
   00000000000111110000000000000000 ,

create black-bits
   00000000000000000000000000000000 ,
   00000000000000000000000000000000 ,
   00100000000000000000000000000000 ,
   00110000000000000000000000000000 ,
   00111000000000000000000000000000 ,
   00111100000000000000000000000000 ,
   00111110000000000000000000000000 ,
   00111111000000000000000000000000 ,
   00111111100000000000000000000000 ,
   00111111110000000000000000000000 ,
   00111111111000000000000000000000 ,
   00111111111100000000000000000000 ,
   00111111111110000000000000000000 ,
   00111111111111000000000000000000 ,
   00111111111111100000000000000000 ,
   00111111111111110000000000000000 ,
   00111111111000000000000000000000 ,
   00111111111100000000000000000000 ,
   00111001111100000000000000000000 ,
   00110001111110000000000000000000 ,
   00100000111110000000000000000000 ,
   00000000111111000000000000000000 ,
   00000000011111000000000000000000 ,
   00000000011111100000000000000000 ,
   00000000001111100000000000000000 ,
   00000000001111110000000000000000 ,
   00000000000111110000000000000000 ,
   00000000000111110000000000000000 ,
   00000000000011100000000000000000 ,
   00000000000000000000000000000000 ,
   00000000000000000000000000000000 ,
hex
[then]



0 value /rect
0 value old-rect
0 value new-rect
: alloc-mouse-cursor  ( -- )
   cursor-w cursor-h *  ['] pix* screen-execute  to /rect
   cursor-w cursor-h *  alloc-pixels to old-rect
   cursor-w cursor-h *  alloc-pixels to new-rect
;

: merge-cursor  ( -- )
   background  white-bits new-rect cursor-w cursor-h ['] merge-rect screen-execute
   black       black-bits new-rect cursor-w cursor-h ['] merge-rect screen-execute
;

: put-cursor  ( x y adr -- )
   -rot  cursor-w cursor-h  draw-rectangle
;

: remove-mouse-cursor  ( -- )
   mouse-ih 0=  if  exit  then
   xpos ypos  old-rect  put-cursor
;
: draw-mouse-cursor  ( -- )
   mouse-ih 0=  if  exit  then
   xpos ypos 2dup old-rect -rot         ( x y adr x y )
   cursor-w cursor-h  read-rectangle    ( x y )
   old-rect  new-rect /rect move        ( x y )
   merge-cursor                         ( x y )
   new-rect  put-cursor
;

: clamp  ( n min max - m )  rot min max  ;

: update-position  ( x y -- )
   2dup or 0=  if  2drop exit  then  \ Avoid flicker if there is no movement

   \ Minimize the time the cursor is down by doing computa1000000000000000000 ,tion in advance
   \ Considering the amount of code that is executed to put up the cursor,
   \ this optimization is probable unnoticeable, but it doesn't cost much.
   negate  ypos +  0  max-y cursor-h -  clamp      ( x y' )
   swap    xpos +  0  max-x cursor-w -  clamp      ( y' x')
   to xpos  to ypos
;

: get-key-code  ( -- c | c 9b )
   key  case
      \ Distinguish between a bare ESC and an ESC-[ sequence
      esc of
         d# 10 ms  key?  if
            key  [char] [ =  if  key csi  else  esc  then
         else
            esc
         then
      endof

      csi of  key csi  endof
      dup
   endcase
;
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
