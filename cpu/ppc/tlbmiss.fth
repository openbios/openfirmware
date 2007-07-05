purpose: TLB miss handlers for 603-style (software PTE search) MMU
\ See license at end of file

also assembler definitions
\needs set-y  : set-y  ( -- )  h# 0020.0000 add-bits  ;
previous definitions

headerless
label itlb-miss
   \ Adapted from the code in section 7.6.3.2.2 of the 603 manual
   mfspr   r2,hash1		\ PTEG address
   mfspr   r0,ctr		\ Save CTR
   mfspr   r3,icmp		\ Comparison value
   begin
      mfmsr   r1
      andi.   r1,r1,1
      <> if			\ Little-endian
         addi    r2,r2,-4	\ Account for pre-increment and endianness
      else
         addi    r2,r2,-8	\ Account for pre-increment
      then
      addi    r1,0,8		\ PTEs per PTEG
      mtspr   ctr,r1		\ Load CTR
      begin
         lwzu  r1,8(r2)		\ Get first word of PTE
         cmp   0,0,r1,r3	\ Found PTE?
      = ctr=0 until
      = if			\ Found?
         \ Found a matching TLB entry
         mfmsr   r1
         andi.   r1,r1,1
         <> if			\ Little-endian
            addi  r2,r2,-8	\ Bias address to account for endianness
         then
         lwz   r1,4(r2)		\ Get physical word of matching TLB entry
         andi. r3,r1,8		\ Check G bit
         1 F: <> brif		\ ISI because of ifetch of guarded page

         mtspr ctr,r0		\ Restore CTR
         mfspr r0,imiss		\ Miss address
         mfspr r3,srr1		\ saved cr0 bits
         mtcrf h#80,r3		\ Restore CR0
         mtspr rpa,r1		\ Set PTE
         ori   r1,r1,h#100	\ Set the reference bit
         tlbli r0		\ Load the TLB entry
         tlbsync		\ wait for tlbli to complete
         stw  r1,4(r2)		\ update page table with R bit set
         sync			\ wait for page table store to complete
         rfi
      then

      \ Not found; try secondary hash or signal exception
      andi.   r1,r3,h#40	\ See if we have done second hash
   0= while
      mfspr   r2,hash2		\ Try secondary hash
      ori     r3,r3,h#40	\ Set H bit in compare value
   repeat

   \ No HTAB entry; let the normal IAE handler take care of it
   mfspr  r3,srr1		\ Get SRR1
   rlwinm r2,r3,0,16,31 	\ Clear high bits
   addis  r2,r2,h#4000  	\ Or in srr1<1> = 1 to flag PTE not found
   2 F: always brif		\ Branch to common IAE code

1 L:				\ Protection violation (guarded page)
   mfspr  r3,srr1		\ Get SRR1
   rlwinm r2,r3,0,16,31 	\ Clear high bits
   addis  r2,r2,h#0800  	\ Or in srr1<4> = 1 to flag prot. violation
   
2 L:				\ Common code for instruction access exception
   mtspr  ctr,r0		\ Restore CTR
   mtspr  srr1,r2		\ Put back fixed SRR1
   mfmsr  r0			\ Get MSR
   xoris  r0,r0,h#0002		\ Flip the MSR<tgpr> bit
   mtcrf  h#80,r3		\ Restore CR0
   mtmsr  r0			\ Go back to the normal GPRs
   h# 400 ba *			\ Go to the normal ISI handler
end-code
here itlb-miss - constant /itlb-miss

\ This handler is used for both load and store exceptions because, since
\ we don't do demand paging, we need not maintain the "C" (changed) bit.

