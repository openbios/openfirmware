\ See license at end of file
purpose: Create an ELF format 

\ This handles several different loader cases

0 value #pheaders
0 value elf-entry
0 value file-offset
0 value elf-addr

[ifdef] grub-loaded
\ For GRUB, we want to copy the stuff after the ELF headers and the Multiboot
\ header to the final RAM location (dropin-base), so OFW sees just the dropins.
\ The start address is just after the first dropin header.

dropin-base  h# 20 + to elf-entry   \ Skip OBMD header in RAM copy
1 to #pheaders                      \ The pheader causes the image to be copied to RAM
h# 54 h# 0c +  to file-offset       \ Copy start after pheader + multiboot header (0c)
dropin-base to elf-addr             \ Copy file image directly to dropin-base
[then]

[ifdef] coreboot-loaded
  [ifdef] coreboot-qemu
    \ For coreboot under QEMU, we want to copy everything, including the ELF headers.
    \ We want the ELF headers to be in memory, but Forth shouldn't see them, so we
    \ put the headers before dropin-base

    dropin-base h# 20 +  to elf-entry  \ Skip OBMD header in RAM copy
    1 to #pheaders                     \ The pheader causes the image to be copied to RAM
    0 to file-offset                   \ Copy the whole thing, don't skip the ELF headers
    dropin-base h# 80 - to elf-addr    \ Copied headers will precede dropin-base
  [else]
    \ For coreboot running from ROM, we can leave everything in ROM, no need to copy,
    \ so there's no need for a pheader.

    dropin-base  h# 80 + h# 20 +  to elf-entry  \ Entry is after ELF + OBMD headers
    0 to #pheaders                     \ No pheaders; we'll use the ROM copy of the dropins
  [then]
[then]

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
  elf-entry    l,  \ 0x18 entry point virtual address
  h# 34        l,  \ 0x1c program header file offset
  0            l,  \ 0x20 section header file offset
  0            l,  \ 0x24 flags
  h# 34        w,  \ 0x28 ELF header size
  h# 20        w,  \ 0x2a program header table entry size
  #pheaders    w,  \ 0x2c program header table entry count (one pheader)
  0            w,  \ 0x2e section header table entry size
  0            w,  \ 0x30 section header table entry count
  0            w,  \ 0x32 section header string table index

#pheaders [if]
  1             l,  \ 0x34 entry type PT_LOAD
  file-offset   l,  \ 0x38 file offset
  elf-addr      l,  \ 0x3c vaddr
  elf-addr      l,  \ 0x40 paddr - where to put the bits
  h# ffffffff   l,  \ 0x44 file size   - backpatched later
  h# ffffffff   l,  \ 0x48 memory size - backpatched later
  7             l,  \ 0x4c entry flags RWX
  0             l,  \ 0x50 alignment
                    \ 0x54 End of pheader
[else]
  here  h# 54 h# 34 -  dup allot  erase  \ Pad to make the size consistent
[then]

[ifdef] grub-loaded 
  \ "Multiboot" header that GRUB looks for
  h# 1BADB002 ,         \ 0x54 signature
  h#        0 ,         \ 0x58 flags
  h# 1BADB002 negate ,  \ 0x5c checksum: -(signature + flags)
                        \ 0x60 End 
[else]
  here  h# 60 h# 54 -  dup allot  erase  \ Pad to make the size consistent
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
