purpose: PCI physical address mapping to root node
copyright: Copyright 1994-2001 FirmWorks  All Rights Reserved

hex

headerless

\ map-pci-phys creates a virtual mapping for the PCI physical address range
\ "paddr io? size", returning its virtual address "vaddr".  It does so by
\ first translating the PCI physical base address "paddr io?" to the
\ corresponding physical address in the parent node's address space (which
\ is often the primary system bus address space, but in this case is the
\ VL bus address space), and then calling the parent's "map-in" method.
\ "io?" is false for PCI memory space, true for PCI I/O space.

: map-pci-phys  ( paddr io? phys.hi size -- vaddr )
   -rot 2drop  " map-in" $call-parent
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

