
[ifdef] old-stuff
   \ Host bus control device
   c8 0250 config-wb   \ Snoop stall timer
   \ 251 is set later, after 267
   ef 0252 config-wb   \ CPU Interface ctl Advanced - Enable most speedups
   44 0253 config-wb   \ Arbitration - occupancy timers
   1c 0254 config-wb   \ Misc ctl - CPU host Frequency - 100 MHz Host bus 000, 11100 per porting note
   24 0255 config-wb   \ Misc ctl - 20res, 4+writeRetire
   63 0256 config-wb   \ Write policy - various knobs
   01 0257 config-wb   \ HREQ5 calibration - per porting note
   09 0259 config-wb   \ CPU Misc ctl - 475ns Warm Reset length, also contains Reset bit (8), MSIflat 1
   10 025c config-wb   \ CPU Misc ctl - MSI redirect
   a2 025d config-wb   \ Write policy 2 - knobs
   88 025e config-wb   \ Bandwidth timers - knobs
   ce 025f config-wb   \ CPU Misc ctl - knobs
   \ DRAM timing
   2a 0260 config-wb   \ DRDY timing ctl for read line 4,3,2,1 
   00 0261 config-wb   \ DRDY timing ctl for read line 8,7,6,5
   00 0262 config-wb   \ res
   15 0263 config-wb   \ DRDY timing ctl for read quad 4,3,2,1
   00 0264 config-wb   \ DRDY timing ctl for read quad 8,7,6,5
   00 0265 config-wb   \ res
   00 0266 config-wb   \ DRDY timing ctl for Burst 8-1
   00 0267 config-wb   \ res
   f8 0251 config-wb   \ 80 bit must be set after 54,55,60-67

   dd 0270 config-wb   \ Pullup strengths
   66 0271 config-wb   \ Pulldown strengths
   aa 0272 config-wb   \ Pullup strengths
   55 0273 config-wb   \ Pulldown strengths
