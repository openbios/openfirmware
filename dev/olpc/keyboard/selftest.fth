purpose: Interactive keyboard test shows which keys are pressed
\ See license at end of file

\needs final-test?  0 value final-test?
\needs smt-test?    0 value smt-test?

dev /keyboard
hex

\ This is 1 for the original rubber keyboard and 2 for the mechanical keyboard
1 value keyboard-type

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
   /n field >key-time
constant /key

/key d# 128 * buffer: keys

0 value #keys
0 value key-y
0 value key-x

d#  10 constant key-gap
d#  12 constant row-gap
d#   0 constant hidden-key-w
d#  70 constant smulti-key-w
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
   r@ >key-h ! r@ >key-w !  r@ >key-y !  r@ >key-x !
   0 r> >key-time !
   #keys++
;
: make-key  ( w -- )  dup key-x key-y rot single-key-h (make-key) ++key-x  ;
: make-key&gap  ( w -- )  make-key add-key-gap  ;
: make-single-key  ( -- )  single-key-w make-key&gap  ;
: make-smulti-key  ( i -- )
   1 and  if
      hidden-key-w make-key
   else
      smulti-key-w make-key
   then
;
: make-double-key  ( -- )  single-key-w 2* make-key&gap  ;
: make-shift-key   ( -- )  shift-key-w make-key&gap  ;
: make-space-key   ( -- )  space-key-w make-key&gap  ;
: make-quad-key    ( -- )
   key-x key-y single-key-w 2* dup >r single-key-h 2* row-gap + (make-key)
   r> ++key-x
   add-key-gap
;
: make-button  ( x y -- )  button-w button-h (make-key)  ;

: make-buttons
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

: make-keys1  ( -- )
   0 to #keys
   top-key-row
   2 0  do  make-single-key  loop
   7 0  do  i make-smulti-key  loop  add-key-gap
   7 0  do  i make-smulti-key  loop  add-key-gap
   7 0  do  i make-smulti-key  loop  add-key-gap

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

   make-buttons
