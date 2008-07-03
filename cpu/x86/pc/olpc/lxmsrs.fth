purpose: Table of MSR values to setup Geode LX processor on OLPC

hex
create lx-msr-init
\ Memsize-dependent MSRs are set in the early startup code

\ CPU
  msr: 0000.1100 00000100.00005051.  \ Branch tree messaging sync
  msr: 0000.1210 00000000.00000003.  \ Suspend on halt and pause
  msr: 0000.1900 00000000.02001131.  \ Pausedly 16 clocks, SUSP + TSC_SUSP
  msr: 0000.1920 00000000.0000000f.  \ Enable L2 cache
  msr: 0000.1930 00000000.00070303.  \ MSR_PMODE
  msr: 0000.1981 00000000.2814d352.  \ MSS_ARRAY_CTL0 - cache timings - value from PRS
  msr: 0000.1982 00000000.1068334d.  \ MSS_ARRAY_CTL1 - cache timings - value from PRS
  msr: 0000.1983 00000106.83104104.  \ MSS_ARRAY_CTL2 - cache timings - value from PRS
  msr: 0000.1a00 00000000.00000001.  \ Imprecise exceptions

\ northbridgeinit: GLIUS
\ \ 1000.0020   0  80000  2  >p2d-bm  msr,
\ msr: 1000.0020 20000000.000fff80.   \ 0 - 7.ffff low RAM Early startup

\ 1000.0022  gp-pci-base  4000  a  >p2d-bm msr,  \ GP  - local to GLIU0
\ 1000.0023  vp-pci-base  4000  4  >p2d-bm msr,  \ VP  - via GLIU1
\ 1000.0024 vip-pci-base  4000  4  >p2d-bm msr,  \ VIP - via GLIU1
\ 1000.0025 aes-pci-base  4000  4  >p2d-bm msr,  \ AES - via GLIU1

  msr: 1000.0022 a00000fe.000ffffc.   \ fe00.0000 - fe00.3fff GP
  msr: 1000.0023 400000fe.008ffffc.   \ fe00.8000 - fe00.bfff VP in GLIU1
  msr: 1000.0024 400000fe.00cffffc.   \ fe00.c000 - fe00.ffff VIP in GLIU1
  msr: 1000.0025 400000fe.010ffffc.   \ fe01.0000 - fe01.3fff security block in GLIU1

\ msr: 1000.0026 000000ff.fff00000.   \ BMO Unmapped - default (used for low mem in gxvga.fth)
\ msr: 1000.0027 000000ff.fff00000.   \ BMO Unmapped - default (used for low mem in gxvga.fth)

\ msr: 1000.0028 2000000e.fff00100.   \ Main memory from 1M to top, fbsize

\ Graphics
\ 1000.0029 fb-pci-base fb-size fb-offset  2  >p2d-range-offset  msr,  \ fd00.0000 - fdff.ffff mapped to f00.0000 Memsize dependent, fbsize dependent
\ msr: 1000.0029 20a7e0fd.ffffd000.   \ fd00.0000 - fdff.ffff mapped to f00.0000 Memsize dependent, fbsize dependent

\ 1000.002a dc-pci-base  4000 0  8  >p2d-range-offset  msr,
  msr: 1000.002a 801ffcfe.007fe004.   \ fe00.4000 - fe00.7fff mapped to 0 in DC space

\ msr: 1000.002b 00000000.000fffff.   \ Unmapped - default
\ msr: 1000.002c 00000000.00000000.   \ Unmapped - default (Swiss Cheese)

  msr: 1000.0080 00000000.00000003.   \ Coherency - route snoops to CPU
  msr: 1000.0082 80000000.00000000.   \ Arbitration
  msr: 1000.0083 00000000.0000ff00.   \ Disable SMIs
  msr: 1000.0084 00000000.0000ff00.   \ Disable Async errors

\ msr: 1000.00e0 000000ff.fff00000.   \ Unmapped - default
\ msr: 1000.00e1 000000ff.fff00000.   \ Unmapped - default
\ msr: 1000.00e2 000000ff.fff00000.   \ Unmapped - default
\ msr: 1000.00e3 00000000.00000000.   \ Unmapped - default (Swiss Cheese)

  msr: 1000.2002 0000001f.0000001f.   \ Disables SMIs
  msr: 1000.2004 00000000.00000005.   \ Clock gating

\ DMA incoming maps
\ 4000.0020  0 10.0000 2 >p2d-bm  msr, \ 0 - f.ffff low RAM, route to GLIU0
  msr: 4000.0020 20000000.000fff00.   \ 0 - f.ffff low RAM, route to GLIU0

