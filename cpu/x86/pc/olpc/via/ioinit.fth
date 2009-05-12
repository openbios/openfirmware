\ Also from FinalSetting.c

   0 4 devfunc  \ PM_table
   a0 80 80 mreg \ Enable dynamic power management (coreboot for vx800 uses f0; 70 bits are reserved on vx855)
   a1 e0 e0 mreg \ Dynamic power management for DRAM
   a2 d6 d6 mreg \ Dynamic clock stop controls (coreboot for vx8000 uses ff fe; 29 bits are reserved on vx800)
   a3 80 80 mreg \ Toggle reduction on
   a5 81 81 mreg \ "Reserved"
   end-table

\ cache_as_ram_auto.c : enable_shadow_ram

   0 3 devfunc
\ Initial DOS hole settings, so the firmware can set things up
   80 ff ff mreg \ Enable R/W memory access to Cxxxx bank
   81 ff ff mreg \ Enable R/W memory access to Dxxxx bank
   82 ff ff mreg \ Enable R/W memory access to Exxxx bank
   83 30 30 mreg \ Enable R/W memory access to Fxxxx bank (30), no memory hole (0c), SMM switching of Axxxx bank (03)

\ Final DOS hole settings, after stuff has been copied in, for reference
\  80 ff 2a mreg \ CC000-CFFFF off, C0000-C7FFF RO
\  81 ff 00 mreg \ D0000-DFFFF off
\  82 ff aa mreg \ E0000-EFFFF RO
\  83 ff 20 mreg \ Enable R/W memory access to Fxxxx bank (20), no memory hole (0c), SMM switching of Axxxx bank (03)
   end-table

   0 3 devfunc
   86 38 38 mreg  \ SMM and APIC Decoding: enable APIC lowest int arb, IOAPIC split decode, MSI (SMM later)
   end-table

   \ Additional Power Management Setup not in coreboot
   0 2 devfunc
   76 08 08 mreg  \ AGTL Power down buffers in S3
\   92 ff 00 mreg  \ ACPI IO Base address
\   93 ff 04 mreg  \ ACPI IO Base address
   end-table

   0 4 devfunc
   84 ff db mreg  \ Dynamic clocks
   85 ff 05 mreg  \ Dynamic clocks
   89 ff f8 mreg  \ Dynamic clocks
   8b ff bf mreg  \ Dynamic clocks
   8d ff 30 mreg  \ Self-refresh in C3 and C4
   90 ff ff mreg  \ Gate clocks
   91 ff ff mreg  \ Gate clocks
   92 cc cc mreg  \ Dynamic buffer control, power down comparators
   a8 20 20 mreg  \ Central traffic controller dynamic clock stop
   end-table
    
   \ Bus tuning
   0 5 devfunc
   54 8f 80 mreg  \ SM request gets high priority, PCCA occupancy timer off
   55 0f 04 mreg  \ PCCA P2C Promote Timer value 4
   59 0f 02 mreg  \ IGFX Promote Timer value 2
   5f 0f 06 mreg  \ IPI Promote Timer value 6
   64 20 00 mreg  \ Upstream MSI doesn't flush queued P2C Write Data
   80 0b 08 mreg  \ Upstream Request 1T earlier
   83 ff 81 mreg  \ P2PW down arb timer timer 8, P2PR down arb timer timer 1
   84 7f 28 mreg  \ Downstream arbitration Timeout timer for C2P
   85 c0 c0 mreg  \ Abort P2P cycle to PCI1, CPU to PCI1 cycle blocks next C2P cycle
   a3 01 01 mreg  \ 01 res be like Phx
   end-table

   d# 12 0 devfunc  \ SDIO tuning
   44 01 01 mreg  \ Enable backdoor
\   8b 05 01 mreg  \ Do not report 1.8V support
   8c c3 03 mreg  \ Falling edge trigger for Slots 1 and 2 data in high speed
   8e ff 7e mreg  \ Delay host clock for Slots 1, 2, 3 by 4.8 nS
   8f 09 01 mreg  \ Falling edge trigger on slot 3 output clock under high speed
