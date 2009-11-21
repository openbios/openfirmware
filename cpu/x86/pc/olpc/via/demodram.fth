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
[ifdef] demo-board
   0 3 devfunc  90 07 04 mreg  end-table  d# 20 wait-us  \ 266 MHz !ATEST
[then]
[ifdef] xo-board
\  0 3 devfunc  90 07 03 mreg  end-table  d# 20 wait-us  \ 200 MHz ATEST
\  0 3 devfunc  90 e7 03 mreg  end-table  d# 20 wait-us  \ 200 MHz ATEST
   0 3 devfunc  90 ff 43 mreg  end-table  d# 20 wait-us  \ 200 MHz ATEST
[then]
   0 3 devfunc  6b d0 c0 mreg  end-table  d# 20 wait-us  \ PLL Off
   0 3 devfunc  6b 00 10 mreg  end-table  d# 20 wait-us  \ PLL On
   0 3 devfunc  6b c0 00 mreg  end-table  \ Adjustments off
   0 7 devfunc  47 04 00 mreg  end-table  \ disable V_LINK Auto-Disconnect

\   h# 24 port80   d# 300000 wait-us

\  TimingSetting.c
   0 3 devfunc
[ifdef] phoenix-timings
   61 ff 55 mreg  \ Trfc: 0x15+8 = 29 * 3.75 = 108.75 ns, Trrd: 01 -> 3T
   62 ff 8a mreg  \ Tras: 8+5=13 *3.75=48.75, 8bank-timing constraint, CL 2+2=4
   63 ff 49 mreg  \ Twr:2+2=4 *3.75=15, Trtp:1+2=3 *3.75=11.25, Twtr:1+2=3 *3.75=11.25
   64 ff 66 mreg  \ Trp 5, Trcd 5 
[then]
[ifdef] coreboot-timings
   61 ff 54 mreg  \ Trfc: 0x14+8 = 28 * 3.75 = 105.00 ns, Trrd: 01 -> 3T
   62 ff 7a mreg  \ Tras: 7+5=12 *3.75=45.00, 8bank-timing constraint, CL 2+2=4
   63 ff 40 mreg  \ Twr:2+2=4 *3.75=15, Trtp:0+2=2 *3.75=7.5, Twtr:0+2=2 *3.75=7.5
   64 ff 44 mreg  \ Trp 2+2=4, Trcd 2+2=4
[then]
[ifdef] compute-timings
\ The subtractions below (e.g. "2 -") account for the way that numbers are
\ encoded in bit fields - e.g. 00b means 2T, 01b means 3T, etc.
\ The shifts below (e.g. "6 <<") move the value into the correct bit position.

   61 3f  Trfc ns>tck 8 -       mreg   \ Trfc: ceil(127.50/5) = 26   - 8 = 0x12
   61 c0  Trrd ns>tck 2 - 6 <<  mreg   \ Trrd: ceil(  7.50/5) =  2   - 0 = 0x00

\  61 ff 12 mreg  \ Trfc, Trrd  Trfc = 0x39+8 = 65  Trrd=4T ceil(7.5ns/5ns)

   62 08  08                    mreg   \ 8-bank timing constraint
\ !!!
   62 f0  Tras ns>tck 5 - 4 <<  mreg   \ Tras: ceil( 40.00/5) = 8     - 5 = 0x03

\  62 ff 3a mreg  \ CL, 8-bank constraint, Tras  Tras = 8T (3+5=8)

   63 e0  Twr  ns>tck 2 - 5 <<  mreg   \ Twr:  ceil( 15.00/5) = 3     - 2 = 0x01
\ !!!
   63 08  Trtp ns>tck 2 - 3 <<  mreg   \ Trtp: ceil(  7.50/5) = 2     - 2 = 0x00
\ !!!
   63 03  Twtr ns>tck 2 -       mreg   \ Twtr: ceil( 10.00/5) = 2     - 2 = 0x00

\  63 ff 20 mreg  \ Twr, Twtr, Trtp  Twr=3T (15ns/5), Twtr=2T (10/5)  Trtp=2T ceil(7.5/5)

\ !!!
   64 0e  Trp  ns>tck 2 - 1 <<  mreg   \ Trp:  ceil( 15.00/5) = 3     - 2 = 0x01
\ !!!
   64 e0  Trcd ns>tck 2 - 5 <<  mreg   \ Trcd: ceil( 15.00/5) = 3     - 2 = 0x01

