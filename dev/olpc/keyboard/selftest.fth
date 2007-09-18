purpose: Interactive keyboard test shows which keys are pressed
\ See license at end of file

dev /8042/keyboard
hex

\ There are two scancode tables:
\   1.  simple scancode (down values); up value is f0 + scancode
\   2.  e0 + scancode (down values);   up value is e0 + f0 + scancode
\ For each scancode: index into keys

\ For each key: x, y, w, h
\   where x, y, w, h are parameters for painting the key

struct
   /n field >key-x
   /n field >key-y
   /n field >key-w
   /n field >key-h
constant /key

/key d# 128 * buffer: keys

0 value #keys
0 value key-y
0 value key-x

d#  10 constant key-gap
d#  12 constant row-gap
d#  40 constant smulti-key-w
d#  70 constant single-key-w
d#  70 constant single-key-h
d# 105 constant shift-key-w
d# 540 constant space-key-w

: key-adr  ( i -- adr )  /key * keys +  ;
: top-key-row  ( -- )  row-gap to key-y  key-gap to key-x  ;
: next-key-row  ( -- )
   key-y single-key-h + row-gap + to key-y
   key-gap to key-x 
;
: #keys++  ( -- )  #keys 1+ to #keys  ;
: ++key-x  ( n -- )  key-x + to key-x  ;
: add-key-gap  ( -- )  key-gap ++key-x  ;
: (make-key)  ( x y w h -- )
   #keys key-adr >r
   r@ >key-h ! r@ >key-w !  r@ >key-y !  r> >key-x !
   #keys++
;
: make-key  ( w -- )  dup key-x key-y rot single-key-h (make-key) ++key-x  ;
: make-key&gap  ( w -- )  make-key add-key-gap  ;
: make-single-key  ( -- )  single-key-w make-key&gap  ;
: make-smulti-key  ( -- )  smulti-key-w make-key  ;
: make-double-key  ( -- )  single-key-w 2* make-key&gap  ;
: make-shift-key   ( -- )  shift-key-w make-key&gap  ;
: make-space-key   ( -- )  space-key-w make-key&gap  ;
: make-quad-key    ( -- )
   key-x key-y single-key-w 2* dup >r single-key-h 2* row-gap + (make-key)
   r> ++key-x
   add-key-gap
;

: make-keys  ( -- )
   0 to #keys
   top-key-row
   2 0  do  make-single-key  loop
   7 0  do  make-smulti-key  loop  add-key-gap
   7 0  do  make-smulti-key  loop  add-key-gap
   7 0  do  make-smulti-key  loop  add-key-gap
   2 0  do  make-single-key  loop
   next-key-row
   d# 13 0  do  make-single-key  loop
   make-double-key
   next-key-row
   d# 13 0  do  make-single-key  loop
   make-quad-key
   next-key-row
   d# 13 0  do  make-single-key  loop
   next-key-row
   make-shift-key
   d# 10 0  do  make-single-key  loop
   make-shift-key
   2 0  do  make-single-key  loop
   next-key-row
   3 0  do  make-single-key  loop
   make-space-key
   5 0  do  make-single-key  loop
;

\ Keyboard top row: key entries    0-0x18
\         next row: key entries 0x19-0x26
\         next row: key entries 0x27-0x31
\         next row: key entries 0x35-0x41
\         next row: key entries 0x42-0x4f
\         next row: key entries 0x50-0x58

