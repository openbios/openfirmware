\ Via timing settings for a specific 512MiB DIMM 

\ Detection.c
\  DRAMCmdRate
    
   0 3 devfunc
   50 11 00 mreg  \ Use stable 2T command rate
   end-table

\   h# 23 port80   d# 300000 wait-us

\ FreqSetting.c : DRAMFreqSetting()
   \ The following register is undocumented.  coreboot has this comment:
   \ Must use "CPU delay" to make sure VLINK is dis-connect
   0 7 devfunc  47 00 04 mreg  end-table  d# 20 wait-us
   0 3 devfunc  90 07 07 mreg  end-table  d# 20 wait-us  \ First set DRAM Freq to invalid
   0 3 devfunc  90 07 04 mreg  end-table  d# 20 wait-us  \ 266 MHz
   0 3 devfunc  6b d0 c0 mreg  end-table  d# 20 wait-us  \ PLL Off
   0 3 devfunc  6b 00 10 mreg  end-table  d# 20 wait-us  \ PLL On
   0 3 devfunc  6b c0 00 mreg  end-table  \ Adjustments off
   0 7 devfunc  47 04 00 mreg  end-table  \ disable V_LINK Auto-Disconnect

\   h# 24 port80   d# 300000 wait-us

\  TimingSetting.c
   0 3 devfunc
   61 ff 55 mreg  \ Trfc, Trrd
   62 ff 8a mreg  \ CL, Trp, Tras
   63 ff 49 mreg  \ Twr, Twtr, Trtp
   64 ff 66 mreg  \ Trp, Trcd
   end-table

\ DRDR_BL.c
\  DRAMDRDYsetting
   0 2 devfunc
   60 ff aa mreg  \ DRDY Timing Control 1 for Read Line
   61 ff 0a mreg  \ DRDY Timing Control 2 for Read Line
   62 ff 00 mreg  \ Reserved, probably channel B
   63 ff aa mreg  \ DRDY Timing Control 1 for Read QW
   64 ff 0a mreg  \ DRDY Timing Control 2 for Read QW
   65 ff 00 mreg  \ Reserved, probably channel B
   66 ff 00 mreg  \ Burst DRDR Timing Control for Second cycle in burst
   67 ff 00 mreg  \ Reserved, probably channel B
   54 0a 08 mreg  \ Misc ctl 1 - special mode for DRAM cycles
   51 00 80 mreg  \ Last step - enable DRDY timing - should the mask be f7 ?
   end-table

\  DRAMBurstLength
   0 3 devfunc
   6c 08 08 mreg  \ Burst length 8
\ DrivingSetting.c
\  DrivingODT
   d0 ff 88 mreg    \ Pull up/down Termination strength
   d6 fc fc mreg    \ DCLK/SCMD/CS drive strength
   d3 fb 01 mreg    \ Compensation control - enable DDR Compensation
   9e 30 10 mreg    \ SRAM ODT Control 1 - 1T wait state turnaround
   9f 11 11 mreg    \ SDRAM ODT Control 2 - Late extension values
   d5 a0 00 mreg    \ DQ/DQS Burst and ODT Range Select - disable bursts for channel A
   d7 80 00 mreg    \ SCMD/MA Burst - Disable SDMD/MAA burst
   d5 0c 04 mreg    \ Enable DRAM MD Pad ODT of Channel  A High 32 bits

   9c ff e1 mreg    \ ODT Lookup table
   d4 36 30 mreg    \ ChannelA MD ODT dynamic-on
   9e 00 01 mreg    \ Enable Channel A differential DQS Input
   9e 00 80 mreg    \ Enable ODT controls

\  DrivingDQS,DQ,CS,MA,DCLK
   e0 ff ee mreg \ DQS A
   e1 ff 00 mreg \ DQS B
   e2 ff ac mreg \ DQ A
   e3 ff 00 mreg \ DQ B
   e4 ff 44 mreg \ CS A
   e5 ff 00 mreg \ CS B
   e6 ff ff mreg \ MCLK A
   e7 ff 88 mreg \ MCKL B
   e8 ff 86 mreg \ MA A
   e9 ff 00 mreg \ MA B

\ ClkCtrl.c  (register tables in mainboard/via/6413e/DrivingClkPhaseData.c)
\  DutyCycleCtrl
   ec ff 30 mreg  \ DQS/DQ Output duty control
   ee f0 00 mreg  \ DCLK Output duty control
   ef 30 00 mreg  \ DQ CKG Input Delay - going with Phoenix value; coreboot uses 30

\  DRAMClkCtrl
\   WrtDataPhsCtrl
   74 07 00 mreg \ DQS Phase Offset
   75 07 00 mreg \ DQ Phase Offset
   76 ef 07 mreg \ Write data Phase control
   8c 03 03 mreg \ DQS Output Control