\ 4000.0022  gp-pci-base  4000  2  >p2d-bm msr,  \ GP, route to GLIU0
\ 4000.0024  dc-pci-base  4000  2  >p2d-bm msr,  \ DC, route to GLIU0
\ 4000.0025  vp-pci-base  4000  4  >p2d-bm msr,  \ VP, route to VP in GLIU1
\ 4000.0026 vip-pci-base  4000  a  >p2d-bm msr,  \ VIP, route to VIP in GLIU1

  msr: 4000.0022 200000fe.000ffffc.   \ fe00.0000 - fe00.03ff GP, route to GLIU0
\ msr: 4000.0023 000000ff.fff00000.   \ Unmapped - default

  msr: 4000.0024 200000fe.004ffffc.   \ fe00.4000 - fe00.7fff DC, route to GLIU0
  msr: 4000.0025 400000fe.008ffffc.   \ fe00.8000 - fe00.bfff VP, route to VP in GLIU1
  msr: 4000.0026 a00000fe.00cffffc.   \ fe00.c000 - fe00.ffff VIP, route to VIP in GLIU1
\ msr: 4000.0027 000000ff.fff00000.   \ Unmapped - default
\ msr: 4000.0028 000000ff.fff00000.   \ Unmapped - default
\ msr: 4000.0029 000000ff.fff00000.   \ Unmapped - default

\ 4000.002a fb-pci-base  fb-size 2 >p2d-range msr,  \ frame buffer - route to GLIU0, fbsize
\ 4000.002b aes-pci-base    4000 c >p2d-range msr,  \ Security Block

  msr: 4000.002a 200000fd.ffffd000.   \ frame buffer - fd00.0000 .. fdff.ffff, route to GLIU0, fbsize
  msr: 4000.002b c00000fe.013fe010.   \ Security Block - fe01.0000 .. fe01.3fff

\ 4000.002c 10.0000 fb-offset over -  2 >p2d-range msr,  \ 10.0000 - sysram-top - Memsize dependent
\ msr: 4000.002c 20000007.7ff00100.   \ 10.0000 - 0f7f.ffff High RAM - Memsize dependent
\ msr: 4000.002d 00000000.000fffff.   \ Unmapped - default

  msr: 4000.0080 00000000.00000001.   \ Route coherency snoops from GLIU1 to GLIU0
  msr: 4000.0081 00000000.0000c77f.   \ Port active enable
  msr: 4000.0082 80000000.00000000.   \ Arbitration scheduling
  msr: 4000.0083 00000000.0000ffff.   \ Disable SMIs
  msr: 4000.0084 00000000.00000008.   \ Disable AERRs
\ msr: 4000.0085 00000000.00000104.   \ default
\ msr: 4000.0086 20311030.0100400a.   \ default

\ msr: 4000.00e0 20000000.3c0fffe0.   \ IOD_BM DC - VGA
\ msr: 4000.00e1 000000ff.fff00000.   \ Unmapped - default
  msr: 4000.00e3 60000000.033000f0.   \ Map reads and writes of Port F0 to GLCP, I think
  msr: 4000.2002 0000001f.0000001f.   \ Disables SMIs
  msr: 4000.2004 00000000.00000005.   \ Clock gating

\ GeodeLink Priority Table
  msr: 0000.2001 00000000.00000220.
  msr: 4c00.2001 00000000.00000001.
  msr: 5000.2001 00000000.00000027.
  msr: 5800.2001 00000000.00000013.
  msr: 8000.2001 00000000.00000320.

  msr: 0000.1700 00000000.00000400.  \ Evict clean lines - necessary for L2

\ Region config
\ msr: 0000.1808 25fff002.1077e000.  \ System RAM and ROM region configs - Memsize dependent
\ msr: 0000.180a 00000000.00000000.
  msr: 0000.1800 00004000.00004022.  \ Data memory - 4 outstanding write ser., evict
                                     \ INVD => WBINVD, serialize load misses.
  msr: 0000.180a 00000000.00000011.  \ Disable cache for table walks
  msr: 0000.180b 00000000.00000000.  \ Cache a0000-bffff
  msr: 0000.180c 00000000.00000000.  \ Cache c0000-dffff
  msr: 0000.180d 00000000.00000000.  \ Cache e0000-fffff
\ msr: 0000.180e 00000001.00000001.  \ SMM off - default
\ msr: 0000.180f 00000001.00000001.  \ DMM off - default

