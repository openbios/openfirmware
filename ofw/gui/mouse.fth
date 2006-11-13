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

: merge-line  ( color mask adr -- )
   cursor-w bounds  ?do                         ( color mask )
     dup h# 80000000 and  if  over i c!  then   ( color mask )
     2*                                         ( color mask' )
   loop
   2drop
;
: merge-rect  ( color mask-adr rect-adr -- )
   cursor-h  0  do  ( color mask-adr rect-adr )
      3dup swap @ swap  merge-line
      swap na1+  swap cursor-w +
   loop
   3drop
;

cursor-w cursor-h *  constant /rect
/rect  buffer: old-rect
/rect  buffer: new-rect

: merge-cursor  ( -- )
   0f white-bits new-rect merge-rect
   00 black-bits new-rect merge-rect
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

   \ Minimize the time the cursor is down by doing computation in advance
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
