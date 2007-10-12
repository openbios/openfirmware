purpose: Populate keymaps from the KA manufacturing data tag
\ See license at end of file

\ Per http://wiki.laptop.org/Manufacturing_Data#Keyboard_ASCII_Map

h# 60 constant /submap

\ Special hack for the OLPC keyboard multiply/divide key, which is
\ sometimes used for ASCII punctuation
: ?multkey  ( scancode -- scancode' )
   \ Translate down to the range that fits in the ASCII keymaps
   dup h# 73 =  if  drop h# 5f   then
;

: !map  ( scancode ascii submap# -- )
   /submap * rot  ?multkey  +  oem-keymap +  1+  c!
;

\ Clear out a range of map entries
: zap  ( first last -- )
   1+ swap  ?do  i 0 0 !map  i 0 1 !map  loop
;

: punctuation  " 0123456789!""#$%&'()*+,-./:;<=>?@[\]^_`{|}~"  drop  ;
: fill-keymap  ( value$ -- )
   oem-keymap /keymap 0 fill    ( adr len )
   3 oem-keymap c!              ( adr len )  \ #submaps
   \ Prime the shift and unshift maps with special characters
   [ also keyboards ] us [ previous ]  3 +  oem-keymap 1+ /submap 2*  move

   \ Clear out some the map entries for the alphanumeric/punctuation stations,
   \ so we don't have confusing leftovers from the US map
   2 h# d zap   h# 10 h# 1b zap  h# 1e h# 29 zap  h# 2b h# 35 zap

   \ Set the a-z entries - assume unshifted and infer shifted
   2dup d# 26 min  0  ?do   ( value$ adr )
      dup i + c@            ( value$ adr scancode )
      [char] a i +          ( value$ adr scancode ascii )
      2dup 0 !map           ( value$ adr scancode ascii )  \ Unshifted
      h# 20 xor  1 !map     ( value$ adr )   \ Shifted
   loop                     ( value$ adr )
   drop                     ( value$ )
   dup d# 26 min /string    ( value$' )
      
   \ Set the 0-9 and punctuation entries in specifed maps
   d# 42 min  0  ?do        ( adr )
      dup  i 2* +           ( adr adr' )
      dup c@                ( adr adr' scancode )
      punctuation i + c@    ( adr adr' scancode ascii )
      rot 1+ c@ !map        ( adr )
   loop                     ( adr )
   drop
;

\ If a KA tag is present, parse it into a keymap
: olpc-keymap?  ( -- got? )
   " KA" " find-tag" eval  if  ( value$ )
      ?free-keymap
      /keymap alloc-mem to oem-keymap                ( adr' len' )
      fill-keymap
      oem-keymap to keymap
      true
   else
      false
   then
;

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
