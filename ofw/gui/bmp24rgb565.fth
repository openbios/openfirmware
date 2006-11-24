\ See license at end of file
purpose: Conversion from RGB888 BMP to RGB565 raw formats

0 value image-width
0 value image-height
0 value #planes
0 value line-bytes

h# 36 constant /bmp-hdr
/bmp-hdr buffer: bmp-hdr

: copy-scan-line  ( #entries -- )
   0  ?do
      ifd @ fgetc  3 rshift                   ( src val )   \ B
      ifd @ fgetc  2 rshift  d#  5 lshift or  ( src val' )  \ G
      ifd @ fgetc  3 rshift  d# 11 lshift or  ( src val' )  \ R
      wbsplit      ( low high )
      swap  ofd @ fputc  ofd @ fputc
   loop
;

: get-planes  ( -- )
   #planes 0  ?do    
      image-height 0   do
         image-height i 1+ -  line-bytes *  /bmp-hdr +  ifd @ fseek
         image-width copy-scan-line
      loop
   loop
;

: putw  ( w -- )  wbsplit  swap  ofd @ fputc  ofd @ fputc  ;

: bmp>rects  ( -- )
   bmp-hdr h# 12 + le-l@  to image-width
   bmp-hdr h# 16 + le-l@  to image-height
   bmp-hdr h# 1a + le-w@  to #planes

   bmp-hdr h# 1c + le-w@  d# 24 <>  abort" Not 24-bit format"
   image-width 3 *  4 round-up  to line-bytes

   " C565" ofd @ fputs
   image-width putw  image-height putw
   
   get-planes
;      

: bmp24rgb565  ( -- )
   reading writing
   bmp-hdr  /bmp-hdr  ifd @ fgets  /bmp-hdr <>  abort" Can't get header"
   
   bmp>rects
   ifd @ fclose  ofd @ fclose
;

[ifdef] notdef
Here is a dump of a 24-bit BMP header.

             Magic filesize... .res.  .res. imageoffset hdrsize.
    00000000 42 4d 5e d7 00 00 00 00  00 00 36 00 00 00 28 00

             ..... Width...... Height...... #plns depth compre.
    00000010 00 00 87 00 00 00 87 00  00 00 01 00 18 00 00 00

            .ssion ImageSize.. pels/meter-x pels/meterY #colors-used
    00000020 00 00 28 d7 00 00 13 0b  00 00 13 0b 00 00 00 00

             .ents #cols-impor Image_Data............
    00000030 00 00 00 00 00 00 ad 18  29 00 ad 21 31 00 ad 29
    ...
             ..................Image........
    0000d750 ff ff ff ff ff ff ff ff ff ff ff 00 00 00

Magic is 'BM'
Numerical values are in little-endian
compression values: 0-RGB  1-RLE4  2-RLE8
hdrsize     values: 0xc-old format  0x28-new Windows  0x40-new OS2
The image array follows the header.  It is stored as a sequence of
scan lines, each of which is padded if necessary to occupy a multiple
of 4 bytes in the file.  The first scan line in the file is the one that
appears at the bottom of the visual image.
[then]

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
