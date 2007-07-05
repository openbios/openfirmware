purpose: PowerPC-specific words for remote GDB interface
\ See license at end of file

only forth also hidden also definitions
headerless

: ppc-read-registers  ( -- )
  xbuf
  %r0  gr  %r1  gr  %r2  gr  %r3  gr  %r4  gr  %r5  gr  %r6  gr  %r7  gr 
  %r8  gr  %r9  gr  %r10 gr  %r11 gr  %r12 gr  %r13 gr  %r14 gr  %r15 gr 
  %r16 gr  %r17 gr  %r18 gr  %r19 gr  %r20 gr  %r21 gr  %r22 gr  %r23 gr 
  %r24 gr  %r25 gr  %r26 gr  %r27 gr  %r28 gr  %r29 gr  %r30 gr  %r31 gr 

  %f0  dr  %f1  dr  %f2  dr  %f3  dr  %f4  dr  %f5  dr  %f6  dr  %f7  dr
  %f8  dr  %f9  dr  %f10 dr  %f11 dr  %f12 dr  %f13 dr  %f14 dr  %f15 dr
  %f16 dr  %f17 dr  %f18 dr  %f19 dr  %f20 dr  %f21 dr  %f22 dr  %f23 dr
  %f24 dr  %f25 dr  %f26 dr  %f27 dr  %f28 dr  %f29 dr  %f30 dr  %f31 dr

\  %y gr   %psr gr %wim gr %tbr gr %pc gr  %npc gr %fpsr gr %cpsr gr
  xbuf tuck - putpkt
;   
: ppc-write-registers  ( -- )
  rbuf 1+
  v to %r0  v to %r1  v to %r2  v to %r3  v to %r4  v to %r5  v to %r6  v to %r7
  v to %r8  v to %r9  v to %r10 v to %r11 v to %r12 v to %r13 v to %r14 v to %r15
  v to %r16 v to %r17 v to %r18 v to %r19 v to %r20 v to %r21 v to %r22 v to %r23
  v to %r24 v to %r25 v to %r26 v to %r27 v to %r28 v to %r29 v to %r30 v to %r31

  w to %f0  w to %f1  w to %f2  w to %f3  w to %f4  w to %f5  w to %f6  w to %f7
  w to %f8  w to %f9  w to %f10 w to %f11 w to %f12 w to %f13 w to %f14 w to %f15
  w to %f16 w to %f17 w to %f18 w to %f19 w to %f20 w to %f21 w to %f22 w to %f23
  w to %f24 w to %f25 w to %f26 w to %f27 w to %f28 w to %f29 w to %f30 w to %f31

\  v to %y v to %psr v to %wim v to %tbr v to %pc  v to %npc
\  v to %fpsr v to %cpsr gr
  drop
  okay-reply
;  
' ppc-read-registers to read-registers
' ppc-write-registers to write-registers

headers
only forth also definitions

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
