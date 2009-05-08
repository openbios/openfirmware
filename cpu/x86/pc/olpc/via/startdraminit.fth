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
   101258 #) ax mov  \ Depends on Twr, CL, and Burst Length

   21e00 #) ax mov   \ For 150 ohm; 75 ohm is 21c20
   20200 #) ax mov   \ For 150 ohm; 75 ohm is 21c20

   10 36b config-wb  \ SDRAM Normal

   ret
end-code
