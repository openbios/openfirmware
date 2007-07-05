purpose: Block address translation (BAT) fault handler
\ See license at end of file

\ This handler for the DSI interrupt treats the BAT registers
\ as a 4-entry software-filled TLB.  4 BAT registers are not
\ enough to hold all of the translations that the firmware and
\ the client program might need, so we use the BATs as a translation
\ cache.  When a translation fault occurs, we pick a BAT register
\ and change its value to translate the address at which the fault
\ occurred.

\ For simplicity, we use a fixed block size.  For memory economy,
\ we use the largest possible block size (256 MBytes), thus requiring
\ a 16-entry in-memory translation table indexed by the high 4 bits
\ of the logical address.

\ Each table entry uses 8 bits - 4 for the physical block number
\ and 4 for the WIMG bits - so we use 8-bit table entries.
\ The other BAT register bits are either fixed values or can be
\ derived from the logical address.

\ We use a round-robin replacement policy.

\ We store the translation table in the DSI handler vector area so
\ it is easy to access from the fault handlers.

h# 300 /exc + constant bat-table
bat-table h# 10 + constant 'next-bat
\ /exc h# 18 + constant /dsi-footprint

\ On entry:
\ r2, r3, and lr have been saved. r2 points to this cpu's exception-area,

\ Low memory usage:
\    Firmware private area:
\        0:  save r3 and t1
\        4:  save r2
\        8:  save lr and t2
\        c:  save t0
\       10:  save cr
\    DSI vector:
\       300.. jump to dsi-handler
\       3x0:  bat-table (16 bytes)
\       3y0:  next-bat (1 byte)

\ Note:  next-bat should be cpu specific: 3yc ?

label bat-dsi-handler
   mfcr   r3
   stw    r3,h#10(r2)		\ Save CR

   \ Determine the fault type
   mfspr   r3,dsisr		\ SPR18
   rlwinm. r3,r3,0,1,1		\ Test bit 1
   0=  if			\ Not a translation fault
( Label )   begin but
      \ Restore registers and jump to unexpected exception handler
      lwz    r3,h#10(r2)
      mtcrf  h#ff,r3		\ Restore CR
      addi  r3,r0,h#300		\ Exception address
\ XXX we need to jump to the physical address of save-state
      save-state  b  *  	\ branch to exception handler
   then

   mfspr   r3,dar		\ Get fault address
   rlwinm  r3,r3,4,28,31	\ Convert high 4 bits to a table index
   lbz     r3,h#380(r3)		\ Translation entry in t2
   cmpi    0,0,r3,0
   <> until			\ Jump back to Label if no translation

   lwz    r3,h#08(r2)		\ Restore lr
   mtspr  lr,r3

   stw    t0,h#0c(r2)		\ Save t0 in the exception table area
   stw    t2,h#08(r2)		\ Save t2

   mfspr  t0,dar		\ Get fault address

   \ Index into translation table and get translation info
   rlwinm  t2,t0,4,28,31	\ Convert high 4 bits to a table index
   lbz     t2,h#380(t2)		\ Translation entry in t2

   \ Format Upper BAT entry
   rlwinm  t0,t0,0,0,3		\ Mask out lower bits, leaving page index
   ori     t0,t0,h#1ffe		\ 256M block size, supervisor mode

   \ Format Lower BAT entry
   rlwinm  r3,t2,24,0,3		\ Shift up physical block number
   rlwimi  r3,t2,3,25,28	\ Shift WIMG bits into place
   ori     r3,r3,2		\ Allow all accesses

   lbz     t2,h#37f(r0)		\ Select a BAT

   \ Replace BAT value
   \ On average, it takes more instructions to do an indexed jump
   \ than to do explicit compares for this number of cases.

   cmpi	0,0,t2,0  =  if
      sync  isync  mtspr dbat0u,t0   mtspr dbat0l,r3  sync  isync
      set    t2,1
   else

   cmpi	0,0,t2,1  =  if
      sync  isync  mtspr dbat1u,t0   mtspr dbat1l,r3  sync  isync
      set    t2,2
   else

[ifdef]  NTkludge
      \ Some earlier NT HALs have a bug that causes them to hang
      \ if the KSEG0 (virt 8000.0000 -> phys 0) mapping resides in
      \ IBAT3, so to be safe, we avoid using either IBAT3 or DBAT3.
      sync  isync  mtspr dbat2u,t0   mtspr dbat2l,r3  sync  isync
      set    t2,0
   then then
[else]
   cmpi	0,0,t2,2  =  if
      sync  isync  mtspr dbat2u,t0   mtspr dbat2l,r3  sync  isync
      set    t2,3
   else
      sync  isync  mtspr dbat3u,t0   mtspr dbat3l,r3  sync  isync
      set    t2,0
   then then then
[then]

   stb    t2,h#37f(r0)	\ Update BAT replacement pointer

   \ Restore registers
   lwz    t0,h#10(r2)
   mtcrf  h#ff,t0	\ Restore CR
   lwz    t0,h#0c(r2)	\ Restore t0
   lwz    r3,h#00(r2)	\ Restore r3
   lwz    t2,h#08(r2)	\ Restore t2
   lwz    r2,h#04(r2)	\ Restore r2

   \ Return from interrupt
   rfi
end-code

label bat-isi-handler
   mfcr   r3
   stw    r3,h#10(r2)		\ Save CR

   \ In violation of the PowerPC architecture definition, the 603 does
   \ not implement the translation fault bit for instruction accesses,
   \ so we assume that any 603 instruction fault is a translation fault.
   \ This is tolerable because instruction accesses to non-existent devices
   \ do not occur on purpose - probing to determine the presence of devices
   \ is done with data accesses.
   
