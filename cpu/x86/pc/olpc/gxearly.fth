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
   20000000.000fff80.  10000020 set-msr  \ memory - 0..7ffff
   20000000.080fffe0.  10000026 set-msr  \ memory - 80000..9ffff (a0000..bffff is for VGA)
   20000000.0c0fffc0.  10000027 set-msr  \ memory - c0000..fffff
   ffbff000.ff800100.      1817 set-msr  \ Region config - OFW area cacheable

   1030 port-rl 4 bitand  0<> if  \ 128 MiB
      25fff002.10780000.      1808 set-msr
      20000007.7ff00100.  10000028 set-msr \ Range - Top of memory at 07ff.ffff, fbsize
      20a800fd.7fffd000.  10000029 set-msr \ Range Offset - Frame buffer at PA fd00.0000 maps to RAM at 0780.0000, fbsize
      207c00ff.bffff800.  1000002b set-msr \ Range Offset - OFW area ff80.0000 maps to RAM at 0740.0000, fbsize
      10075012.00003400.  20000018 set-msr \ Refresh/SDRAM - DIMM 0 size 128 MB
      20000007.7ff00100.  40000029 set-msr \ Top of memory for DMA  - 77ff.0000, fbsize
      077ff000.00100130.  50002019 set-msr \ Memory Region 1 config - top at 77ff.0000, PF, WC, fbsize
   else                           \ 256 MiB
      25fff002.10f80000.      1808 set-msr
      2000000f.7ff00100.  10000028 set-msr \ Range - Top of memory at 0fff.ffff, fbsize
      212800fd.7fffd000.  10000029 set-msr \ Range Offset - Frame buffer at PA fd00.0000 maps to RAM at 0f80.0000, fbsize
      20fc00ff.bffff800.  1000002b set-msr \ Range Offset - OFW area ff80.0000 maps to RAM at 0f40.0000, fbsize
      10076013.00003400.  20000018 set-msr \ Refresh/SDRAM - DIMM 0 size 128 MB
      2000000f.7ff00100.  40000029 set-msr \ Top of memory for DMA  - f7ff.0000, fbsize
      0f7ff000.00100130.  50002019 set-msr \ Memory Region 1 config - top at f7ff.0000, PF, WC, fbsize
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
