purpose: Slam the Falcon and Raven back into default, poweron like mode
\ See license at end of file

label cfg-l!  ( r3:value r4:offset -- )
   mfspr  r28,lr

\ Needs some work here....
label cfg-l!  ( r3:value r4:index -- )  \ Hammers r1,r2

   set	r1,h#80000cf8			\ Config address register
   set	r2,h#80000cfc			\ Config data register

   sync
   stwbrx r4,0,r1
   sync
   stwbrx r3,0,r2
   sync

   bclr   20,0
end-code

label slam-falcon  ( -- )
   mfspr  r29,lr

   falcon-base	set  r1,*

   set	r2,h#0000.0002		\ Setup General Control Register
   stw	r2,h#08(r1)		\ Upper Falcon

\ Danger Will Robinson!  The next two stores will kill the machines
\ DRAM.  If you run this code from DRAM, your dead.  If you enbale
\ the stores, you must load the code to the pflash and then run the
\ code with the "go ff000100" command.

   set  r2,h#0000.0000		\ Setup DRAM Size Register
   stw	r2,h#10(r1)		\ Upper Falcon

   set  r2,h#0000.0000		\ Setup DRAM Base Register
   stw	r2,h#18(r1)		\ Upper Falcon

\ End of danger section
 
   set  r2,h#4200.0000		\ Setup Clock Frequency Register
   stw	r2,h#20(r1)		\ Upper Falcon

   set  r2,h#0000.0000		\ Setup ECC Registers
   stw	r2,h#30(r1)		\ Upper Falcon

   set  r2,h#0000.0000		\ Setup Scruber Registers
   stw	r2,h#40(r1)		\ Upper Falcon

   set  r2,h#ff40.0000		\ Setup ROMB Registers
   stw	r2,h#58(r1)		\ Upper Falcon

   set  r2,h#0000.0000		\ Setup Clock Enable Register
   stw	r2,h#28(r1)		\ Upper Falcon

   mtspr  lr,r29
   bclr   20,0
end-code

label slam-raven  ( -- )
   mfspr  r29,lr

   raven-base	set  r1,*

   set  r2,0
   stw   r2,h#70(r1)
   stw   r2,h#74(r1)
   stw   r2,h#78(r1)
   stw   r2,h#7c(r1)
   stw   r2,h#44(r1)
   stw   r2,h#4c(r1)
   stw   r2,h#54(r1)
   stw   r2,h#40(r1)
   stw   r2,h#48(r1)
   stw   r2,h#50(r1)
   stw   r2,h#30(r1)
   stw   r2,h#20(r1)

   set	 r2,h#8000.00c0
   stw   r2,h#5c(r1)

   set	 r2,h#8000.8080
   stw   r2,h#58(r1)

   set	 r2,h#0000.00be
   stw   r2,h#10(r1)

   lwz	 r2,h#8(r1)
   sync
   andi. r2,r2,h#ffff
   sync
   stw   r2,h#8(r1)

   mtspr  lr,r29
   bclr   20,0			\ ET go home...
end-code

label slam-pci
   mfspr  r29,lr

   set     r3,h#0280.0004
   set	   r4,4
   cfg-l!  bl *

   set	   r3,0
   set	   r4,h#10
   cfg-l!  bl *

   set	   r4,h#14
   cfg-l!  bl *

   set	   r4,h#80
   cfg-l!  bl *
   set	   r4,h#88
   cfg-l!  bl *
   set	   r4,h#90
   cfg-l!  bl *
   set	   r4,h#98
   cfg-l!  bl *

   set	   r4,h#84
   cfg-l!  bl *
   set	   r4,h#8c
   cfg-l!  bl *
   set	   r4,h#94
   cfg-l!  bl *
   set	   r4,h#9c
   cfg-l!  bl *


   mtspr  lr,r29
   bclr   20,0
end-code


label grand-slam  ( -- )
   mfspr   r30,lr

   slam-pci    bl *
   slam-raven  bl *
   slam-falcon bl *

   mtspr   lr,r30
   bclr	   20,0
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

