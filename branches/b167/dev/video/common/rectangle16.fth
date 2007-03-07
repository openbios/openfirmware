\ See license at end of file
purpose: Drawing functions for 16-bit graphics extension

external

: rectangle-setup  ( x y w h -- wb fbadr h )
   swap bytes/pixel * swap                 ( x y wbytes h )
   2swap  /scanline * frame-buffer-adr +   ( wbytes h x line-adr )
   swap bytes/pixel * +                    ( wbytes h fbadr )
   swap                                    ( wbytes fbadr h )
;
: fill-rectangle  ( color x y w h -- )
   rectangle-setup  0  ?do                 ( color wbytes fbadr )
      3dup swap rot                        ( color wbytes fbadr adr wb color )
      bytes/pixel  case                    ( color wbytes fbadr adr wb color )
         1  of   fill  endof
         2  of  wfill  endof
         4  of  lfill  endof
      endcase                              ( color wbytes fbadr )
      /scanline +                          ( color wbytes fbadr' )
   loop                                    ( color wbytes fbadr' )
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
: read-rectangle  ( adr x y w h -- )
   rectangle-setup 0  ?do                  ( adr wbytes fbadr )
      3dup -rot move                       ( adr wbytes fbadr )
      >r  tuck + swap  r>                  ( adr' wbytes fbadr )
      /scanline +                          ( adr' wbytes fbadr' )
   loop                                    ( adr' wbytes fbadr' )
   3drop
;
: dimensions  ( -- width height )
   /scanline bytes/pixel /	( width )
   #scanlines			( width height )
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
