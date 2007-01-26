0 [if]



	register "irqmap" = "0xaa5b"
	register "setupflash" = "0"
	device apic_cluster 0 on
		chip cpu/amd/model_gx2
			device apic 0 on end
  	device pci_domain 0 on 
    		device pci 1.0 on end
		device pci 1.1 on end
      		chip southbridge/amd/cs5536
		# 0x51400025 (IRQ Mapper LPC Mask)= 0x00001002
		# IRQ 12 and 1 unmasked,  Keyboard and Mouse IRQs. OK
		# 0x5140004E (LPC Serial IRQ Control) = 0xEFFD0080.
		# Frame Pulse Width = 4clocks
		# IRQ Data Frames = 17Frames
		# SIRQ Mode = continous , It would be better if the EC could operate in
		# Active(Quiet) mode. Save power....
		# SIRQ Enable = Enabled
		# Invert mask = IRQ 12 and 1 are active high. Keyboard and Mouse IRQs. OK 
			register "lpc_irq" = "0x00001002"
			register "lpc_serirq_enable" = "0xEFFD0080"
 			register "enable_gpio0_inta" = "0"
			register "enable_ide_nand_flash" = "1"
			register "enable_uarta" = "1"
			register "enable_USBP4_host" = "1"
			register "audio_irq" = "5"
			register "usbf4_irq" = "10"
			register "usbf5_irq" = "10"
			register "usbf6_irq" = "0"
			register "usbf7_irq" = "0"
        		device pci d.0 on end	# Realtek 8139 LAN
        		device pci f.0 on end	# ISA Bridge
        		device pci f.2 on end	# IDE Controller
        		device pci f.3 on end 	# Audio
        		device pci f.4 on end	# OHCI
			device pci f.5 on end	# EHCI
			register "unwanted_vpci[0]" = "0x80007E00"	# USB/UDC
			register "unwanted_vpci[1]" = "0x80007F00"	# USB/OTG
			register "unwanted_vpci[2]" = "0"	# End of list has a zero
[then]

[ifdef] later
: enable-ide-nand-flash  ( -- )
   h# fffff007.20000000. h# 5140.0010 wrmsr  \ LBAR, enable NAND at 2000.0000
   1  h# 5140.0015 msr-bitclr                \ Clear IDE_MODE
   h#        0.0010.0010 h# 5140.001b wrmsr  \ Set timings
   h#        0.0000.0010 h# 5140.001c wrmsr  \ Set timings
;
[then]

\ We don't need this because OFW already does it
0 [if]
: setup-i8259  ( -- )
   h# 11 h# 20 pc!		\ initialization sequence to 8259A-1*/
   h# 11 h# A0 pc!		\ and to 8259A-2
   h# 20 h# 21 pc!		\ start of hardware int's (0x20)
   h# 28 h# A1 pc!		\ start of hardware int's 2 (0x28)
   h# 04 h# 21 pc!		\ 8259-1 is master
   h# 02 h# A1 pc!		\ 8259-2 is slave
   h# 01 h# 21 pc!		\ 8086 mode for both
   h# 01 h# A1 pc!		
   h# FF h# A1 pc!		\ mask off all interrupts for now
   h# FB h# 21 pc!		\ mask all irq's but irq2 which is cascaded
;
[then]

[ifdef] later
: set-pci-irq  ( irq function dev bus -- )
   h# 10000 * swap h# 800 * +  swap h# 100 *  +  h# 3c +  config-b!
;

: chipsetinit
   \ Mainboard section (Nothing to do)

   \ Northbridge section


   \ Southbridge (5536) section
   \ setup-i8259    \ Unnecessary; OFW already does it

   \ Use quiet SIRQ mode if the EC supports it
   h# 0.effd0080.  a-test?  0= if  40 bitset  then  MDD_LPC_SIRQ msr-set
   h# 0.00001002 MDD_IRQM_LPC msr-set

   \ Maybe turn this off for real systems
   h# 0400.0000 MDD_IRQM_YHIGH msr-bitset  \ Enable IRQ for COM1

   a-test?  if  enable-ide-nand-flash  then

   \ Assign IRQs to PCI devices
   \ IRQ fun dev  bus
   d# 11  1  h# 1  0  set-pci-irq   \ display
   d# 11  1  h# f  0  set-pci-irq   \ 5536 NAND
   d# 11  2  h# f  0  set-pci-irq   \ 5536 NAND?
   d#  5  3  h# f  0  set-pci-irq   \ sound
   d# 10  4  h# f  0  set-pci-irq   \ USB1.1
   d# 10  5  h# f  0  set-pci-irq   \ USB2

   a-test?  0=  if
      d# 11  0  h# c  0  set-pci-irq   \ CaFe
      d# 11  1  h# c  0  set-pci-irq   \ CaFe
      d# 11  2  h# c  0  set-pci-irq   \ CaFe
   then

   \ Enable USBP4_host
   h# efc00000 h# 7f10 config-l!  \ Set BAR
   \ Might be okay to just write "2" instead of R/M/W
   h# efc00004 l@  3 invert and  2 or  h# efc00000 l!  \ Enable memory access

   \ disable unwanted virtual PCI devices
   h# deadbeef h# 7e7c config-l! \ Disable USB/UDC
   h# deadbeef h# 7f7c config-l! \ Disable USB/OTG