\  30 0274 config-wb   \ Reserved
\  38 0275 config-wb   \ Reserved

   0c 0276 config-wb   \ AGTL+IO config - ROMSIP, 8+ComparatorsOnSuspend
   00 027a config-wb   \ AGTL Compensation - ROMSIP

   \ The next batch is set by ROMSIP but must be reprogrammed during resume from S3
   00 02a0 config-wb
   88 02a1 config-wb
   56 02a2 config-wb
   70 02a3 config-wb
   77 02a4 config-wb
   77 02a5 config-wb
   07 02a6 config-wb
   77 02a7 config-wb
   77 02a8 config-wb
   04 02a9 config-wb
   77 02aa config-wb
   77 02ab config-wb
   77 02ac config-wb
   77 02ad config-wb
   77 02ae config-wb
   77 02af config-wb
   77 02b0 config-wb
   77 02b1 config-wb
   33 02b2 config-wb
   33 02b3 config-wb
   77 02b4 config-wb
   77 02b5 config-wb
   77 02b6 config-wb
   77 02b7 config-wb
   77 02b8 config-wb
   77 02b9 config-wb
   77 02ba config-wb
   77 02bb config-wb
   44 02bc config-wb
   44 02bd config-wb
   14 02be config-wb
   75 02c0 config-wb
   14 02c1 config-wb
   14 02c2 config-wb
   10 02c3 config-wb
   14 02c4 config-wb
   20 02c5 config-wb
   14 02c6 config-wb
   10 02c7 config-wb
   04 02c8 config-wb
   10 02c9 config-wb
   0b 0290 config-wb   \ Misc ctl - DRAM timing

   0f 03fe config-wb   \ 20 bit in this register enables self-refresh

   4c 0540 config-wb   \ res, but called out in S3 resume note
   00 0541 config-wb   \ res, but called out in S3 resume note
   03 0542 config-wb   \ res, but called out in S3 resume note

   \ This is the end of the register list that must be restored from ROM code after S3,
   \ according to the BIOS porting note

   \ DRAM control device
   00 0348 config-wb   \ Virtual Rank 0 Begin
   00 0340 config-wb   \ Virtual Rank 0 End
   00 0349 config-wb   \ Virtual Rank 1 Begin
   00 0341 config-wb   \ Virtual Rank 1 End
   00 034a config-wb   \ Virtual Rank 2 Begin
   00 0342 config-wb   \ Virtual Rank 2 End
   00 034b config-wb   \ Virtual Rank 3 Begin
   08 0343 config-wb   \ Virtual Rank 3 End

   \ I think that we write this to send commands to SDRAM - e.g. ee for Init
   02 0350 config-wb   \ DRAM MA Map Type 1

   60 0351 config-wb   \
   11 0352 config-wb   \
   1f 0353 config-wb   \

                       \ Need to set 0354 to 89 and 0355 to ab to enable all ranks for probing
   00 0354 config-wb   \ Physical to Virtual Rank Mapping - DIMM0
   ab 0355 config-wb   \ Physical to Virtual Rank Mapping - DIMM1

   \ 0356,0357 res
   00 0358 config-wb   \
   00 0359 config-wb   \
   01 035a config-wb   \
   11 035b config-wb   \
   \ 035c-035f res

   d0 0360 config-wb   \ DRAM bus turn-around
   55 0361 config-wb   \ DRAM timing 1
   8a 0362 config-wb   \ DRAM timing 2
   49 0363 config-wb   \ DRAM timing 3
   66 0364 config-wb   \ DRAM timing 4
   d1 0365 config-wb   \ What?
   88 0366 config-wb   \ DRAM Arbitration Ctl
   00 0367 config-wb   \ Command channel select
   0c 0368 config-wb   \ What?
   a7 0369 config-wb   \ DRAM Page Policy Control
   86 036a config-wb   \ Refresh Counter

   \ I think we set this to send NOP Commands - see PG_VX855.. section 4.4.2.1
   10 036b config-wb   \ DRAM Misc ctl

   8c 036c config-wb   \ DRAM Type
   c0 036d config-wb   \ What?
   88 036e config-wb   \ DRAM Control
   42 036f config-wb   \

   00 0370 config-wb   \ DQS Output Delay
   04 0371 config-wb   \ MD Output Delay

   07 0376 config-wb   \ Write Data Phase Control
   95 0377 config-wb   \ DQS Input Delay for Channel A
   83 0378 config-wb   \ DQS Input Capture Range
   80 0379 config-wb   \ res What?
   00 037a config-wb   \ res What?
   20 037b config-wb   \ Read Data Phase Control
   00 037c config-wb   \ Phase Detector Count

   2a 0380 config-wb   \ Page C ROM Shadow
   00 0381 config-wb   \ Page D ROM Shadow
   aa 0382 config-wb   \ Page E ROM Shadow
   20 0383 config-wb   \ Page F ROM Shadow

   00 0384 config-wb   \ Low Top Address - Low
   20 0385 config-wb   \ Low Top Address - High


   3f 0386 config-wb   \ SMM and APIC Decoding
 0020 0388 config-ww   \ Bank End-1

\  02 038b config-wb   \ res
   03 038c config-wb   \ DQS Output Control

   04 0390 config-wb   \ 
   00 0391 config-wb   \ 
   03 0392 config-wb   \ 
   04 0393 config-wb   \ 
\  00 0394 config-wb   \ res
   50 0395 config-wb   \ 
   ac 0396 config-wb   \ 
   00 0397 config-wb   \ 

   00 0398 config-wb   \
   0c 0399 config-wb   \
\  00 039a config-wb   \ res
\  00 039b config-wb   \ res
   b4 039c config-wb   \
\  00 039d config-wb   \ res
   91 039e config-wb   \
   11 039f config-wb   \

 ed01 03a0 config-ww   \ CPU Direct Access Frame Buffer Ctl

   ee 03a2 config-wb   \ Internal GFX Timer
   02 03a3 config-wb   \ GFX MMIO Base Address1 M1 Space Size
 0001 03a4 config-ww   \ GFX Misc

   76 03a6 config-wb   \ Page Register Life Timer 1
   8c 03a7 config-wb   \ GMINT and GFX Related Register


