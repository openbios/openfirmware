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
   1021d8 #) ax mov  \ Depends on Twr, CL, and Burst Length

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