\ However, the 603 ISI exception is front-ended by the ITLB miss handler,
\ in which we set the translation fault bit.

\   mfspr  r3,pvr
\   rlwinm r3,r3,16,16,31
\   cmpi   0,0,r3,3
\   0<>  if

   \ Determine the fault type
   mfspr   r3,srr1		\ Fault type is in SRR1 for I faults
   rlwinm. r3,r3,0,1,1		\ Test bit 1
   0=  if			\ Not a translation fault
( Label )   begin but
      \ Restore registers and jump to unexpected exception handler
      lwz    r3,h#10(r2)
      mtcrf  h#ff,r3		\ Restore CR
      addi  r3,r0,h#400		\ Exception address
      save-state  b  *  	\ branch to exception handler
   then
\   then

   mfspr   r3,srr0		\ Get fault address
   rlwinm  r3,r3,4,28,31	\ Convert high 4 bits to a table index
   lbz     r3,h#380(r3)		\ Translation entry in t2
   cmpi    0,0,r3,0
   <> until			\ Jump back to Label if no translation

   lwz    r3,h#08(r2)		\ Restore lr
   mtspr  lr,r3

   stw    t0,h#0c(r2)		\ Save t0 in the exception table area
   stw    t2,h#08(r2)		\ Save t2

   mfspr  t0,srr0		\ Get fault address

   \ Index into translation table and get translation info
   rlwinm  t2,t0,4,28,31	\ Convert high 4 bits to a table index
   lbz     t2,h#380(t2)		\ Translation entry in t2

   \ Format Upper BAT entry
   rlwinm  t0,t0,0,0,3		\ Mask out lower bits, leaving page index
   ori     t0,t0,h#1ffe		\ 256M block size, supervisor mode

   \ Format Lower BAT entry
   rlwinm  r3,t2,24,0,3		\ Shift up physical block number
   rlwimi  r3,t2,3,25,27	\ Shift WIM  bits into place, masking off G
   ori     r3,r3,2		\ Allow all accesses

   lbz     t2,h#37f(r0)		\ Select a BAT

   \ Replace BAT value
   \ On average, it takes more instructions to do an indexed jump
   \ than to do explicit compares for this number of cases.

   cmpi	0,0,t2,0  =  if
      sync  isync  mtspr ibat0u,t0   mtspr ibat0l,r3  sync  isync
      set    t2,1
   else

   cmpi	0,0,t2,1  =  if
      sync  isync  mtspr ibat1u,t0   mtspr ibat1l,r3  sync  isync
      set    t2,2
   else

   cmpi	0,0,t2,2  =  if
      sync  isync  mtspr ibat2u,t0   mtspr ibat2l,r3  sync  isync
      set    t2,3
   else
      sync  isync  mtspr ibat3u,t0   mtspr ibat3l,r3  sync  isync
      set    t2,0
   then then then

   stb    t2,h#37f(r0)	\ Update BAT replacement pointer

   \ Restore registers
   lwz    t0,h#10(r2)
   mtcrf  h#ff,t0	\ Restore CR
   lwz    t0,h#0c(r2)	\ Restore t0
   lwz    r3,h#00(r2)	\ Restore r3
   lwz    t2,h#08(r2)	\ Restore t2
   lwz    r2,h#04(r2)	\ Restore r2

   \ Return from interrupt
   rfi
end-code

label tlb-miss-template		\ 603-specific
   mfspr   r3,srr1
   set     r2,h#40000000	\ Translation fault bit
   rlwinm. r1,r3,0,13,13
   0<>  if			\ Itlb
      mtcrf  h#80,r3		\ Restore Condition Register
      or     r3,r3,r2		\ Set instruction translation fault bit
      mtspr  srr1,r3		\ .. in SRR1
   else
      mtcrf  h#80,r3		\ Restore Condition Register
      mtspr  dsisr,r2		\ Set data translation fault bit
      mfspr  r2,dmiss		\ Put the miss address
      mtspr  dar,r2		\ in the data address register
   then

   mfmsr  r3
   rlwinm r3,r3,0,15,13		\ Clear TGPR bit to reveal real registers
   mtmsr  r3
end-code
here tlb-miss-template - constant /miss

/miss la1+ to /rm-tlbmiss

: put-tlb-miss-entry  ( entry-vector target-vector -- )
   swap
   tlb-miss-template  /miss  bounds  ?do  ( target-vector entry-vector )
      i l@ over instruction!  la1+
   /l +loop                               ( target-vector entry-vector' )
   put-branch
;

code invalidate-tlbs  ( #entries -- )
   sync isync

   rlwinm tos,tos,12,0,19

   begin
      addic.  tos,tos,h#-1000
      tlbie   tos
   0= until
   
   tlbsync

   lwz    tos,0(sp)
   addi   sp,sp,1cell
c;

: install-bat-handler  ( -- )
   init-paged-mmu

   bat-dsi-handler  h# 300  put-exception
   bat-isi-handler  h# 400  put-exception

   software-tlb-miss?  if
      h# 1000  h# 400 put-tlb-miss-entry  \ Instruction fetch TLB miss
      h# 1100  h# 300 put-tlb-miss-entry  \ Data load TLB
      h# 1200  h# 300 put-tlb-miss-entry  \ Data store TLB
   else
   then

   configure-tlb  #tlb-lines invalidate-tlbs
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