\  aa 03b1 config-wb   \ res
   9a 03b3 config-wb   \ GMINTMisc

   88 03d0 config-wb   \
   67 03d1 config-wb   \
   00 03d2 config-wb   \
   01 03d3 config-wb   \
   30 03d4 config-wb   \
   05 03d5 config-wb   \
   fc 03d6 config-wb   \
   00 03d7 config-wb   \

   80 03db config-wb   \
   00 03dc config-wb   \
   00 03dd config-wb   \

   00 03de config-wb   \
   00 03df config-wb   \

   03e0 9 regs:  ee 00 ac 00 44 00 ff 88 86 00 
   03ec 4 regs:  30 84 00 00 
   00000000 03f0 config-wl  \ DQ/DQS CKG Output Delay Control - Channel A
 0000 03f8 config-ww   \ DRAM Mode Register Setting Control - Channel B

   3e 03fb config-wb   \ Power Management - Channel A

   a9 03fd config-wb   \ Power Management 1

   \ 03fe Already done above

   3d 03ff config-wb   \ The Rest of Registers - DQSB Input Delay, Enable SCMD (MA Bus floats during suspend)

\ After DRAM setup

   29 037b config-wb

   1f 00c6 config-wb   \ vga-specific - 02+monochromeDisplayAdapter addresses to PCI1
   \ d0000000 00c8 config-wl \ RO: Graphics memory base address
   03 00d4 config-wb   \ 2+GfxMemMMIO, 1+GfxMemS.L - Defer to display setup
   10 00fe config-wb   \ vga-specific - 10+FullDecodeOfVGAports

   40 0292 config-wb   \ Description is rather confusing
   00 0293 config-wb   \ Description is rather confusing

   0a 0296 config-wb   \ 8+FastTRDR, 2+DynamicHostDataPower

