\ This is some glue code to convert the machine setup that QEMU gives us
\ to the setup that start-forth (see arm/boot.fth) wants.
\ We get here via a call instruction at origin+8, which is inserted below

code stand-cold-code    ( r0: 0  r1: board-id  r2: &kernel-args  lr: &aif_header+8c )
   here  origin 8 +  put-call  \ Insert call instruction

   \ Put the arguments in safe registers
   sub   r6,lr,#0x8c        \ r6 points to header (lr set by code at origin)
   mov   r7,#0              \ r7: functions
   add   r8,r6,`/fw-ram`    \ r8: memtop - 2MiB above load address
                            \ r9 is up
   mov   r10,#0             \ r10: argc
   mov   r11,r2             \ r11: argv (kernel args)
   mov   r12,`initial-heap-size`  \ r12: initial-heap-size

   b     'code start-forth  \ Branch to the generic startup code
end-code
