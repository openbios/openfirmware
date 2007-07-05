purpose: Machine Status Register access
\ See license at end of file

code msr@  ( -- n )
   stwu   tos,-4(sp)
   mfmsr  tos
c;
code msr!  ( n -- )
   sync  isync
   mtmsr  tos
   sync  isync
   lwz    tos,0(sp)
   addi   sp,sp,4
c;

h# 8000 constant interrupt-enable-bit
: interrupt-enable@   ( -- n )  msr@ interrupt-enable-bit and  ;
: interrupt-enable!   ( n -- )
   msr@ interrupt-enable-bit invert and  or  msr!
;

headerless
: (enable-interrupts)   ( -- )  msr@  interrupt-enable-bit or  msr!  ;
: (disable-interrupts)  ( -- )  msr@  interrupt-enable-bit invert and  msr!  ;
: interrupts-enabled?  ( -- yes? )  interrupt-enable@  ;

code (lock)  ( -- )  ( R: -- oldMSR )
   mfmsr  t0
   stwu   t0,-1cell(rp)
   rlwinm t0,t0,0,17,15		\ Clear EE bit
   mtmsr  t0
c;
code (unlock)  ( -- )  ( R: oldMSR -- )
   lwz    t0,0(rp)
   mtmsr  t0
   addi   rp,rp,1cell
c;

: mapping-on   ( -- )  msr@ h# 30 or          msr!  ;
: mapping-off  ( -- )  msr@ h# 30 invert and  msr!  ;
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
