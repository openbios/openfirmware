\ See license at end of file
purpose: Common code for several versions of reset.bth

   \ The memory layout information from the start dropin is stored in low
   \ memory.

   \ Move GDT to low memory.  We use the first location at gdt-pa as
   \ scratch memory for sgdt, and put the actual gdt at gdt-pa + 0x10
   gdt-pa # ax mov
   0 [ax] sgdt				\ Read GDT
   2 [ax] si mov			\ GDT base
   0 [ax] cx mov			\ GDT limit
   ffff # cx and
   cx inc

   gdt-pa h# 10 + # di mov		\ New GDT base
   di 2 [ax] mov			\ Set new GDT base
   rep movsb				\ Copy ROM GDT to RAM

   \ Copy code and data segment descriptors from 10,18 to 60,68
   gdt-pa h# 10 + h# 10 + #   si  mov   \ Descriptor 0x10 - src
   gdt-pa h# 10 + h# 60 + #   di  mov   \ Descriptor 0x60 - dst
   4 # cx mov                           \ 4 longwords, 2 descriptors
   rep movs

   op: h# ff #   0 [ax]  mov            \ Make GDT bigger for Linux

   0 [ax] lgdt				\ Setup RAM GDT

   \ Next time segment registers are changed, they will be
   \ reloaded from memory.

   h# fff202a0 h# 60  #)  far jmp
\   h# 60 #     push   \ New CS value
\   h# 10.0000 #     push   \ New CS value
\   here 5 + #) call   \ Get return address on stack
\   4 #  0 [sp] add    \ Adjust return address past ret
                      \ The add is 3 bytes and the ret is 1
\   far ret
nop nop nop nop nop nop nop nop nop nop nop nop nop nop nop nop nop nop nop nop 

\ begin again
   h# 68 # ax mov
   ax ds  mov
   ax es  mov
   ax fs  mov
   ax gs  mov
   ax ss  mov

[ifdef] mem-info-pa
   gdt-pa /page round-up #  ax  mov	\ Current low-memory high water mark
   ax     mem-info-pa 2 la+ #)  mov	\ Store in memory info area
[then]

   cld

ascii t report

   ds ax mov  ax es mov

[ifdef]  virtual-mode
   \ Initialize virtual page table
   \ Initialize linear=physical page table (redundant page table entries)
   \ Enable paging  (note that page fault handler is not in place yet)

[ifdef] notdef
   \ clear page tables
   ax ax  xor
   /ptab /l / #  cx  mov
   pt-pa #  di  mov
   rep  ax stos
[then]

ascii h report
   \ create PDEs

\ Create a mapping for the firmware

   \ In the following code, we use ESI as a physical memory allocation pointer
   mem-info-pa 4 + #)  si  mov		\ Top of memory available to software
   /page 1- invert #   si  and		\ Page-align just in case

   /fw-ram #           si  sub		\ Base address of firmware area
   si                  dx  mov		\ Firmware physical address in EDX

   \ Allocate Page Directory
   /ptab #             si  sub
   si                  bx  mov		\ Page directory PA in EBX

   \ Clear Page Directory
   ax ax  xor			\ value to store
   /ptab /l / #  cx  mov	\ #words to clear
   bx  di  mov			\ Base address
   rep ax stos


   /ptab #             si  sub
   si                  bp  mov		\ Page table PA in EBP
   
   bp                  ax  mov
   pte-control #       ax  or		\ Page table PDE in EAX
   ax   fw-virt-base d# 22 rshift /l*  [bx]  mov  \ Set page directory entry

   \ Fill page table with entries for the firmware
   bp                  di  mov
   dx                  ax  mov
   pte-control #       ax  or		\ Firmware PTE in EAX
   /fw-ram /page / #   cx  mov		\ Number of entries
   begin
      ax stos				\ Set PTE
      /page #  ax  add
   loopa

   \ Clear the rest of the table
   ax ax xor				\ Invalid page
   /section /fw-ram - /page / #      cx  mov	\ Number of entries
   rep ax stos

