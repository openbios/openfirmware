\ See license at end of file
purpose: Drawing functions for 16-bit graphics extension

external

: rectangle-setup  ( x y w h -- wb fbadr h )
   swap depth * 3 rshift swap              ( x y wbytes h )
   2swap  /scanline * frame-buffer-adr +   ( wbytes h x line-adr )
   swap depth * 3 rshift +                 ( wbytes h fbadr )
   swap                                    ( wbytes fbadr h )
;
: fill-rectangle  ( color x y w h -- )
   rot /scanline *  frame-buffer-adr +          ( color x w h fbadr )
   -rot >r                                      ( color x fbadr w  r: h )
   \ The loop is inside the case for speed
   depth  case                                  ( color x fbadr w  r: h )
      \ The stack before ?do is                 ( color width-bytes fbadr h 0 )
      8     of      -rot         +  r> 0  ?do  3dup swap rot  fill  /scanline +  loop  endof
      d# 16 of  /w* -rot  swap wa+  r> 0  ?do  3dup swap rot wfill  /scanline +  loop  endof
      d# 32 of  /l* -rot  swap la+  r> 0  ?do  3dup swap rot lfill  /scanline +  loop  endof
      ( default )  r> drop nip    ( color x fbadr bytes/pixel )
   endcase                                      ( color width-bytes fbadr )
   3drop
;

: draw-rectangle  ( adr x y w h -- )
   rectangle-setup  0  ?do                 ( adr wbytes fbadr )
      3dup swap move                       ( adr wbytes fbadr )
      >r  tuck + swap  r>                  ( adr' wbytes fbadr )
      /scanline +                          ( adr' wbytes fbadr' )
   loop                                    ( adr' wbytes fbadr' )
   3drop
;

: draw-transparent-rectangle  ( adr x y w h -- )
   rectangle-setup                         ( adr wbytes fbadr h )
   >r  rot  r>                             ( wbytes fbadr adr h )
   0  ?do                                  ( wbytes fbadr adr )
      2 pick 0  ?do                        ( wbytes fbadr adr )
         dup w@ >r  wa1+ r>                ( wbytes fbadr adr' color )
         dup h# ffff =  if                 ( wbytes fbadr adr color )
            drop                           ( wbytes fbadr adr )
         else                              ( wbytes fbadr adr color )
            2 pick i + w!                  ( wbytes fbadr adr )
         then                              ( wbytes fbadr adr )
      /w +loop                             ( wbytes fbadr adr )
      swap /scanline +   swap              ( wbytes fbadr' adr )
   loop                                    ( wbytes fbadr' adr' )
   3drop
;

: read-rectangle  ( adr x y w h -- )
   rectangle-setup 0  ?do                  ( adr wbytes fbadr )
      3dup -rot move                       ( adr wbytes fbadr )
      >r  tuck + swap  r>                  ( adr' wbytes fbadr )
      /scanline +                          ( adr' wbytes fbadr' )
   loop                                    ( adr' wbytes fbadr' )
   3drop
;
: dimensions  ( -- width height )  width height  ;

: replace-color16  ( old new -- )
   frame-buffer-adr  width height * 2* bounds do
      over i w@ = if
         dup i w!
      then
   2 +loop
   2drop
;

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