\  64 ff 22 mreg  \ Trp 3, Trcd 3
[then]
   end-table

   acpi-io-base 48 + port-rl  h# 0008.0000 # ax and  0<>  if  \ Memory ID0 bit - set for CL4 SDRAM
      0 3 devfunc
      62 07  4    2 -              mreg   \ CL 4
      end-table
   else
      0 3 devfunc
      62 07  3    2 -              mreg   \ CL 3
      end-table
   then


\  DRAMBurstLength
   0 3 devfunc
   6c 08 08 mreg  \ Burst length 8
[ifdef] demo-board
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
   70 ff 00 mreg \ Output delay
   71 ff 04 mreg
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
[then]

[ifdef] xo-board  \ DDR400
\ DrivingSetting.c
\  DrivingODT
   d0 ff 88 mreg    \ Pull up/down Termination strength
   d6 fc fc mreg    \ DCLK/SCMD/CS drive strength
   d3 03 01 mreg    \ Compensation control - enable DDR Compensation
   9f f3 00 mreg    \ 533,667,800: 11 SDRAM ODT Control 2 - Late extension values
   d5 f0 00 mreg    \ DQ/DQS Burst and ODT Range Select - disable bursts for channel A
   d7 c0 00 mreg    \ SCMD/MA Burst - Disable SDMD/MAA burst
   d5 0f 05 mreg    \ Enable DRAM MD Pad ODT of Channel  A High 32 bits

   9c ff e4 mreg    \ ODT Lookup table - XO uses ODT0 only
   d4 3f 30 mreg    \ ChannelA MD ODT dynamic-on
   9e ff 81 mreg    \ 533: 91 667: a1 800: a1 Enable Channel A differential DQS Input

\  DrivingDQS,DQ,CS,MA,DCLK
   e0 ff ee mreg \ DQS A
   e2 ff ac mreg \ DQ A
   e4 ff 44 mreg \ CS A
   e8 ff 86 mreg \ MA A
   e6 ff ff mreg \ MCLK A
\  e1 ff ee mreg \ DQS B
\  e3 ff ca mreg \ DQ B
\  e5 ff 44 mreg \ CS B
\  e9 ff 86 mreg \ MA B
\  e7 ff ff mreg \ MCKL B

\ ClkCtrl.c  (register tables in mainboard/via/6413e/DrivingClkPhaseData.c)
\  DutyCycleCtrl
   ec ff 30 mreg \ DQS/DQ Output duty control
   ed ff 88 mreg \ 533: 84 667: 88 800: 88
   ee ff 00 mreg \ 533: 00 667: 40 800: 40  DCLK Output duty control
   ef 33 00 mreg \ DQ CKG Input Delay

\  DRAMClkCtrl
\   WrtDataPhsCtrl
   70 ff 00 mreg \ Output delay
   71 ff 05 mreg \ 533: 4 667: 6 800: 5
   74 07 07 mreg \ DQS Phase Offset 533: 0 667: 0 800: 1
   75 07 07 mreg \ DQ Phase Offset 533: 0 667: 0 800: 1
   76 ef 06 mreg \ Write data Phase control  533: 7 667: 87 800: 80
   8c 03 03 mreg \ DQS Output Control

\   ClkPhsCtrlFBMDDR2
   91 07 07 mreg \ DCLK Phase  533: 0 667: 1 800: 2
   92 07 02 mreg \ CS/CKE Phase  533: 3 667: 3 800: 4
   93 07 03 mreg \ SCMD/MA Phase  533: 4 667: 5 800: 6
\ Channel B fields
\  91 70 70 mreg \ DCLK Phase  533: 0 667: 10 800: 20
\  92 70 20 mreg \ CS/CKE Phase  533: 30 667: 30 800: 40
\  93 70 30 mreg \ SCMD/MA Phase  533: 40 667: 50 800: 60

\   DQDQSOutputDlyCtrl
   f0 77 00 mreg \ Group A0/1
   f1 77 00 mreg \ Group A2/3
   f2 77 00 mreg \ Group A4/5
   f3 77 00 mreg \ Group A6/7

   f4 77 00 mreg \ ?
   f5 77 00 mreg \ ?
   f6 77 00 mreg \ ?
   f7 77 00 mreg \ ?

\   DQSInputCaptureCtrl
   77 bf 9b mreg \ DQS Input Delay - Manual, value from VIA's BIOS
   78 3f 01 mreg \ 533: 3 667: 7 800: d  DQS Input Capture Range Control A
\  79 ff 83 mreg \ 533: 87 667: 89 800: 89
   79 ff 80 mreg \ Reserved, perhaps for the snapshot RAM ?  Phoenix value
   7a ff 00 mreg \ Reserved
   7b ff 10 mreg \ 533: 20 667: 34 800: 34  Read Data Phase Control
