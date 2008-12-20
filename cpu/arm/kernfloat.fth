purpose: Kernel-level floating point words
\ See license at end of file

\ Contributed by Hanno Schwalm

code fp@	( -- adr )
	top	sp		push
	top	'user fp	ldr c;

code fp!	( a_adr -- )
	top	'user fp	str
	top	sp		pop c;
code (flit)	( -- )
	r0 r1 2 	ip ia!	ldm
	r2	'user fp	ldr
	r0 r1 2		r2 db!	stm
	r2	'user fp	str c;
code f@		( adr -- ) ( -- f1 )
	r0 r1 2		top ia	ldm
	r2	'user fp	ldr
	r0 r1 2		r2 db!	stm
	r2	'user fp	str
	top		sp	pop c;
code f!		( adr -- ) ( f1 -- )
	r2	'user fp	ldr
	r0 r1 2		r2 ia!	ldm
	r2	'user fp	str
	r0 r1 2		top ia	stm
	top		sp	pop c;

code /float	( -- 8)
	top sp push	top 8 # mov c;
code floats	( n -- 8n )
	top  top  3 #asl mov c;
code float+	( adr -- adr1 )
	top  8      incr c;
code floats+	( a_adr index -- a_adr1 )
	r0	sp	pop
	top	r0	top 3 #asl add c;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
