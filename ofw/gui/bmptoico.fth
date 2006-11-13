\ See license at end of file
\ Forth program to extract the image data or the color lookup table data
\ from a ".BMP" bitmap image file and write the raw data (minus headers, etc)
\ to a file.  This is used to prepare icon images for the Open Firmware GUI.

\ To use, start Forth on a development system, load this file, and then
\ execute one of:
\   bmp-to-clut  ( "in-file" "out-file" -- )   \ Extract CLUT data
\   bmp-to-icon  ( "in-file" "out-file" -- )   \ Extract image data
\
\ For example:
\
\   bmp-to-icon foo.bmp foo.ico

fload ${BP}/ofw/gui/bmptools.fth

0 value bmp-adr
0 value bmp-size
: open-bmp  ( "in-file" -- adr w h clut-adr color# #colors )
   reading
   ifd @ fsize  to bmp-size
   bmp-size  alloc-mem   to bmp-adr
   bmp-adr bmp-size  ifd @ fgets  bmp-size <> abort" Error reading BMP file"
   bmp-adr bmp>rect            ( adr w h clut-adr color# #colors )
   bmp-adr bmp-size free-mem   ( adr w h clut-adr color# #colors )
   ifd @ fclose
;
: bmp-to-clut  ( "in-file" "out-file" -- )
   open-bmp                    ( adr w h clut-adr color# #colors )
   writing                     ( adr w h clut-adr color# #colors )
   nip  3 *  2dup ofd @ fputs  ( adr w h clut-adr #bytes )
   ofd @ fclose                ( adr w h clut-adr #bytes)
   free-mem                    ( adr w h )
   * free-mem                  ( )
;
: bmp-to-icon  ( "in-file" "out-file" -- )
   open-bmp              ( adr w h clut-adr color# #colors )
   nip 3 * free-mem      ( adr w h )
   writing               ( adr w h )
   3dup * ofd @ fputs    ( adr w h )
   ofd @ fclose          ( adr w h )
   * free-mem            ( )
;

: putb  ( l -- )  ofd @ fputc  ;
: putw  ( w -- )  wbsplit  swap  putb  putb  ;
: putl  ( l -- )  lwsplit  swap  putw  putw  ;
: write-header  ( adr w h clut-adr color# #colors -- )
   [char] B putb  [char] M putb			\ 00 - Magic
   4 pick 4 round-up  4 pick *  h# 436 +  putl	\ 02 - File size
   0 putw  0 putw				\ 06 - reserved
   h# 436 putl          	                \ 0a - image offset
   h# 28 putl					\ 0e - secondary header size
   4 pick putl					\ 12 - width
   3 pick putl					\ 16 - height
   1 putw					\ 1a - #planes
   8 putw                                       \ 1c - depth (bits/pixel)
   0 putl					\ 1e - compression
   4 pick 4 round-up  4 pick *  putl		\ 22 - Image bytes
   0 putl					\ 26 - X-Pixels/Meter
   0 putl					\ 2a - Y-Pixels/Meter
   d# 256 putl					\ 32 - #colors used
   d# 256 putl					\ 32 - #colors important
;
: write-clut  ( clut-adr color# #colors -- )
   over  0  ?do  0 putl  loop			\ Initial color entries
   2dup + >r                     ( clut-adr color# #colors r: end-color )
   bounds  ?do                                          ( clut-adr  r: " )
      dup 2+ c@ putb  dup 1+ c@ putb  dup c@ putb       ( clut-adr  r: " )
      0 putb  3 +                                       ( clut-adr' r: " )
   loop                                                 ( clut-adr' r: " )
   drop                                                 ( r: end-color )
   h# 100  r>  ?do  0 putl  loop
;
: write-image  ( adr w h -- )
   2dup  or  0=  if  3drop exit  then                ( adr w h )
   swap to image-width                               ( adr h )
   image-width 4 round-up image-width -  -rot        ( #pad adr h )
   1- image-width *  bounds  swap  ?do               ( #pad )
      i image-width  bounds  ?do  i c@ putb  loop    ( #pad )
      dup  0  ?do  0 putb  loop			     ( #pad )  \ padding
   image-width negate +loop                          ( #pad )
   drop
;

: free-clut   ( clut-adr color# #colors -- )  nip 3 * free-mem  ;
: free-image  ( adr w h -- )  * free-mem  ;
: (write-bmp)  ( adr w h clut-adr color# #colors -- )
   write-header      ( adr w h clut-adr color# #colors )
   3dup write-clut   ( adr w h clut-adr color# #colors )
   free-clut         ( adr w h )
   3dup write-image  ( adr w h )
   free-image        ( )
   ofd @ fclose      ( )
;
: write-bmp  ( adr w h clut-adr color# #colors "out-file" -- )
   writing  (write-bmp)
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
