\ Included from romreset.bth - early core MSR setup for the Geode LX

   \ The next few MSRs allow us to access the 5536
   \ EXTMSR - page 449   \ Use PCI device #F for port 2
   00000000.00000f00.   5000201e set-msr  \ cs5536_setup_extmsr(void)

   \ write IDSEL to the write once register at address 0x0000
   \ 02000000 0 port-wl  \ This is the default value so we need not set it

   \ setup CPU interface serial to mode C on both sides
   44000020.00200013. 51000010 set-msr   \ 5536 p 229

   \ Set up GPIO base register
   0000f001.00001000.   5140000c set-msr  \ GPIO BAR

 \ Init UART
[ifndef] lx-devel
fload ${BP}/cpu/x86/pc/olpc/inituart.fth
[then]  \ lx-devel

   h# 11 # al mov  al h# 80 # out
   h# 1430 # dx mov  dx ax in  h# 9999 # ax cmp  =  if
      h# 34 #  al mov    al  h# 70 #  out   \ Write to CMOS 0x34
      h# 11 #  al mov    al  h# 71 #  out   \ Write value 0x11
   then

 \ Init memory controller

   \ sdram_initialize,generic_sdram.c
   \ sdram_set_spdregisters(),auto.c
 
   \ The LX devel board has only 512M ROM, but assigning 1M of address space is harmless
   25fff002.10f00000.      1808 set-msr  \ 1M ROM at fff0.0000, system RAM limit at 0f00.0000, fbsize
   2000000e.fff00100.  10000028 set-msr  \ Range - Top of memory at 0eff.ffff, fbsize
   212000fd.ffffd000.  10000029 set-msr  \ Range Offset - Frame buffer at PA fd00.0000 maps to RAM at 0f00.0000, fbsize
   20f400ff.bffff800.  1000002b set-msr  \ Range Offset - OFW area ff80.0000 maps to RAM at 0ec0.0000, fbsize
   ffbff000.ff800100.      1817 set-msr  \ Region config - OFW area cacheable
   10076013.00005040.  20000018 set-msr  \ DIMM1 empty, DIMM0 256 MB, 1 module bank, 8K pages
   2000000e.fff00100.  4000002c set-msr  \ DMA to memory from 1M to RAM limit at 0f00.0000
   0efff000.00100130.  50002019 set-msr  \ PCI DMA to memory from 1M to RAM limit at 0f00.0000, fbsize

   \ 20000019 rmsr            \ SDRAM timing and mode program
   00000000.2814d352.   00001981 set-msr  \ Memory delay values
   00000000.1068334d.   00001982 set-msr  \ Memory delay values
   00000106.83104104.   00001983 set-msr  \ Memory delay values
   00000000.00000001.   00001980 set-msr  \ Enable memory delays

[ifdef] cmos-startup-control
   h# 61 #  al mov    al  h# 70 #  out   h# 71 #  al in  \ Read CMOS 0x61
   al al test  0= if
[then]
      18000100.6a7332a0.   20000019 set-msr

      \ The RAM controller is now set up

    \ Init the SDRAMs
    \ sdram_enable,src/northbridge/amd/gx2/raminit.c

      \ Clock gating for PMode
      \ Clocks always on in mode 1, hardware gating in mode 0
  \   20002004 rmsr  4 bitclr  1 bitset  20002004 wmsr  \ GX p 199
      1. 20002004 set-msr  \ GX p 199

      \ Delay on exit from power mode 1, use unbuffered RAM
      130cd801. 2000001a set-msr    \ MC_CF1017_DATA  LX p 231
[ifdef] cmos-startup-control
   else
      al dec  al h# 71 # out            \ Decrement safety counter

      h# 64 # al mov  al h# 70 # out  h# 71 # al in   al bl mov
      h# 65 # al mov  al h# 70 # out  h# 71 # al in   al bh mov
      d# 16 # bx shl
      h# 62 # al mov  al h# 70 # out  h# 71 # al in   al bl mov
      h# 63 # al mov  al h# 70 # out  h# 71 # al in   al bh mov
      
      h# 18000100 # dx mov  bx ax mov  h# 20000019 wmsr

      \ The RAM controller is now set up

    \ Init the SDRAMs
    \ sdram_enable,src/northbridge/amd/gx2/raminit.c

      \ Clock gating for PMode
      \ Clocks always on in mode 1, hardware gating in mode 0
  \   20002004 rmsr  4 bitclr  1 bitset  20002004 wmsr  \ GX p 199
      1. 20002004 set-msr  \ GX p 199

      \ Delay on exit from power mode 1, use unbuffered RAM
      h# 68 # al mov  al h# 70 # out  h# 71 # al in   al bl mov
      h# 69 # al mov  al h# 70 # out  h# 71 # al in   al bh mov
      d# 16 # bx shl
      h# 66 # al mov  al h# 70 # out  h# 71 # al in   al bl mov
      h# 67 # al mov  al h# 70 # out  h# 71 # al in   al bh mov

      dx dx xor  bx ax mov  2000001a wmsr    \ MC_CF1017_DATA  LX p 231
   then
[then]

   00000200.00000000. 20000020 set-msr   \ Power mode entry and exit delays

   \ Unmask CKE1 and CKE0
   1000. 2000001d set-msr   \ MC_CFCLK_DBG Clear 300 bits, don't tristate in IDLE

   \ Reset memory controller
   20000018 rmsr    \ MC_CF07_DATA
   2 bitset  20000018 wmsr
   2 bitclr  20000018 wmsr
