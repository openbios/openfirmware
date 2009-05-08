\ See license at end of file
purpose: Common code for several versions of reset.bth

   \ The memory layout information from the start dropin is stored in low
   \ memory.

   \ Beginning of "switch to new GDT" section

   \ Move GDT to low memory.  We use the first location at gdt-pa as
   \ the pointer since 0 is an invalid descriptor number anyway.
   gdt-pa # ax mov
   0 [ax] sgdt				\ Read GDT
   2 [ax] si mov			\ GDT base
   0 [ax] cx mov			\ GDT limit
   ffff # cx and
   cx inc

   gdt-pa # di mov			\ New GDT base
   rep movsb				\ Copy ROM GDT to RAM

   \ Move the code and data descriptors to 60,68
   gdt-pa h# 60 + #   di  mov		\ Destination - New descriptor 0x60

   cs si mov  2 [ax]  si add		\ Source - Current code descriptor
   movs movs                            \ 2 longwords (1 descriptor) -> 60

   ds si mov  2 [ax]  si add		\ Source - Current data descriptor
   movs movs                            \ 2 longwords (1 descriptor) -> 68

   op: gdt-size 1- #   0 [ax]  mov      \ New GDT size
   gdt-pa #  2 [ax]  mov		\ New GDT base
   0 [ax] lgdt				\ Setup RAM GDT

   \ Reload code segment descriptor from new table
   here asm-base - ResetBase +  7 +   h# 60  #)  far jmp  \ 7-byte instruction

   \ Reload data segment descriptors from new table
   h# 68 # ax mov
   ax ds  mov
   ax es  mov
   ax fs  mov
   ax gs  mov
   ax ss  mov

   h# 20 # al mov  al h# 80 # out

   \ End of "switch to new GDT" section

[ifdef] mem-info-pa
   gdt-pa /page round-up #  ax  mov	\ Current low-memory high water mark
   ax     mem-info-pa 2 la+ #)  mov	\ Store in memory info area
[then]

   cld

ascii t report

   ds ax mov  ax es mov
   h# 21 # al mov  al h# 80 # out

[ifdef]  virtual-mode
   " paging" $find-dropin,  \ Assemble call to find-dropin with literal arg

   4 [ax]          cx  mov	\ Length of paging init code (byte-swapped)
   cx                  bswap	\ cx: Length of paging init code
   d# 32 [ax]      si  lea	\ si: Base address of paging init code in ROM
   inflate-base #  di  mov	\ di: RAM address to copy it to

   cld  rep byte movs   	\ Copy the code to RAM

   inflate-base #  ax  mov      \ Absolute address of memory copy
   ax call
[then]

   h# 22 # al mov  al h# 80 # out
   " firmware" $find-dropin,  \ Assemble call to find-dropin with literal arg

   long-offsets on
   d# 12 [ax]  bx  mov		\ "Expanded size" field
   0 #  bx  cmp
   <> if
      \ The firmware dropin is compressed, so we load the inflater into RAM
      \ and use it to inflate the firmware into RAM
      ax  push			\ Save address of firmware dropin

ascii h report

      h# 23 # al mov  al h# 80 # out
      " inflate" $find-dropin,  \ Assemble call to find-dropin with literal arg

      4 [ax]          cx  mov	\ Length of inflater (byte-swapped)
      cx                  bswap	\ cx: Length of inflater
      d# 32 [ax]      si  lea	\ si: Base address of inflater code in ROM
      inflate-base #  di  mov	\ di: Base address of inflater

      cld  rep byte movs	\ Copy the inflater

      h# 24 # al mov  al h# 80 # out
      ax pop  			\ Recover base address of firmware dropin

      d# 32 #  ax     add	\ Skip dropin header
      ax              push	\ Address of compressed bits of firmware dropin (src)

      fw-virt-base #  push	\ Firmware RAM address (destination)
      0 #             push      \ No-header flag - 0 means expect a header
      workspace    #  push	\ Scratch RAM for inflater

      h# 25 # al mov  al h# 80 # out
      ascii m report
      inflate-base #  ax  mov	\ Base address of inflater
      ax call			\ Inflate the firmware
   else
      h# 26 # al mov  al h# 80 # out
      ascii h report

      \ The firmware dropin isn't compressed, so we just copy it to RAM
      4 [ax]          cx  mov	\ Length of firmware (byte-swapped)
      cx                  bswap	\ cx: Length of firmware

      d# 32 [ax]      si  lea	\ si: Base address of firmware code in dropin
      fw-virt-base #  di  mov	\ Firmware RAM address (destination)
      cld  rep byte movs	\ Copy the firmware

      ascii m report
   then
   long-offsets off
   h# 2f # al mov  al h# 80 # out

   ascii a report
   \ "firmware" drop-in should discard redundant page table entries
   fw-virt-base #   ax  mov	\ Jump to Forth in RAM
   ax  jmp

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