label dtlb-r-miss
   \ Adapted from the code in section 7.6.3.2.2 of the 603 manual
   mfspr   r2,hash1	\ PTEG address
   mfspr   r0,ctr	\ Save CTR
   mfspr   r3,dcmp	\ Comparison value
   begin
      mfmsr   r1
      andi.   r1,r1,1
      <> if			\ Little-endian
         addi    r2,r2,-4	\ Account for pre-increment and endianness
      else
         addi    r2,r2,-8	\ Account for pre-increment
      then
      addi    r1,0,8		\ PTEs per PTEG
      mtspr   ctr,r1		\ Load CTR
      begin
         lwzu  r1,8(r2)		\ Get first word of PTE
         cmp   0,0,r1,r3	\ Found PTE?
      = ctr=0 until
      = if
         \ Found a matching TLB entry
         mfmsr   r1
         andi.   r1,r1,1
         <> if			\ Little-endian
            addi  r2,r2,-8	\ Bias address to account for endianness
         then
         lwz   r1,4(r2)		\ Get physical word of matching TLB entry
         mtspr ctr,r0		\ Restore CTR
         mfspr r0,dmiss		\ Miss address
         mfspr r3,srr1		\ saved cr0 bits
         mtcrf h#80,r3		\ Restore CR0
         mtspr rpa,r1		\ Set PTE
         ori   r1,r1,h#100	\ Set the referenced bit
         tlbld r0		\ Load the TLB entry
         tlbsync		\ Wait for tlbld to complete
         stw   r1,4(r2)		\ Update TLB entry
         sync			\ Wait for page table store to complete
	 rfi
      then

      \ Not found; try secondary hash or signal exception
      andi.   r1,r3,h#40	\ See if we have done second hash
   0= while
      mfspr   r2,hash2		\ Try secondary hash
      ori     r3,r3,h#40	\ Set H bit in compare value
   repeat

   set    r1,h#4000.0000	\ Set dsisr1<1> = 1 to flag PTE not found
   
   mfspr  r3,srr1		\ Get SRR1
   mtspr  ctr,r0		\ Restore CTR
   rlwinm r2,r3,0,16,31		\ Clear upper bits of SRR1
   mtspr  srr1,r2		\ Put back fixed SRR1
   mtspr  dsisr,r1		\ Set DSISR
   mfspr  r1,dmiss		\ Get miss address

   rlwinm. r2,r2,0,31,31  	\ Test LE bit
   <> if			\ Little-endian
				\ Note: this is naive; the processor's address
				\ swizzling is size-dependent.  However, this
				\ is what the example code in the 603 data
				\ book does.
      xori  r1,r1,7		\ convert to little-endian data address
   then

   mtspr  dar,r1		\ Set DAR
   mfmsr  r0			\ Get MSR
   xoris  r0,r0,h#0002		\ Flip the MSR<tgpr> bit
   mtcrf  h#80,r3		\ Restore CR0
   mtmsr  r0			\ Go back to the normal GPRs
   h# 300 ba *			\ Go to the normal DSI handler
end-code
here dtlb-r-miss - constant /dtlb-r-miss

label dtlb-w-miss
   \ Adapted from the code in section 7.6.3.2.2 of the 603 manual
   mfspr   r2,hash1	\ PTEG address
   mfspr   r0,ctr	\ Save CTR
   mfspr   r3,dcmp	\ Comparison value
   begin
      mfmsr   r1
      andi.   r1,r1,1
      <> if			\ Little-endian
         addi    r2,r2,-4	\ Account for pre-increment and endianness
      else
         addi    r2,r2,-8	\ Account for pre-increment
      then
      addi    r1,0,8		\ PTEs per PTEG
      mtspr   ctr,r1		\ Load CTR
      begin
         lwzu  r1,8(r2)		\ Get first word of PTE
         cmp   0,0,r1,r3	\ Found PTE?
      = ctr=0 until
      = if
         \ Found a matching TLB entry

         mfmsr   r1
         andi.   r1,r1,1
         <> if			\ Little-endian
            addi  r2,r2,-8	\ Bias address to account for endianness
         then

         lwz   r1,4(r2)		\ Get physical word of matching TLB entry
         andi. r3,r1,h#80	\ Check the C bit
         0 F: = brif		\ If (C==0) goto cEq0ChkProt (check prot modes)