;
[then]

\ D northbridgeinit();
\ D cpubug();	

: msr:  ( -- )
   push-hex
   safe-parse-word $dnumber? 1 <> abort" MSR number must be single precision"
   ,
   safe-parse-word $dnumber? 2 <> abort" MSR value must be double precision"
   , ,
   pop-base
;

create msr-init
\ northbridgeinit: GLIUS
msr: 1000.0020 20000000.000fff80.   \ 0 - 7.ffff low RAM
msr: 1000.0021 20000000.080fffe0.   \ 8.0000 - 9.ffff low RAM
msr: 1000.002c 20000000.f0000003.   \ f.0000 - f.ffff Read only to expansion ROM
msr: 1000.0028 20000007.7df00100.   \ 10.000 - 077d.f000 High RAM - Memsize dependent

\ SMM memory (fbe) (40. is SMM_OFFSET)
msr: 1000.0026 2c7be040.400fffe0.   \ 4040.0000 - 405f.ffff relocated to 7fe.0000 - Memsize dependent

\ Graphics
msr: 1000.0022 a00000fe.000ffffc.   \ fe00.0000 - fe00.3fff GP
msr: 1000.0023 c00000fe.008ffffc.   \ fe00.8000 - fe00.bfff VP
msr: 1000.0024 80000000.0a0fffe0.   \ 000a.0000 - 000b.ffff DC
msr: 1000.0029 20a7e0fd.7fffd000.   \ fd00.0000 - fd7f.ffff mapped to 77e.0000 Memsize dependent (Frame Buffer)
msr: 1000.002a 801ffcfe.007fe004.   \ fe00.4000 - fe00.7fff mapped to 0 in DC space

msr: 1000.0025 000000ff.fff00000.   \ Unmapped
msr: 1000.0027 000000ff.fff00000.   \ Unmapped
msr: 1000.002b 00000000.000fffff.   \ Unmapped

msr: 1000.0080 00000000.00000003.   \ Coherency
msr: 1000.00e0 80000000.3c0ffff0.   \ IOD_BM DC
msr: 1000.00e1 80000000.3d0ffff0.   \ IOD_BM DC (why 2)
msr: 1000.00e3 00000000.f030ac18.   \ IOD_SC

\ DMA incoming maps
msr: 4000.0020 20000000.000fff80.   \ 0 - 7.ffff low RAM
msr: 4000.0021 20000000.080fffe0.   \ 8.0000 - 9.ffff low RAM
msr: 4000.002d 20000000.f0000003.   \ expansion ROM
msr: 4000.0029 20000007.7df00100.   \ 10.0000 - 0f7d.f000 High RAM - Memsize dependent
msr: 4000.0023 20000040.400fffe0.   \ 4040.0000 - 405f.ffff SMM memory
msr: 4000.0024 200000fe.004ffffc.   \ fe00.4000 - fe00.7fff DC
msr: 4000.00e3 60000000.033000f0.   \ CPU - 0003.3000 don't know what this is
msr: 4000.0080 00000000.00000001.   \ Route coherency snoops from GLIU1 to GLIU0
msr: 4000.0022 200000fe.000ffffc.   \ fe00.0000 - fe00.03ff GP
msr: 4000.0025 200000fe.008ffffc.   \ fe00.8000 - fe00.bfff VP
msr: 4000.0026 20000000.0a0fffe0.   \ 000a.0000 - 000b.ffff DC in low mem
msr: 4000.002d 20000000.f0000003.   \ 000f.0000 - 000f.ffff expansion ROM

msr: 4000.0027 000000ff.fff00000.   \ Unmapped
msr: 4000.0028 000000ff.fff00000.   \ Unmapped

msr: 4000.00e0 20000000.3c0fffe0.   \ IOD_BM DC

