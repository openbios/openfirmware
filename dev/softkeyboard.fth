purpose: Interactive keyboard test shows which keys are pressed
\ See license at end of file

: bounded?  ( n  lower size -- flag )  bounds swap  within  ;

: inside?  ( tx ty  x y  w h -- flag )
   >r                     ( tx ty  x y  w  r: h )
   swap >r                ( tx ty  x    w  r: h y )
   rot  >r                ( tx     x    w  r: h y ty )
   bounded?  if           (                r: h y ty )
      r> r> r>  bounded?  ( flag )
   else                   (                r: h y ty )
      r> r> r>  3drop     ( )
      false               ( flag )
   then                   ( flag )
;

dev /touchscreen
new-device

" hotspot" device-name
: open  ( -- okay? )  true  ;
: close  ;

0 0 instance 2value hit-xy
0 0 instance 2value hit-wh
: set-hotspot  ( x y w h -- )  to hit-wh  to hit-xy  ;
: hit?  ( -- flag )
   " pad?" $call-parent   0=  if   ( )
      false exit                   ( -- false )
   then                            ( pad-x,y,z down? contact# )
   drop  if                        ( pad-x,y,z  )
      drop  hit-xy hit-wh inside?  ( flag )
   else                            ( pad-x,y,z  )
      3drop  false                 ( false )
   then                           ( flag )
;
: read  ( adr len -- actual | -1 )
   0=  if  drop -1 exit  then     ( adr )
   hit?  if                       ( adr )
      carret swap c!  1           ( 1 )
   else                           ( adr )
      drop  -1                    ( -1 )
   then                           ( 1 | -1 )
;

finish-device
device-end


dev /touchscreen
new-device

" keyboard" device-name

hex

struct
   /w field >key-x
   /w field >key-y
   /w field >key-w
   /w field >key-h
   /c field >key-code1
   /c field >key-code2
constant /key

/key d# 128 * buffer: keys

0 value #keys
0 value key-y
0 value key-x

d#   8 constant key-gap
d#  10 constant row-gap
d#   0 constant hidden-key-w
d#  60 constant smulti-key-w
d#  60 constant single-key-w
d#  60 constant single-key-h
d#  90 constant shift-key-w
d# 460 constant space-key-w
d# 400 constant top-row-offset
d#  34 constant button-w
d#  34 constant button-h

: key-adr  ( i -- adr )  /key * keys +  ;

0 value codes1
0 value codes2
: set-codes  ( adr2 len2 adr1 len1 -- )  drop to codes1  drop to codes2  ;
: set-key-code  ( key -- )
   key-adr  ( 'key )
   codes1 c@  over >key-code1 c!  1 codes1 + to codes1
   codes2 c@  swap >key-code2 c!  1 codes2 + to codes2
;

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
   r@ >key-h w! r@ >key-w w!  r@ >key-y w!  r@ >key-x w!
   r> drop
   #keys set-key-code
   #keys++
;
: make-key  ( w -- )  dup  key-x key-y  rot single-key-h  (make-key)  ++key-x  ;
: make-key&gap  ( w -- )  make-key add-key-gap  ;
: make-single-key  ( -- )  single-key-w make-key&gap  ;
: blank-single-key  ( -- )  single-key-w ++key-x  add-key-gap  ;
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
0 [if]
: make-button  ( x y -- )  button-w button-h (make-key)  ;

: make-buttons
   d#   68 d#  25 make-button  \ Rocker up    65
   d#   25 d#  68 make-button  \ Rocker left  67
   d#  110 d#  68 make-button  \ Rocker right 68
   d#   68 d# 110 make-button  \ Rocker down  66
   d#   68 d# 196 make-button  \ Rotate       69

   d#  918 d#  25 make-button  \ O            e0 65
   d#  875 d#  68 make-button  \ square       e0 67
   d#  960 d#  68 make-button  \ check        e0 68
   d#  918 d# 110 make-button  \ X            e0 66
;
[then]

: make-keys  ( -- )
   0 to #keys

   top-key-row
   " ~!@#$%^&*()_+"b"
   " '1234567890-="b" set-codes
   d# 13 0  do  make-single-key  loop
   make-double-key
   next-key-row
   " "tQWERTYUIOP{}"r"
   " "tqwertyuiop[]"r" set-codes
   d# 13 0  do  make-single-key  loop
   make-quad-key

   next-key-row
   " "(80)ASDFGHJKL:""|"
   " "(80)asdfghjkl;'\" set-codes
   d# 13 0  do  make-single-key  loop

   next-key-row
   " "(81)ZXCVBNM<>?"(8186)"            \ 86 may be unused
   " "(81)zxcvbnm,./"(8182)" set-codes  \ 82 may be unused
   make-shift-key
   d# 10 0  do  make-single-key  loop
   make-shift-key
   make-single-key

   next-key-row
   " "(1b) "(878889)"
   " "(1b) "(838485)" set-codes
   make-single-key
   2 0  do  blank-single-key  loop
   make-space-key
   2 0  do  blank-single-key  loop
   3 0  do  make-single-key  loop

\  make-buttons
;

: >key-bounds  ( 'key -- x y w h )
   >r  r@ >key-x w@  r@ >key-y w@  r@ >key-w w@  r> >key-h w@
;
: key-hit?  ( x y key# -- )
   key-adr >key-bounds  inside?
;
: find-key?  ( x y -- false | key# true )
   #keys 0  do              ( x y )
      2dup i key-hit?  if   ( x y )
         2drop i true       ( key# true )
         unloop exit        ( -- key# true )
      then                  ( x y )
   loop                     ( x y )
   2drop false              ( false )
;

\ 80 ctrl   81 shift
\ 82 up     83 left  84 down   85 right
\ 86 pg up  87 home  88 pg dn  89 end

h# f81f constant down-key-color
h# 07ff constant tested-key-color
h# 001f constant idle-key-color
h# ffff constant kbd-bc

0 value esc?

: key-inset  ( dx dy 'key -- x y )
   >key-bounds 2drop     ( dx dy x y )
   rot +  >r  +  r>      ( x y )
;
: string-label  ( adr len 'key -- )
   d# 15 d# 25 rot key-inset   ( adr len x y )
   type-at-xy                 ( )
;
: special-label?  ( char -- flag )  h# 20  h# 7e  between  0=  ;
: special-label  ( char 'key -- )
   >r                            ( char r: 'key )
   case
      h# 08  of  " Backspace"  r> string-label  endof
      h# 09  of  " Tab"    r> string-label  endof
      h# 1b  of  " Esc"    r> string-label  endof
      h# 80  of  " Ctrl"   r> string-label  endof
      h# 81  of  "  Shift" r> string-label  endof
      h# 82  of  "  Up"    r> string-label  endof
      h# 83  of  " Left"   r> string-label  endof
      h# 84  of  " Down"   r> string-label  endof
      h# 85  of  " Right"  r> string-label  endof
      h# 0d  of  " Enter"  d# 35 d# 55 r> key-inset type-at-xy  endof
      ( default )  r> drop
   endcase
;
: label-key  ( color 'key -- )
   >r   to char-bg  kbd-bc to char-fg    ( r: 'key )
   r@ >key-code2 c@                      ( char  r: 'key )
   dup special-label?  if                ( char  r: 'key )
      r> special-label exit              ( )
   then                                  ( char  r: 'key )
   dup [char] A [char] Z between  if     ( letter  r: 'key )
      d# 10 d# 10 r> key-inset           ( char x y  )
      character-at-xy                    ( )
   else                                  ( char        r: 'key )
      d# 40 d# 10 r@ key-inset           ( char x y    r: 'key )
      character-at-xy                    (             r: 'key )
      r@ >key-code1 c@                   ( char x y    r: 'key )
      d# 25 d# 35 r> key-inset           ( char x y  )
      character-at-xy                    ( )
   then
;   
: draw-key  ( key# color -- )
   swap key-adr >r                       ( color r: 'key )
   r@ >key-w w@  hidden-key-w  =  if     ( color r: 'key )
      r> 2drop                           ( )
   else                                  ( color r: 'key )
      dup r@ >key-bounds                 ( color  x y w h  r: 'key )
      " fill-rectangle" $call-screen     ( color  r: 'key )
      r> label-key                       ( )
   then
;

0 value ctrl?
0 value shift?

: get-ascii?  ( key# -- false | ascii true )
   key-adr                               ( 'key )
   shift?  if  >key-code2  else  >key-code1  then  c@  ( code )

   dup h# 80 >=  if                      ( code )
      case
         h# 80  of  true to ctrl?   endof
         h# 81  of  true to shift?  endof
         \ Rest are reserved
      endcase
      false exit                         ( -- false )
   then                                  ( code )

   ctrl?  if                             ( code )
      dup h# 40  h# 7f  between  if      ( code )
         h# 1f and  true                 ( ascii true )
      else                               ( code )
         drop false                      ( false )
      then                               ( false | ascii true )
      exit                               ( -- false | ascii true )
   then                                  ( code )

   true
;
: cancel-shifts  ( key# -- )
   key-adr >key-code1 c@   ( code )
   case
      h# 80  of  false to ctrl?   endof
      h# 81  of  false to shift?  endof
      \ Rest are reserved
   endcase
;

: key-down   ( key# -- )  down-key-color draw-key  ;
: key-up     ( key# -- )
    dup cancel-shifts
    idle-key-color draw-key
;

: fill-screen  ( color -- )
   0 0 " dimensions" $call-screen " fill-rectangle" $call-screen
;

struct
   /n field >contact-time
   /n field >contact-key#
constant /contact

d# 10 /contact * buffer: contacts

: >contact  ( contact# -- 'contact )  /contact *  contacts +  ;
: cancel-contact  ( contact# -- )  >contact >contact-key# off  ;
: get-contact-key#?  ( contact# -- false | key# true )
   >contact >contact-key# @  ( n )
   dup  if  1- true  then    ( false | key# true )
;
: set-contact-key#  ( contact# key# -- )
   1+ swap                   ( key#' contact# )
   >contact >contact-key# !  ( )
;
          
d#  100 value short  \ Auto-repeat interval in ms
d# 1000 value long   \ Initial auto-repeat interval in ms

: set-repeat  ( contact# interval -- )
   get-msecs +                     ( adr ascii contact# new-time )
   swap >contact >contact-time !   ( adr ascii contact# new-time )
;
: get-repeat  ( contact# -- time )  >contact >contact-time @  ;

\ Records the contact and returns the key code if there is one
: return-key-code  ( adr contact# key# -- -1 | 1 )
   over long set-repeat     ( adr contact# key# )  \ Set repeat time
   tuck set-contact-key#    ( adr key# )           \ Remember key
   get-ascii?  if           ( adr ascii )
      swap c!  1            ( 1 )
   else                     ( adr )
      \ There was no ASCII code - probably it was ctrl or shift -
      \ so nothing to return.
      drop -1               ( -1 )
   then                     ( 1 | -1 )
;

\ Called when a finger is still down in the same key area as before.
\ Repeats the key code when the time is right.
: ?repeated  ( adr contact# key# -- )
   get-ascii?  if           ( adr contact# ascii )
      swap dup get-repeat   ( adr ascii contact# time )
      get-msecs - 0<=  if   ( adr ascii contact# )
         short set-repeat   ( adr ascii )
         swap c!  1         ( 1 )
      else                  ( adr ascii contact# )
         3drop -1           ( -1 )
      then                  ( 1 | -1 )
   else                     ( adr contact# )
      \ No code value, so no need to auto-repeat
      2drop -1              ( -1 )
   then                     ( 1 | -1 )
;

: press-key  ( adr x y contact# -- 1 | -1 )
   -rot find-key?  if             ( adr contact# key# )
      \ The event happened in a key area
      over get-contact-key#?  if  ( adr contact# key# old-key# )
         \ Continued press
         2dup =  if               ( adr contact# key# old-key# )
            \ Same - check for auto-repeat
            drop                  ( adr contact# key# )
            ?repeated             ( -1 | 1 )
         else                     ( adr contact# key# old-key# )
            \ Different - release old key and activate new one
            key-up                ( adr contact# key# )
            dup key-down          ( adr contact# key# )
            return-key-code       ( -1 | 1 )
         then                     ( -1 | 1 )
      else                        ( adr contact# key# )
         \ New keypress
         dup key-down             ( adr contact# key# )
         return-key-code          ( 1 )
      then         
   else                           ( adr contact# )
      \ The event happened outside a key area
      dup get-contact-key#?  if   ( adr contact# old-key# )
         \ Moved out of key area - release key
         key-up                   ( adr contact# )
         cancel-contact           ( adr )
         drop -1                  ( -1 )
      else                        ( adr contact# )
         \ Press in blank area with nothing down
         2drop -1                 ( -1 )
      then                        ( -1 )
   then                           ( 1 | -1 )
;

: release-key  ( adr x y contact# -- -1 )
   dup get-contact-key#?  if  ( adr x y contact# key# )
      key-up                  ( adr x y contact# )
   then                       ( adr x y contact# )
   cancel-contact             ( adr x y )
   3drop -1                   ( -1 )
;

: read  ( adr len -- actual | -1)
   0=  if  drop -1 exit  then     ( adr )
   " pad?" $call-parent   0=  if  ( adr )
      drop  -1 exit               ( -- -1 )
   then                           ( adr x y z down? contact# )
   rot drop  swap  if             ( adr x y contact# )
      press-key                   ( 1 | -1 )
   else                           ( adr x y contact# )
      release-key                 ( -1 )
   then                           ( 1 | -1 )
;

0 [if]
: poller  ( -- )
   begin  here 1 read 0> if  here c@ emit  then   ukey? until
;
[then]

: erase-keyboard  ( color -- )
   kbd-bc   0 top-row-offset               ( color x y )
   " dimensions" $call-screen  2over xy-   ( color x y w h )
   " fill-rectangle" $call-screen          ( )
;

: draw-keyboard  ( -- )
   kbd-bc fill-screen
   #keys 0  ?do  i key-up  loop
;

variable buf
: flush  ( -- )
   begin  buf 1  read  0<  until
;

: open  ( -- okay? )
   make-keys
   draw-keyboard
   flush
   true
;
: close  ( -- )
   erase-keyboard
;

finish-device
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