\  8b ff 10 mreg \ 533: 20 667: 34 800: 34
   8b ff 02 mreg \ Phoenix value
[then]

\   DCLKPhsCtrl - depends on which clock outputs are used
[ifdef] demo-board
   99 1e 12 mreg \ MCLKOA[3,2,1,0] outputs
[then]
[ifdef] xo-board
   99 1e 06 mreg \ MCLKOA[1,0] outputs
[then]
   end-table

\ DevInit.c
\  DRAMRegInitValue

   0 3 devfunc
   50 ee ee mreg \ DDR default MA7 for DRAM init
   51 ee 60 mreg \ DDR default MA3 for CHB init
   \ Via says 11, 1F gives slightly better performance in their environment,
   \ but that setting doesn't work for us - it crashes with Forth+X+
   52 ff 33 mreg \ DDR use BA0=M17, BA1=M18,
   53 ff 3F mreg \ DDR	  BA2=M19

   54 ff 00 mreg \ default PR0=VR0; PR1=VR1
   55 ff 00 mreg \ default PR2=VR2; PR3=VR3
   56 ff 00 mreg \ default PR4=VR4; PR5=VR5
   57 ff 00 mreg \ default PR6=VR6; PR7=VR7

   60 ff 00 mreg \ disable fast turn-around
   65 ff d1 mreg \ AGP timer = D; Host timer = 1; (coreboot uses 9 for host timer)
   66 ff 88 mreg \ DRAMC Queue Size = 4; park at the last bus owner,Priority promotion timer = 8
   68 ff 0C mreg
   69 0F 04 mreg \ Disable multiple page and page active for now, enable refresh priority
   6A ff 00 mreg \ refresh counter
   6E 87 80 mreg \ must set 6E[7],or else DDR2  probe test will fail
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

forth  #ranks 2 >=  assembler  [if]
   0 3 devfunc
   40 ff 00 mreg \ Rank 1 top back to 0 to work on other ranks

   54 ff 09 mreg \ Enable rank 1
   55 ff 00 mreg \ Disable ranks 2 and 3
   41 ff 10 mreg \ Rank 1 top
   49 ff 00 mreg \ Rank 1 base
   end-table

   DDRinit #) call
[else]
   0 3 devfunc   
   55 ff 00 mreg \ Disable ranks 2 and 3 and leave them off
   end-table
[then]

   h# 12 port80

forth  #ranks 3 >=  assembler  [if]
   0 3 devfunc
   41 ff 00 mreg \ Rank 1 top back to 0 to work on other ranks
   end-table

   h# 14 port80

   0 3 devfunc
   54 ff 00 mreg \ Disable ranks 0,1
   55 ff a0 mreg \ Enable Rank 2
   42 ff 10 mreg \ Rank 2 top
   4a ff 00 mreg \ Rank 2 base
   end-table

   DDRinit #) call 

   0 3 devfunc
   42 ff 00 mreg \ Rank 2 top back to 0 to work on other ranks
   end-table
[then]

   h# 13 port80

forth  #ranks 4 >=  assembler  [if]
   0 3 devfunc
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

   h# 14 port80

   0 3 devfunc
forth #banks 8 = assembler [if]
   69 c3 c3 mreg \ Enable page optimizations (03) 8-bank interleave (c0)
[else]
   69 c3 83 mreg \ Enable page optimizations (03) 4-bank interleave (80)
[then]


\ RankMap.c
\  DRAMBankInterleave
\   (see 69 above)
   87 ff 00 mreg \ Channel B #banks or some such - FF BA  
\ SizingMATypeM


[ifdef] compute-timings
   50 ff  ma-type 5 <<  mreg
[else]
   50 ff 20 mreg \ MA Map type - ranks 0/1 type 1 - 2 bank bits, 10 column bits !ATEST
\ Check 1T command rate.  What controls it?
\  50 ff a1 mreg \ 1T Command Rate, RMA Map type - ranks 0/1 type 5 - 3 bank bits, 14 row bits, 10 col bits ATEST
[then]

   51 ff 60 mreg \ "Reserved"
   52 ff 33 mreg \ Bank interleave on A17, A18, and

forth #banks 8 =  [if]
   53 ff bf mreg \ BA2 on (80), A19, Rank interleave on A20 and A21
[else]
   53 ff 3f mreg \ A19 (but BA2 off because 4 banks), Rank interleave on A20 and A21
[then]
                 \ Different interleave bits might improve performance on some workloads

forth #ranks 1 > assembler  [if]
   54 ff 89 mreg \ Rank map A 0/1   Ranks 0 and 1