\ GeodeLink Priority Table
msr: 00002001 00000000.00000220.
msr: c0002001 00000000.00040f80.
msr: 80002001 00000000.00000320.
msr: a0002001 00000000.00000010.
msr: 50002001 00000000.00000027.
msr: 4c002001 00000000.00000001.
msr: 54002001 00000000.00000000.
msr: 58002001 00000000.00000000.

\ Region config
msr: 1808 25fff002.1077e000.  \ Memsize dependent
\ msr: 180a 00000000.00000000.
msr: 180a 00000000.00000011.  \ Disable cache for table walks
msr: 1800 00002000.00000022.
msr: 1810 fd7ff000.fd000111.  \ Video (write through)
msr: 1811 fe003000.fe000101.  \ GP
msr: 1812 fe007000.fe004101.  \ DC
msr: 1813 fe00b000.fe008101.  \ VP

\ PCI
msr: 50002000 00000000.00105001.
msr: 50002001 00000000.00000027.
msr: 50002004 00000000.00000015.
msr: 50002005 00000000.00000000. \ Enable some PCI errors
msr: 50002010 fff030f8.001a0215.
msr: 50002011 00000300.00000100.
msr: 50002014 00000000.00f000ff.
msr: 50002015 35353535.35353535.
msr: 50002016 35353535.35353535.
msr: 50002017 35353535.35353535.
msr: 50002018 0009f000.00000130.
msr: 50002019 077df000.00100130.  \ Memsize dependent
msr: 5000201a 4041f000.40400120.
msr: 5000201b 00000000.00000000.
msr: 5000201c 00000000.00000000.
msr: 5000201e 00000000.00000f00.
msr: 5000201f 00000000.0000006b.

\ clockgating
msr: 10002004 00000000.00000005.
msr: 20002004 00000000.00000003.  \ early setup uses 0, eng1398 changes to 3
msr: 40002004 00000000.00000005.
msr: 80002004 00000000.00000000.
msr: a0002004 00000000.00000001.
msr: c0002004 00000000.00000155.
msr: 4c002004 00000000.00000005.  ( 15 GLCP_GLD_MSR_PM )
msr: 50002004 00000000.00000015.
msr: 54002004 00000000.00000000.

\ cpu/amd/model_gx2/cpubug.c

\ pcideadlock();

\ CPU_DM_CONFIG0 - 1800 - already set correctly above
\ Interlock instruction fetches to WS regions with data accesses
msr: 00001700 00000000.00100000.

\ We could probably set all these to 0 (cacheable) because we
\ don't use them for the traditional DOS purposes.
\ 0000180b 21212121.21212121.  \ This is what the code implies
msr: 0000180b 01010101.01010101. \ This is what LB actually has
msr: 0000180c 21212121.21212121.
msr: 0000180d 21212121.21212121.

\ eng1398();
\ The result of this is already included in clockgating above

\ eng2900();
msr: 00003003 0080a13d.00000000.  \ clear 800 bit in high word

\ swapsif thing - don't do this stuff for use with FS2
msr: 4c00.005f 00000000.00000000. \ Disable enable_actions in DIAGCTL while setting up GLCP
msr: 4c00.0016 00000000.00000000. \ Changing DBGCLKCTL register to GeodeLink
msr: 4c00.0016 00000000.00000002. \ Changing DBGCLKCTL register to GeodeLink
msr: 1000.2005 00000000.80338041. \ Send mb0 port 3 requests to upper GeodeLink diag bits
msr: 4c00.0045 5ad68000.00000000. \ set5m watches request ready from mb0 to CPU (snoop)
msr: 4c00.0044 00000000.00000140. \ SET4M will be high when state is idle (XSTATE=11)
msr: 4c00.004c 00002000.00000000. \ SET5n to watch for processor stalled state
\ Writing action number 13: XSTATE=0 to occur when CPU is snooped unless we're stalled
msr: 4c00.0075 00000000.00400000.
msr: 4c00.0073 00000000.00030000. \ Writing action number 11: inc XSTATE every GeodeLink clock unless we're idle
msr: 4c00.006d 00000000.00430000. \ Writing action number 5: STALL_CPU_PIPE when exitting idle state or not in idle state
msr: 4c00.005f 00000000.80004000. \ Writing DIAGCTL Register to enable the stall action and to let set5m watch the upper GeodeLink diag bits.
\ End swapsif thing

