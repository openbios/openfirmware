\ See license at end of file
purpose: Code to search for dropin modules

also forth definitions
: c$,  ( adr len -- )
   1+  here swap note-string dup allot move
;
previous definitions

also 386-assembler definitions
[ifdef] rom-loaded
\ This version does not require a stack, but you do need to know the load addr
: $find-dropin,  ( adr len -- patch-adr )
   \   mov ax,#<address after jmp>
   \   jmp find-dropin
   \   ...string...

   h# b8 c,  here 9 + asm-base - ResetBase + le-l,           \ mov ax,#<after jmp>
   h# e9 c,  here 4 + " find-dropin " evaluate swap - le-l,  \ jmp find-dropin
   c$,
;
[else]
: $find-dropin,  ( adr len -- )
   \ length of string + null terminator +
   \ address of instruction + length of instruction
   dup 1+ here + 5 +      ( adr len target )
   " #) call"               evaluate	\ Call past string area  ( adr len )
   c$,					\ Place string           ( )
   " ax pop"                evaluate    \ Put string address in ax
   " find-dropin #) call" evaluate	\ and call find routine
;
[then]

: bswap  ( reg -- )
   7  [ also forth ]  and  [ previous ]  h# 0f asm8,  h# c8 +  asm8,
;

fload ${BP}/cpu/x86/pc/report.fth			\ Startup reports

previous definitions

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
