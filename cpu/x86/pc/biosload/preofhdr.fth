\ See license at end of file
purpose: Create header for starting Forth from preOF, 32-bit protected mode

command: &builder &this
build-now

\needs start-assembling  fload ${BP}/cpu/x86/asmtools.fth

hex

start-assembling

label preof-hdr

\ This code begins execution in 32-bit mode.

[ifdef] ramsize
   ramsize #  mem-info-pa 1 la+ #)  mov
   0 #  mem-info-pa 2 la+ #)  mov
[then]
   ResetBase # ax mov
   ax jmp
   h# 20 pad-to
end-code

end-assembling
here preof-hdr -  constant /preof-hdr