\ bug118339();
msr: 4c00.005f 00000000.00000000. \ Disable enable_actions in DIAGCTL while setting up GLCP
msr: 4c00.0042 596b8000.00000a00. \ SET2M fires if VG pri is odd (3, not 2) and Ystate=0
msr: 4c00.0043 596b8040.00000000. \ SET3M fires if MBUS changed and VG pri is odd
msr: 1000.2005 00000000.80338041. \ Put VG request data on lower diag bus
msr: 4c00.0074 00000000.0000c000. \ Increment Y state if SET3M if true
msr: 4c00.0020 0000d863.20002000. \ Set up MBUS action to PRI=3 read of MBIU
msr: 4c00.0071 00000000.00000c00. \ Trigger MBUS action if VG=pri3 and Y=0, this blocks most PCI
msr: 4c00.005f 00000000.80004000. \ Writing DIAGCTL

\ Already set above, but to wrong value
msr: 4c00.0042 596b8008.00000a00. \ enable FS2 even when BTB and VGTEAR SWAPSiFs are enabled

\ bug784();  Put "Geode by NSC" in the ID
msr: 0000.3006 646f6547.80000006.
msr: 0000.3007 79622065.43534e20.
msr: 0000.3008 00000000.00000552.  \ Supposed to be same as msr 3002
msr: 0000.3009 c0c0a13d.00000000.

\ bug118253();
\ Already done above
\ 5000.201f 00000000.0000006b.  \ Disable GLPCI PIO Post Control

\ disablememoryreadorder();
msr: 2000.0019 18000108.286332a3.

\ chipsetinit(nb);

\ set hd IRQ
\	outl	(GPIOL_2_SET, GPIOL_INPUT_ENABLE);
\	outl	(GPIOL_2_SET, GPIOL_IN_AUX1_SELECT);
\	/*  Allow IO read and writes during a ATA DMA operation.*/
\	/*   This could be done in the HD rom but do it here for easier debugging.*/
\	100 ATA_SB_GLD_MSR_ERR msr-bitclr
\	GLPCI_CRTL_PPIDE_SET GLPCI_SB_CTRL msr-bitset  \ Enable Post Primary IDE

\ Set the prefetch policy for various devices
msr: 5160.0001  0.00008f000.   \ USB1
msr: 5120.0001  0.00008f000.   \ USB2
\ 5130.0001 0.00048f000.   \ ATA  (many of these bits are reserved)
msr: 5150.0001  0.00008f000.   \ AC97 (turn off?)
msr: 5140.0001  0.00000f000.   \ DIVIL

\  Set up Hardware Clock Gating
msr: 5102.4004  0.000000004.  \ GLIU_SB_GLD_MSR_PM
msr: 5100.0004  0.000000005.  \ GLPCI_SB_GLD_MSR_PM
msr: 5170.0004  0.000000004.  \ GLCP_SB_GLD_MSR_PM
\ SMBus clock gating errata (PBZ 2226 & SiBZ 3977)
msr: 5140.0004  0.050554111.  \ DIVIL
msr: 5130.0004  0.000000005.  \ ATA
msr: 5150.0004  0.000000005.  \ AC97

\ setup_gx2();

\ Don't need this, RCONF is already set, cache is already on
\ .. size_kb = setup_gx2_cache();

\ 1000.0026 is already set

\ For now we will skip the real mode IDT setup and see if
\ we can get away with it - no real mode interrupts.
\ src/cpu/amd/model_gx2/vsmsetup.c:setup_realmode_idt();

\ do_vsmbios();

\ Stuff done by VSA when graphics initialized
msr: a000.2001 00000000.00000010.  \ GP config (priority)
msr: a000.2002 00000001.00000001.  \ GP SMI
msr: 8000.2001 00000000.00000320.  \ VG config (priority)
msr: 8000.2002 00000001.00000001.  \ VG SMI (9. to enable vertical blanking SMI)
msr: 8000.2012 00000000.06060202.  \ VG DELAY
msr: 8000.2011 00000000.00000001.  \ VG SPARE - VG fetch state machine hardware fix off

msr: c000.2001 00000000.00040f80.  \ DF config.  - or in 8. for FP ???
\ msr: 4c00.0015 00000037.00000001.  \ MCP DOTPLL reset; unnecessary because of later video init

\ More GLCP stuff
msr: 4c00.0021 00000000.00000001b.   \ GLD Action Data Control
msr: 4c00.0022 00000000.000001001.   \ GLD Action Data

\ Probably don't want to do this because we don't virtualize anything
\ msr: 5000.2012 00ff0000.00008002.
\ msr: 5000.2014 00000000.00fff3ff.  \ Enables PCI access to low mem
msr: 5000.2014 00000000.00ffffff.  \ Enables PCI access to low mem

