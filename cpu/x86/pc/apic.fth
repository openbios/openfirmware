purpose: Advanced Programmable Interrupt Controller (APIC) driver
\ See license at end of file

: apic@  ( index -- l )  h# fec0.0000 c!  h# fec0.0010 l@  ;
: apic!  ( l index -- )  h# fec0.0000 c!  h# fec0.0010 l!  ;
: apic-eoi  ( vector -- )  h# fec0.0040 l!  ;

: .apic-mode  ( low -- )
   8 rshift 7 and  case
      0 of  ." Fixed  "  endof
      1 of  ." LowPri "  endof
      2 of  ." SMI    "  endof
      3 of  ." Res3   "  endof
      4 of  ." NMI    "  endof
      5 of  ." Init   "  endof
      6 of  ." Res6   "  endof
      7 of  ." Ext    "  endof
   endcase
;

: .apic-irq  ( int# -- )
   2* h# 10 + dup apic@
   ." Vec: "  dup h# ff and 2 u.r space
   dup .apic-mode
   dup h#  800 and  if  ." Logical  "  else  ." Physical "  then
   dup h# 1000 and  if  ." Pending "  else  ." Idle    "  then
   dup h# 2000 and  if  ." Low  "  else  ." High "  then
   dup h# 8000 and  if
      ." Level "  dup h# 4000 and  if  ." IRR "  else  ." EOI "  then
   else  ." Edge      "  then
   h# 10000 and  if  ." Masked "  else  ." Open   "  then
   1+ apic@
   ." EDID: " dup d# 16 rshift h# ff and  2 u.r
   ."  Dest: " d# 24 rshift h# ff and 2 u.r
   cr
;
: .apic-irqs  ( -- )
   push-hex
   1 apic@ d# 16 rshift h# ff and 1+  0  do
      i 2 u.r space  i .apic-irq
   loop
   pop-base
;

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

