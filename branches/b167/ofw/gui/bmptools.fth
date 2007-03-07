\ See license at end of file
purpose: Conversions between .BMP format and internal image format

\ These tools convert from Windows/OS2 .BMP format to Open Firmware
\ internal format, and also allow you to adjust color lookup table (CLUT)
\ entries.  CLUT adjustments include packing the colors that are actually
\ used in the image array into a contiguous sequence of color indices and
\ adding a fixed offset to the color indices.  These adjustments are useful
\ when the fixed number of system CLUT indices must be allocated among a
\ number of different images, and when certain pre-allocated ranges (e.g.
\ the 16 standard DOS colors) must be avoided.

\ The Open Firmware internal image format is that established by the
\ arguments to the methods defined by the "8-bit Graphics Extension"
\ Recommended Practice document.
\ The image data is stored in memory as an array of "height" scan-lines,
\ each consisting of "width" bytes, each byte containing a CLUT index.
\ There is no padding between scan lines, even if "width" is not a multiple
\ of say 4.  The first scan-line in the memory image corresponds to the
\ line at the top of the visual image.
\ The CLUT data is stored in memory as an array of "#colors" color values,
\ each consisting of three bytes representing red, green, and blue intensities
\ in that order.  The first color value in the array corresponds to the
\ CLUT index "color#", the second to "color#+1", and so on.  The intensity
\ values go from 0 to 255; if the hardware cannot display that many distinct
\ intensities, it is the device driver's responsibility to convert from the
\ 8-bit intensity space to the hardware's space.

0 value color#
0 value #colors

0 value image-width
0 value image-height
0 value #planes
0 value bmp-line-width
0 value clut
0 value /clut

