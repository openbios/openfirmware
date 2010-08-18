\ This is the dance you have to do for each DDR rank to turn on the RAM chips
label DDRinit
   11 36b config-wb  \ SDRAM NOP
   0 #) ax mov       \ Access RAM
   d# 200 wait-us

   12 36b config-wb  \ SDRAM Precharge All
   0 #) ax mov       \ Access RAM
      
   13 36b config-wb  \ SDRAM MRS Enable
   20200 #) ax mov   \ Access RAM for DLL enable - 150 ohm (20020 for 75 ohm)
     800 #) ax mov   \ Access RAM for DLL reset

   12 36b config-wb  \ SDRAM Precharge All
   0 #) ax mov       \ Access RAM

   14 36b config-wb  \ SDRAM CBR Cycle Enable

   8 # cx mov
   begin
      0 #) ax mov
      d# 100 wait-us
   loopa
   
   13 36b config-wb  \ SDRAM MRS Enable
\  101258 #) ax mov  \ Depends on Twr, CL, and Burst Length

   \ The address in the mov below sends setup information to the DDR2 SDRAM chips
   \ The address bits are:
   \    P .... .www DmCC CtBB B___
   \
   \ ___ are the low-order address bits that don't go directly to the RAM chips
   \ because the DRAM data bus from the processor is 8 bytes wide.
   \
   \ BBB is Burst Length    - 010=BL4, 011=BL8
   \ t is Burst Type        - 0=sequential, 1=interleaved
   \ CCC is CAS Latency     - 010=CL2, 011=CL3, 100=CL4, 101=CL5, 110=CL6
   \ m is test mode         - 0=normal, 1=test
   \ D is DLL reset         - 0=no reset, 1=reset
   \ www is Write Recovery  - 001=WR2, 010=WR3, 011=WR4, 100=WR5, 101=WR6
   \ P is Power Down Exit   - 0=fast, 1=slow
      
   \ At this point, the address multiplexing is set for 12 column addresses, i.e MA type 111,
   \ per the preceding setting of D0F3 Rx50 in demodram.fth  (50 ee ee mreg).
   \ That keep the 12-bit group "www DmCC CtBB B" together as a contiguous set.
   \ I'm not sure how the P bit gets routed from processor A20 to SDRAM A12.  In fact
   \ I'm just assuming that that leading 1 in the addresses below is the P bit.
   \ It can't be a bank address bit, because BA0, BA1, and BA2 are suppose to be all 0
   \ for MRS (Mode Register Set)

   acpi-io-base 48 + port-rl  h# 0008.0000 # ax and  0<>  if  \ Memory ID0 bit - set for CL4 SDRAM
      102258 #) ax mov  \ Depends on Twr, CL, and Burst Length - WR3, CL4, BL8
   else
      1021d8 #) ax mov  \ Depends on Twr, CL, and Burst Length - WR3, CL3, BL8
   then

0 [if]
2024b
011 BL 8
1 BT interleave
100 CL 4  Anck
0 TM normal
0 DLL rst no
001 WR 2  write recov for autoprecharge
      2 and 3 are possible for 400
0 PD fast exit from active power down
000 ???

      12
10 0000
10 BA1,0 EMR2
[then]

   21e00 #) ax mov   \ For 150 ohm; 75 ohm is 21c20
   20200 #) ax mov   \ For 150 ohm; 75 ohm is 21c20


   10 36b config-wb  \ SDRAM Normal

   ret
end-code