\ 0000.1810 fb-pci-base  fb-size 111 >rconf msr,  \ Video (write through), fbsize
\ 0000.1811 gp-pci-base     4000 101 >rconf msr,  \ GP registers non-cacheable
\ 0000.1812 dc-pci-base     4000 101 >rconf msr,  \ DC registers non-cacheable
\ 0000.1813 vp-pci-base     4000 101 >rconf msr,  \ VP registers non-cacheable
\ 0000.1814 vip-pci-base    4000 101 >rconf msr,  \ VIP registers non-cacheable
\ 0000.1815 aes-pci-base    4000 101 >rconf msr,  \ AES registers non-cacheable

  msr: 0000.1810 fdfff000.fd000111.  \ Video (write through), fbsize
  msr: 0000.1811 fe003000.fe000101.  \ GP registers non-cacheable
  msr: 0000.1812 fe007000.fe004101.  \ DC registers non-cacheable
  msr: 0000.1813 fe00b000.fe008101.  \ VP registers non-cacheable
  msr: 0000.1814 fe00f000.fe00c101.  \ VIP registers non-cacheable
  msr: 0000.1815 fe013000.fe010101.  \ AES registers non-cacheable

\ msr: 0000.1816 00000000.00000000.  \ Disabled - default
\ msr: 0000.1817 00000000.00000000.  \ Disabled - default

\ PCI
\ msr: 5000.2000 00000000.00105400.  \ RO
  msr: 5000.2001 00000000.00000017.  \ Priority 1, domain 7
  msr: 5000.2002 00000000.003f003f.  \ No SMIs
  msr: 5000.2003 00000000.00370037.  \ No ERRs
  msr: 5000.2004 00000000.00000015.  \ Clock gating for 3 clocks
  msr: 5000.2005 00000000.00000000.  \ Enable some PCI errors
  msr: 5000.2010 fff01140.001a021d.  \ PCI timings - LB has the latency timer at max
  msr: 5000.2011 04000300.00800f01.  \ GLPCI_ARB - LX page 581

\ I don't think we need to do anything special for the DOS hole from PCI
\ msr: 5000.2014 00000000.00f000ff.  \ Fixed region enables - f, b, and a
\ msr: 5000.2015 30303030.30303030.  \ Cache, prefetch, write combine a0000 - bffff
\ msr: 5000.2016 30303030.30303030.  \ Cache, prefetch, write combine c0000 - dffff
\ msr: 5000.2017 34343434.30303030.  \ Cache, prefetch, write combine e0000 - fffff, write protect f0000 - fffff

  msr: 5000.2018 000ff000.00000130.  \ Cache PCI DMA to low memory 0 .. fffff
\ msr: 5000.2019 0f7ff000.00100130.  \ Cache PCI DMA to high memory - Memsize dependent
\ msr: 5000.201a 4041f000.40400120.
\ msr: 5000.201a 00000000.00000000.  \ Off - default
  msr: 5000.201b 00000000.00000000.
  msr: 5000.201c 00000000.00000000.
  msr: 5000.201e 00000000.00000f00.  \ PCI function number for MSR accesses to VP port
  msr: 5000.201f 00000000.0000004b.
\ We don't need posted I/O writes to IDE, as we have no IDE

\ VIP
\ msr: 5400.2004 00000000.00000005.  \ Clock gating - default

\ AES
\ msr: 5800.2002 00000007.00000007.  \ SMI mask - default is all off
\ msr: 5800.2004 00000000.00000015.  \ Clock gating - default

\ chipsetinit(nb);

\ Set the prefetch policy for various devices
  msr: 5150.0001 00000000.0008f000.   \ AC97
  msr: 5140.0001 00000000.0000f000.   \ DIVIL

\  Set up Hardware Clock Gating
  msr: 5102.4004 00000000.00000004.  \ GLIU_SB_GLD_MSR_PM
  msr: 5100.0004 00000000.00000005.  \ GLPCI_SB_GLD_MSR_PM
  msr: 5170.0004 00000000.00000004.  \ GLCP_SB_GLD_MSR_PM
\ SMBus clock gating errata (PBZ 2226 & SiBZ 3977)
  msr: 5140.0004 00000000.50554111.  \ DIVIL
  msr: 5130.0004 00000000.00000005.  \ ATA
  msr: 5150.0004 00000000.00000005.  \ AC97

\ setup_gx2();

\ Graphics init
  msr: a000.2001 00000000.0fde0000.  \ CBASE field is FB addr + 14M, fbsize
  msr: a000.2002 00000001.00000001.  \ Disable GP SMI
  msr: a000.2003 00000003.00000003.  \ Disable GP ERR
  msr: a000.2004 00000000.00000001.  \ Clock gating
  msr: 8000.2001 00000000.00000720.  \ VG config (priority)
  msr: 8000.2002 1001ffff.1001ffff.  \ Disable SMIs
  msr: 8000.2003 0000003f.0000003f.  \ Disable ERRs