[ifdef] demo-board
   99 ff f9 mreg  \ Two slots
[else]
   99 ff fa mreg  \ Three slots
[then]
   end-table

   d# 15 0 devfunc  \ EIDE tuning
   40 02 02 mreg  \ Enable primary channel
   4a ff 5e mreg  \ Drive1 timing
   4b ff 20 mreg  \ Drive0 timing
   4c f0 60 mreg  \ Address setup time
   52 df 0e mreg  \ Ultra dma wait strobe timing
\   53 df c6 mreg  \ Ultra DMA mode control
   53 df 06 mreg  \ Ultra DMA mode control
   c4 1d 18 mreg  \ Config 1
\  d4 ac 24 mreg  \ Config 3
   d4 bc 34 mreg  \ Config 3 - 10 res be like Phx
   end-table

   \ USB Tuning
   d# 16 0 devfunc  \ UHCI Ports 0,1
   4a 02 02 mreg  \ Enable Stop Bus Master Cycle if HALT Bit is Asserted
   4b 60 60 mreg  \ Enable New UHCI Dynamic Scheme - 66MHz (40) & 33MHz (20)
   c1 20 00 mreg  \ Disable USB PIRQ
   end-table

   d# 16 1 devfunc  \ UHCI Ports 2,3
   4a 02 02 mreg  \ Enable Stop Bus Master Cycle if HALT Bit is Asserted
   4b 60 60 mreg  \ Enable New UHCI Dynamic Scheme - 66MHz (40) & 33MHz (20)
   c1 20 00 mreg  \ Disable USB PIRQ
   end-table

   d# 16 2 devfunc  \ UHCI Ports 4,5
   4a 02 02 mreg  \ Enable Stop Bus Master Cycle if HALT Bit is Asserted
   4b 60 60 mreg  \ Enable New UHCI Dynamic Scheme - 66MHz (40) & 33MHz (20)
   c1 20 00 mreg  \ Disable USB PIRQ
   end-table

   d# 16 4 devfunc  \ EHCI
   42 40 40 mreg  \ Enable Check PRESOF of ITDOUT Transaction during Fetching Data from DRAM
   43 c0 c0 mreg  \ Enable Dynamic Clock Scheme - 66MHz (80) & 33MHz (40)
   48 20 00 mreg  \ Disable DMA bursts
   4c 03 03 mreg  \ Squelch detector fine tune - 01 is 112.5 mV
   4d 10 10 mreg  \ 10 res be like Phx
   4e 03 03 mreg  \ reserved bit - setting is appropriate for vx800 03 res be like Phx
   4f 10 10 mreg  \ Enable Clear RUN Bit when EHCI_IDLE
   50 80 80 mreg  \ Fetch one more QH before de-asserting Doorbell
   52 ff 11 mreg  \ be like Phx
   53 ff 3f mreg  \ be like Phx
   55 ff ff mreg  \ Disconnect level fine tune - 575 mV for ports 0-3
   56 0f 0f mreg  \ Disconnect level fine tune - 575 mV for ports 4-5
   5a ff cc mreg  \ HS termination resistor fine tune - 45 ohm, 48 ohm for ports 0,1
   5b ff cc mreg  \ HS termination resistor fine tune - 45 ohm, 48 ohm for ports 2,3
   5c 0f 00 mreg  \ DPLL Track Speed 2, DPLL Lock Speed 2
   5d ff cc mreg  \ HS termination resistor fine tune - 45 ohm, 48 ohm for ports 4,5
   64 05 05 mreg  \ Bump NULL-SOF valid time to 8 micro frames (04), Inhibit C4 state on USB 1.1 ISO activity (01)
   end-table

   d# 17 0 devfunc  \ Bus control and power management
   40 44 44 mreg  \ Enable I/O Recovery time (40), Enable ports 4d0/4d1 for edge/level setting (04)
   42 fc f0 mreg  \ Various setting related to DMA line  buffers
   43 0f 0b mreg  \ Enable PCI delayed transactions (08), Write transaction timer (02), Read transaction timer (01)
