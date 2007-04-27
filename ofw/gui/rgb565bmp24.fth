\ See license at end of file
purpose: Conversion from RGB565 raw format to RGB888 BMP

0 value image-width
0 value image-height
0 value #planes
0 value line-bytes

h# 36 constant /bmp-hdr
/bmp-hdr buffer: bmp-hdr

d#  8 constant /565-hdr
/565-hdr buffer: 565-hdr

: copy-scan-line  ( #entries -- )
   0  ?do
      ifd @ fgetc  ifd @ fgetc  bwjoin                   ( rgb565 )
      dup              h# 1f and  3 lshift  ofd @ fputc  ( rgb565 )    \ B
      dup d#  5 rshift h# 3f and  2 lshift  ofd @ fputc  ( rgb565 )    \ G
          d# 11 rshift h# 1f and  3 lshift  ofd @ fputc  ( )           \ R
   loop
;

: get-planes  ( -- )
   #planes 0  ?do    
      image-height 0   do
         image-height i 1+ -  line-bytes *  /565-hdr +  ifd @ fseek
         image-width copy-scan-line
ifd @ ftell . ofd @ ftell . cr

      loop
   loop
;

: putw  ( w -- )  wbsplit  swap  ofd @ fputc  ofd @ fputc  ;

: 565>rects  ( -- )
   1 to #planes
   image-width 2 * to line-bytes

   " BM"  bmp-hdr swap  move           \ Signature
   image-width 3 *  4 round-up  image-height *
   dup  bmp-hdr h# 22 + le-l!          \ Image size
   /bmp-hdr +   bmp-hdr 2 + le-l!      \ File size

   0  bmp-hdr 6 + le-l!                \ Reserved
   /bmp-hdr     bmp-hdr h# 0a + le-l!  \ Image offset
   h# 28        bmp-hdr h# 0e + le-l!  \ Some variant of header size
   image-width  bmp-hdr h# 12 + le-l!
   image-height bmp-hdr h# 16 + le-l!
   #planes      bmp-hdr h# 1a + le-w!
   d# 24        bmp-hdr h# 1c + le-w!
   0            bmp-hdr h# 1e + le-l!  \ Compression

   d# 2835      bmp-hdr h# 26 + le-l!  \ X pixels/meter
   d# 2835      bmp-hdr h# 2a + le-l!  \ Y pixels/meter
   0            bmp-hdr h# 2e + le-l!  \ Colors used
   0            bmp-hdr h# 32 + le-l!  \ Colors important

   bmp-hdr /bmp-hdr  ofd @ fputs
   
   get-planes
;      

: get-c565-hdr  ( -- )
   565-hdr  /565-hdr  ifd @ fgets  /565-hdr <>  abort" Can't get header"
   565-hdr  " C565"  comp  abort" Source file not in C565 format"
   565-hdr  4 +  le-w@  to image-width
   565-hdr  6 +  le-w@  to image-height
;
: rgb565bmp24  ( -- )
   reading writing

   get-c565-hdr

   565>rects
   ifd @ fclose  ofd @ fclose
;
: raw565bmp24  ( -- )
   reading writing
   d# 640 to image-width
   d# 480 to image-height

   565>rects
   ifd @ fclose  ofd @ fclose
;
: xraw565bmp24  ( -- )
   reading writing
   d# 1200 to image-width
   d# 256 to image-height

   565>rects
   ifd @ fclose  ofd @ fclose
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
