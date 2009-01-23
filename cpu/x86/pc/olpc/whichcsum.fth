\ This is a diagnostic used when checksum-test is enabled in resume.bth
\ Usage: which-all .s   (ignore the first two numbers)
code which-all  ( -- .. )
   si push  di push  sp dx mov
   \ Checksum memory from 1M to top (excluding framebuffer)
   h# 0010.0000 #  si  mov
   resume-data h# 10 - #)  di  mov   \ Save checksum base address
   begin
      bx bx xor
      h# 10.0000 2 rshift #  cx  mov  \ Word count for 1MB
      begin  ax lods  ax bx add  loopa
      ax  0 [di]  cmp
      <>  if
         si push
      then   
      4 [di]  di  lea
    \  h# ec0.0000 # si cmp
      h# 300.0000 # si cmp
   = until
   0 [dx] di mov  4 [dx] si mov
c;