defer copy-scan-line  ( src dst #entries -- )
['] move to copy-scan-line

: copy16  ( src dst #entries -- )
   0 do
      over i 2/ + c@  i 1 and 0= if  4 rshift  then  h# f and
      ( src dst nibble )
      over i + c!
   loop
   2drop
;

: copy2  ( src dst #entries -- )
   0 do
      over i 3 rshift + c@  7  i 7 and -  rshift  1 and
      ( src dst nibble )
      over i + c!
   loop
   2drop
;

: decode-depth  ( depth -- 'copy-scan-line bytes/line /clut )
   case
     1 of
        ['] copy2   image-width 7 + 8 /      2   ( xt bytes/line #colors )
     endof
     4 of
        ['] copy16  image-width 1 + 2/   d# 16   ( xt bytes/line #colors )
     endof
     8 of
        ['] move    image-width         d# 256   ( xt bytes/line #colors )
     endof
     ( default )  ." Unsupported color depth: " . cr abort
   endcase
;
: get-clut  ( bmp-clut-adr -- )
   /clut alloc-mem  to clut

   \ Set LUT
   clut  /clut bounds  ?do
      dup c@  i 2+ c!  dup 1+ c@  i 1+ c!  dup 2+ c@  i c!
      la1+
   3 +loop
   drop
;

: get-planes  ( rect-adr bmp-adr -- )
   #planes 0  ?do                                            ( rect bmp-adr )
      over image-height 1-  image-width * bounds  swap  do   ( rect bmp-adr )
         dup i image-width copy-scan-line                    ( rect bmp-adr )
         bmp-line-width +                                    ( rect bmp-adr' )
      image-width negate +loop                               ( rect bmp-adr' )
      swap  image-width image-height * +  swap               ( rect' bmp-adr' )
   loop
   2drop
;

: bmp>rects  ( bmp-adr -- adr w h #planes clut-adr color# #colors )
   >r
   r@ h# 12 + le-l@  to image-width
   r@ h# 16 + le-l@  to image-height
   r@ h# 1a + le-w@  to #planes

   r@ h# 1c + le-l@  decode-depth         ( xt width #colors )
   to #colors   4 round-up  to bmp-line-width  to copy-scan-line
   #colors 3 * to /clut

   r@ h# 36 +  get-clut

   image-width image-height * #planes * alloc-mem            ( rect-adr )
   dup  r@  h# a + le-l@  r> +   get-planes                  ( rect-adr )
   image-width image-height  #planes  clut 0 #colors
;      

: bmp>rect  ( bmp-adr -- adr w h clut-adr color# #colors )
   bmp>rects            ( adr w h #planes clut-adr color# #colors )
   2>r >r               ( adr w h #planes r: color#,#colors clut-adr )
   dup 1 <>  if         ( adr w h #planes r: color#,#colors clut-adr )
      4dup >r * r>      ( .. adr /plane #planes r: .. )
      1- over *         ( .. adr /plane /unused r: .. )
      >r + r> free-mem  ( adr w h #planes r: color#,#colors clut-adr )
      /                 ( adr w h' #planes r: color#,#colors clut-adr )
   else                 ( adr w h #planes r: color#,#colors clut-adr )
      drop              ( adr w h r: color#,#colors clut-adr )
   then                 ( adr w h r: color#,#colors clut-adr )
   r> 2r>               ( adr w h clut-adr color# #colors )
;

0 value clut'
0 value color#'
0 value #colors'
0 value clut-map

\ Allocate and free memory for the temporary CLUT map array
\ Each map entry consists of 2 bytes:
\    0: flag       - non0 if allocated, 0 if not
\    1: new color#
: alloc-map  ( -- )
   d# 256 /w* alloc-mem to clut-map
   clut-map  d# 256 /w*  erase
;
: free-map  ( -- )  clut-map  d# 256 /w*  free-mem  ;

\ Scan the image, replacing color indices with densely-packed indices
\ beginning at color#'.  Upon exit, #colors' is the number of distinct
\ colors that were present in the image array, the clut-map array contains
\ the translation from old to new (densely-packed) color numbers, and the
\ image contains the new color numbers.

: map-colors  ( image-adr len -- )
   0 to #colors'
   bounds  ?do                                ( )
      clut-map  i c@  wa+                     ( adr )     \ Get image's color# 
      dup c@   if                             ( adr )     \ Old map entry
         1+ c@                                ( color' )  \ Get new color#
      else                                    ( adr )     \ New map entry
         1 over c!                            ( adr )     \ Set flag
         color#' #colors' + tuck  swap 1+ c!  ( color' )  \ Set new color#
         #colors' 1+ to #colors'              ( color' )  \ Allocate it
      then                                    ( color' )
      i c!                                    ( )         \ Update image
   loop
;

\ Create a new CLUT array clut', using the clut-map array (which was created by
\ map-colors) and the colors from the old CLUT array clut.
: new-clut  ( -- )   
   #colors' 3 * alloc-mem to clut'
   d# 256  0  do
      clut-map i wa+ c@  if
         \ Copy color entry from old CLUT to new one
         clut  i color# -  3 *  +                       ( old-adr )
         clut'  clut-map i wa+ 1+ c@ color#' -  3 *  +  ( old-adr new-adr )
         3 move
      then
   loop
;

\ Creates a new clut that contains only those colors that are actually
\ used in the image, adjusting the image pixels to the new color indices.
\ The new color indices begin at new-color#.
: pack-colors  ( adr w h clut-adr color# #colors new-color# -- ... )
   ( ... -- adr w h clut-adr' new-color# #colors' )
   to color#'                    ( adr w h clut-adr c# #c )
   \ The incoming clut-adr is the base address corresponding to
   \ the color "color#".  We compute the base address corresponding
   \ to color 0 so we can use the color indices from the rectangle
   \ directly.
   to #colors  to color#  to clut  ( adr w h )
   alloc-map                       ( adr w h )
   3dup *  map-colors              ( adr w h )
   new-clut                        ( adr w h )
   free-map                        ( adr w h )
   clut #colors 3 * free-mem       ( adr w h )  \ Release old CLUT
   clut' color#' #colors'          ( adr w h clut-adr color# #colors )
;

\ Adjusts all color indices up to begin at new-color#, but don't
\ change color #255, which usually means bright white.
: push-colors  ( adr w h clut-adr color# #colors new-color# -- ... )
               ( ... -- adr w h clut-adr' new-color# #colors' )
   to color#'  to #colors  to color#  to clut        ( adr w h )
   3dup *  bounds  do                                ( adr w h )
      i c@                                           ( adr w h color )
      \ Don't modify color 255; assume it's white
      dup d# 255 <>  if  color#' + color# -  then    ( adr w h color' )
      i c!                                           ( adr w h )
   loop                                              ( adr w h )
   clut  color#'                                     ( adr w h clut color# )

   #colors  color#'  +  d# 255 >  if
      d# 255  color#' -
   else
      #colors
   then                                              ( adr w h clut c# #c )
;

\ Dump the CLUT in human-readable form
[ifndef] c@+
: c@+  ( adr -- adr' b )  dup 1+ swap c@  ;
[then]
: dump-clut  ( clut-adr color# #colors -- )
   push-hex
   bounds  ?do                ( adr )
      c@+ 3 u.r  c@+ 3 u.r  c@+ 3 u.r  ."  ( " i . ." )"  cr
   loop  drop
   pop-base
;

[ifdef] notdef
Here is a dump of an 8-bit BMP header.
For more info about the BMP format, look at /usr/local/src/xv-3.10a/xvbmp.c

nocup.bmp:
             Magic filesize... .res.  .res. imageoffset hdrsize.
    00000000 42 4d 7a 15 00 00 00 00  00 00 36 04 00 00 28 00

             ..... Width...... Height...... #plns depth compre.
    00000010 00 00 32 00 00 00 55 00  00 00 01 00 08 00 00 00

            .ssion ImageSize.. pels/meter-x pels/meterY #colors-used
    00000020 00 00 44 11 00 00 00 00  00 00 00 00 00 00 00 01

             .ents #cols-impor CLUT............
    00000030 00 00 00 01 00 00 ad 18  29 00 ad 21 31 00 ad 29
    ...
             .............CLUT Image.........................
    00000430 00 00 ff ff ff 00 ff ff  ff ff ff ff ff ff ff ff
    ...
             ..................Image
    00001570 ff ff ff ff ff ff 00 00

Magic is 'BM'
Numerical values are in little-endian
compression values: 0-RGB  1-RLE4  2-RLE8
hdrsize     values: 0xc-old format  0x28-new Windows  0x40-new OS2
For 8-bit color, each CLUT entry is 4 bytes:  blue, green, red, pad
The image array follow the CLUT.  It is stored as a sequence of
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