\   ClkPhsCtrlFBMDDR2
   91 07 00 mreg \ DCLK Phase
   92 07 03 mreg \ CS/CKE Phase
   93 07 04 mreg \ SCMD/MA Phase

\   DQDQSOutputDlyCtrl
   f0 ff 00 mreg \ Group A0/1
   f1 ff 00 mreg \ Group A2/3
   f2 ff 00 mreg \ Group A4/5
   f3 ff 00 mreg \ Group A6/7

\   DQSInputCaptureCtrl
   77 bf 8a mreg \ DQS Input Delay - Manual
   78 3f 03 mreg \ DQS Input Capture Range Control A
   7a 0f 00 mreg \ Reserved
   7b 7f 20 mreg \ Read Data Phase Control

\   DCLKPhsCtrl
   99 1e 12 mreg \ MCLKOA[4,3,0] outputs
   end-table

\ DevInit.c
\  DRAMRegInitValue

   0 3 devfunc
   50 ee ee mreg \ DDR default MA7 for DRAM init
   51 ee 60 mreg \ DDR default MA3 for CHB init
   52 ff 33 mreg \ DDR use BA0=M17, BA1=M18,
   53 ff 3F mreg \ DDR	  BA2=M19

   54 ff 00 mreg \ default PR0=VR0; PR1=VR1
   55 ff 00 mreg \ default PR2=VR2; PR3=VR3
   56 ff 00 mreg \ default PR4=VR4; PR5=VR5
   57 ff 00 mreg \ default PR4=VR4; PR5=VR5

   60 ff 00 mreg \ disable fast turn-around
   65 ff D9 mreg \ AGP timer = D; Host timer = 8;
   66 ff 88 mreg \ DRAMC Queue Size = 4; park at the last bus owner,Priority promotion timer = 8
   68 ff 0C mreg
   69 0F 04 mreg \ set RX69[3:0]=0000b
   6A ff 00 mreg \ refresh counter
   6E 07 80 mreg \ must set 6E[7],or else DDR2  probe test will fail
   85 ff 00 mreg
   40 ff 00 mreg
   end-table

   80 4a3 config-wb       \ Enable toggle reduction on MA/SCMD per coreboot

\  DRAMInitializeProc

   0 3 devfunc
   6c 00 04 mreg \ Enable channel A only

   54 ff 80 mreg \ Enable rank 0, disable rank 1
   55 ff 00 mreg \ Disable ranks 2 and 3
   40 ff 10 mreg \ Rank 0 top
   48 ff 00 mreg \ Rank 0 base
   end-table

\   h# 25 port80   d# 300000 wait-us

   DDRinit #) call

   h# 11 port80

   0 3 devfunc
   40 ff 00 mreg \ Rank 1 top back to 0 to work on other ranks

   54 ff 09 mreg \ Enable rank 1
   55 ff 00 mreg \ Disable ranks 2 and 3
   41 ff 10 mreg \ Rank 1 top
   49 ff 00 mreg \ Rank 1 base
   end-table

   DDRinit #) call

   0 3 devfunc
   41 ff 00 mreg \ Rank 1 top back to 0 to work on other ranks
   end-table

   h# 14 port80

0 [if] \ This is for a DIMM in the other socket
   0 3 devfunc
   54 ff 00 mreg \ Disable ranks 0,1
   55 ff a0 mreg \ Enable Rank 2
   42 ff 10 mreg \ Rank 2 top
   4a ff 00 mreg \ Rank 2 base
   end-table

   DDRinit #) call 

   0 3 devfunc
   42 ff 00 mreg \ Rank 2 top back to 0 to work on other ranks
   54 ff 00 mreg \ Disable ranks 0,1
   55 ff 0b mreg \ Enable Rank 3
   43 ff 10 mreg \ Rank 3 top
   4b ff 00 mreg \ Rank 3 base
   end-table

   DDRinit #) call

   0 3 devfunc
   43 ff 00 mreg \ Rank 3 top back to 0 to work on other ranks
   end-table
[then]

   0 3 devfunc
   69 03 03 mreg \ Reinstate page optimizations (03) - FF #ranks

\ RankMap.c
\  DRAMBankInterleave
\   (see 69 above)
   87 ff 00 mreg \ Channel B #banks or some such - FF BA  
