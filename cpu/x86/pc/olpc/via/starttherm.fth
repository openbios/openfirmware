\ Undocumented:
\ MSR 1107 bit 20 - Enable APIC ????
\ MSR 116a bits 1:0 - Enable thermal monitor - MSR is not even mentioned except in code
\ Error in description of MSR 19d - TM2 clock ratio called out as bits 15:0, should be 15:8
\ MSR 1152, 1164, 1165, 1166, 1167, 1168, 116a, 116b *completely undocumented* - just used in code
\ (MSR 1167 is briefly mentioned in text, but the reference in text fails to mention the processors
\   to which it applies (which can sort of be inferred by the code)
\ MSR 1141 bit 22 alternate sense used in code, listed as reserved in MSR table


   h# 011.0400 h#  1a0 bitset-msr   \ Turn on powersaver (bit 16) and lock it on (bit 20),
                                    \ Also turn on Pending Break Enable (bit 10) for APIC wakeup
                                    \ The VIA thermal code doesn't turn on bit 10
   h# 100.0000 h# 1107 bitset-msr   \ Enable APIC (from Via thermal code; bit not documented)
   h#       03 h# 116a bitclr-msr   \ Disable monitor

   h# 1140 rmsr  ax ax or  0=  if   \ If no factory-configured inflection ratio,
      dx bx mov                     \ Save high dword in BX
      h# 198 rmsr
      h# ff00.0000 # dx and         \ Min ratio
      dx ax mov                     \ Move to low dword for MSR 1140
      bx dx mov                     \ Restore high dword
      h# 1140 wmsr
   then

   \ Check for Overstress VID
   h# 1140 rmsr
   h# 7f # ax and   0<> if          \ Fused Overstress VID bits - if nonzero, CPU is C7-D+
      h# 80 h# 1142 bitset-msr      \ Turn on down-style iteration
   else                             \ CPU is Eden, C7, C7-M, or C7-D
      h# 1154 rmsr                  \ Get C5R branding bits
      2 # ax shr                    \ Move bits 5:2 down to 0
      al ah mov                     \ Save a copy
      2 # ah shr                    \ Move bits 5:4 down to 0
      ah al xor                     \ XOR bits 5:4 with bits 3:2
      3 # al and                    \ Discard other bits
      0<>  if                       \ If nonzero, CPU is C7 (1), Eden (2), or C7-D (3)
         h# 100 h# 1142 bitclr-msr  \ Turn off up-style iteration
      else                          \ If zero, CPU is C7-M
         h#  80 h# 1142 bitset-msr  \ Turn on down-style iteration
      then
   then
   
   \ Go to the minimum ratio
   h# 198 rmsr                     \ Get performance state info - min.max in %edx, current in %eax
   dx ax mov                       \ Get ratios into EAX
   d# 16 # ax shr                  \ Select minimum ratio
   dx dx xor                       \ MSR.high = 0
   h# 199 wmsr                     \ We should be going slow now

   ax bx mov                       \ Save a copy of the minimum ratio value.  BX: MinFreq.MinVoltage

   h# 1140 rmsr
   d# 16 # ax shr
   h# 3f # ah and                  \ Inflection ratio in AH -> TM2 clock ratio
   bl al mov                       \ Merge in low byte from BL -> TM2 voltage
   0=  if                          \ If inflection ratio is 0
      bx ax mov                    \ Then use min FID/VID
   then
   h# 19d wmsr                     \ Set TM2 value

   \ H: Init Model D Thermal Monitor
   h# 1152 rmsr
   dx not                          \ Inverted value is 18d34c60 AOOO.OOOO.OOOO.RRRR.RRRR.RRRT.THHH.????
                                   \ A: Alternate Sense, O: Offset, R: Resolution, T: Trip=125-T*4, H: High=70+H*5 
   dx bx mov                       \ BX: 18d34c60
   9 # dx shr                      
   h# 7ff # dx and                 \ Resolution - 1a6 (decimal 422)
   ax ax xor
   dx ax xchg
   h# 116b wmsr                    \ MSR value is 00000000.000001a6

   bx ax mov                       \ 18d34c60, from ~MSR1152.hi
   d# 20 # ax shr
   h# 7ff # ax and                 \ Offset - 18d (decimal 397)
   h# 1168 wmsr                    \ MSR value is 00000000.0000018d

   bx cx mov                       \ BX: 18d34c60
   7 # cx shr
   3 # cx and                      \ Value is 0
   d# 125 # ax mov
   2 # cx shl
   cx ax sub                       \ Value is 125
   h# 1166 wmsr                    \ Thermal trip temperature - (decimal) 125

   bx dx mov                       \ Copy of fuse values
   4 # dx shr                      \ [38:36]*5 + 70 = high threshold 
   7 # dx and                      \ Value is 6
   dx cx mov                       \ Copy of bits [38:36]
   2 # cx shl                      \ Multiply by 4
   cx dx add                       \ Add to give *5  (6*5 => 30)
   d# 70 # dx add                  \ Result is (decimal) 100
   dx ax mov
   dx dx xor
   h# 1165 wmsr                    \ High threshold - (decimal) 100

   5 # ax sub
   h# 1164 wmsr                    \ Low threshold - (decimal) 95

   h# 1141 rmsr
   h# 8000.0000 # bx and           \ Alternate sense bit
   9 # bx shr                      \ Move into position for MSR 1141 at bit 22
   h# 0400.0000 invert # ax and    \ Clear alt sense bit in MSR value
   bx ax or                        \ Merge in new value
   wrmsr

   h# 00.0003 h# 116a bitset-msr   \ N: Re-enable monitor

   1 # ax mov
   cpuid
   h# 180 # cx and  0=  if         \ Enhanced power saver bit (100) or TM2 bit (80)
      8 h# 1a0 bitset-msr          \ Use TM1
   else
      h# 03.0000 h# 1141 bitset-msr \ Enable TM2
      h# 1140 rmsr
      h# 7f # ax and  0<>  if      \ Fused Overstress VID
         h# 01.0000 h# 1141 bitclr-msr \ Enable TM3
      else
         h# 1154 rmsr
         2 # ax shr
         al ah mov
         2 # ah shr
         ah al xor
         3 # al and  0=  if        \ 0 means C7-M
            h# 01.0000 h# 1141 bitclr-msr \ Enable TM3
         then
      then
      h# 1140 rmsr
      h# 00f0.0000 # ax and
      0<>  if                      \ Parallax support?
         h# 0000.4000 h# 1141 bitset-msr  \ Enable parallax
      then
   then

   h# 1107 rmsr                    \ Enable catastropic thermal protection
   h# 40.0000 bitset-hi            \ Bit 54
   wrmsr
