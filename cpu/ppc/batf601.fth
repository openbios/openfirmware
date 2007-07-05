purpose: Block address translation (BAT) fault handler
\ See license at end of file

\ This handler for the DSI interrupt treats the BAT registers
\ as a 4-entry software-filled TLB.  4 BAT registers are not
\ enough to hold all of the translations that the firmware and
\ the client program might need, so we use the BATs as a translation
\ cache.  When a translation fault occurs, we pick a BAT register
\ and change its value to translate the address at which the fault
\ occurred.

\ The 601 BAT registers are not compliant with the PowerPC architecture.
\ The locations of some fields are different, and each 601 BAT can only
\ map 8 MBytes, as opposed to 256 MBytes for PPC BATs.  In order to
\ minimize memory usage, and to keep the same mapping granularity
\ between the 601 and PPC, we allow mapping only at 256 MByte granularity,
\ simulating that granularity in software in this implementation by
\ copying logical address bits 4-8 to the physical address.

\ This allows us to make the mapping table quite small, so it will
\ fit nicely in otherwise-unused space in the trap vector.

\ Each table entry uses 8 bits - 4 for the physical block number
\ and 4 for the WIMG bits - so we use 8-bit table entries.
\ The other BAT register bits are either fixed values or can be
\ derived from the logical address.

\ For 601, the BAT registers do not support the "G" bit, so we mask it out.

\ We use a round-robin replacement policy.

\ Low memory usage:
\    Firmware private area:
\        e0:  save r3 and t1
\        e4:  save lr and t2
\        e8:  save t0
\    DSI vector:
\       300.. jump to dsi-handler
\       37f:  next-bat (1 byte)
\       380:  bat-table (16 bytes)

headerless

label bat-fault-handler-601
   \ We assume that t0 has been saved at location f8 and now contains
   \ the fault address.

   lwz    r3,h#e4(r0)		\ Restore lr
   mtspr  lr,r3
   lwz    r3,h#e0(r0)		\ Restore r3

   stw    t1,h#e0(r0)
   stw    t2,h#e4(r0)
   mfcr   t2
   stw    t2,h#ec(r0)		\ Save CR

\ [ifdef] notyet
\    \ Determine the fault type
\    mfspr  t1,dsisr		\ SPR18
\    add.   t1,t1,t1		\ Test bit 1 by shifting it to the sign bit
\    0>=  if			\ Not a translation fault
\       \ Restore registers and jump to unexpected exception handler
\    then
\ [then]      

   \ Fault address is in t0

   \ Index into translation table and get translation info
   rlwinm  t2,t0,4,28,31	\ Convert high 4 bits to a table index
   lbz     t2,h#380(t2)		\ Translation entry in t2

   \ Format lower BAT entry
   rlwinm  t1,t2,24,0,3		\ Shift up physical block number      
   rlwimi  t1,t0,0,4,8		\ Merge in bits 4-8 of virtual address
   ori     t1,t1,h#7f		\ valid (40 bit) and 8 MByte size (3f bits)

   \ Format upper BAT entry

   rlwinm  t0,t0,0,0,8		\ Mask out lower bits, leaving page index
   rlwimi  t0,t2,3,25,27	\ Shift WIMG bits into place, masking out G
   ori     t0,t0,2		\ Allow all accesses

   lbz     t2,h#37f(r0)		\ Select a BAT

   \ Replace BAT value
   \ On average, it takes more instructions to do an indexed jump
   \ than to do explicit compares for this number of cases.

   cmpi	0,0,t2,0
   =  if
      sync  isync
      mtspr  ibat0u,t0
      mtspr  ibat0l,t1
      sync  isync
      set    t2,1
   else

   cmpi	0,0,t2,1
   =  if
      sync  isync
      mtspr  ibat1u,t0
      mtspr  ibat1l,t1
      sync  isync
      set    t2,2
   else

   cmpi	0,0,t2,2
   =  if
      sync  isync
      mtspr  ibat2u,t0
      mtspr  ibat2l,t1
      sync  isync
      set    t2,3
   else

      sync  isync
      mtspr  ibat3u,t0
      mtspr  ibat3l,t1
      sync  isync
      set    t2,0
   then then then

   stb    t2,h#37f(r0)	\ Update BAT replacement pointer


   \ Restore registers
   lwz    t0,h#ec(r0)
   mtcrf  h#ff,t0	\ Restore CR
   lwz    t0,h#e8(r0)	\ Restore t0
   lwz    t1,h#e0(r0)	\ Restore t1
   lwz    t2,h#e4(r0	\ Restore t2

   \ Return from interrupt
   rfi
end-code

label bat-dsi-handler-601
   stw    t0,h#e8(r0)		\ Save t0 in the exception table area
   mfspr  t0,dar		\ Get fault address
   bat-fault-handler-601 again	\ Jump to common code
end-code

label bat-isi-handler-601
   stw    t0,h#e8(r0)		\ Save t0 in the exception table area
   mfspr  t0,srr0		\ Get fault address
   bat-fault-handler-601 again	\ Jump to common code
end-code

: install-bat-handler-601  ( -- )
   init-paged-mmu

   bat-dsi-handler-601  h# 300  put-exception
   bat-isi-handler-601  h# 400  put-exception
;
warning @ warning off
: install-bat-handler  ( -- )
   601?  if  install-bat-handler-601 exit  then
   install-bat-handler
;
warning !

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