\ 5536 region configs
msr: 5100.0010 44000020.00020013.  \ PCI timings
msr: 5100.0020 018b4001.018b0001.  \ Region configs
msr: 5100.0021 010fc001.01000001.
msr: 5100.0022 0183c001.01800001.
msr: 5100.0023 0189c001.01880001.
msr: 5100.0024 0147c001.01400001.
msr: 5100.0025 0187c001.01840001.
msr: 5100.0026 014fc001.01480001.
msr: 5100.0027 fe01a000.fe01a001. \ OHCI
msr: 5100.0028 fe01b000.fe01b001. \ EHCI
msr: 5100.0029 efc00000.efc00001. \ UOC
msr: 5100.002b 018ac001.018a0001.
msr: 5100.002f 00084001.00084009.
msr: 5101.0020 400000ef.c00fffff. \ P2D_BM0 UOC
msr: 5101.0023 500000fe.01afffff. \ P2D_BMK Descriptor 0 OHCI
msr: 5101.0024 400000fe.01bfffff. \ P2D_BMK Descriptor 1 UHCI
msr: 5101.00e0 60000000.1f0ffff8. \ IOD_BM Descriptor 0  ATA IO address
msr: 5101.00e1 a0000001.480fff80. \ IOD_BM Descriptor 1
msr: 5101.00e2 80000001.400fff80. \ IOD_BM Descriptor 2
msr: 5101.00e3 80000001.840ffff0. \ IOD_BM Descriptor 3
msr: 5101.00e4 00000001.858ffff8. \ IOD_BM Descriptor 4
msr: 5101.00e5 60000001.8a0ffff0. \ IOD_BM Descriptor 5
msr: 5101.00eb 00000000.f0301850. \ IOD_SC Descriptor 1

msr: 5130.0008 00000000.000018a1. \ IDE_IO_BAR - IDE bus master registers

msr: 5140.0008 0000f001.00001880. \ LBAR_IRQ
msr: 5140.0009 fffff001.fe01a000. \ LBAR_KEL (USB)
msr: 5140.000b     f001.000018b0. \ LBAR_SMB
msr: 5140.000c     f001.00001000. \ LBAR_GPIO
msr: 5140.000d     f001.00001800. \ LBAR_MFGPT
msr: 5140.000e     f001.00001840. \ LBAR_ACPI
msr: 5140.000f     f001.00001400. \ LBAR_PMS
msr: 5140.0010 fffff007.20000000. \ LBAR_FLSH0
\ msr: 5140.0011  \ LBAR_FLSH1
\ msr: 5140.0012  \ LBAR_FLSH2
\ msr: 5140.0013  \ LBAR_FLSH3
msr: 5140.0014 00000000.80070003. \ LEG_IO
msr: 5140.0015 00000000.00000f7c. \ BALL_OPTS
msr: 5140.001b 00000000.00100010. \ NANDF_DATA
msr: 5140.001c 00000000.00000010. \ NANDF_CTL
msr: 5140.001f 00000000.00000011. \ KEL_CTRL
msr: 5140.0020 00000000.bb050a00. \ IRQM_YLOW
msr: 5140.0021 00000000.04000000. \ IRQM_YHIGH
msr: 5140.0022 00000000.00002222. \ IRQM_ZLOW
msr: 5140.0023 00000000.000aa5b2. \ IRQM_ZHIGH
msr: 5140.0025 00000000.00001002. \ IRQM_LPC
msr: 5140.0028 00000000.000000ff. \ MFGPT_IRQ
msr: 5140.0040 00000000.00000000. \ DMA_MAP
\ msr: 5140.004e 00000000.ef2500c0. \ LPC_SIRQ
msr: 5140.004e 00000000.effd0080. \ LPC_SIRQ

\ USB host controller
msr: 5120.0001 0000000b.00000000.  \ USB_GLD_MSR_CONFIG - 5536 page 262
msr: 5120.0008 0000000e.fe01a000.  \ USB OHC Base Address - 5536 page 266
msr: 5120.0009 0000200e.fe01b000.  \ USB EHC Base Address - 5536 page 266
msr: 5120.000b 00000002.efc00000.  \ USB UOC Base Address - 5536 page 266


here msr-init - constant /msr-init

create bigmem-msrs
msr:      1808 25fff002.10f7e000.  \ Memsize dependent
msr: 1000.0028 2000000f.7df00100.   \ 10.000 - 0f7d.f000 High RAM - Memsize dependent
msr: 1000.0026 2cfbe040.400fffe0.   \ 4040.0000 - 405f.ffff relocated to ffe.0000 - Memsize dependent
msr: 1000.0029 2127e0fd.7fffd000.   \ fd00.0000 - fd7f.ffff mapped to f7e.0000 Memsize dependent (Frame Buffer)
msr: 4000.0029 2000000f.7df00100.   \ 10.0000 - 0f7d.f000 High RAM - Memsize dependent
msr: 5000.2019 0f7df000.00100130.    \ Memsize?
here bigmem-msrs - constant /bigmem-init


