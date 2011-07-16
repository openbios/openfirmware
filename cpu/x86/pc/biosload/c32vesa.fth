purpose: Call VESA BIOS functions via syslinux c32 callback

\ [ifdef] notdef-get-com32-ptr
   sp  0 #)  mov  \ Save COM32 stack pointer for possible later use
\ [then]
[ifdef] notdef-getvbe
   \ There is an extra return address on the stack from the e9 call above
   d# 16 [sp]  bp  mov  \ COM32 intcall helper function
   d# 20 [sp]  dx  mov  \ bounce buffer address

   h# 4f00 #  d# 36 [dx]  mov  \ AX

   dx ax mov
   h# 200 # ax add
   h# 32454256 #  0 [ax] mov   \ VBE2

   op: ax  d# 08 [dx]  mov     \ DI - result pointer offset
   d# 16 # ax shr              \ Discard lower 16 bits
   d# 12 # ax shl              \ Shift segment into place
   op: ax  d# 04 [dx]  mov     \ ES - result pointer segment

   dx push  dx push  h# 10 # push  bp call  d# 12 # sp add
   d# 36 [dx]  ax mov  ax 4 #) mov \ AX   
[then]

[ifdef] notdef-findmode
   \ Registers:
   \ edx: pointer to register array for calling the gateway function
   \ ebp: address of gateway function
   \ ecx: pointer to result array
   \ esi: moving pointer to mode number array
   \ eax: scratch

   \ There is an extra return address on the stack from the e9 call above
   d# 16 [sp]  bp  mov  \ COM32 intcall helper function
   d# 20 [sp]  dx  mov  \ bounce buffer address

   dx push  dx push  h# 10 # push

   h# 4f00 #  d# 36 [dx]  mov  \ AX

   dx cx mov
   h# 100 # cx add             \ ecx: pointer to result buffer

   h# 32454256 #  0 [cx] mov   \ 'VBE2' to signature field of result buffer - probably unnecessary (we don't need the OEM string)

   cx ax mov
   op: ax  d# 08 [dx]  mov     \ DI - result pointer offset
   d# 16 # ax shr              \ Discard lower 16 bits
   d# 12 # ax shl              \ Shift segment into place
   op: ax  d# 04 [dx]  mov     \ ES - result pointer segment

   bp call

   \ Extract the mode list pointer and convert it to a linear address
   si si xor
   op: h# 10 [cx]  si  mov     \ Segment portion of mode list pointer
   4 # si shl                  \ Move into position
   ax ax xor
   op: h# 0e [cx]  ax  mov     \ Offset portion of mode list pointer
   ax si add                   \ esi: Linear address of mode list pointer

   \ Get a new result buffer so as not to overwrite the mode list
   h# 100 # cx add
   cx ax mov
   op: ax  d# 08 [dx]  mov     \ DI - result pointer offset
   d# 16 # ax shr              \ Discard lower 16 bits
   d# 12 # ax shl              \ Shift segment into place
   op: ax  d# 04 [dx]  mov     \ ES - result pointer segment

   h# 0 # ax mov  ax 8 #) mov  \ Clear the output value

   begin
      op: ax lods              \ Get mode number
      op: h# ffff # ax cmp
   <> while                    \ Exit if all modes have been tested
      op: ax  d# 32 [dx]  mov  \ CX - Mode number
      op: ax bx mov

      h# 4f01 #  d# 36 [dx]  mov  \ AX - GetMode function number
      bp call

      op: 0 [cx]  ax mov       \ Mode attributes
      1 # al test  0<>  if     \ Is the mode supported?
         h# 12 [cx]  ax mov    \ Yres.Xres
         TARGET_RES #  ax  cmp  =  if
            h# 19 [cx]  al mov \ BPP
            TARGET_BPP # al cmp  =  if
               op: bx  8 #) mov        \ Mode number
               op: h# 10 [cx]  ax mov
               op: ax  h# a #)  mov    \ Stride
            then
         then
      then
   repeat
   d# 12 # sp add
[then]

