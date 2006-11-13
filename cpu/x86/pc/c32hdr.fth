\ See license at end of file
purpose: Create header for starting Forth from 32-bit protected mode

command: &builder &this
build-now

\needs start-assembling  fload ${BP}/cpu/x86/asmtools.fth

hex
\ This is appropriate for SYSLINUX/ISOLINUX's .C32 format

start-assembling

\ This code begins execution in 32-bit mode.
\ Its main purpose is to skip past the "reset" module's dropin header,
\ to the beginning of that module's code.
\ It also contains a multiboot header so GRUB will recognize it.

label c32-hdr
   \ This will be loaded at h# 10.1000
   h# 21cd4cff # ax mov  \ COM32 signature
   h# 1000 #     bx mov  \ mem-info-pa address
   sp  4 [bx]  mov       \ Save memory size
   bx  8 [bx]  mov       \ Area below DOS hole

   cld
   h# 10.1040       #  si  mov     \ Address of next module
   dropin-base      #  di  mov     \ Destination of copy
   dropin-size 4 /  #  cx  mov     \ Longwords to copy
   rep movs

   dropin-base h# 20 + #  ax  mov  \ Jump past the dropin header
   ax call

   \ Signature is h# c bytes, so padding makes end at h# 40
   h# 34 pad-to
   h# 1BADB002        ,  \ Multiboot magic number
   h#        0        ,  \ Multiboot flags
   h# 1BADB002 negate ,  \ Multiboot checksum
   \ This will end up at offset h# 40, absolute h# 10.1060
end-code

end-assembling
here c32-hdr -  constant /c32-hdr
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