\ msr: 8000.2004 00000000.00000000.  \ Clock gating - default
\ msr: 8000.2004 00000000.00000055.  \ Clock gating
  msr: 8000.2011 00000000.00000042.  \ VG SPARE - VG fetch state machine hardware fix off
  msr: 8000.2012 00000000.00000302.  \ VG DELAY

\ msr: 4c00.0015 00000037.00000001.  \ MCP DOTPLL reset; unnecessary because of later video init

\ More GLCP stuff
  msr: 4c00.000f f2f100ff.56960444.  \ I/O buffer delay controls - LB uses 82f1.00aa.5696.0444
           \ Our value has lower drive for mem signals and more delay for BA, MA, CKE, CS, RAS, CAS, WE

  msr: 4c00.0016 00000000.00000000.  \ Turn off debug clock - LB has 2 (default, GLIU1 to debug logic)
\ msr: 4c00.001e 00000000.0000603c.  \ Processor throttle off delay - LB values
  msr: 4c00.2004 00000000.00000015.  \ Hardware clock gating for everything (Insyde uses 0x14)

  msr: 5000.2014 00000000.00ffffff.  \ Enables PCI access to low mem

[ifdef] lx-devel
  msr: 4800.2001 00000000.00040c00.  \ Set VP reference clock divider to 0xc, not 0xe, CRT mode
[else]
\  msr: 4800.2001 00000000.00040c08.  \ Set VP reference clock divider to 0xc, not 0xe, TFT mode
  msr: 4800.2001 00000000.00048c08.  \ Set VP reference clock divider to 0xc, not 0xe, TFT + CRT mode
[then]
  \ The datasheet says the MSR number is 4800.0011, but that is wrong
  msr: 4800.2011 0000003f.dfffffff.  \ Set TFT pads to registered

\ 5536 region configs
  msr: 5100.0002 00000000.007f0000.  \ Disable SMIs
  msr: 5101.0002 0000000f.0000000f.  \ Disable SMIs

\ msr: 5100.0010 44000020.00020013.  \ PCI timings - already set

\ XXX convert to >rconf form - need an IO version
\  msr: 5100.0020 018b4001.018b0001.  \ Region configs
  msr: 5100.0020 06004001.06000001.  \ Region configs
  msr: 5100.0021 010fc001.01000001.  \ GPIO
  msr: 5100.0022 0183c001.01800001.  \ MFGPT
  msr: 5100.0023 0189c001.01880001.  \ IRQ mapper
  msr: 5100.0024 0147c001.01400001.  \ PMS
  msr: 5100.0025 0187c001.01840001.  \ ACPI
  msr: 5100.0026 014fc001.01480001.  \ AC97 128 bytes (0x80)

\ 5100.0027 ohci-pci-base  1000  1 >rconf msr,  \ OHCI
\ 5100.0028 ehci-pci-base  1000  1 >rconf msr,  \ EHCI
\ 5100.0029 uoc-pci-base   1000  1 >rconf msr,  \ UOC

  msr: 5100.0027 fe01a000.fe01a001.  \ OHCI
  msr: 5100.0028 fe01b000.fe01b001.  \ EHCI
  msr: 5100.0029 efc00000.efc00001.  \ UOC

  msr: 5100.002b 018ac001.018a0001.  \ IDE bus master
  msr: 5100.002f 00084001.00084009.  \ Port 84 (what??)

\ 5101.0020 uoc-pci-base   1000 4 >p2d-bm msr,  \ P2D_BM0 UOC
\ 5101.0023 ohci-pci-base  1000 5 >p2d-bm msr,  \ P2D_BMK OHCI
\ 5101.0024 ehci-pci-base  1000 4 >p2d-bm msr,  \ P2D_BMK EHCI

  msr: 5101.0020 400000ef.c00fffff.  \ P2D_BM0 UOC
  msr: 5101.0023 500000fe.01afffff.  \ P2D_BMK Descriptor 0 OHCI
  msr: 5101.0024 400000fe.01bfffff.  \ P2D_BMK Descriptor 1 EHCI

  msr: 5101.0083 00000000.0000ff00.  \ Disable SMIs
  msr: 5101.00e0 60000000.1f0ffff8.  \ IOD_BM Descriptor 0 ATA IO address
  msr: 5101.00e1 a0000001.480fff80.  \ IOD_BM Descriptor 1 AC97
  msr: 5101.00e2 80000001.400fff80.  \ IOD_BM Descriptor 2 PMS
  msr: 5101.00e3 80000001.840fffe0.  \ IOD_BM Descriptor 3 ACPI