;
: make-narrower-key  ( -- )  d# 65 make-key&gap  ;
: make-wider-key  ( -- )  d# 83 make-key&gap  ;
: make-keys2  ( -- )
   0 to #keys
   top-key-row
   d# 15 0  do  d# 69 make-key&gap  loop  \ exc, f1-f12,ins,del
   next-key-row
   make-narrower-key  \ `
   d# 10 0  do  make-wider-key  loop  \ 1-0
   make-narrower-key  \ -
   d# 95 make-key&gap  \ bksp
   next-key-row
   d# 95 make-key&gap  \ Tab
   d# 10 0  do  make-wider-key  loop \ Q-P
   make-narrower-key make-narrower-key \ []
   next-key-row
   d# 125 make-key&gap \ ctrl
   d# 9 0  do  make-wider-key  loop  \ A-L
   make-narrower-key  \ ;
   d# 125 make-key&gap  \ enter

   next-key-row
   d# 160 make-key&gap  \ lshift
   d# 7 0  do  make-wider-key  loop
   d# 3 0  do  make-narrower-key  loop
   d# 125 make-key&gap  \ rshift
   next-key-row
   make-wider-key make-wider-key make-narrower-key  make-wider-key  \ fn hand \ alt
   d# 330 make-key&gap  \ space
   7 0  do  d# 60 make-key&gap  loop  \ altgr,+,",left,down,up,right

   make-buttons
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

0 value key-stuck?

d# 128 8 / constant #key-bytes
#key-bytes buffer: key-bitmap
: set-key-bit  ( key# -- )
   8 /mod           ( bit# byte# )
   key-bitmap +     ( bit# adr )
   tuck c@          ( adr bit# old-byte )
   1 rot lshift or  ( adr byte )
   swap c!
;
-1 value last-1
-1 value last-2
: clear-key-bitmap  ( -- )
   key-bitmap #key-bytes erase
   -1 to last-1   -1 to last-2
;

\ Funny-map1 has bits clear at the locations of intermediate
\ slider keys.  Those keys are only active by pressing the fn
\ key, and need not be tested during operator finger-sweeps of the
\ keyboard.  It is okay if the operator tests them, so we mask
\ off those bits if they happen to be set in the bitmap.
h# ffd5ab57 constant funny-map1

create all-keys-bitmap1
57 c, ab c, d5 c, ff c, ff c, ff c, ff c, ff c,  \ Omits the intermediate slider keys
ff c, ff c, ff c, ff c, 03 c, 00 c, 00 c, 00 c,

\ The mechanical keyboard has no slider keys. All displayed button locations are
\ activated by pressing single keystrokes, so the map is dense
h# ffffffff constant funny-map2
create all-keys-bitmap2
ff c, ff c, ff c, ff c, ff c, ff c, ff c, ff c,
ff c, ff c, 3f c, 00 c, 00 c, 00 c, 00 c, 00 c,

: all-tested?0  ( -- flag )  \ Just buttons
   key-bitmap w@  h# 1ff and  h# 1ff =
;
: all-tested?1  ( -- flag )
   key-bitmap @ funny-map1 and key-bitmap !
   key-bitmap  all-keys-bitmap1  #key-bytes comp 0=
;
: all-tested?2  ( -- flag )
   key-bitmap @ funny-map2 and key-bitmap !
   key-bitmap  all-keys-bitmap2  #key-bytes comp 0=
;
defer all-tested?

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
( \ ) h# 1c of  d# 64  endof  \ Numeric enter
( \ ) h# 1d of  d# 64  endof  \ R CTRL
      h# 52 of  d# 75  endof  \ Insert
      h# 53 of  d# 76  endof  \ Delete
( \ ) h# 47 of  d# 80  endof  \ Home
( \ ) h# 4f of  d# 81  endof  \ End
( \ ) h# 49 of  d# 85  endof  \ PageUp
( \ ) h# 51 of  d# 86  endof  \ PageDown

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

decimal
: ,game-buttons  ( -- )
   \ Game buttons - key#s 0x59 - 0x61  (these IBM#s are made up just for this program)
   150 c, 151 c, 152 c, 153 c,        \ Rocker up, left, right, down
   154 c,                             \ Rotate
   156 c, 157 c, 158 c, 159 c,        \ Game O, square, check, X
;
hex

\ "key#" is a physical location on the screen
\ "ibm#" is the key number as shown on the original IBM PC documents
\ These keynum values are from the ALPS spec "CL1-matrix-20060920.pdf"
decimal
create ibm#s0
   ,game-buttons
here ibm#s0 - constant /ibm#s0

create ibm#s1
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

   ,game-buttons
here ibm#s1 - constant /ibm#s1

\ "key#" is a physical location on the screen
\ "ibm#" is the key number as shown on the original IBM PC documents
\ The actual #s for F6 and F7 are 146 and 147, but the EC does some magic
create ibm#s2
   \ Top row, key#s 0x00-0x18
   110 c,                                            \ ESC
   112 c, 113 c, 114 c, 115 c, 116 c, 117 c,         \ F1-F6
   118 c, 119 c, 120 c, 121 c, 122 c, 123 c,         \ F6-F12
\  148 c, 149 c,                                     \ ins, del
    75 c,  76 c,                                     \ ins, del

   \ Number row
   1 c, 2 c, 3 c, 4 c, 5 c, 6 c, 7 c, 8 c, 9 c, 10 c, 11 c, 12 c, 15 c,  \ 1 is really 150

   \ Top alpha row - tab QWERTYUIOP []
   16 c, 17 c, 18 c, 19 c, 20 c, 21 c, 22 c, 23 c, 24 c, 25 c, 26 c, 27 c, 28 c, \ 28 is really 151

   \ Middle alpha row - ctrl ASDFGHIJKL ; enter
   58 c, 31 c, 32 c, 33 c, 34 c, 35 c, 36 c, 37 c, 38 c, 39 c, 40 c, 43 c,

   \ Bottom alpha row - shift ZXCVBNM , . / shift
   44 c, 46 c, 47 c, 48 c, 49 c, 50 c, 51 c, 52 c, 53 c, 54 c, 55 c, 57 c,

   \ Function row - fn grab \ alt space altgr   ..  left down up right  29 is really 152, 13>153, 41>154
   59 c, 127 c, 29 c, 60 c, 61 c, 62 c, 13 c, 41 c, 79 c, 84 c, 83 c, 89 c,

   ,game-buttons
here ibm#s2 - constant /ibm#s2
hex

defer make-keys  ( -- )
defer ibm#s      ( -- adr )
defer /ibm#s     ( -- n )

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

h# f81f constant down-key-color
h# 07ff constant tested-key-color
h# 001f constant idle-key-color
h# ffff constant kbd-bc

0 value esc?

: scan1->key#  ( scancode -- true | key# false )
   esc?  scan1>ibm#  
   ?dup 0=  if  true exit  then
   ibm#>key#
;

: set-key-time  ( timestamp key-adr -- )
   over 0<>  over >key-time @  0<>  and   if  ( timestamp key-adr )
      \ If both timestamp and old key time are nonzero, then we preserve the old key time
      >key-time @  d# 3,000 +  -  0>  to key-stuck?
   else
      \ If either timestamp or old key time is 0, we set the key time
      >key-time !
   then
;

: draw-key  ( key# color timestamp  -- )
   rot key-adr >r          ( color# timestamp r: key-adr )
   r@ set-key-time         ( color#           r: key-adr )
   r@ >key-w @  hidden-key-w  =  if  ( color# r: key-adr )
      r> 2drop                       ( )
   else                              ( color# r: key-adr )
      r@ >key-x @  r@ >key-y @  r@ >key-w @  r> >key-h @  ( color# x y w h )
      " fill-rectangle" $call-screen   ( )
   then
;
: key-tested ( key# -- )  tested-key-color 0          draw-key  ;
: key-down   ( key# -- )  down-key-color   get-msecs  draw-key  ;
: key-up     ( key# -- )  idle-key-color   0          draw-key  ;

: fill-screen  ( color -- )
   0 0 " dimensions" $call-screen " fill-rectangle" $call-screen
;

: draw-keyboard  ( -- )
   kbd-bc fill-screen
   #keys 0  ?do  i key-up  loop
   final-test?  smt-test?  or  0=  if  0 d# 13 at-xy ." X"  then
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
         swap h# 80 and  if   \ Up           ( key# )
            final-test?  smt-test?  or  if   ( key# )
               dup key-tested                ( key# )
               dup 0=  last-1 0= and  last-2 0=  and  if   ( key# )
                  drop true                  ( exit? )
               else                          ( key# )
                  last-1 to last-2  to last-1  ( )
                  all-tested?                ( exit? )
               then
            else                             ( key# )
               dup key-up                    ( key# )
               \ 0 is the ESC key
               0=                            ( exit? )
            then                             ( exit? )
            if  true exit  then              ( )
         else                                ( key# )
            dup set-key-bit                  ( key# )
            key-down                         ( )
         then                                ( )
      then                                   ( )
      false to esc?                          ( )
   then                                      ( )
   false
;

\ For XO-1.75, the game buttons are connected directly to the CPU SoC,
\ instead of going through the EC.  To preserve the rest of the test
\ logic, we generate a stream of up-down events from the game button
\ mask information.

0 value pending-scancode  \ One-byte queue for scancodes that follow an e0 prefix
0 value pending-buttons   \ Bitmask of button changes that haven't been sent yet
0 value last-buttons      \ State of game keys the last time we looked

\ Finds the rightmost one bit in mask
: choose-bit  ( mask -- bit# )
   d# 32 0  do                ( mask )
      dup 1 and  if           ( mask )
	 drop i unloop exit   ( -- bit# )
      then                    ( mask )
      u2/                     ( mask' )
   loop                       ( mask )
   drop -1                    ( bit# )  \ Shouldn't happen
;

\ Maps bit number to scancode sequence

create button-scancodes
\  square   check    up     down   left   right  rotate  o        x
\  0        1        2      3      4      5      6       7        8
   e067 w,  e068 w,  65 w,  66 w,  67 w,  68 w,  69 w,   e065 w,  e066 w,

\ If the scancode has an e0 prefix, bit#>scancode returns e0 and puts
\ the suffix scancode in pending-scancode where it will be picked up
\ the next time.
: bit#>scancode  ( bit# -- scancode )
   button-scancodes over wa+ w@             ( bit# scancode )
   \ Or in the 80 bit on an "up" transition
   1 rot lshift  last-buttons and  0=  if   ( scancode )
      h# 80 or                              ( scancode' )
   then                                     ( scancode )
   dup h# ff00 and  if                      ( scancode )
      h# ff and to pending-scancode         ( scancode )
      h# e0                                 ( e0 )
   then                                     ( scancode )
;

\ Returns the next button-related scancode byte.
: button-event?  ( -- false | scancode true )
   \ Handle the suffix of an e0-scancode sequence
   pending-scancode  if                              ( )
      pending-scancode  0 to pending-scancode  true  ( scancode true )
      exit                                           ( -- scancode true )
   then                                              ( )

   \ If the pending-buttons change mask is 0, we don't have anymore
   \ events to generate from the last time around, so reread the
   \ game buttons and set pending-buttons to the ones that have
   \ changed.
   pending-buttons  0=  if
      game-key@                                  ( new-buttons )
      dup last-buttons xor  to pending-buttons   ( new-buttons )
      to last-buttons                            ( )
   then

   \ If there are bits set in pending-buttons, generate an event from
   \ the leftmost set bit and remove that bit from pending-buttons.
   pending-buttons  if                           ( )
      \ Find the rightmost changed bit
      pending-buttons choose-bit                 ( bit# )

      \ Remove that bit from pending-buttons so it won't be reported again
      1 over lshift invert                       ( bit# clear-mask )
      pending-buttons and  to pending-buttons    ( bit# )

      \ Generate an up or down scancode sequence corresponding to that bit
      dup bit#>scancode  true                    ( scancode true )
   else                                          ( )
      false                                      ( false )
   then                                          ( false | scancode true )
;

\ Check for a change in button state if necessary.
: or-button?  ( [scancode] key? -- [scancode] flag )
   \ If there is already a key from get-data?, handle it before checking the game buttons
   dup  if  exit  then          ( [scancode] key? phandle )

   \ If the /ec-spi device node is present, the game buttons are directly connected
   \ so we must handle them here.  Otherwise the EC will handle them and fold their
   \ events into the keyboard scancode stream.
   " /ec-spi" find-package  if  ( false phandle )
      2drop                     ( )
      button-event?             ( [scancode] flag )
   then                         ( [scancode] flag )
;

0 value last-timestamp
: selftest-keys  ( -- )
   false to esc?
   clear-key-bitmap
   get-msecs to last-timestamp
   begin
      final-test?  smt-test?  or  if
         key-stuck?  if  exit  then
      then
      get-data?  or-button?  if      ( scancode )
         process-raw                 ( exit? )
         get-msecs to last-timestamp
      else
         final-test?  smt-test?  or  if
            false   \ Final test exit inside process-raw
         else
            get-msecs last-timestamp -  d# 10,000 >=
         then
      then             ( exit? )
   until
   begin  get-data?  while  drop  repeat
;

: toss-keys  ( -- )  begin  key?  while  key drop  repeat  ;

: set-keyboard-type  ( -- )
   smt-test?  if
      0
   else
      " KM" find-tag  if                    ( adr len )
         -null                              ( adr' len' )
         " olpcm" $=  if  2  else  1  then  ( type )
      else                                  ( )
         1                                  ( type )
      then                                  ( type )
   then
   to keyboard-type
   keyboard-type  case

      0 of  ['] make-buttons  ['] ibm#s0  ['] /ibm#s0  ['] all-tested?0  endof
      1 of  ['] make-keys1    ['] ibm#s1  ['] /ibm#s1  ['] all-tested?1  endof
      2 of  ['] make-keys2    ['] ibm#s2  ['] /ibm#s2  ['] all-tested?2  endof
      ( default )  true abort" Unknown keyboard type"
   endcase
   to all-tested?  to /ibm#s  to ibm#s  to make-keys
;

warning @ warning off
: selftest  ( -- error? )
   open  0=  if  true exit  then

   set-keyboard-type

   make-keys

   0 to key-stuck?
   cursor-off draw-keyboard
   true to locked?   \ Disable the keyboard alarm handler; it steals our scancodes
   selftest-keys
   false to locked?
   cursor-on
   screen-ih iselect  erase-screen  iunselect
   page
   close

   final-test? smt-test? or  if
      key-stuck?  if
         ." Stuck key" cr
         true exit
      then

      all-tested?  if
         false
      else
         ." Some keys were not pressed" cr
         true
      then
   else
      confirm-selftest?
   then
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