create raw-scancode
   ( -0 )  -1 c, 10 c, 0d c, 09 c, 06 c, 02 c, 04 c, 16 c,
   ( 08 )  -1 c, 12 c, 0f c, 0b c, 08 c, 27 c, 19 c, 50 c,
   ( 10 )  -1 c, 52 c, 42 c, -1 c, 35 c, 28 c, 1a c, -1 c,
   ( 18 )  -1 c, -1 c, 43 c, 37 c, 36 c, 29 c, 1b c, -1 c,
   ( 20 )  -1 c, 45 c, 44 c, 38 c, 2a c, 1d c, 1c c, -1 c,
   ( 28 )  -1 c, 53 c, 46 c, 39 c, 2c c, 2b c, 1e c, -1 c,
   ( 30 )  -1 c, 48 c, 47 c, 3b c, 3a c, 2d c, 1f c, -1 c,
   ( 38 )  -1 c, -1 c, 49 c, 3c c, 2e c, 20 c, 21 c, -1 c,
   ( 40 )  -1 c, 4a c, 3d c, 2f c, 30 c, 23 c, 22 c, -1 c,
   ( 48 )  -1 c, 4b c, 4c c, 3e c, 3f c, 31 c, 24 c, -1 c,
   ( 50 )  -1 c, 4f c, 40 c, -1 c, 32 c, 25 c, -1 c, -1 c,
   ( 58 )  -1 c, 4d c, 34 c, 33 c, -1 c, 41 c, -1 c, -1 c,
   ( 60 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, 26 c, -1 c,
   ( 68 )  -1 c, -1 c, -1 c, -1 c, -1 c, 4f c, -1 c, -1 c,
   ( 70 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, 00 c, -1 c,
   ( 78 )  14 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c,

create e0-scancode
   ( 00 )  -1 c, 10 c, 0d c, 09 c, 06 c, 02 c, 04 c, 16 c,
   ( 08 )  17 c, 12 c, 0f c, 0b c, 08 c, -1 c, -1 c, -1 c,
   ( 10 )  -1 c, 54 c, -1 c, 13 c, -1 c, -1 c, -1 c, 18 c,
   ( 18 )  -1 c, 11 c, -1 c, -1 c, -1 c, -1 c, -1 c, 51 c,
   ( 20 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, 55 c,
   ( 28 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, 18 c,
   ( 30 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c,
   ( 38 )  -1 c, 0e c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c,
   ( 40 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c,
   ( 48 )  -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c, -1 c,
   ( 50 )  -1 c, 0c c, -1 c, 0a c, -1 c, -1 c, -1 c, 17 c,
   ( 58 )  -1 c, -1 c, -1 c, -1 c, 07 c, -1 c, -1 c, 05 c,
   ( 60 )  -1 c, 53 c, 03 c, 01 c, 01 c, -1 c, -1 c, -1 c,
   ( 68 )  -1 c, 58 c, -1 c, 56 c, 56 c, -1 c, -1 c, 15 c,
   ( 70 )  4d c, 26 c, 57 c, -1 c, 58 c, 4e c, 00 c, -1 c,
   ( 78 )  14 c, -1 c, 57 c, -1 c, -1 c, 4e c, -1 c, -1 c,

raw-scancode value cur-sc-table

h# 07ff constant pressed-key-color
h# 001f constant idle-key-color
h# ffff constant kbd-bc

: scancode->key  ( scancode -- key# )  cur-sc-table + c@  ;

: draw-key  ( key# color -- )
   swap
   key-adr >r
   r@ >key-x @  r@ >key-y @  r@ >key-w @  r> >key-h @
   " fill-rectangle" $call-screen
;
: key-down  ( key# -- )  pressed-key-color draw-key  ;
: key-up    ( key# -- )  idle-key-color    draw-key  ;

: fill-screen  ( color -- )
   0 0 " dimensions" $call-screen " fill-rectangle" $call-screen
;

: draw-keyboard  ( -- )
   kbd-bc fill-screen
   #keys 0  ?do  i key-up  loop
   0 d# 20 at-xy ." Press the top left key to exit"
;

false value verbose?
false value exit-selftest?
false value up-key?

: process-raw  ( scan-code -- )
   verbose?  if  dup u.  then
   dup h# f0 =  if
      true to up-key?  drop
   else
   dup h# e0 =  if
      e0-scancode to cur-sc-table  drop
   else
      scancode->key  dup h# ff =  if
         drop
      else
         up-key?  if  dup 0= to exit-selftest? key-up  else  key-down  then
      then
      false to up-key?
      raw-scancode to cur-sc-table
   then  then
;

: selftest-keys  ( -- )
   raw-scancode to cur-sc-table
   false to exit-selftest?  false to up-key?
   begin
      get-data?  if  process-raw  then
      exit-selftest?
   until
;

: toss-keys  ( -- )  begin  key?  while  key drop  repeat  ;

: selftest  ( -- error? )
   open  0=  if  true exit  then
   make-keys
   cursor-off draw-keyboard
   toss-keys  " translation-off" $call-parent
   selftest-keys
   " translation-on" $call-parent  toss-keys cursor-on
   screen-ih iselect  erase-screen  iunselect
   page
   close
   false
;

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
