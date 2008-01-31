purpose: SMI setup and handler for Geode LX

also assembler definitions

: smint  ( -- )  prefix-0f  h# 38 asm8,  ;
: rsm    ( -- )  prefix-0f  h# aa asm8,  ;
: svdc  ( sr m80 -- )  prefix-0f  h# 78 asm8,  rot r/m,  ;
: rsdc  ( m80 sr -- )  prefix-0f  h# 79 asm8,  r/m,   ;

previous definitions

h# 4000.0000 constant smm-base
h#    1.0000 constant smm-size
: +smm  ( offset -- adr )  smm-base +  ;

h# 30 constant /smm-gdt
smm-size h# 100 -
dup constant smm-stack
dup constant smm-save-gdt 8 +
dup constant smm-gdtp     8 +
dup constant smm-gdt      /smm-gdt +
dup constant smm-pdir     4 +

dup constant smm-code16  h# a +
dup constant smm-data16  h# a +
dup constant smm-code32  h# a +
dup constant smm-data32  h# a +
dup constant smm-ds      h# a +
dup constant smm-es      h# a +
dup constant smm-fs      h# a +
dup constant smm-gs      h# a +
dup constant smm-ss      h# a +
dup constant smm-cs      h# a +
dup constant smm-esp     4 +
drop

: set-descr  ( base limit d.type sel offset -- )
   +smm 2>r  format-descriptor  ( d.descr r: sel adr )
   2r@ 8 + w!                   ( d.descr r: sel adr )
   2dup r> d!                   ( d.descr r: sel )
   r> smm-gdt + +smm d!         ( )
;

: set-smm-descs  ( -- )
   smm-base -1 code32 format-descriptor  smm-gdt 8 + +smm d!  \ Boosted code32

   smm-base smm-size 1- code16 h# 10 smm-code16 set-descr
   smm-base smm-size 1- data16 h# 18 smm-data16 set-descr
   0 -1 code32 h# 20 smm-code32 set-descr
   0 -1 data32 h# 28 smm-data32 set-descr
   /smm-gdt 1-   smm-gdtp +smm 4 + w!   \ GDT limit
   smm-gdt +smm  smm-gdtp +smm l!       \ GDT base
;

label smm-handler
   16-bit

   cs: ds      smm-ds #)  svdc
   cs: smm-data16 #)  ds  rsdc   \ Now we have a data segment

   es  smm-es #)  svdc
   fs  smm-fs #)  svdc
   gs  smm-gs #)  svdc
   ss  smm-ss #)  svdc
   smm-data16 #)  ss  rsdc   \ Now we have a data segment

   op: sp  smm-esp #)  mov
   smm-stack #  sp  mov      \ Now we have a stack

   op: pusha

   h# cf8 #  dx   mov   \ Save/restore PCI config address
   op: dx    ax   in
   op: ax         push

   cr3 ax mov  op: ax push

\ ---
\ Get into protected mode using the same segments 
\ Don't bother with the IDT; we won't enable interrupts
   op: smm-save-gdt #) sgdt
   op: smm-gdtp     #) lgdt

\ Test<
   \ Get into the 4G flat code-32 address space
   cs  smm-cs  #)  svdc       \ So we can get back
   smm-code32  #)  cs  rsdc   \ 4G flat address space for code
   32-bit
   here 5 + +smm #) jmp       \ Into unboosted segment

nop nop nop nop nop nop nop 

   cr0 ax mov  1 # al or  ax cr0 mov   \ Enter protected mode
   here 2 + #) jmp

   \ Reload segment registers with protected mode bits
   cs: smm-data32 +smm #)  ds  rsdc
   smm-data32 +smm #)  ss  rsdc
   smm-data32 +smm #)  es  rsdc
   smm-data32 +smm #)  fs  rsdc
   smm-data32 +smm #)  gs  rsdc

   \ Turn on paging
   smm-pdir +smm   #)  ax  mov
   ax cr3  mov	\ Set Page Directory Base Register
   cr0 ax mov  h# 8000.0000 # ax or  ax cr0 mov	 \ Turn on Paging Enable bit


