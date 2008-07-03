\ Call VESA BIOS from a syslinux-loaded ".c32" image
\ COM32 arguments are at 0 @ 4 +

code vesa-mode  ( mode# -- )
   cx pop

   si push  di push  bp push
   0 #)  ax mov  \ Pointer to COM32 args
   d# 16 [ax]  bx  mov  \ COM32 intcall helper function
   d# 20 [ax]  dx  mov  \ bounce buffer address

   4f02 #  d# 36 [dx]  mov  \ AX
   cx      d# 24 [dx]  mov  \ BX

   \ dx push
   0 # push
   dx push
   h# 10 # push

   bx call
   ax pop  ax pop  ax pop

   bp pop  di pop  si pop
c;
