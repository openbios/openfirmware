purpose: Access functions for processor status register
\ See license at end of file

code psr@  ( -- n )  psh tos,sp  mrs tos,cpsr  c;
code psr!  ( n -- )  msr cpsr,tos  pop tos,sp  c;

h# 80 constant interrupt-enable-bit
: interrupt-enable@   ( -- n )  psr@ interrupt-enable-bit and  ;
: interrupt-enable!   ( n -- )  psr@ interrupt-enable-bit invert and or  psr! ;

headerless
: (disable-interrupts)   ( -- )  psr@  interrupt-enable-bit or  psr!  ;
: (enable-interrupts)  ( -- )  psr@  interrupt-enable-bit invert and  psr!  ;
: interrupts-enabled?  ( -- yes? )  interrupt-enable@ 0=  ;

code (lock)  ( -- )  ( R: -- oldMSR )
   mrs     r0,cpsr
   psh     r0,rp
   orr     r0,r0,#0x80
   msr     cpsr,r0
c;
code (unlock)  ( -- )  ( R: oldMSR -- )
   pop     r0,rp
   msr     cpsr,r0
c;

' (enable-interrupts) to enable-interrupts
' (disable-interrupts) to disable-interrupts
' (lock) to lock[
' (unlock) to ]unlock

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
