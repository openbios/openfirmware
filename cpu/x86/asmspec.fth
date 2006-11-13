\ See license at end of file
purpose: Forth access words for special 386 registers

decimal

only forth also definitions

\ Descriptor table registers and task register
code idtr@  ( -- base limit )
   ax ax sub   ax push   ax push	\ Make room on stack
   sp ax mov   0 [ax] sidt		\ Read onto stack
   2 [ax] bx mov  bx 4 [ax] mov		\ Move base up
   bx bx sub  op: bx 2 [ax] mov		\ Insert 0 in high half of limit
c;
code gdtr@  ( -- base limit )
   ax ax sub   ax push   ax push	\ Make room on stack
   sp ax mov   0 [ax] sgdt		\ Read onto stack
   2 [ax] bx mov  bx 4 [ax] mov		\ Move base up
   bx bx sub  op: bx 2 [ax] mov		\ Insert 0 in high half of limit
c;
code idtr!  ( base limit -- )
   sp ax mov
   4 [ax] bx mov  bx 2 [ax] mov		\ Move base down
   0 [ax] lidt				\ Load from stack
   ax pop   ax pop			\ Clean up stack
c;
code gdtr!  ( base limit -- )
   sp ax mov
   4 [ax] bx mov  bx 2 [ax] mov		\ Move base down
   0 [ax] lgdt				\ Load from stack
   ax pop   ax pop			\ Clean up stack
c;

code tr@   ( -- tr  )   ax str    1push c;
code ldtr@  ( -- ldt )   ax sldt   1push c;
code tr!   ( tr -- )    ax pop    ax ltr   c;
code ldtr!  ( ldt -- )   ax pop    ax lldt  c;

\ Control registers
code cr0@  ( -- n )  cr0 ax mov  1push c;
code cr2@  ( -- n )  cr2 ax mov  1push c;
code cr3@  ( -- n )  cr3 ax mov  1push c;
code cr4@  ( -- n )  cr4 ax mov  1push c;

code cr0!  ( n -- )  ax pop  ax cr0 mov  c;
code cr2!  ( n -- )  ax pop  ax cr2 mov  c;
code cr3!  ( n -- )  ax pop  ax cr3 mov  c;
code cr4!  ( n -- )  ax pop  ax cr4 mov  c;

\ Debug registers
code dr0@  ( -- n )  dr0 ax mov  1push c;
code dr1@  ( -- n )  dr1 ax mov  1push c;
code dr2@  ( -- n )  dr2 ax mov  1push c;
code dr3@  ( -- n )  dr3 ax mov  1push c;
code dr6@  ( -- n )  dr6 ax mov  1push c;
code dr7@  ( -- n )  dr7 ax mov  1push c;

code dr0!  ( n -- )  ax pop  ax dr0 mov  c;
code dr1!  ( n -- )  ax pop  ax dr1 mov  c;
code dr2!  ( n -- )  ax pop  ax dr2 mov  c;
code dr3!  ( n -- )  ax pop  ax dr3 mov  c;
code dr6!  ( n -- )  ax pop  ax dr6 mov  c;
code dr7!  ( n -- )  ax pop  ax dr7 mov  c;

\ Test registers
code tr6@  ( -- n )  tr6 ax mov  1push c;
code tr7@  ( -- n )  tr7 ax mov  1push c;

code tr6!  ( n -- )  ax pop  ax tr6 mov  c;
code tr7!  ( n -- )  ax pop  ax tr7 mov  c;

code clts  ( -- )  h# 0f asm8,  h# 06 asm8,  c;

code ds@  ( -- sel )  ax ax xor  ds ax mov  ax push  c;
code cs@  ( -- sel )  ax ax xor  cs ax mov  ax push  c;
code ss@  ( -- sel )  ax ax xor  ss ax mov  ax push  c;
code es@  ( -- sel )  ax ax xor  es ax mov  ax push  c;
code fs@  ( -- sel )  ax ax xor  fs ax mov  ax push  c;
code gs@  ( -- sel )  ax ax xor  gs ax mov  ax push  c;
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
