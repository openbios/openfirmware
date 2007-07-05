purpose: Optimized fb8 package support routines
\ See license at end of file

headerless
decimal

\ Invert foreground and background colors within a rectangular region
code fb8-invert  ( adr width height bytes/line fg-color bg-color -- )
				\ bg-color in tos
    lwz		t4,0(sp)	\ fg-color in t4
    lwzu	t0,1cell(sp)	\ bytes/line in scr
    lwzu	t2,1cell(sp)	\ height in t1 (outer loop index, >0)
    lwzu	t1,1cell(sp)	\ width in t2 (inner loop index, >0)
    lwzu	t3,1cell(sp)	\ adr in sc3 (starting address)

    mfspr	t6,ctr		\ Save counter
    
    subf	t0,t1,t0	\ Account for inner loop incrementing
    addi	t3,t3,-1	\ Account for inner loop incrementing

    begin 			\ Outer loop
        mtspr	ctr,t1		\ Starting width value
	begin			\ Inner loop
	    lbzu  t5,1(t3)	\ read byte
	    cmp   0,0,t5,tos	\ Background?
	    =  if
		mr  t5,t4	\ Set to foreground
	    else
		cmp  0,0,t5,t4	\ Foreground?
		= if
		    mr  t5,tos	\ Set to background
		then
	    then
	    stb	  t5,0(t3)	\ store byte
	countdown		\ End inner loop when width=0

	addic.	t2,t2,-1	\ decrement height until =0
	add	t3,t3,t0	\ increment adr to next line
    = until			\ End outer loop when height=0

    mtspr	ctr,t6		\ Restore counter
    lwzu	tos,1cell(sp)	\ Clean up stack
    addi	sp,sp,1cell
c;

\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
\ Assumptions: 	Fontbytes is 2; 0 < width <= 16
\		Fontadr is divisible by 2
code fb8-paint
( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
    \ tos already there		\ bg-color in tos
    lwz		t9,0(sp)	\ fg-color in t9
    lwzu	t2,1cell(sp)	\ Bytes/line - bytes per scan line
    lwzu	t3,1cell(sp)	\ Screenadr - start address in frame buffer
    lwzu	t4,1cell(sp)	\ Height - character height in pixels
    lwzu	t5,1cell(sp)	\ Width - character width in pixels (bytes)
    lwzu	t6,1cell(sp)	\ Fontbytes - bytes per font line
    lwzu	t7,1cell(sp)	\ Fontadr - start adr of this char in font table
 
    addi	t3,t3,-1	\ Account for pre-incrementing
    subf	t2,t5,t2	\ Account for inner loop incrementing
    mfspr	t8,ctr		\ Save counter

    addi	r0,r0,8		\ Constant 8 (pixels/font-byte), needed below


    begin			\ Outer loop - for all scan lines in char
	lbz	t0,0(t7)	\ Up to 8 font bits into scr  
	rlwinm	t0,t0,23,1,8	\ Align almost to high part of word so that
				\ one more shift will affect the sign bit

	mr	t1,t5		\ Reset width counter for the new scan line

	ahead			\ Branch down to end of loop
	begin

	    cmpi  0,0,t1,8
	    <  if
	        mtspr  ctr,t1	\ Set count
	        subf   t1,t1,t1	\ Width is exhausted
	    else
		mtspr  ctr,r0	\ Max inner loop count is 8
		addi   t1,t1,-8	\ Reduce width by 8
	    then

	    begin		\ Inner loop - for each pixel in a font byte
		add.  t0,t0,t0		\ Shift next pixel bit to top position
		0<  if
		    stbu  t9,1(t3)	\ Write foreground color to framebuffer
		else
		    stbu  tos,1(t3)	\ Write background color to framebuffer
		then	    	    
	    countdown               \ Repeat until width count = 0

        but then
	    cmpi  0,0,t1,0
        = until

	add	t7,t7,t6	\ Next scan line in font table
	addic.	t4,t4,-1	\ Decrement height counter
	add	t3,t3,t2	\ Increment frame buffer addr to next line
    = until                	\ Repeat until height count = 0

    mtspr	ctr,t8		\ Restore counter
    lwzu	tos,4(sp)	\ Clean up stack
    addi	sp,sp,4
c;

\ Very fast window move, for scrolling
\ Similar to 'move', but only moves #move/line out of every 'bytes/line' bytes
\ Assumes bytes/line is divisible by 8 (for double-long load/stores)
\ Assumes src and dst separated by n*bytes/line
\ Called with:
\ src-start dst-start      size      bytes/line #move/line      fb8-move
\ (break-lo)(cursor-y) (winbot-breaklo)  (")  (emu-bytes/line)
\ src > dst, so move from start towards end

\ Note that the 601 is a 32-bit implementation.
\ It would be cool to test here, but the PVR is supervisor-only!
[ifdef] sixtyfour-bit
   8 constant fbalign
[else]
   4 constant fbalign
[then]

code fb8-window-move  ( src-start dst-start size bytes/line #move/line -- )
    				\ tos=#move/line
    lwz		t0,0(sp)	\ t0=bytes/line
    lwzu	t1,1cell(sp)	\ t1=size
    lwzu	t2,1cell(sp)	\ t2=dst-start
    lwzu	t3,1cell(sp)	\ t3=src-start

    fbalign 1-  addi	t5,r0,*	\ Get fbalign-1 into a register

    \ First, force src and dst to alignment boundary, adjust #move/line
    and		t4,t3,t5	\ Any extra bytes at start?
    add		tos,tos,t4	\ Adjust #move/line by that amount
    andc	t3,t3,t5	\ Lock src to alignment boundary
    andc	t2,t2,t5	\ Lock dst to alignment boundary
    add		tos,tos,t5	\ Round #move/line up to next unit
    andc	tos,tos,t5

    subf	t4,tos,t0	\ Account for inner loop incrementing

    fbalign negate  addi t3,t3,*  \ Account for pre-incrementing
    fbalign negate  addi t2,t2,*  \ Account for pre-incrementing
[ifdef] sixtyfour-bit
    rlwinm	tos,tos,29,3,31
[else]
    rlwinm	tos,tos,30,2,31
[then]
    mfspr	t7,ctr		\ Save counter

    cmpi	0,0,t1,0
    ahead			\ Branch to loop end for initial comparison
    begin			\ Outer loop
        mtspr   ctr,tos		\ Setup inner loop index

	begin			\ Inner loop
[ifdef] sixtyfour-bit
	    ldzu	t6,8(t3)
	    stdu	t6,8(t2)
[else]
	    lwzu	t6,4(t3)
	    stwu	t6,4(t2)
[then]
        countdown

	subf.	t1,t0,t1	\ Decrement size until =0
	add	t2,t4,t2	\ Increment src
	add	t3,t4,t3	\ Increment dst
    but then			\ Target of "ahead" branch
    <= until			\ End outer loop when size=0

    mtspr	ctr,t7		\ Restore counter

    lwzu	tos,1cell(sp)	\ Clean up stack
    addi	sp,sp,1cell
c;

headers

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