XXX sort of edited to here

   \ 4 Power Management Control
   db 0484 config-wb   \
   05 0485 config-wb   \
   f8 0489 config-wb   \
   bf 048b config-wb   \
   00 048e config-wb   \ 20 bit must be set to enter S3
   00 048f config-wb   \
   ff 0490 config-wb   \
   ff 0491 config-wb   \
   cc 0492 config-wb   \
   80 04a0 config-wb   \
   e0 04a1 config-wb   \
   d6 04a2 config-wb   \
   80 04a3 config-wb   \
   20 04a8 config-wb   \

   \ 5 APIC and Central Traffic Control
   18 0580 config-wb   \

   \ 6 Scratch
   \ 7 North-South Module Interface Control

   02 78c1 config-wb
   00 78c6 config-wb   \ Note says 4
   00 78d5 config-wb
   00 78e0 config-wb
   02 78e1 config-wb

   00 8005 config-wb  eb 804b config-wb
   00 8105 config-wb  eb 814b config-wb
   00 8205 config-wb  eb 824b config-wb

   20 8441 config-wb
   43 8442 config-wb
   9e 8448 config-wb
   13 844c config-wb
   94 844d config-wb
   03 844e config-wb
   10 844f config-wb  \ ?? BPN says 11
   80 8450 config-wb
   11 8452 config-wb
   bf 8453 config-wb
   0b 8459 config-wb
   cc 845a config-wb
   cc 845b config-wb  \ ?? BPN says 44
   00 845c config-wb
   cc 845d config-wb

   \ Dev 17 Fun 0
   44 8840 config-wb
   f0 8842 config-wb
   00 8844 config-wb
   00 8845 config-wb
   00 8846 config-wb
   00 8848 config-wb
   01 884d config-wb
   c0 8850 config-wb  \ 40 disables USB device mode, 80 is reserved!!
   4d 8851 config-wb  \ 40 is reserved, 8+RTC, 4+MSE, 1+KBD
   19 8852 config-wb  \ Serial IRQ control
   80 8853 config-wb  \ PC/PCI DMA control 80+DMA
   00 8854 config-wb  \ PCI INT inversion; default is okay
   a0 8855 config-wb  \ PCI PnP Interrupt routing 1 INTA#,GPIO14 - INTA# -> IRQ10
   b9 8856 config-wb  \ PCI PnP Interrupt routing 2 INTC#,INTB#
   a0 8857 config-wb  \ PCI PnP Interrupt routing 3 INTD#,reserved
   60 8858 config-wb  \ South module misc - 40+APIC, 20+33MhzInts, 2 write protects RTC 0xD ?? 62
   00 8859 config-wb  \ South module misc
   53 885b config-wb  \ misc 40-port80onLPC, 10+DMAoutToPCI, 2reserved,1+dynamicClockStop

   80 8868 config-wb  \ HPET - 80+HPET
   00 8869 config-wb  \ HPET base 15:8
   d0 886a config-wb  \ HPET base 23:15
   fe 886b config-wb  \ HPET base 31:24 - fed0.0000

   00 886c config-wb  \ ISA pos decode - OBIO, MSS, APIC, ROM, PCS1#, PCS0#
   00 886d config-wb  \ ISA pos decode - FDC, LPT, Game, MIDI
   df 886e config-wb  \ ISA pos decode - FDC, LPT, Game, MIDI
   00 886f config-wb  \ ISA pos decode - SPI, TPM, PCS2/3, CF9, FDC, SoundBlaster

   1106 8870 config-ww \ Subsystem vendor ID backdoor 2D-2C
   3337 8872 config-ww \ Subsystem vendor ID backdoor 2F-2E

 \ 8875-887f LPC and firmware memory IDSELs
   20 8880 config-wb   \ 20+DebouncePwrBtn
   84 8881 config-wb   \ 80+ACPIIO, 4+GuardRTCduringPowerTransitions
   50 8882 config-wb   \ 50isRO, low 4 bits select APCI IRQ - 0 is disabled
   40da 8884 config-ww \ Primary interrupt channels mask - 14,7,c,4,3,1
   0000 8886 config-ww \ Secondary interrupt channels mask
   4001 8888 config-ww \ ACPI Power Management I/O base - Ports 4000+
   1f 888a config-wb   \ Auto-switch power state
   07 888c config-wb   \ Host Power Management Control - thermal throttling off
   18 888d config-wb   \ Throttle/ClockStopControl
\  0020e800 8890 config-wl  \ Power Management Timer Control - throttling off, timers disabled 
   28 8894 config-wb   \ Power well - 20+StopNorthInS1, 8+SDIOpowerSwitchPullup
   c1 8895 config-wb   \ Power well - 80+FastResume, 40+StartNorthPLLbeforePWRGDonS4resume, 1+USBwake
   08 8896 config-wb   \ Battery well - 8=CPUfreqStrapValue
   80 8897 config-wb   \ Power well - 80+WaitForPWRGDlowBeforeWake
   00 8898 config-wb   \ GP2/GP3 timer control - I think GP3 is a BIOS watchdog
   88 889b config-wb   \ Boot option mask - 80reserved, 8+USBwake
   ad 889f config-wb   \ SDIO change - 80+KB/MSpullup, 20reserved, 08+10msSDIOpowerUpDelay, 4useCRforSDMMC,1unmaskINTRbefore8259init
   00 88b0 config-wb   \ UART enables and APIC C4 state control
\  34 88b2 config-wb   \ UART IRQ routing
\  00 88b4 config-wb   \ UART1 base address
\  00 88b5 config-wb   \ UART2 base address
   40 88b7 config-wb   \ COM control - 40reserved
