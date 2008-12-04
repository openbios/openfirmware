\ See license at end of file

[ifdef] notdef
also assembler definitions
: xop,  op,  r16? ,/c,  ;  patch xop, op, test
previous definitions
[then]

headerless
decimal

\ Invert foreground and background colors within a rectangular region
code fb8-invert  ( adr width height bytes/line fg-color bg-color -- )
   cld	ds ax mov  ax es mov  \ Setup for stos
   ax pop                    \ background color
   bx pop		     \ foreground color
   al  bh  mov		     \ foreground in bl, background in bh
   si push		     \ Save si
   di push		     \ Save di
   2 /n* [sp]  si  mov	     \ bytes/line in si
   3 /n* [sp]  dx  mov	     \ height in dx
   4 /n* [sp]  cx  mov	     \ width in cx
   5 /n* [sp]  di  mov	     \ adr in di

   cx   si   sub	\ Account for increment of pointer during inner loop

   \ Execute byte-by-byte

   begin  \ Outer loop over scan lines
      begin  \ Inner loop across width of character
         0 [di]   al   mov   \ Read byte
         al       bl   cmp   \ Foreground?
         =  if
	    bh    al   mov   \ Set to background
         else
	    al    bh   cmp   \ Background?
	    =  if
	       bl al   mov   \ Set to foreground
            then
	 then
         al            stos  \ Write it back
         cx            dec   \ Decrement byte counter
      0= until		     \ End inner loop 
      si           di  add   \ increment adr to next line
      4 /n* [sp]   cx  mov   \ restore starting width value
      dx               dec   \ decrement height
   0= until   \ End outer loop when height=0

   di pop		\ Restore di
   si pop		\ Restore si
   4 /n* #  sp  add	\ Remove stuff from stack
c;

\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
code fb8-paint
( fontadr fontbytes width height screenadr bytes/line foreground background -- )
   cld	ds ax mov  ax es mov  \ Setup for stos
   bp           push	\ save rp
   si           push	\ save ip
   di           push	\ save up

   \ Stack:  0 di  1 si  2 bp
   \  3 bg  4 fg  5 bytes/line  6 scradr  7 height  8 width  9 fontby  a fntadr

   8 /n* [sp]  ax  mov	\ Width in pixels
   7 #         ax  add  \ Round up ..
   ax         3 #  shr  \ Convert to bytes
   ax  9 /n* [sp]  sub  \ Account for incrementing of byte pointer
                        \ item 9 is now the excess to add for the next scan line
   
   4 /n* [sp]  bl  mov	\ Foreground
   3 /n* [sp]  bh  mov	\ Background
   6 /n* [sp]  di  mov	\ Screenadr - start address in frame buffer
   7 /n* [sp]  bp  mov	\ Height - character height in pixels
  h# 0a /n* [sp]  si  mov 
\ Fontadr - start address (of this char) in font table


   8 /n* [sp]  dx   mov    \ Width - character width in pixels (bytes)
   dx  5 /n* [sp]  sub  \ Account for pointer incrementing in inner loop

   begin                   \ Outer loop - for all scan lines in char
      8 /n* [sp]  dx   mov    \ Width - character width in pixels (bytes)
      begin			\ Middle loop - over the font scan line pixels
         dx          dx   or
      0<> while
         8 #         dx   cmp
         >  if			 
            8 #      cx   mov
         else
	    dx       cx   mov
         then
         cx          dx   sub    \ Reduce master width

         al               lodsb  \ Up to 32 font bits into scr  
         al          ah   mov

	 \ The inner loop handles the 1-8 pixels contained in one byte of
	 \ the font data.
         begin                   \ Inner loop - up to 8 pixel at a time
            ah             shl   \ Select and test font bit
            carry?  if
               bl     al   mov   \ Use foreground color
            else
               bh     al   mov   \ Use background color
            then
            al             stos  \ Write to frame buffer
            cx             dec   \ Increment width pixel count
         0= until                \ Repeat until width count = 0
      repeat       

      9 /n* [sp]   si   add   \ Next scan line in font table
      5 /n* [sp]   di   add   \ Increment frame buffer addr to next line
      bp                dec   \ Decrement height counter
   0= until                   \ Repeat until height count = 0
   
   di pop  si pop  bp pop	\ Restore Forth virtual machine registers
   8 /n* #  sp  add
c;

