\ Enable cache as RAM
   cr0 ax mov  h# 4000.0000 bitset  ax cr0 mov  invd  \ Disable cache

   00000000.00000c00. 2ff set-msr  \ Enable fixed and variable MTRRs in DefType
   00000000.00000000. 250 set-msr  \ Clear fixed MTRR
   258 wmsr  259 wmsr  268 wmsr  269 wmsr  26a wmsr \ Fixed MTRRs
   26b wmsr  26c wmsr  26d wmsr  26e wmsr  26f wmsr \ Fixed MTRRs
   200 wmsr  201 wmsr  202 wmsr  203 wmsr  204 wmsr \ Variable MTRRs
   205 wmsr  206 wmsr  207 wmsr  208 wmsr  209 wmsr \ Variable MTRRs
   20a wmsr  20b wmsr  20c wmsr  20d wmsr  20e wmsr \ Variable MTRRs
   20f wmsr                                         \ Last variable one

   dcached-base 6 +          0  200 set-msr   \ Dcache base address, write back
   /dcached negate h# 800 +  f  201 set-msr   \ Dcache size
   dropin-base 6 +           0  202 set-msr   \ ROM base address
   /icached negate h# 800 +  f  203 set-msr   \ Icache size
   \ This region is for CForth
   h# ffff.0000 6 +          0  204 set-msr   \ ROM base address
   /icached negate h# 800 +  f  205 set-msr   \ Icache size


   00000000.00000800.           2ff set-msr   \ Enable variable MTRRs in DefType   


   cr0 ax mov  h# 6000.0000 bitclr  ax cr0 mov  invd  \ Cache on

   cld

   \ Access ROM to load it into the icache
   dropin-base #  esi  mov
   /icached 4 / #  ecx  mov
   rep  eax lods

   \ Access "RAM" area to load it into the dcache
   dcached-base #  esi  mov
   /dcached 4 / #  ecx  mov
   rep  eax lods

   \ Put the stack pointer at the top of the dcached area
   dcached-base /dcached + 4 - #  esp  mov
   ds ax mov  ax ss mov
