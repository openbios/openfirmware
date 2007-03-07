\ See license at end of file
purpose: Create an ELF format 

create elf-header
  h# 7f c,  char E c,  char L c,  char F c,
  1            c,  \ 4 
  1            c,  \ 5
  1            c,  \ 6
  0            c,  \ 7
  0            l,  \ 8
  0            l,  \ 0x0c
  2            w,  \ 0x10 object file type ET_EXEC
  3            w,  \ 0x12 architecture EM_386
  1            l,  \ 0x14 object file version EV_CURRENT

  \ Skip this ELF dropin (80) + the OBMD header of the next dropin (20)
[ifdef] etherboot-variant
   \ elf-header is not a dropin, so we only need to skip OBMD header of reset
   \ we adjust the load-address below at position 0x40
  dropin-base  h# 20 +  l,  \ 0x18 entry point virtual address
[else]
   \ Skip this ELF dropin (80) + the OBMD header of the next dropin (20)
  dropin-base  h# 80 + h# 20 +  l,  \ 0x18 entry point virtual address
[then]
  h# 34        l,  \ 0x1c program header file offset
  0            l,  \ 0x20 section header file offset
  0            l,  \ 0x24 flags
  h# 34        w,  \ 0x28 ELF header size
  h# 20        w,  \ 0x2a program header table entry size
[ifdef] grub-loaded
  1            w,  \ 0x2c program header table entry count (one pheader)
[else]
  0            w,  \ 0x2c program header table entry count (no pheaders)
[then]
  0            w,  \ 0x2e section header table entry size
  0            w,  \ 0x30 section header table entry count
  0            w,  \ 0x32 section header string table index

[ifdef] grub-loaded  \ Pheader causes GRUB to copy us to RAM
  \ 0x34  Pheader
  1            l,  \ 0x34 entry type PT_LOAD
  h# 54        l,  \ 0x38 file offset
  0            l,  \ 0x3c vaddr
[ifdef] etherboot-variant
   \ we need to skip what left of elf-hdr. to get it to point to a dropin
   \ why is it 0x14 ?  I would have thought it should be the size of the multiboot header
   \ which is 0x0c
  dropin-base  h# 14 - l,  \ 0x40 paddr         \ Where to put the bits
[else]
  dropin-base  l,  \ 0x40 paddr         \ Where to put the bits
[then]
  h# ffffffff  l,  \ 0x44 file size     \ backpatched later
  h# ffffffff  l,  \ 0x48 memory size   \ backpatched later
  0            l,
  0            l,
  7            l,  \ 0x4c entry flags RWX
  0            l,  \ 0x50 alignment
                   \ 0x54 End of pheader

  \ "Multiboot" header that GRUB looks for
  h# 1BADB002 ,         \ 0x54
  h#        0 ,         \ 0x58
  h# 1BADB002 negate ,  \ 0x5c
                        \ 0x60 End 
[then]

[ifdef] linuxbios-loaded
  \ Pad out to h# 60 so the size is the same as above
  here  h# 60 h# 34 -  dup allot  erase
[then]

  \ The total size, including the dropin header, will be h# 80 
here elf-header -  constant /elf-header

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