\ Fast window move, for scrolling
\ Similar to 'move', but only moves #move/line out of every 'bytes/line' bytes
\ Assumes src and dst separated by n*bytes/line
\ Called with:
\ src-start dst-start      size      bytes/line #move/line      fb8-move
\ (break-lo)(cursor-y) (winbot-breaklo)  (")  (emu-bytes/line)
\ src > dst, so move from start towards end

code fb-window-move  ( src-start dst-start size bytes/line #move/line -- )
                      \ tos=#move/line
   cld	ds ax mov  ax es mov  \ Setup for stos

   ax                pop	\ ax=#move/line
   dx                pop	\ Compute the distance from the end of ..
   ax          dx    sub	\ one line to the start of the next
   cx                pop	\ Total size

   bp push  si push  di push 	\ Save registers
   \ Stack cell offsets:
   \ 0 di  1 si  3 bp  3 dst  4 src

   3 /n*  [sp]  di   mov        \ di=dst-start
   4 /n*  [sp]  si   mov        \ si=src-start
   si           bx   mov	\ Compute the ..
   cx           bx   add        \ ending address  (cx is now available)

   begin   \ Outer loop
      ax   cx   mov		\ Set byte counter

      ahead begin		\ Handle unaligned bytes at the beginning
         movsb
         cx  dec
      but then
         3 #  di  test
      0= until

      cx bp mov			\ Save for later
      cx    shr			\ Convert to longword count
      cx    shr			\ ...
      rep  movs
      bp   cx  mov		\ Recover low bits
      3 #  cx  and		\ Compute number of leftover bytes at end
      rep  movsb

      dx  si  add       	\ Increment src
      dx  di  add         	\ Increment dst
      si  bx  cmp 	  	\ Compare source index to end value
   <= until   \ End outer loop when done

   di pop
   si pop
   bp pop
   2 /n* #  sp  add		\ Pop 2 cells
c;

\ ax bx cx dx si di bp
\ Invert foreground and background colors within a rectangular region
code fb16-invert  ( adr width height bytes/line fg-color bg-color -- )
   cld	ds ax mov  ax es mov  \ Setup for stos
   ax pop                    \ background color
   bx pop		     \ foreground color
   si push		     \ Save si
   di push		     \ Save di
   bp push		     \ Save bp
   ax bp mov                 \ backround in bp
   3 /n* [sp]  si  mov	     \ bytes/line in si
   4 /n* [sp]  dx  mov	     \ height in dx
   5 /n* [sp]  cx  mov	     \ width in cx
   6 /n* [sp]  di  mov	     \ adr in di

   cx   si   sub	\ Account for increment of pointer during inner loop
   cx   si   sub	\  (2 bytes per pixel)

   \ Execute word-by-word

   begin  \ Outer loop over scan lines
      begin  \ Inner loop across width of character
         0 [di]   ax   op: mov   \ Read word
         ax       bx   op: cmp   \ Foreground?
         =  if
	    bp    ax       mov   \ Set to background
         else
	    ax    bp   op: cmp   \ Background?
	    =  if
	       bx ax       mov   \ Set to foreground
            then
	 then
         ax        op: stos  \ Write it back
         cx            dec   \ Decrement pixel counter
      0= until		     \ End inner loop
      si           di  add   \ increment adr to next line
      5 /n* [sp]   cx  mov   \ restore starting width value
      dx               dec   \ decrement height
   0= until   \ End outer loop when height=0

   bp pop		\ Restore bp
   di pop		\ Restore di
   si pop		\ Restore si
   4 /n* #  sp  add	\ Remove stuff from stack
c;

\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
code fb16-paint
( fontadr fontbytes width height screenadr bytes/line foreground background -- )
   cld	ds ax mov  ax es mov  \ Setup for stos
   bp           push	\ save rp
   si           push	\ save ip
   di           push	\ save up

   \ Stack:  0 di  1 si  2 bp
   \  3 bg  4 fg  5 bytes/line  6 scradr  7 height  8 width  9 fontby  a fntadr

   8 /n* [sp]  ax  mov	\ Width in pixels
   7 #         ax  add  \ Round up ..
   ax         3 #  shr  \ Convert to bytes
   ax  9 /n* [sp]  sub  \ Account for incrementing of byte pointer
                        \ item 9 is now the excess to add for the next scan line

\  4 /n* [sp]  bl  mov	\ Foreground
   3 /n* [sp]  bx  mov	\ Background
   6 /n* [sp]  di  mov	\ Screenadr - start address in frame buffer
   7 /n* [sp]  bp  mov	\ Height - character height in pixels
  h# 0a /n* [sp]  si  mov
\ Fontadr - start address (of this char) in font table


   8 /n* [sp]  dx   mov    \ Width - character width in pixels
   dx          dx   add    \ Character width in bytes
   dx  5 /n* [sp]   sub    \ Account for pointer incrementing in inner loop

   begin                   \ Outer loop - for all scan lines in char
      8 /n* [sp]  dx   mov    \ Width - character width in pixels
      begin			\ Middle loop - over the font scan line pixels
         dx          dx   or
      0<> while
         8 #         dx   cmp
         >  if
            8 #      cx   mov
         else
	    dx       cx   mov
         then
         cx          dx   sub    \ Reduce master width

         al               lodsb  \ Get 8 font bits into al
         al          bl   mov    \ Move them into bl

	 \ The inner loop handles the 1-8 pixels contained in one byte of
	 \ the font data.
         begin                   \ Inner loop - up to 8 pixel at a time
            bl             shl   \ Select and test font bit
            carry?  if
               4 /n* [sp]  ax  mov    \ Use foreground color
            else
               3 /n* [sp]  ax   mov   \ Use background color
            then
            ax         op: stos  \ Write to frame buffer
            cx             dec   \ Increment width pixel count
         0= until                \ Repeat until width count = 0
      repeat

      9 /n* [sp]   si   add   \ Next scan line in font table
      5 /n* [sp]   di   add   \ Increment frame buffer addr to next line
      bp                dec   \ Decrement height counter
   0= until                   \ Repeat until height count = 0
   
   di pop  si pop  bp pop	\ Restore Forth virtual machine registers
   8 /n* #  sp  add
c;

\ ax bx cx dx si di bp
\ Invert foreground and background colors within a rectangular region
code fb32-invert  ( adr width height bytes/line fg-color bg-color -- )
   cld	ds ax mov  ax es mov  \ Setup for stos
   ax pop                    \ background color
   bx pop		     \ foreground color
   si push		     \ Save si
   di push		     \ Save di
   bp push		     \ Save bp
   ax bp mov                 \ backround in bp
   3 /n* [sp]  si  mov	     \ bytes/line in si
   4 /n* [sp]  dx  mov	     \ height in dx
   5 /n* [sp]  cx  mov	     \ width in cx
   6 /n* [sp]  di  mov	     \ adr in di

   cx   si   sub	\ Account for increment of pointer during inner loop
   cx   si   sub	\  (4 bytes per pixel)
   cx   si   sub	\  (4 bytes per pixel)
   cx   si   sub	\  (4 bytes per pixel)

   \ Execute word-by-word

   begin  \ Outer loop over scan lines
      begin  \ Inner loop across width of character
         0 [di]   ax       mov   \ Read word
         ax       bx       cmp   \ Foreground?
         =  if
	    bp    ax       mov   \ Set to background
         else
	    ax    bp       cmp   \ Background?
	    =  if
	       bx ax       mov   \ Set to foreground
            then
	 then
         ax            stos  \ Write it back
         cx            dec   \ Decrement pixel counter
      0= until		     \ End inner loop 
      si           di  add   \ increment adr to next line
      5 /n* [sp]   cx  mov   \ restore starting width value
      dx               dec   \ decrement height
   0= until   \ End outer loop when height=0

   bp pop		\ Restore bp
   di pop		\ Restore di
   si pop		\ Restore si
   4 /n* #  sp  add	\ Remove stuff from stack
c;

\ Draws a character from a 1-bit-deep font into a 32bpp frame buffer
code fb32-paint
( fontadr fontbytes width height screenadr bytes/line foreground background -- )
   cld	ds ax mov  ax es mov  \ Setup for stos
   bp           push	\ save rp
   si           push	\ save ip
   di           push	\ save up

   \ Stack:  0 di  1 si  2 bp
   \  3 bg  4 fg  5 bytes/line  6 scradr  7 height  8 width  9 fontby  a fntadr

   8 /n* [sp]  ax  mov	\ Width in pixels
   7 #         ax  add  \ Round up ..
   ax         3 #  shr  \ Convert to bytes
   ax  9 /n* [sp]  sub  \ Account for incrementing of byte pointer
                        \ item 9 is now the excess to add for the next scan line
   
\  4 /n* [sp]  bl  mov	\ Foreground
   3 /n* [sp]  bx  mov	\ Background
   6 /n* [sp]  di  mov	\ Screenadr - start address in frame buffer
   7 /n* [sp]  bp  mov	\ Height - character height in pixels
  h# 0a /n* [sp]  si  mov 
\ Fontadr - start address (of this char) in font table


   8 /n* [sp]  dx   mov    \ Width - character width in pixels

   dx          dx   add    \ Character width in bytes 
   dx          dx   add    \ Character width in bytes

   dx  5 /n* [sp]   sub    \ Account for pointer incrementing in inner loop

   begin                   \ Outer loop - for all scan lines in char
      8 /n* [sp]  dx   mov    \ Width - character width in pixels
      begin			\ Middle loop - over the font scan line pixels
         dx          dx   or
      0<> while
         8 #         dx   cmp
         >  if			 
            8 #      cx   mov
         else
	    dx       cx   mov
         then
         cx          dx   sub    \ Reduce master width

         al               lodsb  \ Get 8 font bits into al
         al          bl   mov    \ Move them into bl

	 \ The inner loop handles the 1-8 pixels contained in one byte of
	 \ the font data.
         begin                   \ Inner loop - up to 8 pixel at a time
            bl             shl   \ Select and test font bit
            carry?  if
               4 /n* [sp]  ax  mov    \ Use foreground color
            else
               3 /n* [sp]  ax   mov   \ Use background color
            then
            ax             stos  \ Write to frame buffer
            cx             dec   \ Increment width pixel count
         0= until                \ Repeat until width count = 0
      repeat       

      9 /n* [sp]   si   add   \ Next scan line in font table
      5 /n* [sp]   di   add   \ Increment frame buffer addr to next line
      bp                dec   \ Decrement height counter
   0= until                   \ Repeat until height count = 0
   
   di pop  si pop  bp pop	\ Restore Forth virtual machine registers
   8 /n* #  sp  add
c;

headers
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