: init-msr  ( adr -- )  dup la1+ 2@  rot @  wrmsr  ;

: set-msrs  ( -- )
   msr-init /msr-init bounds  ?do  i init-msr  d# 12 +loop
;

code msr-slam  ( adr len -- )
   bx pop
   dx pop
   dx bx add  \ endaddr
   bp push    \ save
   dx bp mov  \ Use BP as pointer

   begin
      0 [bp]  cx  mov   \ msr#
      4 [bp]  dx  mov   \ msr.hi
      8 [bp]  ax  mov   \ msr.lo
      h# 0f asm8,  h# 30 asm8,   \ wrmsr
      d# 12 #  bp  add
      bp bx cmp
   = until

   bp pop
c;

h# fd00.0000 value fb-base
h# fe00.0000 value gp-base
h# fe00.4000 value dc-base
h# fe00.8000 value vp-base

: fix-memsize  ( -- )
   1030 pl@  4 and  0=  if
      bigmem-msrs /bigmem-init bounds  ?do  i init-msr  d# 12 +loop
      h# f7e.0000 h# 88 dc-base + l!   \ DV_CTL register, undocumented Memory size dependent???
   then
;

: fix-sirq  ( -- )
   9 ec-cmd 9 <>  if
      h# 5140.004e rdmsr  swap h# 40 or swap  h# 5140.004e wrmsr
   then
;

: video-map
   h# 80.0000   \ 8 MB video memory
   \ BAR0 is frame buffer - 8M
   \ BAR1 is GP regs - 16K
   \ BAR2 is VG regs - 16K
   \ BAR2 is DF regs - 16K

   \ Unlock the display controller registers
\ write_vg_32(DC_UNLOCK, DC_UNLOCK_VALUE);
   h# 4758 dc-base 0 + l!

\ Set up the DV Address offset in the DC_DV_CTL register to the offset from frame 
\ buffer descriptor.  First, get the frame buffer descriptor so we can set the 
\ DV Address Offset in the DV_CTL register.  Because this is a pointer to real
\ silicon memory, we don't need to do this whenever we change the framebuffer BAR,
\ so it isn't included in the hw_fb_map_init routine.
\ SYS_MBUS_DESCRIPTOR((unsigned short)(vga_config_addr+BAR0),(void *)&mVal);
\ mVal.high &= DESC_OFFSET_MASK;
\ mVal.high <<= 4;
\ mVal.high += framebuffer_base;	// Watch for overflow issues here...
\ write_vg_32(DC_DV_CTL, mVal.high);

   \ The base address of the frame buffer in physical memory
\   h# f7e.0000 h# 88 dc-base + l!   \ DV_CTL register, undocumented Memory size dependent???
   h# 77e.0000 h# 88 dc-base + l!   \ DV_CTL register, undocumented Memory size dependent???

\ hw_fb_map_init(PCI_FB_BASE);
\ Initialize the frame buffer base realated stuff.

   h# fd00.0000 h#  84 dc-base + l!   \ GLIU0 Memory offset
   h# fd00.0000 h#  4c gp-base + l!   \ GP base
   h# fd80.0000 h# 460 vp-base + l!   \ Flat panel base

   \ VGdata.hw_vga_base = h# fd7.c000
   \ VGdata.hw_cursor_base = h# fd7.bc00
   \ VGdata.hw_icon_base = h# fd7.bc00 - MAX_ICON;
;