\   op:  here 7 + smm-handler - smm-base +  h# 20 #)  far jmp
\   op:  here 7 + smm-handler -   8 #)  far jmp

\ Put Forth stuff here  

\   smm-code16 +smm #)  cs  rsdc
\   smm-code16 +smm #)  cs  rsdc   \ 64K boosted

   nop nop nop nop nop nop nop nop nop nop 

   \ Turn off paging
   cr0 ax mov  h# 8000.0000 invert # ax and  ax cr0 mov	 \ Turn off Paging Enable bit


   cr0 ax mov  1 invert # al and  ax cr0 mov   \ Enter real mode
   here 2 + #) jmp


   \ Reload segment registers with real mode bits
   cs: smm-data16 +smm #)  ss  rsdc
   cs: smm-data16 +smm #)  ds  rsdc


   \ Return to the boosted code-16 address space
   smm-cs  #)  cs  rsdc
   16-bit
   here 2 + #) jmp  \ 16-bit JMP zeros EIP[31:16]

\ >Test


   op: smm-save-gdt #) lgdt

\ ---
   op: ax pop  ax cr3 mov

   op: ax        pop
   h# cf8 #  dx  mov   \ Save/restore PCI config address
   op: ax    dx  out

   op: popa

   op: smm-esp #)  sp  mov

   smm-ss #)  ss  rsdc
   smm-gs #)  gs  rsdc
   smm-fs #)  fs  rsdc
   smm-es #)  es  rsdc
   smm-ds #)  ds  rsdc

   rsm
end-code
here smm-handler - constant /smm-handler

: setup-smi  ( -- )
   \ Map the SMM region to physical memory at e.0000
   \ This is a Base Mask Offset descriptor - the base address
   \ is 4000.0000 and to that is added the offset c00e.0000
   \ to give the address 000e.0000 in the GLMC address space.
   \ The mask is ffff.0000 , i.e. 64K
   h# 2.c00e0.40000.ffff0. h# 1000.0026 msr!

   \ Put 64K SMM memory at 4000.0000 in the processor linear address space
   \ Cacheable in SMM mode, non-cacheable otherwise
   h# 4000f.0.00.40000.1.01. h# 180e msr!

   \  Base     Limit
\   smm-base  smm-size 1-  h# 133b msr!
   smm-base  -1  h# 133b msr!   \ Big limit

   smm-base smm-size + 0   h# 132b msr!  \ Offset of SMM Header

   h# 18.  h# 1301 msr!       \ Enable IO and software SMI

   smm-base dup  smm-size  -1 mmu-map

   smm-handler smm-base  /smm-handler  move
   set-smm-descs
   cr3@ smm-pdir +smm l!
;

: enable-virtual-pci  ( -- )
   h# 5000.2012 msr@  swap h# 8002 or   swap  h# 5000.2002 msr!  \ Virtualize devices f and 1
   h# 5000.2002 msr@  swap 8 invert and swap  h# 5000.2002 msr!  \ Enable SSMI for config accesses
;


code smi  smint  ax push  c;

\ Forth stuff
[ifdef] notyet
   op: smm-forth-origin #)  bx  mov
   op: smm-forth-up     #)  up  mov
[then]
   
[ifdef] notyet
   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0  sp  mov
   'user rp0  rp  mov

   'user smi-sp0  sp  xchg
   'user smi-rp0  rp  xchg

   sp  'user sp0  mov
   rp  'user rp0  mov

   \ Set the interpreter pointer
   'body smi-exec origin - # ip mov
   bx ip add				\ add current origin

   cld
c;
XXX code to return from Forth
[then]

[ifdef] notyet
   \ We are running in a segment that is identity mapped
   cr0 ax mov  h# 8000.0000 invert # ax and  ax cr0  mov  \ Turn off Paging Enable bit
[then]

label emita
   op: dx dx xor   dx dx xor
   h# 3fd # dx mov
   begin dx al in h# 20 # al and 0<> until
   h# 41 # al mov  h# f8 # dl mov  al dx out
   begin again
\   h# 3fd # dx mov
\   begin dx al in h# 20 # al and 0<> until
end-code
here emita - constant /emita
: puta  ( adr -- )  emita swap /emita move  ;