\ msr: 5101.00e4 00000001.858ffff8.  \ IOD_BM Descriptor 4 Don't carve ACPI into partially-emulated ranges
  msr: 5101.00e5 60000001.8a0ffff0.  \ IOD_BM Descriptor 5 bus master IDE
\ msr: 5101.00eb 00000000.f0301850.  \ IOD_SC Descriptor 1 Don't carve ACPI into partially-emulated ranges

  msr: 5140.0002 0000fbff.00000000.  \ Disable SMIs

  msr: 5140.0008 0000f001.00001880.  \ LBAR_IRQ
\ 5140.0009 ohci-pci-base 1000 1 >usb-kel msr,  \ LBAR_KEL (USB)
  msr: 5140.0009 fffff001.fe01a000.  \ LBAR_KEL (USB)
  msr: 5140.000b     f001.000018b0.  \ LBAR_SMB
  msr: 5140.000c     f001.00001000.  \ LBAR_GPIO
  msr: 5140.000d     f001.00001800.  \ LBAR_MFGPT
  msr: 5140.000e     f001.00001840.  \ LBAR_ACPI
  msr: 5140.000f     f001.00001400.  \ LBAR_PMS
\ msr: 5140.0010 fffff007.20000000.  \ LBAR_FLSH0 no 5536 NAND FLASH on any LX platform
\ msr: 5140.0011  \ LBAR_FLSH1
\ msr: 5140.0012  \ LBAR_FLSH2
\ msr: 5140.0013  \ LBAR_FLSH3
\ msr: 5140.0014 00000000.80070003.  \ LEG_IO already set in romreset
  msr: 5140.0015 00000000.00000f7d.  \ BALL_OPTS - IDE pins are IDE, not NAND
\ msr: 5140.001b 00000000.07770777.  \ NANDF_DATA - default
\ msr: 5140.001c 00000000.00000777.  \ NANDF_CTL - default
  msr: 5140.001f 00000000.00000011.  \ KEL_CTRL
  msr: 5140.0020 00000000.00350a00.  \ IRQM_YLOW PM SCI OR, AC97, RTC Alarm, USB, -, SW IRQ
  msr: 5140.0021 00000000.04000000.  \ IRQM_YHIGH UART1
  msr: 5140.0022 00000000.00002222.  \ IRQM_ZLOW MFGPTs
  msr: 5140.0023 00000000.33b006e0.  \ IRQM_ZHIGH SCI-3, LID-3, CaFe-11, DCON-6, CPU-14
  msr: 5140.0025 00000000.00001002.  \ IRQM_LPC Enable mouse(12) and kbd (1)
\ msr: 5140.0028 00000000.00000000.  \ MFGPT_IRQ off - default
\ msr: 5140.0040 00000000.00000000.  \ DMA_MAP - default
\ msr: 5140.004e 00000000.ef2500c0.  \ LPC_SIRQ
\ msr: 5140.004e 00000000.effd0080.  \ LPC_SIRQ
  msr: 5140.004e 00000000.effd00c0.  \ LPC_SIRQ - Active high bit 12 (mouse) and 2 (kbd), Enable, Quiet, 17 frames
  msr: 5140.0055 00000000.0000003d.  \ RTC alarm day (offset into CMOS RAM)
  msr: 5140.0056 00000000.0000003e.  \ RTC alarm month (offset into CMOS RAM)
  msr: 5140.0057 00000000.00000032.  \ RTC century (offset into CMOS RAM)

\ USB host controller

  msr: 5120.0001 0000000b.00000000.  \ USB_GLD_MSR_CONFIG - 5536 page 262

\ 5120.0008 ohci-pci-base  e msr,    \ USB OHC Base Address - 5536 page 266
\ 5120.0009 ehci-pci-base  e msr,    \ USB EHC Base Address - 5536 page 266 FLADJ set
\ 5120.000b uoc-pci-base   2 msr,    \ USB UOC Base Address - 5536 page 266

  msr: 5120.0008 0000000e.fe01a000.  \ USB OHC Base Address - 5536 page 266
  msr: 5120.0009 0000200e.fe01b000.  \ USB EHC Base Address - 5536 page 266 FLADJ set
  msr: 5120.000b 00000002.efc00000.  \ USB UOC Base Address - 5536 page 266

\ Clear possible spurious USB Short Serial detect bit per 5536 erratum 57
  msr: 5120.0015 00000010.00000000.  \ USB_GLD_MSR_DIAG

here lx-msr-init - constant /lx-msr-init
