purpose: fb8 package support routines
\ See license at end of file

\ Rectangular regions are defined by "adr width height bytes/line".
\ "adr" is the address of the upper left-hand corner of the region.
\ "width" is the width of the region in pixels (= bytes, since
\ this is the 8-bit-per-pixel package).  "height" is the height of the
\ region in scan lines.  "bytes/line" is the distance in bytes from
\ the beginning of one scan line to the beginning of the next one.

\ Within the rectangular region, replace bytes whose current value is
\ the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb8-invert  ( adr width height bytes/line fg-color bg-color -- )
   mov     r0,tos
   ldmia   sp!,{r1,r2,r3,r4,r5,tos}
   \ r0:bg-colour  r1:fg-colour r2:bytes/line  r3:height  r4:width  r5:adr

   begin
      cmp     r3,#0
   > while
      mov     r6,#0
      begin
         cmp     r4,r6		\ more pixels/line?
      > while
         ldrb    r7,[r5,r6]	\ get pixel colour at adr+offset
         cmp     r7,r0
         streqb  r1,[r5,r6]
         cmp     r7,r1
         streqb  r0,[r5,r6]
         inc     r6,#1
      repeat
      add     r5,r5,r2
      dec     r3,#1
   repeat
c;

\ Within the rectangular region, replace halfwords whose current value is
\ the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb16-invert  ( adr width height bytes/line fg-color bg-color -- )
   mov     r0,tos
   ldmia   sp!,{r1,r2,r3,r4,r5,tos}
   \ r0:bg-colour  r1:fg-colour r2:bytes/line  r3:height  r4:width  r5:adr

   add      r4,r4,r4     \ Byte count instead of pixel count
   begin
      cmp     r3,#0
   > while
      mov     r6,#0
      begin
         cmp     r4,r6		\ more bytes/line?
      > while
         ldrh    r7,[r5,r6]	\ get pixel colour at adr+offset
         cmp     r7,r0
         streqh  r1,[r5,r6]
         cmp     r7,r1
         streqh  r0,[r5,r6]
         inc     r6,#2
      repeat
      add     r5,r5,r2
      dec     r3,#1
   repeat
c;

