   fb-pci-base  810 config-wl  \ S.L. Base address
   gfx-pci-base 814 config-wl  \ MMIO Base address

[ifdef] notdef
   \ Determine the frame buffer size from the register that controls
   \ the GFX base address register size bits
   8b2 config-rb  \ Mask bits in al
   h# 80 al or    \ Insert high mask bit which isn't implemented
   d# 24 # ax shl \ Move bits up so they can be sign-extended down
   d# 2  # ax sar \ Shift into place with sign extension
   ax not         \ invert bitmask
   ax inc         \ Frame buffer size now in ax

   \ Now convert it to the log2 of the size, starting at 4M
   bx bx xor             \ Initial value
   h# 40.0000 # cx mov   \ Test size
   begin
      cx ax test
   0= while
      bx inc
      1 # cx shl         \ Bump test size by a factor of 2
   repeat

   \ bx now contains the code that goes in bits 14:12 of D0F3 a0-a1

   d# 12 # bx shl        \ Move it into place
   h# 8d01 # bx or       \ Set GFX enable (8000), Framebuf enable (1), and Address (d000.0000 shifted)
   h# 3a0 config-setup  bx ax mov  op: ax dx out  \ Stuff it in the register
[then]

   h# 3a0 config-rw      \ Get old value of config reg 3a0.w  (D0F3 RxA0)
   h# ffe invert #  ax  and              \ Clear Frame Buffer Address bits
   fb-pci-base d# 20 rshift #  ax  or    \ Insert new value
   ax bx mov
   h# 3a0 config-setup  bx ax mov  op: ax dx out  \ Stuff it in the register   

\       cd01 3a0 config-ww  \ Set frame buffer size and CPU-relative address and enable
