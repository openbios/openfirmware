 \ enable_mainboard_devices()
\  41 8f4f config-wb   \ Enable P2P Bridge Header for External PCI Bus (coreboot value)
\  43 8f4f config-wb   \ As above, plus support extended PCIe config space
    1 8f4f config-wb   \ Disable P2P bridge

\  4f6 config-rb   \ Get Northbridge revision ... don't need it because the
                   \ init table contains no revision-specific entries

 \ via_pci_inittable(NBrevision,mNbStage1InitTbl)

   \ Enable extended config space for PCIe
   0 5 devfunc  \ NB_APIC
   61 ff 0e mreg  \ Set Exxxxxxx as PCIe MMIO config range
   60 f4 13 mreg  \ Support extended cfg address of PCIe (preserve 28 bits) (coreboot used vx800 bit resv in vx855)
   end-table

   0 2 devfunc  \ HOST CPU CTL
   50 1f 08 mreg  \ Request phase ctrl: Dynamic Defer Snoop Stall Count = 8
   51 ff 78 mreg  \ CPU I/F Ctrl-1: Disable Fast DRDY and RAW (coreboot uses 7c)
\ Try the following value !!
\  51 ff f8 mreg  \ CPU I/F Ctrl-1: Enable Fast DRDY and RAW (coreboot uses 7c) 
   52 cb cb mreg  \ CPU I/F Ctrl-2: Enable all for performance
   53 ff 44 mreg  \ Arbitration: Host/Master Occupancy timer = 4*4 HCLK
   54 1e 1c mreg  \ Misc Ctrl: Enable 8QW burst Mem Access

   55 06 04 mreg  \ Miscellaneous Control 2
   56 f7 63 mreg  \ Write Policy 1
   5d ff a2 mreg  \ Write Policy
   5e ff 88 mreg  \ Bandwidth Timer
   5f 46 46 mreg  \ CPU Misc Ctrl

[ifdef] xo-board
   90 03 03 mreg  \ 5T faster Host to DRAM cycles
[then]
   96 0b 0a mreg  \ Write Policy
   98 c1 41 mreg  \ Bandwidth Timer
   99 0e 06 mreg  \ CPU Misc Ctrl
   97 ff 00 mreg  \ APIC Related Control
   end-table