\ Linearly-map low addresses to cover physical memory
\ This code could be simplified by using 4M pages, at the expense
\ of requiring a modern processor variant and additional complexity
\ in later MMU management code.

   \ /section is the amount of memory that can be mapped with one page table
   mem-info-pa 4 + #)  dx  mov		\ Top of memory available to software
   /section 1- #       dx  add		\ Round up to a multiple of /section
   d# 22 #             dx  shr		\ Number of ptabs needed

   dx                  ax  mov		\ Copy of #ptabs
   d# 12 #             ax  shl		\ Number of bytes for page tables
   ax                  si  sub          \ Get memory for page tables

   \ Page Directory Entries
   si                  ax  mov
   pte-control #       ax  or		\ PDE contents
   bx                  di  mov		\ Base address
   dx                  cx  mov		\ Loop count (#ptabs)
   begin
      ax stos				\ pde for linear=physical page table
      /ptab # ax add			\ Point to next page table
   loopa

   \ Page Table Entries
   mem-info-pa 4 + #)     cx  mov	\ Top of memory available to software
   /page 1- #             cx  add	\ Round to a multiple of /page
   d# 12 #                cx  shr	\ #pages

   pte-control #          ax  mov	\ First PTE value (physical 0)
   si                     di  mov	\ Base address of first page table
   begin
      ax stos				\ Set PTE
      /page #  ax  add
   loopa

   d# 10 #                dx  shl	\ #pages mapped by ptabs
   dx                     cx  mov	\ Move into cx

   mem-info-pa 4 + #)     dx  mov	\ Top of memory available to software
   /page 1- #             dx  add	\ Round to a multiple of /page
   d# 12 #                dx  shr	\ #pages

   dx                     cx  sub	\ #ptes to zero
   ax                     ax  xor	\ Clear ax to make invalid PTE
   rep  ax  stos			\ Fill the leftovers

[ifdef] mem-info-pa
   si  mem-info-pa 1 la+ #)  mov	\ Report top of page table area
\   di  mem-info-pa 2 la+ #)  mov	\ Report top of page table area
[then]

ascii M report
[ifdef] rom-pa
   \ Page Directory Entry
   /ptab #             si  sub
   si                  bp  mov		\ Page table PA in EBP
   bp                  ax  mov
   pte-control #       ax  or		\ Page table PDE in EAX
   ax   rom-pa d# 22 rshift /l*  [bx]  mov  \ Set PDE for ROM page tables

   \ Page Table Entries

   \ create PTEs for the ROM version OFW
   rom-pa /page 1- invert land  pte-control + #       ax  mov
   bp                                                 di  mov
   rom-pa pte-mask land /page / /l* #                 di  add

   /rom /page / #		             cx  mov

   begin
      ax stos
      /page #  ax  add
   loopa
[then]
ascii a report
   \ enable paging
   bx              cr3  mov	\ Set Page Directory Base Register
   cr0		   ax   mov
   8000.0000 #     ax   or
   ax              cr0  mov	\ Turn on Paging Enable bit
[then]

   " firmware" $find-dropin,  \ Assemble call to find-dropin with literal arg

   d# 12 [ax]  bx  mov		\ "Expanded size" field
   0 #  bx  cmp
   <> if
      \ The firmware dropin is compressed, so we load the inflater into RAM
      \ and use it to inflate the firmware into RAM
      ax  push			\ Save address of firmware dropin

      " inflate" $find-dropin,  \ Assemble call to find-dropin with literal arg

      4 [ax]          cx  mov	\ Length of inflater (byte-swapped)
      cx                  bswap	\ cx: Length of inflater
      d# 32 [ax]      si  lea	\ si: Base address of inflater code in ROM
      inflate-base #  di  mov	\ di: Base address of inflater

      cld  rep byte movs	\ Copy the inflater

      ax pop  			\ Recover base address of firmware dropin

      d# 32 #  ax     add	\ Skip dropin header
      ax              push	\ Address of compressed bits of firmware dropin (src)

      fw-virt-base #  push	\ Firmware RAM address (destination)
      0 #             push      \ No-header flag - 0 means expect a header
      workspace    #  push	\ Scratch RAM for inflater

      inflate-base #  ax  mov	\ Base address of inflater
      ax call			\ Inflate the firmware
   else
      \ The firmware dropin isn't compressed, so we just copy it to RAM
      4 [ax]          cx  mov	\ Length of firmware (byte-swapped)
      cx                  bswap	\ cx: Length of firmware

      d# 32 [ax]      si  lea	\ si: Base address of firmware code in dropin
      fw-virt-base #  di  mov	\ Firmware RAM address (destination)
      cld  rep byte movs	\ Copy the firmware
   then

   \ "firmware" drop-in should discard redundant page table entries
   fw-virt-base #   ax  mov	\ Jump to Forth in RAM
   ax  jmp

   \ Notreached, in theory
   begin  again
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
