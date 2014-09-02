purpose: Low-level startup code for Raven
\ See license at end of file

label setup-raven  ( -- )
   mfspr  r30,lr

[ifdef] slam-it

   \ PPCbus registers
   raven-base	set  r1,*

   set  r2,h#fd00.fdff
   stw   r2,h#40(r1)

   set  r2,h#0300.00c2
   stw   r2,h#44(r1)

   set  r2,h#fe00.fe7f
   stw   r2,h#48(r1)

   set  r2,h#0200.00c0
   stw   r2,h#4c(r1)

   set  r2,h#c000.fcff
   stw   r2,h#50(r1)

   set  r2,h#4000.00c2
   stw   r2,h#54(r1)

   set  r2,h#8000.bf7f
   stw   r2,h#58(r1)

   set  r2,h#8000.00c0
   stw   r2,h#5c(r1)

   set  r2,h#55
   stb   r2,h#60(r1)
   set  r2,h#aa0f
   sth   r2,h#60(r1)

   set  r2,h#55
   stb   r2,h#68(r1)
   set  r2,h#aa0f
   sth   r2,h#68(r1)

   set  r2,h#dead.beef
   stw   r2,h#74(r1)

   \ PCIbus registers

   set     r1,h#80000cf8	\ PCI Configuration Address Register

   set     r2,h#80000004	\ Config address of word containing offset 4
   stwbrx  r2,r0,r1
   set     r3,h#06		\ Memory and mastership enable
   stb     r3,4(r1)		\ Write to config register 0x04

   set     r2,h#80000014	\ Config address of word containing offset 14
   stwbrx  r2,r0,r1
   set     r3,h#0000003c	\ (swapped) MPIC base address in PCI mem space
   stw     r3,4(r1)		\ Write to config register 0x14

   set     r2,h#80000080	\ Config address of word containing offset 80
   stwbrx  r2,r0,r1
   set     r3,h#fe.81.00.80	\ (swapped) PCI aperture [8000.0000-81ff.0000)
   stw     r3,4(r1)		\ Write to config register 0x80

   set     r2,h#80000084	\ Config address of word containing offset 84
   stwbrx  r2,r0,r1
   set     r3,h#f3.00.00.80	\ (swapped) maps to PPC bus 0
   stw     r3,4(r1)		\ Write to config register 0x84

   set     r2,h#80000088	\ Config address of word containing offset 88
   stwbrx  r2,r0,r1
   set     r3,h#ff.81.ff.81	\ (swapped) PCI aperture [81ff.0000-8200.0000)
   stw     r3,4(r1)		\ Write to config register 0x88

   set     r2,h#8000008c	\ Config address of word containing offset 8c
   stwbrx  r2,r0,r1
   set     r3,h#e3.00.00.80	\ (swapped) maps to PPC bus 01ff.0000
   stw     r3,4(r1)		\ Write to config register 0x8c


[then]

   mtspr  lr,r30
   bclr   20,0			\ ET go home...
end-code


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