: gpio-init  ( -- )
\   h# h# 1000 l!  \ GPIOL_OUTPUT_VALUE 
   h# 00a6a8ea h# 1004 pl!  \ GPIOL_OUTPUT_ENABLE 
   h# 00002000 h# 1008 pl!  \ GPIOL_OUT_OPENDRAIN 
   h# a6a8ea01 h# 100c pl!  \ GPIOL_OUTPUT_INVERT_ENABLE 
   h# 60660000 h# 1010 pl!  \ GPIOL_OUT_AUX1_SELECT 
   h# a8ea02b0 h# 1014 pl!  \ GPIOL_OUT_AUX2_SELECT 
   h# 660000a6 h# 1018 pl!  \ GPIOL_PULLUP_ENABLE 
   h# ea03b060 h# 101c pl!  \ GPIOL_PULLDOWN_ENABLE 
   h#  0000a6a8 h# 1020 pl!  \ GPIOL_INPUT_ENABLE 
   h# 04b06066 h# 1024 pl!  \ GPIOL_INPUT_INVERT_ENABLE 
   h# 00a6a8ea h# 1028 pl!  \ GPIOL_IN_FILTER_ENABLE 
   h# b0606600 h# 102c pl!  \ GPIOL_IN_EVENTCOUNT_ENABLE 
   h# 60660000 h# 1034 pl!  \ GPIOL_IN_AUX1_SELECT 
   h# a8ea06b0 h# 1038 pl!  \ GPIOL_EVENTS_ENABLE 
   h# 660000a6 h# 103c pl!  \ GPIOL_LOCK_ENABLE 
   h# 105000ff h# 1040 pl!  \ GPIOL_IN_POSEDGE_ENABLE 
   h# 00000000 h# 1044 pl!  \ GPIOL_IN_NEGEDGE_ENABLE
   h#     0000 h# 1050 pw!  \ GPIO_00_FILTER_AMOUNT
   h#     0000 h# 1052 pw!  \ GPIO_00_FILTER_COUNT
   h#     0000 h# 1054 pw!  \ GPIO_00_EVENT_COUNT
   h#     0000 h# 1056 pw!  \ GPIO_00_EVENTCOMPARE_VALUE
   h#     0000 h# 1058 pw!  \ GPIO_01_FILTER_AMOUNT
   h#     0000 h# 105a pw!  \ GPIO_01_FILTER_COUNT
   h#     0000 h# 105c pw!  \ GPIO_01_EVENT_COUNT
   h#     0000 h# 105e pw!  \ GPIO_01_EVENTCOMPARE_VALUE
   h#     ffff h# 1060 pw!  \ GPIO_02_FILTER_AMOUNT
   h#     0000 h# 1062 pw!  \ GPIO_02_FILTER_COUNT
   h#     9b00 h# 1064 pw!  \ GPIO_02_EVENT_COUNT
   h#     00cf h# 1066 pw!  \ GPIO_02_EVENTCOMPARE_VALUE
   h#     ffff h# 1068 pw!  \ GPIO_03_FILTER_AMOUNT
   h#     0000 h# 106a pw!  \ GPIO_03_FILTER_COUNT
   h#     9300 h# 106c pw!  \ GPIO_03_EVENT_COUNT
   h#     00cf h# 106e pw!  \ GPIO_03_EVENTCOMPARE_VALUE
   h#     0000 h# 1070 pw!  \ GPIO_04_FILTER_AMOUNT
   h#     0000 h# 1072 pw!  \ GPIO_04_FILTER_COUNT
   h#     0000 h# 1074 pw!  \ GPIO_04_EVENT_COUNT
   h#     0000 h# 1076 pw!  \ GPIO_04_EVENTCOMPARE_VALUE
   h#     ea0d h# 1078 pw!  \ GPIO_05_FILTER_AMOUNT
   h#     a6a8 h# 107a pw!  \ GPIO_05_FILTER_COUNT
   h#     0000 h# 107c pw!  \ GPIO_05_EVENT_COUNT
   h#     6066 h# 107e pw!  \ GPIO_05_EVENTCOMPARE_VALUE
 \  h# ffff0000 h# 1080 pl!  \ GPIOH_ OUTPUT_VALUE 
   h# 660001a6 h# 1084 pl!  \ GPIOH_OUTPUT_ENABLE
   h# ea0fb060 h# 1088 pl!  \ GPIOH_OUT_OPENDRAIN
   h# 0000a6a8 h# 108c pl!  \ GPIOH_OUTPUT_INVERT_ENABLE
   h# 10b06166 h# 1090 pl!  \ GPIOH_OUT_AUX1_SELECT
   h# 00a6a8ea h# 1094 pl!  \ GPIOH_OUT_AUX2_SELECT
   h# b0606600 h# 1098 pl!  \ GPIOH_PULLUP_ENABLE
   h# a6a8ea11 h# 109c pl!  \ GPIOH_PULLDOWN_ENABLE
   h# 60660000 h# 10a0 pl!  \ GPIOH_INPUT_ENABLE
   h# a8ea12b0 h# 10a4 pl!  \ GPIOH_INPUT_INVERT_ENABLE
   h# 660000a6 h# 10a8 pl!  \ GPIOH_IN_FILTER_ENABLE
   h# ea13b060 h# 10ac pl!  \ GPIOH_IN_EVENTCOUNT_ENABLE
   h# 0000a6a8 h# 10b0 pl!  \ GPIOH_READ_BACK
   h# 14b06066 h# 10b4 pl!  \ GPIOH_IN_AUX1_SELECT
   h# 00a6a8ea h# 10b8 pl!  \ GPIOH_EVENTS_ENABLE
   h# b0606600 h# 10bc pl!  \ GPIOL_LOCK_ENABLE
   h# a6a8ea15 h# 10c0 pl!  \ GPIOH_IN_POSEDGE_ENABLE
   h# 60660000 h# 10c4 pl!  \ GPIOH_ IN_NEGEDGE_ENABLE
   h# a8ea16b0 h# 10c8 pl!  \ GPIOH_ IN_POSEDGE_STATUS
   h# 660000a6 h# 10cc pl!  \ GPIOH_IN_NEGEDGE_STATUS
   h#     b060 h# 10d0 pw!  \ GPIO_06_FILTER_AMOUNT
   h#     ea17 h# 10d2 pw!  \ GPIO_06_FILTER_COUNT
   h#     a6a8 h# 10d4 pw!  \ GPIO_06_EVENT_COUNT
   h#     0000 h# 10d6 pw!  \ GPIO_06_EVENTCOMPARE_VALUE
   h#     6066 h# 10d8 pw!  \ GPIO_07_FILTER_AMOUNT
   h#     18b0 h# 10da pw!  \ GPIO_07_FILTER_COUNT
   h#     a8ea h# 10dc pw!  \ GPIO_07_EVENT_COUNT
   h#     00a6 h# 10de pw!  \ GPIO_07_EVENTCOMPARE_VALUE

   h# b0606600 h# 10e0 pl!  \ GPIO_MAPPER_X
   h# a6a8ea19 h# 10e4 pl!  \ GPIO_MAPPER_Y
   h# 60660000 h# 10e8 pl!  \ GPIO_MAPPER_Z
   h# a8ea1ab0 h# 10ec pl!  \ GPIO_MAPPER_W
   h#       a6 h# 10f0 pc!  \ GPIO_EE_SELECT_0
   h#       00 h# 10f1 pc!  \ GPIO_EE_SELECT_1
   h#       00 h# 10f2 pc!  \ GPIO_EE_SELECT_2
   h#       66 h# 10f3 pc!  \ GPIO_EE_SELECT_3
   h#       60 h# 10f4 pc!  \ GPIO_EE_SELECT_4
   h#       b0 h# 10f5 pc!  \ GPIO_EE_SELECT_5
   h#       1b h# 10f6 pc!  \ GPIO_EE_SELECT_6
   h#       ea h# 10f7 pc!  \ GPIO_EE_SELECT_7
   h#     a6a8 h# 10f8 pl!  \ GPIOL_EVENT_DECREMENT
   h# 1cb06066 h# 10fc pl!  \ GPIOH_EVNET_DECREMENT