\  4d 01 01 mreg  \ Enable LPC TPM
\  4e 08 08 mreg  \ Enable ports 74/75 for CMOS RAM access
   4e 18 18 mreg  \ Enable ports 74/75 for CMOS RAM access  - 10 res be like Phx
\  50 40 40 mreg  \ Disable USB device mode
   50 c0 c0 mreg  \ Disable USB device mode - 80 res be like Phx
   52 1b 19 mreg  \ No wait state between SIRQ transactions (10), Enable SIRQ (08), SIRQ frame is 6 clocks (3>1)
   53 80 80 mreg  \ Enable PC/PCI DMA
   55 ff a0 mreg  \ INTA and External General interrupt routing - INTA:IRQ10
   56 ff b9 mreg  \ INTB,C routing - INTC:IRQ11, INTB:IRQ9
   57 f0 a0 mreg  \ INTD routing - INTD:IRQ10
   58 40 40 mreg  \ Enable Internal APIC
\  5b 10 10 mreg  \ Enable APIC Clock Gating
   5b 53 53 mreg  \ Enable APIC Clock Gating - 43 res be like Phx
   68 80 80 mreg  \ Enable HPETs
   69 ff 00 mreg  \ HPET base low
   6a ff d0 mreg  \ HPET base mid
   6b ff fe mreg  \ HPET base high
   6e ff 18 mreg  \ COMB not pos decoded but otherwise set to 2f8, COMA pos decoded at 3f8
   70 ff 06 mreg  \ SVID backdoor
   71 ff 11 mreg  \ SVID backdoor
   72 ff 37 mreg  \ SVID backdoor
   73 ff 33 mreg  \ SVID backdoor
   80 20 20 mreg  \ Debounce power button
   81 08 08 mreg  \ 32-bit ACPI timer
\  81 08 00 mreg  \ 24-bit ACPI timer - why?
   84 ff da mreg  \ IRQs 7,6,4,3,1 are primary wakeups
   85 ff 40 mreg  \ IRQ 14 is primary wakeup
   8a 9f 1f mreg  \ C-state auto switching with normal latencies
[ifdef] demo-board
   8d 18 18 mreg  \ fast clock as throttle timer tick, hold SMI# low until event status cleared (FIXME for OLPC)
[else]
   8d 18 10 mreg  \ fast clock as throttle timer tick, do not hold SMI# low
[then]
   
   94 ff 68 mreg  \ be like Phx
   95 ff c1 mreg  \ be like Phx
   97 ff 80 mreg  \ be like Phx 

   9b ff 88 mreg  \ 80 res be like Phx
   9f ff ad mreg  \ be like Phx (slot 3 is Card Reader not SDIO)

   b4 80 00 mreg  \ No positive decoding for UART1 ???
   b7 40 40 mreg  \ 40 res be like Phx
   b8 fc 80 mreg  \ UART DMA Control Registers Base low (port is 4080)
   b9 ff 40 mreg  \ UART DMA Control Registers Base high
   ba 77 44 mreg  \ COM1 DMA Channel Selects - DMA0 for both Transmit and Receive
   bc ff 00 mreg  \ SPI MMIO Base Address 15:8  (address is fed30000)
   bd ff d3 mreg  \ SPI MMIO Base Address 23:16
   be ff fe mreg  \ SPI MMIO Base Address 31:24
   d0 f0 00 mreg  \ SMBUS IO Base Address low (port is 4100)
   d1 ff 41 mreg  \ SMBUS IO Base Address high
   d2 0f 01 mreg  \ Enable SMBUS and set other characteristics
   e2 80 80 mreg  \ Inhibit C4 during USB isochronous transaction
   e4 ff a0 mreg  \ Enable short C3/C4 (80), select various multi-function pins
   e5 60 60 mreg  \ Enable NM bus master as source of bus master status, enable NB int to wakeup from Cx
   e6 20 20 mreg  \ Enable USB Device Mode Bus Master as Break Event
   e7 80 80 mreg  \ Enable APIC Cycle Reflect to ALL Bus Master Activity Effective Signal
   fc 06 04 mreg  \ DPSLP# to SLP# Latency Adjustment - 22.5 us
   end-table

   d# 17 7 devfunc  \ South-North Module Interface Control
   50 df 08 mreg  \ SM priorities - HDAC high priority, others low
   51 80 80 mreg  \ Enable subtractive decode for P2P cycle
   54 7b 02 mreg  \ CCA REQ timing - synchronize USB REQ but not others
