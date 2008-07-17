\ Included from romreset.bth - early core MSR setup for the Geode GX

   11. 1100 set-msr        \ Enable branch target buffer and near call return stack GX page 116

   \ The next few MSRs allow us to access the 5536
   \ EXTMSR - page 449   \ Use PCI device #F for port 2
   00000000.00000f00.   5000201e set-msr  \ cs5536_setup_extmsr(void)

   \ write IDSEL to the write once register at address 0x0000
   \ 02000000 0 port-wl  \ This is the default value so we need not set it

   \ setup CPU interface serial to mode C on both sides
   44000020.00200013. 51000010 set-msr   \ 5536 p 229

   \ Tell the GX what kind of companion chip is attached.
   \ The GX datasheet is incorrect; 2 means 5536, not a reserved value
   00000000.00000002.   54002010 set-msr

   \ Set up GPIO base register
   0000f001.00001000.   5140000c set-msr  \ GPIO BAR

fload ${BP}/cpu/x86/pc/olpc/inituart.fth

   h# 11 # al mov  al h# 80 # out
   h# 1430 # dx mov  dx ax in  h# 9999 # ax cmp  =  if
      h# 34 #  al mov    al  h# 70 #  out   \ Write to CMOS 0x34
      h# 10 #  al mov    al  h# 71 #  out   \ Write value 01
   then

 \ Init memory controller

   \ sdram_initialize,generic_sdram.c
   \ sdram_set_spdregisters(),auto.c
 
   \ gpio_init,auto.c
   4 1020 port-wl          \ Enable the GPIO bit that reports DRAM size (ticket 151)

   \ Refresh and SDRAM program MSR GX page 205
   \ Some of these don't really have to be set here, and could be
   \ moved to the big table of MSR values, except that the table
   \ slammer is dumb and can't handle conditionals.
   20000000.000fff00.   10000020 set-msr  \ memory - 0..fffff

   1030 port-rl 4 bitand  0<> if  \ 128 MiB
      25fff002.1077e000.      1808 set-msr
      2c7be040.400fffe0.  10000026 set-msr
      20000007.7df00100.  10000028 set-msr \ Top of memory
      20a7e0fd.7fffd000.  10000029 set-msr \ Frame buffer
      10075012.00003400.  20000018 set-msr
      20000007.7df00100.  40000029 set-msr \ top of memory.
      077df000.00100130.  50002019 set-msr
   else                           \ 256 MiB
      25fff002.10f7e000.      1808 set-msr
      2cfbe040.400fffe0.  10000026 set-msr
      2000000f.7df00100.  10000028 set-msr \ Top of memory
      2127e0fd.7fffd000.  10000029 set-msr \ Frame buffer
      10076013.00003400.  20000018 set-msr
      2000000f.7df00100.  40000029 set-msr \ top of memory.
      0f7df000.00100130.  50002019 set-msr
   then

   \ 20000019 rmsr            \ SDRAM timing and mode program
   18000108.286332a3.   20000019 set-msr

   \ The RAM controller is now set up

 \ Init the SDRAMs
 \ sdram_enable,src/northbridge/amd/gx2/raminit.c

   \ Clock gating for PMode
   \ Clocks always on in mode 1, hardware gating in mode 0
\   20002004 rmsr  4 bitclr  1 bitset  20002004 wmsr  \ GX p 199
   1. 20002004 set-msr  \ GX p 199

   \ Delay on exit from power mode 1, use unbuffered RAM
   101. 2000001a set-msr    \ MC_CF1017_DATA GX p 210

   \ Unmask CKE1 and CKE0
   0. 2000001d set-msr   \ MC_CFCLK_DBG Clear 300 bits

   \ load RDSYNC
   \ Empirically, the recommended setting of 0xff310.00000000. causes RAM errors
   00000310.00000000.   2000001f set-msr  \ GX page 215

   \ set delay control.  The exact value below is specified in the GX manual.
   830d415a.8ea0ad6a.   4c00000f set-msr
