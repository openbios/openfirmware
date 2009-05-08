\ See license at end of file
purpose: Assembler macro for tracing progress through startup code

\ write a byte to an ISA port
: isa-c!   ( n a - )  "  # dx mov   # al mov   al dx out " evaluate  ;

[ifdef] debug-startup
: init-com1  ( -- )
   h#  1  h# 3fc  isa-c!	\ DTR on
   h# 80  h# 3fb  isa-c!	\ Enable divisor latch
   h# 01  h# 3f8  isa-c!	\ Baud rate divisor low - 115200 baud
   h#  0  h# 3f9  isa-c!	\ Baud rate divisor high - 115200 baud
   h#  3  h# 3fb  isa-c!	\ 8 bits, no parity
   h#  0  h# 3f9  isa-c!        \ Interrupts off
   h#  1  h# 3fa  isa-c!        \ Enable FIFO
;

\ Assembler macro to assemble code to send the character "char" to COM1
: report  ( char -- )
   " begin   h# 3fd # dx mov   dx al in   h# 20 # al and  0<> until" evaluate
   ( char )  " # al mov   h# 3f8 # dx mov  al dx out  " evaluate
   " begin   h# 3fd # dx mov  dx al in   h# 20 # al and  0<> until" evaluate
;
[else]
: init-com1  ( -- )  ;
: report  ( char -- )  drop  ;
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
