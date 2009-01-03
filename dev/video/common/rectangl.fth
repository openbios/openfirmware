\ See license at end of file
purpose: Drawing functions for 8-bit graphics extension

external

: fill-rectangle  ( index x y w h -- )
   2swap  /scanline *  +  frame-buffer-adr +          ( index w h fbadr )
   swap  0  ?do                                       ( index w fbadr )
      3dup swap rot fill                              ( index w fbadr )
      /scanline +                                     ( index w fbadr' )
   loop
   3drop
;
: draw-rectangle  ( adr x y w h -- )
   2swap  /scanline *  +  frame-buffer-adr +          ( adr w h fbadr )
   swap  0  ?do                                       ( adr w fbadr )
      3dup swap move                                  ( adr w fbadr )
      >r  tuck + swap  r>                             ( adr' w fbadr )
      /scanline +                                     ( adr' w fbadr' )
   loop
   3drop
;
: read-rectangle  ( adr x y w h -- )
   2swap  /scanline *  +  frame-buffer-adr +          ( adr w h fbadr )
   swap  0  ?do                                       ( adr w fbadr )
      3dup -rot move                                  ( adr w fbadr )
      >r  tuck + swap  r>                             ( adr' w fbadr )
      /scanline +                                     ( adr' w fbadr' )
   loop
   3drop
;
: dimensions  ( -- width height )  width height  ;

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
