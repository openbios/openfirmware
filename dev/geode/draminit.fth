   h# 18 # al mov  al h# 80 # out
   h# 1430 # dx mov  dx ax in  h# 9999 # ax cmp  =  if
      h# 34 #  al mov    al  h# 70 #  out   \ Write to CMOS 0x34
      h# 18 #  al mov    al  h# 71 #  out   \ Write value 01
   then

   \ Enable DLL, load Extended Mode Register by set and clear PROG_DRAM
   20000018 rmsr
   10000001 bitset  20000018 wmsr
   10000001 bitclr  20000018 wmsr

   \ Reset DLL (bit 27 is undocumented in GX datasheet, but is in the LX one)
   08000001 bitset  20000018 wmsr
   08000001 bitclr  20000018 wmsr

   \ Here we are supposed to wait 200 SDCLK cycles to let the DLL settle.
   \ That is approximately 2 uS.  The ROM instruction access is so slow that
   \ anything we do will take quite a bit longer than that, so we just let the
   \ "rmsr, bitset" sequence take care of the time delay for us.

   \ In the following sequence of writes the 2000.0018 MSR, we
   \ take advantage of the fact that the existing value stays
   \ in EAX/EDX, so we don't have to re-read the value.

   \ Generate 2 refresh requests.  The refresh queue is 8 deep, and we
   \ need to make sure 2 refreshes hit the chips, so we have to issue
   \ 10 requests to the queue.  According to the GX datasheet, we don't
   \ have to clear the REF_TST bit (8) explicitly between writes 
   20000018 rmsr  8 bitset
   wrmsr wrmsr wrmsr wrmsr wrmsr wrmsr wrmsr wrmsr wrmsr wrmsr
   8 bitclr

\ LinuxBIOS LX raminit.c has a big delay here, using Port 61

   \ Load Mode Register
   1 bitset  20000018 wmsr
   1 bitclr  20000018 wmsr

   \ Earlier code has set up an MSR so the fxxxx address range hits memory

   \ The RAM DLL needs a write to lock on
   ax  h# ffff0 #)  mov

   h# 19 # al mov  al h# 80 # out
   h# 1430 # dx mov  dx ax in  h# 9999 # ax cmp  =  if
      h# 34 #  al mov    al  h# 70 #  out   \ Write to CMOS 0x34
      h# 19 #  al mov    al  h# 71 #  out   \ Write value 01
   then

   \ Turn on the cache
   cr0	ax   mov
   6000.0000 bitclr  \ Cache-disable off, coherent
   ax   cr0  mov
   invd

   h# 1a # al mov  al h# 80 # out
   h# 1430 # dx mov  dx ax in  h# 9999 # ax cmp  =  if
      h# 34 #  al mov    al  h# 70 #  out   \ Write to CMOS 0x34
      h# 1a #  al mov    al  h# 71 #  out   \ Write value 01
   then

   0000f001.00001400.   5140000f set-msr  \ PMS BAR

   \ It is tempting to test bit 0 of PM register 5c, but a 5536 erratum
   \ prevents that bit from working.  Bit 1 works, but LX errata 34
   \ sometimes requires that we reset the system to fix the memory DLL,
   \ which destroys all the bits of PM register 5c.  So we put a breadcrumb
   \ in a PM register that we don't otherwise use.
   1430 port-rl  h# 9999 # ax cmp  =  if  \ Wakeup event flag
      0 1430 port-wl
      h# 1b # al mov  al h# 80 # out
      h# 34 #  al mov    al  h# 70 #  out   \ Write to CMOS 0x34
      h# 1b #  al mov    al  h# 71 #  out   \ Write value 01

      char r 3f8 port-wb  begin  3fd port-rb 40 bitand  0<> until

      resume-data  # sp mov
      resume-entry # ax mov  ax call   \ This might return if checksumming fails
      char x 3f8 port-wb  begin  3fd port-rb 40 bitand  0<> until
   then

   h# 1c # al mov  al h# 80 # out
   h# 1808 rmsr                \ Default region configuration properties MSR
   h# 0fffff00 # ax and        \ Top of System Memory field
   4 # ax shl                  \ Shift into place
   ax mem-info-pa 4 + #)  mov  \ Put it where resetend.fth can find it

   \ char D 3f8 port-wb  begin  3fd port-rb 40 bitand  0<> until

   \ Memory is now on
   h# 8.0000 #  sp  mov        \ Setup a stack pointer for later code

   h# 1d # al mov  al h# 80 # out
\ Some optional debugging stuff ...
[ifdef] debug-startup
init-com1

carret report
linefeed report
ascii F report
ascii o report
ascii r report
[then]

\ fload ${BP}/cpu/x86/pc/ramtest.fth

0 [if]
ax ax xor
h# 12345678 #  bx mov
bx 0 [ax] mov
h# 5555aaaa #  4 [ax] mov
0 [ax] dx  mov
dx bx cmp  <>  if  ascii B report  ascii A report  ascii D report  begin again  then
[then]

