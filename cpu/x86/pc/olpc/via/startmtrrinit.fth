
\ Fix the MTRRs so the real RAM is cacheable, instead of the fake nonexistent area
   cr0 ax mov  h# 6000.0000 bitset  ax cr0 mov  \ Cache off
   
   0000.0000.0000.0006.  200 set-msr   \ RAM starting at 0
   0000.0000.0000.0c00.  2ff set-msr   \ Enable fixed and variable MTRRs in DefType   
   0000.000f.c000.0800.  201 set-msr   \ 1 GiB
   0000.0000.ff00.0006.  202 set-msr   \ ROM in last meg
   0000.000f.ff00.0800.  203 set-msr   \ 1 MiB
   0000.0000.d000.0001.  204 set-msr   \ Frame buffer - Write Combining mode
   0000.000f.f000.0800.  205 set-msr   \ 256 MB

   0606.0606.0606.0606.  250 set-msr   \ Cache 00000-7FFFF
   0606.0606.0606.0606.  258 set-msr   \ Cache 80000-9FFFF
   0000.0000.0000.0000.  259 set-msr   \ Don't Cache VGA range from A0000 to BFFFF
   0606.0606.0606.0606.  268 set-msr   \ Cache C0000-C7FFF
   0606.0606.0606.0606.  269 set-msr   \ Cache C8000-CFFFF
   0606.0606.0606.0606.  26a set-msr   \ Cache D0000-D7FFF
   0606.0606.0606.0606.  26b set-msr   \ Cache D8000-DFFFF
   0606.0606.0606.0606.  26c set-msr   \ Cache E0000-E7FFF
   0606.0606.0606.0606.  26d set-msr   \ Cache E8000-EFFFF
   0606.0606.0606.0606.  26e set-msr   \ Cache F0000-F7FFF
   0606.0606.0606.0606.  26f set-msr   \ Cache F8000-FFFFF

   0000.0000.0000.0c00.  2ff set-msr   \ Enable fixed and variable MTRRs in DefType   

   cr0 ax mov  h# 6000.0000 bitclr  ax cr0 mov  \ Cache on