0 [if]
   61 ff 2a mreg  \ Page C ROM shadow - C0000-CBFFF RO, CC000-CFFFF off
   62 ff 00 mreg  \ Page D ROM shadow - D0000-DFFFF off
   63 f3 a0 mreg  \ Page E/F ROM shadow - E0000-EFFFF RO, F0000-FFFFF RO, no memory hole
   64 ff aa mreg  \ Page E ROM shadow - E0000-EFFFF RO
[then]
   70 fb 82 mreg  \ CPU to PCI flow control - CPU to PCI posted write, Enable Delay Transaction
   72 af ee mreg  \ Read caching and prefix - various knobs (40 bit is reserved)
   73 79 01 mreg  \ Enable PCI broken master timer & various knobs
\  74 d8 08 mreg  \ Lock Cycle Issued by CPU Blocks P2C Cycles (04 bit is reserved)
   74 dc 0c mreg  \ Lock Cycle Issued by CPU Blocks P2C Cycles - 04 res be like Phx
   75 ff 0f mreg  \ Use New grant mechanism for PCI arbitration, PCI Master Bus Timeout is 7x16 PCI clock
   76 fd 50 mreg  \ Enable PCI parking, Grant to CPU after 2 PC master grants
   77 58 48 mreg  \ PCI1 FIFO empty blocks CPU to PCI read, Read FIFO times out after 1 ms
   80 07 07 mreg  \ PCI1 and HDAC upstream read does not pass write, APCI blocks upstream write
\  82 3e 20 mreg  \ Monitor CCA and SDIO2
   82 3f 21 mreg  \ Monitor CCA and SDIO2 - 01 res be like Phx
\  e0 e0 80 mreg  \ Dynamic CCA clock
   e0 f3 93 mreg  \ Dynamic CCA clock - 13 res be like Phx
\  e2 1e 00 mreg  \ Use dynamic clocks for Downstream Interface, PCI1, Downstream HDAC, Downstream SM Internal PCI device
   e2 1f 00 mreg  \ Use dynamic clocks for Downstream Interface, PCI1, Downstream HDAC, Downstream SM Internal PCI device 01 res be like Phx
   e3 ff 5e mreg  \ PCI1 dynamic clock, PCI clock on when GRANT# asserted, Enable P2CR data timeout at 7*8 PCI clocks
\  e6 1f 1f mreg  \ Split APIC decoding, Snoop FEEx.xxxx, Enable top SMM, High SMM, Compat SMM (20 bit is reserved)
   e6 1f 19 mreg  \ Split APIC decoding, Snoop FEEx.xxxx, Enable top SMM, High SMM, Compat SMM (20 bit is reserved)
\  fc 40 40 mreg  \ Enable CCA Read Clock When MTXCTL state machine is not idle
   fc 48 48 mreg  \ Enable CCA Read Clock When MTXCTL state machine is not idle - 08 res be like Phx
   end-table

   d# 20 0 devfunc
   41 01 01 mreg  \ Dynamic clock for HDAC
   end-table

   \ APIC setup
   0 2 devfunc
   59 01 01 mreg  \ MSI Flat model support
   5c 10 10 mreg  \ Data bit 11 mask for MSI
   97 01 01 mreg  \ Redirect lowest priority MSI requests to APIC 00
   end-table

   0 3 devfunc
   86 38 38 mreg  \ SMM and APIC Decoding: enable APIC lowest int arb, IOAPIC split decode, MSI (SMM later)
   end-table

   \ Low 2 bits of 86:
   \ x1 to write to SMM shadow memory behind VGA
   \ 00 to run - Axxxxx hits VGA in normal mode, hits shadow DRAM in SMM
   \ 01 to access VGA when in SMM (data cycles only)
