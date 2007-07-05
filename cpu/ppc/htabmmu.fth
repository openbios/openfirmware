purpose: HTAB paged MMU driver
\ See license at end of file

also forth definitions

headers

h#    1.0000 value /htab
/htab value htab
/htab value htab-phys

headerless

false value mmu64?
h#        40 value tag-h
h# 8000.0000 value tag-v
              8 value /htab-entry
/htab-entry 8 * value /htab-group
previous definitions

also
: invalidate-pte  ( pte-adr -- )  0 swap l!  ;

\ Data in exception vector area:
\ 4f0: save-state address
\ 4f4: PTEG roving replacement offset
\ 4f8: physical base address of "translations" list
\ 4fc: virtual base address of "translations" list

\ Data in this cpu's exception area (exception-area)
\  00: save r3
\  04: save r2
\  08: save lr
\  0c: save exception number
\  10: save cr
\  14: save base
\  18: save ip
\  1c: save lr
\  20-3c: save registers

\ fault - r4   node - r5   offset - r6   adr - r7   end - r8
\ Physical address 
also assembler also register-names definitions
warning @ warning off
4 constant fault
5 constant node
6 constant offset
7 constant adr
8 constant end
9 constant temp
warning !
previous previous definitions

\ get-phys searches the "translations" list, which is the master copy of
\ the information describing the current set of virtual to physical
\ address translations.  The input (in r3) is the virtual address.  The
\ output (in r3) is -1 if there was no mapping for that virtual address,
\ or the physical word of the PTE, containing the physical page number and
\ the mode bits, otherwise.

\ Input:    r4 - virtual address of fault
\ Output:   r3 - physical_PTE_word or -1
\ Destroys: r4-r8
label get-phys
   lwz    node,h#4f8(r0)	\ Physical base address of translation list
   lwz    offset,h#4fc(r0)	\ Virtual base address of translation list
   ahead  begin
      subf node,offset,node	\ Convert node virtual address to physical
      lwz  adr,1cell(node)	\ Beginning virtual address of range
      cmpl 0,0,adr,fault	\ Test beginning of range
      <=  if
         lwz  end,2cells(node)	\ Length of mapped range
         add  end,adr,end	\ Ending virtual address of range
         cmpl 0,0,end,fault	\ Test end of range
         >  if
1 L:
	    \ We found it
	    rlwinm  temp,fault,0,0,19	\ Zero fault address page offset bits
	    subf    adr,adr,temp	\ Compute page offset within range
	    lwz     r3,3cells(node)	\ Physical page#
	    rlwinm  r3,r3,12,0,19	\ Shift page# into place
            add     r3,r3,adr		\ physical address portion is complete
            lwz     adr,4cells(node)	\ WIMG.PP
	    or      r3,r3,adr		\ PTE physical word is complete
2 L:
	    bclr    20,0
	 then

	 \ If the ending address is 0, it really means 2^32, which is
	 \ larger than any possible fault address.
         cmpi 0,0,end,0
         1 B:  =  brif

      then

   but then
      lwz  node,0(node)		\ Next node
      cmpi 0,0,node,0
   = until

   \ No translation found
   set  r3,-1

   2 B: again
end-code

\ r3:phys  r4:fault  r5:vsid  r6:pteg  r7:htab/ctr_save  r8:mask  r9:temp

also assembler also register-names definitions
warning @ warning off
5 constant vsid
6 constant pteg
7 constant htab
8 constant mask
warning !
previous previous definitions

