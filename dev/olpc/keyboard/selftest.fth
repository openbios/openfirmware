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
d# 400 constant top-row-offset
d#  40 constant button-w
d#  40 constant button-h

: key-adr  ( i -- adr )  /key * keys +  ;
: top-key-row  ( -- )  top-row-offset to key-y  key-gap to key-x  ;
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
: make-button  ( x y -- )  button-w button-h (make-key)  ;

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

   d#   80 d#  30 make-button  \ Rocker up    65
   d#   30 d#  80 make-button  \ Rocker left  67
   d#  130 d#  80 make-button  \ Rocker right 68
   d#   80 d# 130 make-button  \ Rocker down  66
   d#   80 d# 230 make-button  \ Rotate       69

   d# 1080 d#  30 make-button  \ O            e0 65
   d# 1030 d#  80 make-button  \ square       e0 67
   d# 1130 d#  80 make-button  \ check        e0 68
   d# 1080 d# 130 make-button  \ X            e0 66
;

0 [if]
hex
\ This is indexed by the IBM key number (the physical key number as
\ shown on language-independent drawings of the keyboard layout since
\ the original IBM documentation).  The values are scanset1 codes.
create (ibm#>scan1)
\   0     1     3     3     4     5     6     7     8     9
   00 c, 29 c, 02 c, 03 c, 04 c, 05 c, 06 c, 07 c, 08 c, 09 c,  \   
   0a c, 0b c, 0c c, 0d c, 00 c, 0e c, 0f c, 10 c, 11 c, 12 c,  \ 1x
   13 c, 14 c, 15 c, 16 c, 17 c, 18 c, 19 c, 1a c, 1b c, 2b c,  \ 2x
   3a c, 1e c, 1f c, 20 c, 21 c, 22 c, 23 c, 24 c, 25 c, 26 c,  \ 3x
   27 c, 28 c, 00 c, 1c c, 2a c, 56 c, 2c c, 2d c, 2e c, 2f c,  \ 4x
   30 c, 31 c, 32 c, 33 c, 34 c, 35 c, 73 c, 36 c, 1d c, 00 c,  \ 5x
   38 c, 39 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,  \ 6x
   00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,  \ 7x
   00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c,  \ 8x
   45 c, 47 c, 4B c, 4F c, 00 c, 00 c, 48 c, 4C c, 50 c, 52 c,  \ 9x
   37 c, 49 c, 4D c, 51 c, 53 c, 4A c, 4E c, 00 c, 1c c, 00 c,  \ 1   
   01 c, 00 c, 3b c, 3c c, 3d c, 3e c, 3f c, 40 c, 41 c, 42 c,  \ 11x
   43 c, 44 c, 57 c, 58 c, 00 c, 46 c, 00 c, 00 c, 00 c, 00 c,  \ 12x
   79 c, 00 c, 00 c, 5c c, 73 c, 6e c, 00 c, 00 c, 00 c, 00 c,  \ 13x (analog intermediates)
   00 c, 00 c, 00 c, 00 c, 00 c,                                \ 14x

\ A program to invert the table above.  We used the inverted form.
h# 80 buffer: sc1
: invert-ibm  ( -- )
   sc1 h# 80 erase
   d# 145 0 do
     (ibm#>scan1) i + c@  ?dup  if  i  swap sc1 +  c!  then
   loop

   h# 80 0 do
      ." ( " i 2 u.r ."  ) "
      i 8 bounds do
         sc1 i + c@ push-decimal 3 u.r pop-base  ."  c, "
      loop
      cr
   8 +loop
;
[then]

\ This table is indexed by the (unescaped) scanset1 code, giving
\ an IBM physical key number.

decimal
create (scan1>ibm#)
\      0/8    1/9    2/a    3/b    4/c    5/d    6/e    7/f
(  0 )   0 c, 110 c,   2 c,   3 c,   4 c,   5 c,   6 c,   7 c,  \ 01 is esc
(  8 )   8 c,   9 c,  10 c,  11 c,  12 c,  13 c,  15 c,  16 c,
( 10 )  17 c,  18 c,  19 c,  20 c,  21 c,  22 c,  23 c,  24 c,
( 18 )  25 c,  26 c,  27 c,  28 c,  43 c,  58 c,  31 c,  32 c,  \ 1d is ctrl, 1c is Enter
( 20 )  33 c,  34 c,  35 c,  36 c,  37 c,  38 c,  39 c,  40 c,
( 28 )  41 c,   1 c,  44 c,  29 c,  46 c,  47 c,  48 c,  49 c,
( 30 )  50 c,  51 c,  52 c,  53 c,  54 c,  55 c,  57 c, 100 c,
( 38 )  60 c,  61 c,  30 c, 112 c, 113 c, 114 c, 115 c, 116 c,
( 40 ) 117 c, 118 c, 119 c, 120 c, 121 c,  90 c, 125 c,  91 c,
( 48 )  96 c, 101 c, 105 c,  92 c,  97 c, 102 c, 106 c,  93 c,
( 50 )  98 c, 103 c,  99 c, 104 c,   0 c,   0 c,  45 c, 122 c,
( 58 ) 123 c,  59 c,   0 c,   0 c, 133 c,   0 c,   0 c,   0 c,  \ scan h# 59 is Fn - ibm# d# 59
( 60 )   0 c,   0 c,   0 c,   0 c,   0 c, 150 c, 153 c, 151 c,  \ 66-68 are left rocker
( 68 ) 152 c, 154 c,   0 c,   0 c,   0 c,   0 c, 135 c,   0 c,  \ 69 is rotate
( 70 )   0 c,   0 c,   0 c,  56 c,   0 c,   0 c,   0 c,   0 c,
( 78 )   0 c, 130 c,   0 c,   0 c,   0 c,   0 c,   0 c,   0 c,
hex

\ This should be a lookup table.  It would be smaller that way
: e0-scan1>ibm#  ( scancode -- ibm# )
   case
      h# 38 of  d# 62  endof  \ R ALT

\ For a standard PC keyboard
\     h# 1c of  d# 64  endof  \ Numeric enter
\     h# 1d of  d# 64  endof  \ R CTRL
\     h# 52 of  d# 75  endof  \ Insert
\     h# 53 of  d# 76  endof  \ Delete
\     h# 47 of  d# 80  endof  \ Home
\     h# 4f of  d# 81  endof  \ End
\     h# 49 of  d# 85  endof  \ PageUp
\     h# 51 of  d# 86  endof  \ PageDown

      h# 3b of  d# 112 endof  \ Fn 1
      h# 3c of  d# 113 endof  \ Fn 2
      h# 3d of  d# 114 endof  \ Fn 3
      h# 3e of  d# 115 endof  \ Fn 4
      h# 3f of  d# 116 endof  \ Fn 5
      h# 40 of  d# 117 endof  \ Fn 6
      h# 41 of  d# 118 endof  \ Fn 7
      h# 42 of  d# 119 endof  \ Fn 8
      h# 43 of  d# 120 endof  \ Fn 9
      h# 44 of  d# 121 endof  \ Fn 10
      h# 57 of  d# 122 endof  \ Fn 11
      h# 58 of  d# 123 endof  \ Fn 12

      h# 4b of  d# 79  endof  \ Left Arrow
      h# 48 of  d# 83  endof  \ Up Arrow
      h# 50 of  d# 84  endof  \ Down Arrow
      h# 4d of  d# 89  endof  \ Right Arrow

\ OLPC-specific
      h# 47 of  d# 79  endof  \ Home
      h# 4f of  d# 89  endof  \ End
      h# 49 of  d# 83  endof  \ PageUp
      h# 51 of  d# 84  endof  \ PageDown
      h# 78 of  d# 135 endof  \ Fn View Source
      h# 79 of  d# 135 endof  \ View Source
      h# 77 of  d# 136 endof  \ Fn 1.5
      h# 76 of  d# 137 endof  \ Fn 2.5
      h# 75 of  d# 138 endof  \ Fn 3.5
      h# 74 of  d# 139 endof  \ Fn 5.5
      h# 73 of  d# 140 endof  \ Fn 6.5
      h# 72 of  d# 141 endof  \ Fn 7.5
      h# 71 of  d# 142 endof  \ Fn 9.5
      h# 70 of  d# 143 endof  \ Fn 10.5
      h# 6f of  d# 144 endof  \ Fn 11.5

      h# 64 of  d# 145 endof  \ Fn Chat
      h# 6e of  d# 145 endof  \ Chat

      h# 01 of  d# 110 endof  \ Fn Esc
      h# 5a of  d# 129 endof  \ Fn Frame
      h# 5d of  d# 129 endof  \ Frame
      h# 53 of  d# 15  endof  \ Fn Erase
      h# 52 of  d# 57  endof  \ Fn R-shift
      h# 7e of  d# 56  endof  \ Language

      h# 5b of  d# 127 endof  \ L grab
      h# 56 of  d# 61  endof  \ Fn space
      h# 5c of  d# 128 endof  \ F grab

      h# 65 of  d# 156 endof  \ Button O
      h# 66 of  d# 159 endof  \ Button X
      h# 67 of  d# 157 endof  \ Button square
      h# 68 of  d# 158 endof  \ Button check
      ( default )  0 swap     \ Not recognized
   endcase
;

: scan1>ibm#  ( scancode1 esc? -- ibm# )
   if  e0-scan1>ibm#  else  (scan1>ibm#) + c@  then
;

\ "key#" is a physical location on the screen
\ "ibm#" is the key number as shown on the original IBM PC documents
\ These keynum values are from the ALPS spec "CL1-matrix-20060920.pdf"
decimal
create ibm#s
   \ Top row, key#s 0x00-0x18
   110 c, 135 c,                                     \ ESC, view source
   112 c, 136 c, 113 c, 137 c, 114 c, 138 c, 115 c,  \ Left bar
   116 c, 139 c, 117 c, 140 c, 118 c, 141 c, 119 c,  \ Middle bar
   120 c, 142 c, 121 c, 143 c, 122 c, 144 c, 123 c,  \ Right bar
   145 c, 129 c,                                     \ chat, frame

   \ Number row - key#s 0x19-0x26
   1 c, 2 c, 3 c, 4 c, 5 c, 6 c, 7 c, 8 c, 9 c, 10 c, 11 c, 12 c, 13 c, 15 c,

   \ Top alpha row - key#s 0x27-0x34
   16 c, 17 c, 18 c, 19 c, 20 c, 21 c, 22 c, 23 c, 24 c, 25 c, 26 c, 27 c, 28 c, 43 c,  \ tab, chars, enter

   \ Middle alpha row - key#s 0x35-0x41
   58 c, 31 c, 32 c, 33 c, 34 c, 35 c, 36 c, 37 c, 38 c, 39 c, 40 c, 41 c, 29 c,  \ ctrl, chars

   \ Bottom alpha row - key#s 0x42-0x4f
   44 c, 46 c, 47 c, 48 c, 49 c, 50 c, 51 c, 52 c, 53 c, 54 c, 55 c, 57 c, 83 c, 56 c,  \ shift, chars, shift, up, times

   \ Function row - key#s 0x50 - 0x58
   59 c, 127 c, 60 c, 61 c, 62 c, 128 c, 79 c, 84 c, 89 c,  \ Fn, lgrab, alt, space, altgr, rgrab, left, down, right

   \ Game buttons - key#s 0x59 - 0x61  (these IBM#s are made up just for this program)
   150 c, 151 c, 152 c, 153 c,        \ Rocker up, left, right, down
   154 c,                             \ Rotate
   156 c, 157 c, 158 c, 159 c,        \ Game O, square, check, X
here ibm#s - constant /ibm#s
hex

: ibm#>key#  ( ibm# -- true | key# false )
   /ibm#s 0  ?do   ( ibm# )
      dup  ibm#s i + c@   =  if
         drop i false unloop exit
      then
   loop                      ( ibm# )
   drop true
;

0 [if]
\ This is a program to invert the ibm#s table
d# 145 buffer: sc2
: invert-key  ( -- )
   sc2 d# 145 erase
   h# 59 0 do
     i  ibm#s i + c@  sc2 +  c!
   loop

   d# 145 0 do
      ." ( " i  push-decimal  3 u.r  pop-base  ."  ) "
      i d# 10 bounds do
         sc2 i + c@ push-hex  2 u.r    pop-base  ."  c, "
      loop
      cr
   d# 10 +loop
;
[then]

0 [if]
\ These are maps from scanset 2 to key position numbers.
\ They are no longer used
hex
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
[then]

h# 07ff constant pressed-key-color
h# 001f constant idle-key-color
h# ffff constant kbd-bc

0 value esc?

: scan1->key#  ( scancode -- true | key# false )
   esc?  scan1>ibm#  
   ?dup 0=  if  true exit  then
   ibm#>key#
;

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
   0 d# 13 at-xy ." X"
;

false value verbose?

: process-raw  ( scan-code -- exit? )
   verbose?  if  dup u.  then
   dup h# e0 =  if                           ( scan )
      drop  true to esc?                     ( )
   else                                      ( scan )
      dup h# 7f and scan1->key#  if          ( scan )
         drop                                ( )
      else                                   ( scan key# )
         swap h# 80 and  if                  ( key# )
            dup key-up                       ( key# )
            0=  if  true exit  then          ( )
         else                                ( key# )
            key-down                         ( )
         then                                ( )
      then                                   ( )
      false to esc?                          ( )
   then                                      ( )
   false
;

0 value last-timestamp
: selftest-keys  ( -- )
   false to esc?
   get-msecs to last-timestamp
   begin
      get-data?  if
         process-raw
         get-msecs to last-timestamp
      else
         get-msecs last-timestamp -  d# 20,000 >=
      then             ( exit? )
   until
;

: toss-keys  ( -- )  begin  key?  while  key drop  repeat  ;

warning @ warning off
: selftest  ( -- error? )
   open  0=  if  true exit  then
   make-keys
   cursor-off draw-keyboard
   true to locked?   \ Disable the keyboard alarm handler; it steals our scancodes
   selftest-keys
   false to locked?
   cursor-on
   screen-ih iselect  erase-screen  iunselect
   page
   close
   false
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