;

: acpi-init
   0 h# 1840 w!
   h# 100 1842 w!
   0 h# 1848 w!
   0 h# 184c w!
   0 h# 1858 w!
   0 h# 185c w!
   \ h# 1400 is PM-base
;
: setup  
   set-msrs
   fix-memsize
\   fix-sirq
   gpio-init
   video-map
   acpi-init
;

0 [if]
void do_vsmbios(void)
{
	device_t dev;
	unsigned long busdevfn;
	unsigned int rom = 0;
	unsigned char *buf;
	unsigned int size = SMM_SIZE*1024;
	int i;
	unsigned long ilen, olen;
	
	\ clear vsm bios data area
        h# 400  h# 100  erase

	\ declare rom address here - keep any config data out of the way of core LXB stuff
        /rom negate  h# 1.0000 +  to vsa-bits

	buf = (unsigned char *) 0x60000;
	olen = unrv2b((uint8_t *)rom, buf, &ilen);

	\ check for post code at start of vsainit.bin. If you don't see it, don't bother.
	if ((buf[0x20] != 0xb0) || (buf[0x21] != 0x10) ||
	    (buf[0x22] != 0xe6) || (buf[0x23] != 0x80)) {
		return;
	}

	\ ecx gets smm, edx gets sysm
	real_mode_switch_call_vsm(0x10000026, 0x10000028);

	\ restart timer 1
	h# 56 h# 43 pc!
	h# 12 h# 41 pc!
}


                graphics_init();

\ Skip this; OFW knows what PCI config method to use
\ 		dev->ops = &pci_domain_ops;
\ 		pci_set_method(dev);

		ram_resource(dev, 0, 0, ((sizeram() - VIDEO_MB) * 1024) - SMM_SIZE);
[then]

