   \ Determine the top of usable memory.
   \ Start with the bottom address of the area used for the frame buffer.

   bx bx xor
   h# 6d h# 3c4 port-wb  h# 3c5 port-rb  al bl mov  \ Sequencer register 6d
   h# 6e h# 3c4 port-wb  h# 3c5 port-rb  al bh mov  \ Sequencer register 6e
   d# 21 # bx shl
   \ There are some higher bits in 6f but we only support 32-bit addresses

   \ Then subtract the top SMM memory size, if it is enabled
   h# 386 config-rb
   4 # ax test  0<>  if
      6 # ax shr           \ Top SMM memory size field
      ax cx mov            \ Move to cx
      h# 10.0000 # ax mov  \ Field==0 means 1M
      ax cl shl            \ Now ax contains SMM memory size
      ax bx sub            \ Adjust bx
   then

   bx  mem-info-pa 4 + #) mov   \ Top of memory

\   bx di mov
\   h# 800.0000 # di sub         \ Clear the last 128 MB
\   h# 800.0000 4 / # cx mov     \ Longword count
\   cld
\   ax ax xor
\   rep  ax stos