\  00 88b8 config-wb   \ UART DMA base low
\  00 88b9 config-wb   \ UART DMA base high
   00 88ba config-wb   \ UART1 DMA Channel Control
   00 88bb config-wb   \ UART2 DMA Channel Control
   d3 88bd config-wb   \ SPI MMIO base address 15:8
   fe 88be config-wb   \ SPI MMIO base address 23:16
   90 88bf config-wb   \ SPI MMIO base address 31:24 - 90fe.d300
 4101 88d0 config-ww   \ SMBus I/O base address - Port 4100
   01 88d2 config-wb   \ SMBus host config - 1+SMBusHostCtlr
   eb 88e2 config-wb   \ Internal NorthPLL Ctl - 80+InhibitC4inUSBisochronous, rest reserved
   03 88e3 config-wb   \ pullups, break events
   a0 88e4 config-wb   \ multi-function select 1 - 80+FastC3/4, 20+GPO5/6
   60 88e5 config-wb   \ multi-function select 2 - 40+NorthBusMaster, 20+NorthIntWakesCx
   20 88e6 config-wb   \ Break event enable 1 - 20+PCIbusMasterBreakEvent
   80 88e7 config-wb   \ Break event enable 2 - 80+APICcycleReflect
   00 88ec config-wb   \ Watchdog off
   04 88fc config-wb   \ Processor control - 4:DPSLP#toSLP#latencyInRange7.5-15uS
   
   \ Dev 17 Fun 7
   43 8f4f config-wb   \ North/South interface ctl - 40+enableExtPCI,2+ExtendedConfigSpace,1+ReadFlushesWrFIFO
   08 8f50 config-wb   \ Priorities - 8+HDACHighPriority
   80 8f51 config-wb   \ P2P Bridge - 80+SubtractiveDecode (but doc says 1 should be set too)
   11 8f52 config-wb   \ Fast timeouts for SM and HDAC Occupy
   11 8f53 config-wb   \ Fast timeouts for SM and HDAC Promotes
   02 8f54 config-wb   \ Synchronize requests - 2+SyncUSBreq

   80 8f60 config-wb   \ DRAM Bank 7 End high 8 bits
   2a 8f61 config-wb   \ Page C ROM Shadow ctl - cc000 disabled, c0000-cbfff RO
   00 8f62 config-wb   \ Page D ROM Shadow ctl - c0000-cffff disabled
   a0 8f63 config-wb   \ Page E and F Shadow ctl - e0000-fffff RO, no hole - this might be for SMI
   aa 8f64 config-wb   \ Page E ROM Shadow ctl - e0000-effff RO

   82 8f70 config-wb   \ CPU to PCI Flow ctl 1 - 80+PostedWrites,2+DelayTransaction
   c8 8f71 config-wb   \ CPU to PCI Flow ctl 2 - 80isRW1C, 40+FiniteRetries, 8+BurstTimeout
   ee 8f72 config-wb   \ P2C cache ctl - various
   01 8f73 config-wb   \ PCI Master ctl - 1+BrokenMasterTimer
   0c 8f74 config-wb   \ South/North interface ctl - complicated
   0f 8f75 config-wb   \ PCI arb 1 - 8 disable master bus timeout
   50 8f76 config-wb   \ PCI arb 2 - 40+Parking, 10+CPUgetsEveryThirdcycle
   48 8f77 config-wb   \ South misc - DMA write doesn't block PIO read, 1 ms read timeout
   02 8f7c config-wb   \ 2+APIC FSB bypasses PCI

   07 8f80 config-wb   \ disable read-around-write for PCI1,HDAC,APIC
   21 8f82 config-wb   \ CCA test mode thing

   00 8fd1 config-wb   \ 0 in 04 bit enables HDAC
   93 8fe0 config-wb   \ Dynamic clock control 1
\  08 8fe1 config-wb   \ reserved
   00 8fe2 config-wb   \ Dynamic clock control 3 - use dynamic clocking

   5e 8fe3 config-wb   \ various PCI things

   80 8fe5 config-wb   \ DRAM low top address bits 31:24
   3f 8fe6 config-wb   \ SMM/APIC Decoding - some SMM addresses to PCI2, MSI snoop, 4+TopSMM,2+HighSMM,1+CompatSMM

   48 8ffc config-wb   \ PCI Bus ctl - 40+CCAreadClk 8res
   

   07 26 pmio-wb  \ PMIO processor ctl
\ PMIO 2b xxxxxx1x \ 2+THRMTRIP#
\ PMIO 66 xxxxxx1x \ 2+P61FisSTPGNT
[then]