label find-pte  ( r4: virtual -- r5: vsid r6: 'pte )
   mfsrin  vsid,fault		\ Get virtual segment ID
   rlwinm  vsid,vsid,0,13,31	\ Keep the low 19 bits (omit protection bits)
   rlwinm  pteg,fault,20,16,31	\ Move page index bits into place
   xor     pteg,vsid,pteg	\ Compute hash value

   mfspr   htab,sdr1		\ Get hash table base address and size mask

mfspr   mask,pvr
rlwinm  mask,mask,16,16,31
cmpi    0,0,mask,20
<> if   \ 32-bit code
   addi    mask,r0,h#3ff	\ Set low 10 bits of mask
   rlwimi  mask,htab,10,13,21	\ merge in upper 9 bits
   rlwinm  mask,mask,6,7,25	\ Move up 6 bits to align with PTEG address

   rlwinm  pteg,pteg,6,7,25	\ Move into place
   and     pteg,pteg,mask	\ Compute low bits of pte

   rlwinm  htab,htab,0,0,15	\ Eliminate mask bits
   or      pteg,htab,pteg	\ Insert hash table base into the high bits

   \ Now we have the address of the primary page table entry group in "pteg".
   \ We also need to preserve "mask" in case we need to find the secondary
   \ PTEG, and "fault" and "vsid" to generate the first word of the new PTE.

   mfspr   htab,ctr		\ htab is no longer needed so we re-use it

   \ Generate the tag for the first word of the new PTE
   rlwinm  vsid,vsid,7,1,24
   rlwimi  vsid,fault,10,26,31	\ Move bits 4-9 to 26-31
   \ vsid is now the new PTE tag

   \ In little-endian mode, addresses within a PTE are swizzled from the
   \ viewpoint of code executing on the CPU, which does 32-bit or smaller
   \ accesses, but not from the viewpoint of the table-search hardware,
   \ which appears to do 64-bit accesses.  Consequently, in little-endian
   \ mode, the tag word appears at offset 4 and the physical word at offset 0.
   mfmsr  temp
   andi.  temp,temp,1
   <> if			\ Little-endian
      addi  pteg,pteg,4		\ Tag is in second longword when in LE mode
   then

   addi   pteg,pteg,-8
   set    temp,8
   mtspr  ctr,temp
   begin
      lwzu  temp,8(pteg)
      cmpi 0,0,temp,0
      1 F:  >=  brif
   countdown
   
   \ Didn't find room in the primary PTEG - search the secondary PTEG
   addi   pteg,pteg,h#-38	\ Reset the lower bits
   xor    pteg,pteg,mask	\ Invert the hash bits - to secondary PTEG

   ori    vsid,vsid,h#40	\ Set the "H" bit in the tag

   addi   pteg,pteg,-8
   set    temp,8
   mtspr  ctr,temp
   begin
      lwzu  temp,8(pteg)
      cmpi 0,0,temp,0
      1 F:  >=  brif
   countdown

   \ Didn't find room in the secondary PTEG - replace a primary entry.
   addi   pteg,pteg,h#-38	\ Reset the lower bits
   xor    pteg,pteg,mask	\ Invert the hash bits - back to primary PTEG
   rlwinm vsid,vsid,0,26,24	\ Clear the "H" bit in the tag

   \ It might be nice to use the statistics bits to implement a pseudo-LRU
   \ replacement policy, but that is too complicated for now (especially
   \ since I don't want to bother with the complexity of a periodic process
   \ to test the bits), so I'm using a roving replacement pointer instead.
   \ The performance difference is probably entirely negligeable in this
   \ environment, and might favor the roving pointer anyway.
   lwz    temp,h#4f4(r0)	\ Get replacement index
   add    pteg,temp,pteg	\ Address of PTE to replace

   addi   temp,temp,8		\ Update replacement pointer
   cmpi   0,0,temp,h#40
   =  if
      set  temp,0
   then
   stw    temp,h#4f4(r0)

   set    temp,0
   stw    temp,0(pteg)		\ Invalidate tag word
else
   set     mask,h#4.0000	\ Smallest hash table size
\ TRYME   rldcr   mask,mask,htab,45	\ Shift to actual size
   rlwnm   mask,mask,htab,0,13	\ Shift to actual size
   addi    mask,mask,-1         \ Convert to mask
   rlwinm  mask,mask,0,0,24	\ Clear low 7 bits to align to PTEG base

\ TRYME   rldic   pteg,pteg,7,0	\ Move hash value into place
   rlwinm  pteg,pteg,7,0,24	\ Move hash value into place
   and     pteg,pteg,mask	\ Compute low bits of PTE

\ TRYME   rldicr  htab,htab,0,45	\ Eliminate mask bits
   rlwinm  htab,htab,0,0,13	\ Eliminate mask bits
   or      pteg,htab,pteg	\ Insert hash table base into the high bits

   \ Now we have the address of the primary page table entry group in "pteg".
   \ We also need to preserve "mask" in case we need to find the secondary
   \ PTEG, and "fault" and "vsid" to generate the first word of the new PTE.

   mfspr   htab,ctr		\ htab is no longer needed so we re-use it

   \ Generate the tag for the first word of the new PTE
\ TRYME  rldicr  vsid,vsid,12,51
   rlwinm  vsid,vsid,12,0,19
   rlwimi  vsid,fault,16,20,24	\ Move bits 4-8 to 20-24 (64-bit: okay as-is)
   \ vsid is now the new PTE tag

\ ZZZ 23/5/96 was 16
   addi   pteg,pteg,-16   \ Account for pre-increment
   set    temp,8
   mtspr  ctr,temp
   begin
      ldu  temp,16(pteg)
      andi. temp,temp,1		\ Test valid bit
      1 F:  >=  brif
   countdown
   
   \ Didn't find room in the primary PTEG - search the secondary PTEG
   addi   pteg,pteg,h#-70	\ Reset the lower bits
   xor    pteg,pteg,mask	\ Invert the hash bits - to secondary PTEG

   ori    vsid,vsid,2	\ Set the "H" bit in the tag

   addi   pteg,pteg,-16
   set    temp,8
   mtspr  ctr,temp
   begin
      ldu  temp,16(pteg)
      andi. temp,temp,1		\ Test valid bit
      1 F:  >=  brif
   countdown

   \ Didn't find room in the secondary PTEG - replace a primary entry.
   addi   pteg,pteg,h#-70	\ Reset the lower bits
   xor    pteg,pteg,mask	\ Invert the hash bits - back to primary PTEG
   rlwinm vsid,vsid,0,31,29	\ Clear the "H" bit in the tag

   \ It might be nice to use the statistics bits to implement a pseudo-LRU
   \ replacement policy, but that is too complicated for now (especially
   \ since I don't want to bother with the complexity of a periodic process
   \ to test the bits), so I'm using a roving replacement pointer instead.
   \ The performance difference is probably entirely negligeable in this
   \ environment, and might favor the roving pointer anyway.
   lwz    temp,h#4f4(r0)	\ Get replacement index
   add    pteg,temp,pteg	\ Address of PTE to replace

   addi   temp,temp,16		\ Update replacement pointer
   cmpi   0,0,temp,h#80
   =  if
      set  temp,0
   then
   stw    temp,h#4f4(r0)

   set    temp,0
   std    temp,0(pteg)		\ Invalidate tag word

\ ZZZ AEC 23/5/1996 added ; 620 errata: tlbia does not work
\   tlbia
   sync
then

   sync
   tlbie  pteg
   sync
   tlbsync
   sync

1 L:
   mtspr ctr,htab
   bclr  20,0
end-code

\ Common code for HTAB ISI and DSI miss handlers.
\ Input:  r3: virtual address
\         r2: exception-area
\ Output: none (returns from interrupt)
\ Side effects:
\    If the input virtual address is mapped, adds or replaces an HTAB entry,
\    clearing the TLB as needed, to reflect that mapping.
\    If the input virtual address is not mapped, transfers control to the
\    unexpected exception handler.
\ Destroys: nothing
\ Requirements:
\    The pre-trap value of R3 must be in memory location 0(sprg0)
\    The pre-trap value of CR must be in memory location h#10(sprg0)
\    Those register values are restored before returning.
\ Uses:
\    Memory location h#0c(sprg0) to store the exception address.
\    Memory locations h#20-h#34(sprg0) for saving registers.

label htab-miss-handler

   stw r4,h#20(r2)   stw r5,h#24(r2)   stw r6,h#28(r2)	\ Save GPRs
   stw r7,h#2c(r2)   stw r8,h#30(r2)   stw r9,h#34(r2)

   mr    fault,r3

   \ Determine the physical address, if any, to which the virtual address
   \ that caused the fault is mapped.

   get-phys  bl *		\ ( virtual -- pte-phys|-1 )

   \ If there is no valid mapping for that virtual address, invoke the
   \ unexpected exception handler.
   cmpi    0,0,r3,-1		\ If no 
   =  if
      lwz r4,h#20(r2)  lwz r5,h#24(r2)  lwz r6,h#28(r2)	\ Restore GPRs
      lwz r7,h#2c(r2)  lwz r8,h#30(r2)  lwz r9,h#34(r2)

      \ Restore registers and jump to unexpected exception handler
      lwz    r3,h#10(r2)   mtcrf  h#80,r3		\ Restore CR
      lwz    r3,h#4f0(r0)	\ save-state address
      mtspr  lr,r3
      lwz    r3,h#0c(r2)	\ Exception address
      bclr   20,0		\ branch to exception handler
   then

   find-pte  bl *   ( r4: fault-address -- r6: 'pte )

   mfspr   temp,pvr
   rlwinm  temp,temp,16,16,31
   cmpi    0,0,temp,20
   <> if			\ 32-bit processor
      \ pteg now points to the tag word of an invalid PTE; replace its value
      \ See clause 4.12.1 of the PPC architecture spec (hard-back book)
      \ for an explanation of this sequence.
      mfmsr  temp
      andi.  temp,temp,1
      <> if			\ Little-endian
         stw    r3,-4(pteg)	\ Replace physical address portion
      else
         stw    r3,4(pteg)	\ Replace physical address portion
      then

      stw    vsid,0(pteg)	\ Replace the tag word with valid bit clear
      sync
      oris   vsid,vsid,h#8000	\ Set the valid bit
      stw    vsid,0(pteg)	\ Replace the tag word with valid bit set
   else			\ 64-bit processor
      \ pteg now points to the tag word of an invalid PTE; replace its value
      \ See clause 4.12.1 of the PPC architecture spec (hard-back book)
      \ for an explanation of this sequence.
      std    r3,8(pteg)		\ Replace physical address portion
      std    vsid,0(pteg)	\ Replace the tag word with valid bit clear
      sync
      ori    vsid,vsid,1	\ Set the valid bit
      std    vsid,0(pteg)	\ Replace the tag word with valid bit set
   then
   
   \ Restore registers used herein

   lwz r4,h#20(r2)  lwz r5,h#24(r2)  lwz r6,h#28(r2)	\ Restore GPRs
   lwz r7,h#2c(r2)  lwz r8,h#30(r2)  lwz r9,h#34(r2)

   \ Restore registers used by the generic trap preamble
   lwz    r3,h#10(r2)   mtcrf  h#80,r3		\ Restore CR
   lwz    r3,h#08(r2)   mtspr  lr,r3		\ Restore LR
   lwz    r3,h#00(r2)				\ Restore r3
   lwz    r2,h#04(r2)				\ Restore r2

   \ Return from interrupt
   rfi
end-code

\ r2, r3, and lr have been saved. r2 points to the this cpu's exception-area,
\ r3 points to the address where the exception occured.
label htab-isi-handler
   stw    r3,h#0c(r2)		\ Save exception number
   mfcr   r3
   stw    r3,h#10(r2)		\ Save CR

   \ Determine the fault type
   mfspr   r3,srr1		\ Fault type is in SRR1 for I faults
   rlwinm. r3,r3,0,1,1		\ Test bit 1
   0=  if			\ Not a translation fault
      \ Restore registers and jump to unexpected exception handler
      lwz    r3,h#10(r2)   mtcrf  h#80,r3		\ Restore CR
      lwz    r3,h#4f0(r0)	\ save-state address
      mtspr  lr,r3
      lwz    r3,h#0c(r2)	\ Exception address
      bclr   20,0		\ branch to exception handler
   then

   mfspr  r3,srr0		\ Get fault address

   htab-miss-handler  b *	\ Jump to common code
end-code

\ r2, r3, and lr have been saved. r2 points to the this cpu's exception-area,
\ r3 points to the address where the exception occured.
label htab-dsi-handler
   stw    r3,h#0c(r2)		\ Save exception number
   mfcr   r3
   stw    r3,h#10(r2)		\ Save CR

   \ Determine the fault type
   mfspr   r3,dsisr		\ SPR18
   rlwinm. r3,r3,0,1,1		\ Test bit 1
   0=  if			\ Not a translation fault
      \ Restore registers and jump to unexpected exception handler
      lwz    r3,h#10(r2)   mtcrf  h#80,r3		\ Restore CR
      lwz    r3,h#4f0(r0)	\ save-state address
      mtspr  lr,r3
      lwz    r3,h#0c(r2)	\ Exception address
      bclr   20,0		\ branch to exception handler
   then

   mfspr  r3,dar		\ Get fault address

   htab-miss-handler  b *	\ Jump to common code
end-code

previous

headers
\ sdr1@ and sdr1! are okay for 64-bit implementations if the physical
\ address of the page table is in the lower 4GB of memory, which is a
\ fairly safe assumption.
code sdr1!  ( n -- )
   mtspr  sdr1,tos
   lwz    tos,0(sp)
   addi   sp,sp,1cell
c;
code sdr1@  ( -- n )
   stwu   tos,-1cell(sp)
   mfspr  tos,sdr1
c;

headerless
\ We could use "fill" for this, but it is slightly faster to do it this way,
\ because we only have to touch every other word.
code invalidate-htab-64  ( -- )
   mfspr  t3,sdr1
   rlwinm t3,t3,0,27,31		\ Compute hash table size from shift count
   set    t4,h#4.0000		\ Shift count 0 means 256K
   rlwnm  t3,t4,t3,0,31

   'user htab  lwz  t0,*	\ Virtual address of hash table

   \ Hardware accesses PTEs as doublewords, so address swizzling doesn't occur.
   addi   t0,t0,-16		\ Account for pre-increment

   rlwinm t3,t3,28,4,31		\ Divide by 16; we'll touch each PTE once
   set    t2,0
   mtspr  ctr,t3		\ Set loop count
   begin
      stdu t2,16(t0)		\ Clear the tag word of each PTE
   countdown
   mtspr  ctr,up		\ Restore CTR register
c;

\ We could use "fill" for this, but it is slightly faster to do it this way,
\ because we only have to touch every other word.
code invalidate-htab-32  ( -- )
   mfspr  t3,sdr1
   rlwinm t3,t3,16,7,15		\ Compute hash table size from mask bits
   ori    t3,t3,h#ffff		\ MAX(hashbits,64k-1)
   addi   t3,t3,1

   'user htab  lwz  t0,*	\ Virtual address of hash table

   \ Hardware accesses PTEs as doublewords, so address swizzling doesn't occur.
   \ Consequently, when accessing a PTE from the processor, we must undo
   \ its swizzling.
   mfmsr  t4
   andi.  t4,t4,1		\ Test little-endian bit
   <> if			\ Little endian
      addi   t0,t0,-4		\ Account for pre-increment and endianness
   else
      addi   t0,t0,-8		\ Account for pre-increment
   then

   rlwinm t3,t3,29,3,31		\ Divide by 8; we'll touch each PTE once
   set    t2,0
   mtspr  ctr,t3		\ Set loop count
   begin
      stwu t2,8(t0)		\ Clear the tag word of each PTE
   countdown
   mtspr  ctr,up		\ Restore CTR register
c;

: set-mmu  ( -- )
   cpu-version d# 20 =  if
      true to mmu64?
      h#    4.0000 to /htab
                 2 to tag-h
                 1 to tag-v
      d#        16 to /htab-entry
      h#        80 to /htab-group
   then
;

: get-htab  ( -- phys size )
   sdr1@ dup
   mmu64?  if
      h# 3.ffff invert and   h# 4.0000  rot h# 1f and  lshift
   else
      h# ffff invert and  swap h# 1ff and  1+  d# 16 lshift
   then
;
: set-htab  ( phys size -- )
   mmu64?  if
      log2 d# 18 -       ( phys size-code )
   else
      1- d# 16 rshift    ( phys size-mask )
   then
   or sdr1!
;
: init-paged-mmu  ( -- )
   htab /htab 0  mem-claim  drop

   \ We don't use invalidate-htab here because we want the HTAB to start
   \ out completely clean, and invalidate-htab clears only the tag words.
   htab  /htab  erase

   htab-phys  /htab set-htab
[ifdef] invalidate-tlb
   invalidate-tlb
[then]
;

[ifdef] shootdown-range
\ RFE: map? should report BAT mappings and VSID too
\ RFE: MMU driver should account for BAT mappings too

: >htab-adr  ( padr -- vadr )
   htab-phys - htab +
   mmu64?  if  la1+  then
   in-little-endian?  4 and xor
;
: htab-@  ( padr -- l )  >htab-adr l@  ;
: htab-!  ( l padr -- )  >htab-adr l!  ;

\ HTAB display tools

: break-pte  ( phys-stuff tag -- false | rc.wimg.pp phys api vsid h true )
   \ Check valid bit
   dup tag-v and  0=  if  2drop false exit  then     ( phys-stuff tag )

   \ Extract physical address and type field
   over 9 lowbits  rot h# fff invert and   ( tags rc.wimg.pp phys )
   rot                                     ( rc.wimg.pp phys tags )

   \ Extract tag information
   mmu64?  if
      d# 7 5 bits  d# 23 lshift swap        ( rc.wimg.pp phys api tags )
      \ XXX we should extract more vsid bits from the 64-bit tag
      dup d# 12  d# 25 bits  swap           ( rc.wimg.pp phys api vsid tags )
      1 1 bits                              ( rc.wimg.pp phys api vsid h )
   else
      dup h# 7f and d# 22 lshift  swap      ( rc.wimg.pp phys api tags )
      dup 7 d# 19 bits  swap                ( rc.wimg.pp phys api vsid tags )
      6 1 bits                              ( rc.wimg.pp phys api vsid h )
   then
   true
;
headers
: pte@  ( adr -- phys-stuff tag )
   dup /htab-entry 2/ +  htab-@   swap htab-@
;
headerless
: hold.  ( -- )  ascii . hold  ;
: .mode  ( mode -- )
   push-binary
   ."  RC.WIMG.PP: "  <# u# u# hold. 2/ u# u# u# u# hold. u# u# u#> type
   pop-base
;
: .phys  ( phys -- )   push-hex ." Physical: " u. pop-base  ;
: .pte  ( tags phys-stuff -- )
   break-pte  if
      push-hex
      ." H: " .
      ."  Virtual: " <# u# ascii , hold u#s u#> type	( rc.wimg.pp phys api )
      d# 20 >>  (.2) type ." X.Xxxx"			( rc.wimg.pp phys )
      pop-base
      ."   "  .phys  .mode
   else
      ." Invalid"
   then
   cr
;

\ See, for example, figure 7-24 in the 603 manual
\ >vsid is valid on 64-bit implementations only if the implementation
\ also supports mtsr and mfsr, as does the 620.
: >vsid  ( virtual -- sr )
   d# 28 4 bits sr@  mmu64?  if  d# 24 lowbits  then
;
: virtual>hash  ( virtual -- tag hash )
   dup
   mmu64?  if
      d# 23  5                            ( virtual bit# #bits )
   else
      d# 22  6                            ( virtual bit# #bits )
   then
   bits                                   ( virtual api )
   mmu64?  if  7 lshift  then             ( virtual api' )
   over >vsid  tuck                       ( virtual vsid api vsid )
   mmu64?  if  d# 12  else  7  then       ( virtual vsid api vsid bit# )
   lshift or  tag-v or                    ( virtual vsid tag )
   rot d# 12 d# 16 bits                   ( vsid tag page-index )
   rot                                    ( tag page-index vsid )
   \ 39 or 19 bit hash codes
   mmu64?  0=  if  h# 7ffff and  then     ( tag page-index vsid' )
   xor                                    ( tag hash )
;
: hash>ptegs  ( hash -- 'pteg1 'pteg2 )
   /htab-group *              ( hash<< )
   get-htab 1-                ( hash<< base size-mask )
   /htab-group 1- invert and  ( hash<< base size-mask' )

   rot over and               ( base size-mask masked-hash )
   rot or  tuck xor           ( 'pteg1 'pteg2 )
;
: virtual>pteg  ( virtual -- tag 'pteg1 'pteg2 )  virtual>hash hash>ptegs  ;

: virtual>pte  ( virtual -- false | pte-adr true )
   virtual>pteg  -rot                 ( 'pteg2 tag 'pteg1 )
   /htab-group bounds  do             ( 'pteg2 tag )
      dup i htab-@  =  if             ( 'pteg2 tag )
         2drop i true  unloop  exit
      then                            ( 'pteg2 tag )
   /htab-entry +loop                  ( 'pteg2 tag )
   tag-h or  swap                     ( tag' pteg2 )
   /htab-group bounds  do             ( tag )
      dup i htab-@  =  if             ( tag )
         drop i true  unloop  exit
      then                            ( tag )
   /htab-entry +loop                  ( tag )
   drop  false
;
: .pteg  ( 'pteg -- )  d# 64 bounds  ?do  i pte@ .pte  8 +loop  ;
headers
: pteg?  ( virtual -- )
   virtual>pteg                       ( tag 'pteg1 'pteg2 )
   swap ." Primary PTEG" cr  .pteg    ( tag 'pgeg2 )
   ." Secondary PTEG" cr  .pteg       ( tag )
   drop
;
: pte?  ( virtual -- )
   virtual>pte  if  pte@ .pte else  ." Not in HTAB" cr  then
;

headerless
: (shootdown-range)  ( virtual len -- )
   \ If we have to shootdown more than about 8 pages,
   \ it's faster to blow away the whole thing; searching
   \ for matching PTEs is pretty time-consuming.
   dup h# 8000 u>  if                          ( virtual len )
      2drop
      mmu64?  if  invalidate-htab-64  else  invalidate-htab-32  then
      invalidate-tlb   ( )
      exit
   then                                        ( virtual len )
   bounds  ?do                                 ( )
      i virtual>pte  if  0 swap htab-!  i invalidate-tlb-entry  then
   pagesize +loop
;
' (shootdown-range) to shootdown-range

: (map-mode)  ( phys.. mode -- mode' )
   >r  memory?  r>                    ( memory? mode )
   dup -2 -1 between if               ( memory? -1 )
      drop  if			      ( )
         h# 12	 \ For memory, WIMG.x.PP is 0010.0.10, i.e. M=1, PP=10
      else			      ( )
         h# 3a	 \ For I/O, WIMG.x.PP is 0111.0.10, i.e. I=1,M=1,G=1, PP=10
      then			      ( mode' )
   else                               ( memory? mode )
      nip			      ( mode )
   then				      ( mode' )
;
' (map-mode) to map-mode

headers
[ifdef] NOTYET
\ : init  ( -- )  ;

\ finish-device

warning @  warning off
only forth also definitions
: stand-init  ( -- )
   stand-init
   " /mmu" open-dev mmu-node !
;
warning !
[then]

: map?  ( virtual -- )
[ifdef] NOTYET
   " translate" mmu-node @ $call-method  if
[else]
   translate  if
[then]
      >r .phys r> .mode
   else
      ." Not mapped" cr
   then
;
[then]

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