\ Within the rectangular region, replace 3-byte pixels whose current value
\ is the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb24-invert  ( adr width height bytes/line fg-color bg-color -- )
   ldmia   sp!,{r1,r2,r3,r4,r5}
   \ r0:scratch  r1:fg-colour r2:bytes/line  r3:height  r4:width  r5:adr
   \ r6 bytes/line, r7 scratch, r8 scratch, tos bg-color

   add        r4,r4,r4, lsl #1  \ Multiply width by 3 to get bytes
   begin
      cmp     r3,#0
   > while
      mov     r6,#0
      begin
         cmp     r4,r6		\ more bytes on this line?
      > while
         add     r0,r5,r6       \ r0 points to the pixel
         ldrb    r7,[r0]        \ Start reading a 3-byte pixel
         ldrb    r8,[r0,#1]
         orr     r7, r7, r8, lsl #8
         ldrb    r8,[r0,#2]
         orr     r7, r7, r8, lsl #16

         cmp     r7,tos   \ Is it the background color?
         0=  if
            \ If so, replace with the foreground color
            strb  r1,[r0]
            mov   r8,r1,lsr #8
            strb  r8,[r0,#1]
            mov   r8,r1,lsr #16
            strb  r8,[r0,#2]
         then

         cmp     r7,r1   \ Is it the foreground color?
         0=  if
            \ If so, replace with the background color
            strb  tos,[r0]
            mov   r8,tos,lsr #8
            strb  r8,[r0,#1]
            mov   r8,tos,lsr #16
            strb  r8,[r0,#2]
         then
         inc   r6,#3     \ Advance offset to the next pixel
      repeat
      add     r5,r5,r2   \ Advance to next scan line
      dec     r3,#1      \ Decrease the remaining line count
   repeat
   pop   tos,sp
c;

\ Within the rectangular region, replace halfwords whose current value is
\ the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb32-invert  ( adr width height bytes/line fg-color bg-color -- )
   mov     r0,tos
   ldmia   sp!,{r1,r2,r3,r4,r5,tos}
   \ r0:bg-colour  r1:fg-colour r2:bytes/line  r3:height  r4:width  r5:adr

   begin
      cmp     r3,#0
   > while
      mov     r6,#0
      begin
         cmp     r4,r6		\ more bytes on this line?
      > while
         ldr     r7,[r5,r6,lsl #2]	\ get pixel colour at adr+offset
         cmp     r7,r0
         streq   r1,[r5,r6,lsl #2]
         cmp     r7,r1
         streq   r0,[r5,r6,lsl #2]
         inc     r6,#1
      repeat
      add     r5,r5,r2
      dec     r3,#1
   repeat
c;


\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb8-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldmia   sp!,{r1,r2,r3,r4,r5,r6,r7}
   psh     r9,sp
\ tos:bg-col  r1:fg-col  r2:bytes/line  r3: screeadr  r4:height  r5:width
\ r6:font-width  r7:fontadr
\ free: r8 r9 r0
   begin
      cmp     r4,#0
   > while
      mov     r8,#0			\ r8: pixel-offset
      begin
         cmp     r5,r8			\ one more pixel?
      > while
         ldrb     r9,[r7,r8,lsr #3]	\ r9 fontdatabyte
         and     r0,r8,#7
         rsb     r0,r0,#8
         movs    r0,r9,asr r0
         strcsb  r1,[r3,r8]
         strccb  tos,[r3,r8]
         inc     r8,#1
      repeat
      add     r7,r7,r6			\ new font-line
      add     r3,r3,r2			\ new screen-line
      dec     r4,#1
   repeat
   ldmia   sp!,{r9,tos}
c;

\ Draws a character from a 1-bit-deep font into a 16bpp frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb16-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldmia   sp!,{r1,r2,r3,r4,r5,r6,r7}
   psh     r9,sp
\ tos:bg-col  r1:fg-col  r2:bytes/line  r3: screeadr  r4:height  r5:width
\ r6:font-width  r7:fontadr
\ free: r8 r9 r0
   begin
      cmp     r4,#0
   > while
      mov     r8,#0			\ r8: pixel-offset
      begin
         cmp     r5,r8			\ one more pixel?
      > while
         ldrb     r9,[r7,r8,lsr #3]	\ r9 fontdatabyte
         and     r0,r8,#7
         rsb     r0,r0,#8
         movs    r0,r9,asr r0
         mov     r0,r8,lsl #1
         strcsh  r1,[r3,r0]
         strcch  tos,[r3,r0]
         inc     r8,#1
      repeat
      add     r7,r7,r6			\ new font-line
      add     r3,r3,r2			\ new screen-line
      dec     r4,#1
   repeat
   ldmia   sp!,{r9,tos}
c;

\ Draws a character from a 1-bit-deep font into a 24bpp frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb24-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldmia   sp!,{r1,r2,r3,r4,r5,r6,r7}
   psh     r9,sp
\ tos:bg-col  r1:fg-col  r2:bytes/line  r3: screenadr  r4:height  r5:width
\ r6:font-width  r7:fontadr
\ free: r8 r9 r0
   begin
      cmp     r4,#0
   > while
      mov     r8,#0			\ r8: pixel-offset
      begin
         cmp     r5,r8			\ one more pixel?
      > while
         ldrb    r9,[r7,r8,lsr #3]	\ r9 fontdatabyte
         and     r0,r8,#7               \ r9 bit offset 0-7
         rsb     r0,r0,#8               \ r0 bit offset 8-1
         movs    r0,r9,asr r0           \ Test font bit
         add     r9,r3,r8,lsl #1        \ r9 = r3 = r8*2 - Partial address computation
         add     r9,r9,r8               \ r9 = r3 + r8*3
         u<  if
            \ Background
            strb    tos,[r9]		\ store first byte of pixel
            mov     r0,tos,lsr #8
            strb    r0,[r9,#1]		\ store second byte of pixel
            mov     r0,tos,lsr #16
            strb    r0,[r9,#2]		\ store third byte of pixel
         else
            \ Foreground
            strb    r1,[r9]		\ store first byte of pixel
            mov     r0,r1,lsr #8
            strb    r0,[r9,#1]		\ store second byte of pixel
            mov     r0,r1,lsr #16
            strb    r0,[r9,#2]		\ store third byte of pixel
         then
         inc     r8,#1
      repeat
      add     r7,r7,r6			\ new font-line
      add     r3,r3,r2			\ new screen-line
      dec     r4,#1
   repeat
   ldmia   sp!,{r9,tos}
c;

\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb32-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldmia   sp!,{r1,r2,r3,r4,r5,r6,r7}
   psh     r9,sp
\ tos:bg-col  r1:fg-col  r2:bytes/line  r3: screeadr  r4:height  r5:width
\ r6:font-width  r7:fontadr
\ free: r8 r9 r0
   begin
      cmp     r4,#0
   > while
      mov     r8,#0			\ r8: pixel-offset
      begin
         cmp     r5,r8			\ one more pixel?
      > while
         ldrb     r9,[r7,r8,lsr #3]	\ r9 fontdatabyte
         and     r0,r8,#7
         rsb     r0,r0,#8
         movs    r0,r9,asr r0
         strcs   r1,[r3,r8,lsl #2]
         strcc   tos,[r3,r8,lsl #2]
         inc     r8,#1
      repeat
      add     r7,r7,r6			\ new font-line
      add     r3,r3,r2			\ new screen-line
      dec     r4,#1
   repeat
   ldmia   sp!,{r9,tos}
c;

\ Similar to 'move', but only moves width out of every 'bytes/line' bytes
\ "size" is "height" times "bytes/line", i.e. the total length of the
\ region to move.

\ bytes/line is a multiple of 8, src-start and dst-start are separated by
\ a multiple of bytes/line (i.e. src and dst are simililarly-aligned), and
\ src > dst (so move from the start towards the end).  This makes it
\ possible to optimize an assembly language version to use longword or
\ doubleword operations.

\ this assumes width to be also a multiple of 8
code fb-window-move  ( src-start dst-start size bytes/line width -- )
   mov     r0,tos
   ldmia   sp!,{r1,r2,r3,r4,tos}
   \ r0:width  r1: bytes/line  r2:size  r3:dst-start  r4:src-start
   sub     r1,r1,r0	\ r1:bytes/line - width
   add     r2,r2,r4	\ r2:end-of-src-copy-region
   begin
      cmp     r4,r2
   < while
      mov     r7,r0	\ r7:loop-width
      begin
         decs    r7,#8
         ldmgeia r4!,{r5,r6}
         stmgeia r3!,{r5,r6}
      < until

      add     r4,r4,r1
      add     r3,r3,r1
   repeat
c;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
