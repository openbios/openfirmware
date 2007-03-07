\ See license at end of file
purpose: PCI physical address mapping to root node

headerless

\ map-pci-phys creates a virtual mapping for the PCI physical address range
\ "paddr io? size", returning its virtual address "vaddr".  It does so by
\ first translating the PCI physical base address "paddr io?" to the
\ corresponding physical address in the parent node's address space (which
\ in this case is the primary system bus address space), and then calling
\ the parent's "map-in" method.  We have a bit of a problem here in that
\ the root node is bogus - it doesn't recognize I/O space - so we do that
\ explicitly here.
\ "io?" is false for PCI memory space, true for PCI I/O space.

\ We use the top 64K of address space to mean I/O space.
\ The "rX@/!" words understand that and use I/O cycles for such addresses

: map-pci-phys  ( paddr io? phys.hi size -- vaddr )
   nip swap  if                      ( paddr size )
      \ We use the top 64K of address space to mean I/O space.
      \ The "rX@/!" words understand that and use I/O cycles
      \ for such addresses
      drop  h# ffff.0000 or          ( io-vaddr )
   else                              ( paddr size )
      " map-in" $call-parent         ( mem-vaddr )
   then                              ( vaddr )
;      

\ >pci-devaddr translates the DMA address "parent-devaddr", which is in the
\ parent node's physical address space, to the corresponding DMA address
\ "pci-devaddr" in the PCI physical address space (in PCI memory space; DMA
\ to PCI I/O space is not possible).

: >pci-devaddr  ( parent-devaddr -- pci-devaddr )  h# 0  +  ;

\ pci-devaddr> translates the DMA address "pci-devaddr", which is in the
\ PCI physical address space (in PCI memory space; DMA to PCI I/O space is
\ not possible), to the corresponding DMA address "parent-devaddr" in the
\ parent node's physical address space.

: pci-devaddr>  ( pci-devaddr -- parent-devaddr )  h# 0  -  ;
headers
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