[else]
   54 ff 80 mreg \ Rank map A 0/1   Rank 0 only
[then]

forth #ranks 3 < assembler  [if]
   55 ff 00 mreg \ Rank map A 2/3 2 & 3 off
[else]
 forth #ranks 3 = assembler  [if]
   55 ff a0 mreg \ Rank map A 2/3 2 on 3 off
 [else]
   55 ff ab mreg \ Rank map A 2/3 2 & 3 on
 [then]
[then]

   56 ff 00 mreg \ Rank map B ?
   57 ff 00 mreg \ Rank map B ?
   end-table

   0 3 devfunc
   40 ff rank-top0 mreg \ Rank top 0  (register value in units of 64MB)
   41 ff rank-top1 mreg \ Rank top 1
   42 ff rank-top2 mreg \ Rank top 2
   43 ff rank-top3 mreg \ Rank top 3

   48 ff rank-base0 mreg \ Rank base 0
   49 ff rank-base1 mreg \ Rank base 1
   4a ff rank-base2 mreg \ Rank base 2
   4b ff rank-base3 mreg \ Rank base 3
   end-table

   acpi-io-base 48 + port-rl  h# 1000.0000 # ax and  0<>  if  \ Memory ID1 bit - set for 32bit memory width
      0 3 devfunc
      6c 20 20 mreg    \ Enable 32-bit memory width mode - channel A
      d4 30 10 mreg    \ ODT off for low 32 bits
      end-table
   then

   0388 config-rb  ax bx mov  0385 config-setup  bx ax mov  al dx out  \ Copy Low Top from RO reg 88 to reg 85

   h# 15 port80

   0 3 devfunc
   52 77 11 mreg  \ BA1 is A14, BA0 is A13
   53 30 10 mreg  \ BA2 is A15
   69 20 20 mreg  \ Bank address scramble
   end-table

0 [if]  \ Very simple memtest
long-offsets on
ax ax xor
h# 12345678 #  bx mov      \ Data value to write to address 0
bx 0 [ax] mov              \ Write to address 0
h# 5555aaaa #  h# 40 [ax] mov  \ Write 5555aaaa to address 0x40
0 [ax] dx  mov             \ Read from address 0 into register EDX
dx bx cmp  =  if           \ Compare expected value (EBX) with read value (EDX)
   \ Compare succeeded
\   ascii G report  ascii 2 report  h# 20 report  \ Display "G2 " - Good
else
   \ Compare failed
   dx ax mov  dot #) call  \ Display read value
   ascii B report  ascii 2 report  h# 20 report  \ Display "B2 " - Bad

   h# ffff.0000 # ax mov   ax call  \ C Forth

   hlt
then
[then]

   h# 16 port80

\ DQSSearch.c
\  DRAMDQSOutputSearch
   0 3 devfunc

\  DRAMDQSInputSearch
\  Leave the following set to the manual value.
\  Eventually we should implement an auto-search
\  77 ff 00 mreg \ Input delay auto

\ FinalSetting.c
\  RefreshCounter
[ifdef] demo-board
   6a ff 86 mreg \ Refresh interval - FF frequency !ATEST
[then]
[ifdef] xo-board
   6a ff 65 mreg \ Refresh interval - FF frequency  ATEST
[then]

\  DRAMRegFinalValue
    60 00 d0 mreg \ Fast turn-around
    66 30 80 mreg \ DRAMC queue = 4 (already set to 88 up above), park at last owner
    69 00 07 mreg \ Enable multiple page
[ifdef] demo-board
    95 ff 0d mreg \ Self-refresh controls
[then]
[ifdef] xo-board
    95 ff 03 mreg \ Self-refresh controls, depends on #ranks
[then]
    96 f0 a0 mreg \ Enable pairwise by-rank self refresh, after 2 auto-refreshes
    fb ff 3e mreg \ Dynamic clocks
    fd ff a9 mreg \ Dynamic clocks
    fe ff 0f mreg \ Chips select power saving for self-refresh
    ff ff 3d mreg \ DSQB input delay, SCMD enabled
[ifdef] demo-board
    96 0f 03 mreg \ Enable self-refresh for ranks 0 and 1
[then]
[ifdef] xo-board
    96 0f 01 mreg \ Enable self-refresh for rank 0
    b1 ff aa mreg \ Reserved - Phoenix value
[then]

    end-table
    
   h# 17 port80

0 [if]
ax ax xor
h# 12345678 #  bx mov
bx 0 [ax] mov
h# 5555aaaa #  4 [ax] mov
0 [ax] dx  mov
dx bx cmp  <>  if  ascii B report  ascii A report  ascii D report  begin again  then
[then]