\ SizingMATypeM

   50 ff 20 mreg \ MA Map type - ranks 0/1 type 1 - 2 bank bits, 10 column bits
   51 ff 60 mreg \ "Reserved"
   52 ff 33 mreg \ Bank interleave on A17, A18, and
   53 ff 3f mreg \ A19 (but BA2 off because 4 banks), Rank interleave on A20 and A21
                 \ Different interleave bits might improve performance on some workloads

   54 ff 89 mreg \ Rank map A 0/1
   55 ff 00 mreg \ Rank map A 2/3
   56 ff 00 mreg \ Rank map B ?
   57 ff 00 mreg \ Rank map B ?

   40 ff 04 mreg \ Rank top 0
   41 ff 08 mreg \ Rank top 1
   42 ff 00 mreg \ Rank top 2
   43 ff 00 mreg \ Rank top 3

   48 ff 00 mreg \ Rank base 0
   49 ff 04 mreg \ Rank base 1
   4a ff 00 mreg \ Rank base 2
   4b ff 00 mreg \ Rank base 3
   end-table

   20 8f60 config-wb                    \ DRAM Bank 7 ending address - controls DMA upstream
   0388 config-rb  ax bx mov  0385 config-setup  bx ax mov  al dx out  \ Copy Low Top from RO reg 88 to reg 85
   0388 config-rb  ax bx mov  8fe5 config-setup  bx ax mov  al dx out  \ Copy Low Top from RO reg 88 to SB Low Top e5

0 [if]  \ Very simple memtest
ax ax xor
h# 12345678 #  bx mov
bx 0 [ax] mov
h# 5555aaaa #  4 [ax] mov
0 [ax] dx  mov
dx bx cmp  =  if
   ascii G report  ascii 2 report  h# 20 report
else
   dx ax mov  dot #) call
   ascii B report  ascii 2 report  h# 20 report
   hlt
then
[then]

\   d# 17 7 devfunc
\   e6 ff 07 mreg \ Enable Top, High, and Compatible SMM
\   end-table

\ DQSSearch.c
\  DRAMDQSOutputSearch
   0 3 devfunc
   70 ff 00 mreg \ Output delay
   71 ff 04 mreg

\  DRAMDQSInputSearch
   77 ff 00 mreg \ Input delay auto

\ FinalSetting.c
\  RefreshCounter
   6a ff 86 mreg \ Refresh interval - FF frequency

\  DRAMRegFinalValue
    60 00 d0 mreg \ Fast turn-around
    66 30 80 mreg \ DRAMC queue = 4 (already set to 88 up above), park at last owner
    69 00 07 mreg \ Enable multiple page
    95 ff 0d mreg \ Self-refresh controls
    96 f0 a0 mreg \ Auto self-refresh stuff
    fb ff 3e mreg \ Dynamic clocks
    fd ff a9 mreg \ Dynamic clocks
    fe ff 0f mreg \ Chips select power saving for self-refresh
    ff ff 3d mreg \ DSQB input delay, SCMD enabled
    96 0f 03 mreg \ Enable self-refresh for ranks 0 and 1
    end-table
    
    0 4 devfunc  \ PM_table
    a0 f0 f0 mreg \ Enable dynamic power management
    a1 e0 e0 mreg \ Dynamic power management for DRAM
    a2 ff fe mreg \ Dynamic clock stop controls
    a3 80 80 mreg \ Toggle reduction on
    a5 81 81 mreg \ "Reserved"
    end-table
    
1 [if]
ax ax xor
h# 12345678 #  bx mov
bx 0 [ax] mov
h# 5555aaaa #  4 [ax] mov
0 [ax] dx  mov
dx bx cmp  <>  if  ascii B report  ascii A report  ascii D report  begin again  then
[then]

\ fload ${BP}/cpu/x86/pc/ramtest.fth

\ UMARamSetting.c
\  SetUMARam
    0 3 devfunc
    a1 00 80 mreg \ Enable internal GFX
    a2 ff ee mreg \ Set GFX timers
    a4 ff 01 mreg \ GFX Data Delay to Sync with Clock
    a6 ff 76 mreg \ Page register life timer
    a7 ff 8c mreg \ Internal GFX allocation
    b3 ff 9a mreg \ Disable read past write
    de ff 06 mreg \ Enable CHA and CHB merge mode (but description says this value disable merging!)
    end-table

    0 3 devfunc
    a1 70 40 mreg \ Set frame buffer size to 64M (8M:10, 16M:20, 32M:30, etc) - fbsize
    end-table

    1 0 devfunc
                  \ Reg 1b2 controls the number of writable bits in the BAR at 810
    b2 ff 70 mreg \ Offset of frame buffer, depends on size - fbsize
    04 ff 07 mreg \ Enable IO and memory access to display
    end-table

    d000.0000 810 config-wl  \ S.L. Base address
    f000.0000 814 config-wl  \ MMIO Base address
         cd01 3a0 config-ww  \ Set frame buffer size and CPU-relative address and enable

    0 0 devfunc
    d4 00 03 mreg \ Enable MMIO and S.L. access in Host Control device
    fe 00 10 mreg \ 16-bit I/O port decoding for VGA (no aliases)
    end-table

    1 0 devfunc
    b0 07 03 mreg \ VGA memory selection (coreboot uses 03, Phoenix 01.  I think 03 is correct)
    end-table
