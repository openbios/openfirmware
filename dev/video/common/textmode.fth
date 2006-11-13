\ See license at end of file
purpose: Put the VGA part of the chip into particular PC modes

hex

create strict-ega

: $,  ( adr len -- )
   here over allot  swap  ( adr where len )
[ifdef] note-string  note-string  [then]
   move
;
: place-string  ( adr len -- )  dup c,  $,  ;

defer extended-setup

: next-string  ( table-adr -- table-adr' adr len )  count 2dup + -rot  ;

: set-mode  ( table -- )
   palette-off

   dup c@ misc!  1+

   next-string sequencer   start-seq
   next-string attributes  palette-on reset-attr-addr
   next-string graphics
   next-string crt
   drop   
;

\ Some modes

[ifdef] testing
\ 640x480x8, linear frame buffer

: igs-ext-linear-mode
   h# 11  h# 33  grf!			\ Enable Linear Mapping
   h# 01  h# 57  grf!			\ Enable graphics extended mode
   h# 01  h# 77  grf!			\ 8 bpp
   h# 01  h# 90  grf!			\ Enable graphics contlr ext path

   h# 00  h# 11  grf!
   h# 51  h# 14  grf!
   h# 00  h# 15  grf!
   h# 00  h# 56  grf!
;

create linear-mode
   h# e3 c,

   " "(00 01 0f 00 0e)"
   place-string				\ Sequencer registers

   " "(00 01 02 03 04 05 06 07 10 11 12 13 14 15 16 17 01 00 0f 00 00)"
   place-string				\ Attribute registers

   " "(00 00 00 00 00 40 05 0f ff)"
   place-string				\ Graphics registers

   " "(5f 4f 50 82 54 80 0b 3e 00 40 00 00 00 00 07 80 ea 0c df 50 00 e7 04 e3 ff)"
   place-string				\ CRT registers
[then]


\ CGA/EGA text mode 3

create mode2+/3		\ 80x25, 8x16 character cell
   h# 67 c,				\ MISC register

   " "(00 00 03 00 02)"			\ Seq0 will be set to 3 later
   place-string				\ Sequencer registers

[ifdef] strict-ega
   \ The following line generates the "correct" emulation of the VGA (720x400)
   \ version of text mode 3, which is supposedly compatible with EGA.  EGA
   \ doesn't have a color map; instead it feeds the palette output directly
   \ to the digital monitor color control lines, using either CGA-style (aka
   \ RGBI) digital monitors, which have 4 control lines, one each for
   \ red,green,blue,intensity, or enhanced (aka RrGgBb) digital monitors,
   \ with 2 control lines for each color - high-intensity red (R), low-
   \ intensity red (r), etc.
   \ The palette setting where entry 8 has the value 38 is for RrGgBb monitors
   \ (the bits are 00rgbRGB).
   \ In order for this palette setting to work correctly, it would be
   \ necessary to set the first 64 entries of the color map to emulate the
   \ rgbRGB mapping, where the low,high-intensity bits control 1/3 , 2/3 of
   \ the total intensity.
   " "(00 01 02 03 04 05 14 07 38 39 3a 3b 3c 3d 3e 3f 0c 00 0f 08 00)"
[else]
   \ Alternatively, we initialize the palette so that palette entry x generates
   \ color map index x, allowing us to use the 16 colors that we have already
   \ set up at color map indices 0-15.
   " "(00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 0c 00 0f 08 00)"
[then]
   place-string				\ Attribute registers

   " "(00 00 00 00 00 10 0e 00 ff)"
   place-string				\ Graphics registers

   " "(5f 4f 50 82 55 81 bf 1f 00 4f 0d 0e 00 00 00 00 9c 8e 8f 28 1f 96 b9 a3 ff)"
   place-string				\ CRT registers

: plane-mode     ( -- )  6 4 seq!  c 6 grf!  ;
: odd/even-mode  ( -- )  2 4 seq!  e 6 grf!  ;
[ifdef] testing
: read-font   ( -- )  plane-mode     2 4 grf!  ;
: read-text   ( -- )  plane-mode     0 4 grf!  ;
: read-attrs  ( -- )  plane-mode     1 4 grf!  ;
: read-normal ( -- )  odd/even-mode  0 4 grf!  ;
[then]

: write-font  ( -- )
   \ Turn off odd/even mode so we can access all of plane 2, without
   \ directing odd addresses to plane 3.
   plane-mode
   4 2 seq!		\ Set the plane mask to write only to plane 2
;
: write-text  ( -- )
   \ Restore odd/even mode and the plane mask for planes 0 and 1, which
   \ contain the text and the text attribute bytes, respectively.
   odd/even-mode  3 2 seq!
;

0 value ega

: fill-text  ( len value -- )
   ega rot 2*  bounds  do  dup i c!  2 +loop  drop
;
: fill-attrs  ( len value -- )
   ega rot 2*  bounds  do  dup i 1+ c!  2 +loop  drop
;
: pc-font  ( -- )
   write-font
   default-font ( 2>r ) >r >r   ( adr width +-height advance  r: min,#glyphs )
   1 <>  rot 8 > or  over 0>= or
   if  true " Incompatible font"  type abort  then       ( adr -height )
   negate  swap  ( 2r> ) r> r>  bounds   ?do             ( height adr )
      2dup  ega i h# 20 * +  rot  move         ( height adr )
      over +                                   ( height adr' )
   loop                                        ( height adr )
   2drop                                       ( )
   write-text
;
create ega-colors
" "(00 00 00  00 00 aa  00 aa 00  00 aa aa)"  $,
" "(aa 00 00  aa 00 aa  aa aa 00  aa aa aa)"  $,
" "(00 00 55  00 00 ff  00 aa 55  00 aa ff)"  $,
" "(aa 00 55  aa 00 ff  aa aa 55  aa aa ff)"  $,
" "(00 55 00  00 55 aa  00 ff 00  00 ff aa)"  $,
" "(aa 55 00  aa 55 aa  aa ff 00  aa ff aa)"  $,
" "(00 55 55  00 55 ff  00 ff 55  00 ff ff)"  $,
" "(aa 55 55  aa 55 ff  aa ff 55  aa ff ff)"  $,
" "(55 00 00  55 00 aa  55 aa 00  55 aa aa)"  $,
" "(ff 00 00  ff 00 aa  ff aa 00  ff aa aa)"  $,
" "(55 00 55  55 00 ff  55 aa 55  55 aa ff)"  $,
" "(ff 00 55  ff 00 ff  ff aa 55  ff aa ff)"  $,
" "(55 55 00  55 55 aa  55 ff 00  55 ff aa)"  $,
" "(ff 55 00  ff 55 aa  ff ff 00  ff ff aa)"  $,
" "(55 55 55  55 55 ff  55 ff 55  55 ff ff)"  $,
" "(ff 55 55  ff 55 ff  ff ff 55  ff ff ff)"  $,

d# 80 constant #text-columns
d# 25 constant #text-rows

external

: text-mode3  ( -- )
   io-base -1 =  if  map-io-regs  then
   mode2+/3 set-mode
   ext-textmode
\  h# c00b.8000 0  h# 8200.0000  h# 8000  " map-in" $call-parent  to ega
   h# 000b.8000 0  h# 8200.0000  h# 8000  " map-in" $call-parent  to ega
   pc-font
   #text-rows #text-columns  *  dup bl fill-text   7 fill-attrs
[ifdef] strict-ega
   ega-colors  0  d# 64  (set-colors)
[then]
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
