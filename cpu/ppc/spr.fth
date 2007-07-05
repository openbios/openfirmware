purpose: Special Purpose Register access for 604
\ See license at end of file

\ XER register: spr 1.
\ contains overflow and carry bits and byte count for string instructions.
code xer@ ( -- n )
   stwu tos,-1cell(sp)
   mfspr tos,xer
c;
code xer! ( n -- )
   mtspr xer,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ link register: spr 8
code lr@ ( -- n )
   stwu tos,-1cell(sp)
   mfspr tos,lr
c;
code lr! ( n -- )
   mtspr lr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ count register: spr 9
code ctr@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,ctr
c;
code ctr! ( n -- )
   mtspr ctr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ DSISR: spr 18
\ contains the status and cause of the DSI or alignment exception.
\ updated along with DAR.

code dsisr!  ( n -- )
   mtspr  dsisr,tos
   lwz    tos,0(sp)
   addi   sp,sp,1cell
c;
code dsisr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,dsisr
c;

\ Data Address Register (DAR): spr 19
\ contains the faulted address after a DSI or alignment exception.
code dar@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,dar
c;
\ is this register writable? (ry)
code dar! ( n -- )
   mtspr dar,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ -------------------------------------------------------------
\ These are defined in forthint.fth .  They should be here.
\
\ \ Decrementer: spr 22
\ \ code dec!  ( n -- )
\    mtspr  dec,tos
\    lwz    tos,0(sp)
\    addi   sp,sp,1cell
\ c;
\ code dec@  ( -- n )
\    stwu   tos,-1cell(sp)
\    mfspr  tos,dec
\ c;

\ SDR1 register: spr 25
code sdr1@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,sdr1
c;
code sdr1! ( n -- )
   mtspr sdr1,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ machine status Save and Restore Registers (SRR0 - SRR1): spr 26 - 27
code srr0@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,srr0
c;
code srr0! ( n -- )
   mtspr srr0,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code srr1@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,srr1
c;
code srr1! ( n -- )
   mtspr srr1,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ SPRG0 to SPRG3: spr 272 - 275
\ misc. spr for OS usage
code sprg0@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,sprg0
c;
code sprg0! ( n -- )
   mtspr sprg0,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code sprg1@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,sprg1
c;
code sprg1! ( n -- )
   mtspr sprg1,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code sprg2@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,sprg2
c;
code sprg2! ( n -- )
   mtspr sprg2,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code sprg3@ ( -- n)
   stwu tos,-1cell(sp)
   mfspr tos,sprg3
c;
code sprg3! ( n -- )
   mtspr sprg3,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ external address register: spr 282.
\ used with eciwx and ecowx instructions only.
code ear@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,ear
c;   
\ is this register writable? (ry)
code ear! ( n -- )
   mtspr ear,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ timebase register (for writing): spr 284 - 285.
\ use get-tb for reading. see getms.fth.
: put-tb  ( tbu tbl -- )
   ." writing to Time Base Register pair not implemented. " cr
;

\ processor version register: spr 287 (read only).
code pvr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,pvr
c;   
: cpu-version  ( -- n )  pvr@ lwsplit nip  ;

\ instruction Block Address Translation (BAT) registers: spr 528 - 535.
\ data Block Address Translation (BAR) registers: spr 536-543
\ see bat.fth.

\ Monitor Mode Control Register 0 (MMCR0): spr 952
\ Performance Monitor Counters (PMC1-2): spr 953 - 954
code mmcr0@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,mmcr0
c;   
code mmcr0! ( n -- )
   mtspr mmcr0,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code pmc1@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,pmc1
c;   
code pmc1! ( n -- )
   mtspr pmc1,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code pmc2@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,pmc2
c;   
code pmc2! ( n -- )
   mtspr pmc2,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ Sampled Instruction/Data Address (SIA, SDA): spr 955, 959
code sia@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,sia
c;   
code sia! ( n -- )
   mtspr sia,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code sda@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,sda
c;   
code sda! ( n -- )
   mtspr sda,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ Hardware Implementation Dependent Register (HID0): spr 1008.
code hid0@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,hid0
c;   
code hid0! ( n -- )
   mtspr hid0,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ Instr/Data Address Breakpoint Register (IABR, DABR): spr 1010, 1013.
code iabr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,iabr
c;   
code iabr! ( n -- )
   mtspr iabr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code dabr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,dabr
c;   
code dabr! ( n -- )
   mtspr dabr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ Process Identification Register (PIR): spr 1023
code pir@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,pir
c;   
code pir! ( n -- )
   mtspr pir,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code buscsr@  ( -- n )	\ 620-specific
   stwu  tos,-1cell(sp)
   mfspr tos,buscsr
c;

\ 603-Arthur L2 Cache Control Register (L2CR): spr 1017.
code l2cr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,l2cr
c;
code l2cr! ( n -- )
   mtspr l2cr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

\ 823-specific
code ic-csr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,ic-csr
c;   
code ic-csr!  ( n -- )
   sync
   mtspr ic-csr,tos
   isync
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code dc-csr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,dc-csr
c;   
code dc-csr!  ( n -- )
   sync
   mtspr dc-csr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code md-ctr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-ctr
c;   
code md-ctr!  ( n -- )
   mtspr md-ctr,tos
   sync isync
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-epn@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-epn
c;   
code md-epn!  ( n -- )
   mtspr md-epn,tos
   sync isync
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-rpn@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-rpn
c;   
code md-rpn!  ( n -- )
   mtspr md-rpn,tos
   sync isync
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-twc@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-twc
c;   
code md-twc!  ( n -- )
   mtspr md-twc,tos
   sync isync
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-ap@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-ap
c;   
code md-ap!  ( n -- )
   mtspr md-ap,tos
   sync isync
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-cam@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-cam
c;   
code md-cam!  ( n -- )
   eieio
   mtspr md-cam,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-ram0@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-ram0
c;   
code md-ram0!  ( n -- )
   mtspr md-ram0,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code md-ram1@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,md-ram1
c;   
code md-ram1!  ( n -- )
   mtspr md-ram1,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code m-twb@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,m-twb
c;   
code m-twb!  ( n -- )
   mtspr m-twb,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code m-casid@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,m-casid
c;   
code m-casid!  ( n -- )
   mtspr m-casid,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

code immr@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,immr
c;   
code immr! ( n -- )
   mtspr immr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;
code der@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,der
c;
code der!  ( n -- )
   mtspr immr,tos
   lwz tos,0(sp)
   addi sp,sp,1cell
c;

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