[ifdef] notdef-modemap
   \ Registers:
   \ edx: pointer to register array for calling the gateway function
   \ ebp: address of gateway function
   \ ecx: pointer to result array
   \ esi: moving pointer to mode number array
   \ eax: scratch
   \ ebx: output pointer

   \ There is an extra return address on the stack from the e9 call above
   d# 16 [sp]  bp  mov  \ COM32 intcall helper function
   d# 20 [sp]  dx  mov  \ bounce buffer address

   dx push  dx push  h# 10 # push

   h# 4f00 #  d# 36 [dx]  mov  \ AX

   dx cx mov
   h# 100 # cx add             \ ecx: pointer to result buffer

   h# 32454256 #  0 [cx] mov   \ 'VBE2' to signature field of result buffer - probably unnecessary (we don't need the OEM string)

   cx ax mov
   op: ax  d# 08 [dx]  mov     \ DI - result pointer offset
   d# 16 # ax shr              \ Discard lower 16 bits
   d# 12 # ax shl              \ Shift segment into place
   op: ax  d# 04 [dx]  mov     \ ES - result pointer segment

   bp call

   \ Extract the mode list pointer and convert it to a linear address
   si si xor
   op: h# 10 [cx]  si  mov     \ Segment portion of mode list pointer
   4 # si shl                  \ Move into position
   ax ax xor
   op: h# 0e [cx]  ax  mov     \ Offset portion of mode list pointer
   ax si add                   \ esi: Linear address of mode list pointer

   \ Get a new result buffer so as not to overwrite the mode list
   h# 100 # cx add
   cx ax mov
   op: ax  d# 08 [dx]  mov     \ DI - result pointer offset
   d# 16 # ax shr              \ Discard lower 16 bits
   d# 12 # ax shl              \ Shift segment into place
   op: ax  d# 04 [dx]  mov     \ ES - result pointer segment

   h# 40300 # bx mov

   begin
      op: ax lods              \ Get mode number
      op: ax 0 [bx] mov
      op: h# ffff # ax cmp
   <> while                    \ Exit if all modes have been tested
      op: ax  d# 32 [dx]  mov  \ CX - Mode number

      h# 4f01 #  d# 36 [dx]  mov  \ AX - GetMode function number
      bp call

      h# 12 [cx]  ax mov  ax 2 [bx] mov     \ Yres.Xres
      ax ax xor
      h# 19 [cx] al mov  op: ax 6 [bx] mov  \ BPP
      op: h# 10 [cx] ax mov  op: ax 8 [bx]  mov    \ Stride
      ax ax xor
      op: ax h# a [bx] mov  ax h# c [bx]  mov      \ Clear trailing
      h# 10 # bx add
   repeat
   d# 12 # sp add
[then]

[ifdef] notdef-setmode
   \ There is an extra return address on the stack from the e9 call above
   d# 16 [sp]  bp  mov  \ COM32 intcall helper function
   d# 20 [sp]  dx  mov  \ bounce buffer address

   dx push  dx push  h# 10 # push

   dx cx mov
   h# 100 # cx add             \ ecx: pointer to result buffer

   cx ax mov
   op: ax  d# 08 [dx]  mov     \ DI - result pointer offset
   d# 16 # ax shr              \ Discard lower 16 bits
   d# 12 # ax shl              \ Shift segment into place
   op: ax  d# 04 [dx]  mov     \ ES - result pointer segment

   h# 4f01 #  d# 36 [dx]  mov  \ AX - GetMode function number
   h# 0117 #  d# 32 [dx]  mov  \ CX - Mode number
   bp call

   h# 28 [cx] ax mov   ax 0 #) mov                 \ Frame buffer address
   ax ax xor  op: h# 10 [cx] ax mov   ax 4 #) mov  \ Stride

   h# 4f02 #  d# 36 [dx]  mov  \ AX
   h# c117 #  d# 24 [dx]  mov  \ BX  1024x768x16 linear

   bp call

   d# 12 # sp  add
[then]

\ VESA modes:
\  RESv  BPP> 4     8    15   16   24
\  320x200              10d  10e  10f
\  640x400        100
\  640x480        101   110  111  112
\  800x600  102   103   113  114  115
\ 1024x768  104   105   116  117  118
\ 1280x1024 106   107   119  11a  11b