1 L:				\ (ceq2:)
         mtspr ctr,r0		\ Restore CTR
         mfspr r0,dmiss		\ Miss address
         mfspr r3,srr1		\ saved cr0 bits
         mtcrf h#80,r3		\ Restore CR0
         mtspr rpa,r1		\ Set PTE
         tlbld r0		\ Load the TLB entry
         tlbsync		\ Wait for tlbld to complete
         sync
         rfi
      then

      \ Not found; try secondary hash or signal exception
      andi.   r1,r3,h#40	\ See if we have done second hash
   0= while
      mfspr   r2,hash2		\ Try secondary hash
      ori     r3,r3,h#40	\ Set H bit in compare value
   repeat

   set    r1,h#4200.0000	\ Set dsisr1<1> = 1 to flag PTE not found,
				\ <6>=1 to denote "store" operation)
   3 F: always brif

2 L:
   set    r1,h#0a00.0000		\ Set dsisr1<4> = 1 to flag prot. violation
				\           <6> = 1 to denote "store" operation
3 L:
   mfspr  r3,srr1		\ Get SRR1
   mtspr  ctr,r0		\ Restore CTR
   rlwinm r2,r3,0,16,31		\ Clear upper bits of SRR1
   mtspr  srr1,r2		\ Put back fixed SRR1
   mtspr  dsisr,r1		\ Set DSISR
   mfspr  r1,dmiss		\ Get miss address

   rlwinm. r2,r2,0,31,31  	\ Test LE bit
   <> if			\ Little-endian
				\ Note: this is naive; the processor's address
				\ swizzling is size-dependent.  However, this
				\ is what the example code in the 603 data
				\ book does.
      xori  r1,r1,7		\ convert to little-endian data address
   then

   mtspr  dar,r1		\ Set DAR
   mfmsr  r0			\ Get MSR
   xoris  r0,r0,h#0002		\ Flip the MSR<tgpr> bit
   mtcrf  h#80,r3		\ Restore CR0
   mtmsr  r0			\ Go back to the normal GPRs
   h# 300 ba *			\ Go to the normal DSI handler

0 L:				\ (cEq0ChkProt:)
\	We found the PTE in the page table and it has the
\	C (changed) bit set to zero. Check the protection bits.
\	PP:	00	SRSW
\		01	SRWUR
\		10	SRWURW
\		11	SRUR
   rlwinm.	r3,r1,30,0,1	\ test PP
    
   < if 			\ if (PP==10 or PP==11)
      andi.   r3,r1,1		\ test PP[0]
      4 F:  = brif set-y	\ return if PP==10
      2 B:  always brif		\ else Data Access Exception Protection (PP=11)

   then

   \ (chk0:)
   \ PP==00 or PP==01
   \ Test MSR[PR] to determine protection violation.

   mfspr	r3,srr1		\ get old msr
   andi.	r3,r3,0x4000	\ test PR bit

   <> if set-y			\ if (PR!=0)
      mfspr	r3,dmiss	\ get miss address
      mfsrin	r3,r3		\ get associated segment register
      andis.	r3,r3,0x2000	\ test Kp bit
      4 F:  = brif set-y	\ if (Kp==0) goto chk2
      2 B:  always brif		\ else Data Access Exception Protection
   then

   mfspr   r3,dmiss		\ get miss address (chk1:)
   mfsrin  r3,r3		\ get associated segment register
   andis.  r3,r3,0x4000		\ test Ks bit
   4 F:  = brif set-y		\ if (Ks==0) goto chk2
   2 B:  always brif		\ else Data Access Exception Protection

4 L:				\ (chk2:) No protection violation
   ori  r1,r1,0x180		\ set reference and change bit
   stw	r1,4(r2)		\ update page table
   1 B: always brif		\ go back to main-line handler code

end-code
here dtlb-w-miss - constant /dtlb-w-miss

: put-handler  ( adr exc-adr len -- )  2dup 2>r move  2r> sync-cache  ;   

: install-tlb-miss  ( -- )
   software-tlb-miss?  if
      itlb-miss   h# 1000 /itlb-miss   put-handler   \ Ifetch TLB miss
      dtlb-r-miss h# 1100 /dtlb-r-miss put-handler   \ Data load TLB miss
      dtlb-w-miss h# 1200 /dtlb-w-miss put-handler   \ Data store TLB miss
   then
;
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
