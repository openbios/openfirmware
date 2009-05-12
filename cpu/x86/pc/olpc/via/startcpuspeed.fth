   h# 10000 h# 1a0 bitset-msr   \ Enable performance state changes
   h# 198 rmsr                  \ Get performance state info - min.max in %edx, current in %eax
   ax ax xor  op: dx ax mov     \ MSR.low for new performance state - from max field in %edx
   dx dx xor                    \ MSR.high = 0
   h# 199 wmsr                  \ We should start going faster now
