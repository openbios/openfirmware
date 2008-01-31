purpose: SMI setup and handler for Geode LX

also assembler definitions

: smint  ( -- )  prefix-0f  h# 38 asm8,  ;
: rsm    ( -- )  prefix-0f  h# aa asm8,  ;
: svdc  ( sr m80 -- )  prefix-0f  h# 78 asm8,  rot r/m,  ;
: rsdc  ( m80 sr -- )  prefix-0f  h# 79 asm8,  r/m,   ;

previous definitions

h#    f.f000 constant smm-base
h#      1000 constant smm-size  \ We use about 3K of this, 2K for stacks
: +smm  ( offset -- adr )  smm-base +  ;

h# 28 constant /smm-gdt

\ The handler code takes about h# 140 bytes

\ The following save area + the SMM_HEADER (h# 30) takes about h# 100
h# 200     
dup constant smm-save-gdt      8 +
dup constant smm-gdtp          8 +
dup constant smm-gdt           /smm-gdt +
dup constant smm-pdir          la1+
dup constant smm-forth-origin  la1+
dup constant smm-forth-up      la1+
dup constant smm-forth-entry   la1+

\ 10 bytes for each of 6 segment registers
dup constant smm-save-seg      d# 60 +
dup constant smm-save-esp      la1+
dup constant smm-sp            la1+
   \ 8x 4-byte general registers + config adr + cs3 + spare
h# 38 + constant smm-stack

h# 300 constant smm-header

: set-descr  ( base limit d.type sel -- )
   >r  format-descriptor   ( d.descr r: sel )
   r> smm-gdt + +smm d!    ( )
;

: set-smm-descs  ( -- )
\   smm-base -1 code32 format-descriptor  smm-gdt 8 + +smm d!  \ Boosted code32
   smm-base smm-size 1- code16 h# 08 set-descr
   smm-base smm-size 1- data16 h# 10 set-descr
   0 -1 code32 h# 18 set-descr
   0 -1 data32 h# 20 set-descr
   /smm-gdt 1-   smm-gdtp +smm      w!  \ GDT limit
   smm-gdt +smm  smm-gdtp +smm wa1+ l!  \ GDT base
;

nuser smi-sp0
nuser smi-rp0

label smm-handler
   16-bit

   cs: ds  smm-save-seg d# 00 +  #)  svdc
   cs: smm-gdt h# 10 + #)  ds  rsdc   \ Now we have a data segment
   es  smm-save-seg d# 10 +  #)  svdc
   fs  smm-save-seg d# 20 +  #)  svdc
   gs  smm-save-seg d# 30 +  #)  svdc
   ss  smm-save-seg d# 40 +  #)  svdc
   cs  smm-save-seg d# 50 +  #)  svdc       \ So we can get back to the boost segment

   smm-gdt h# 10 + #)  ss  rsdc

   op: sp  smm-save-esp #)  mov
   smm-stack #  sp  mov      \ Now we have a stack

   op: pusha

   h# cf8 #  dx   mov   \ Save/restore PCI config address
   op: dx    ax   in
   op: ax         push

   cr3 ax mov  op: ax push
   sp  smm-sp #)  mov

\ Get into protected mode using the same segments 
\ Don't bother with the IDT; we won't enable interrupts
   op: smm-save-gdt #) sgdt
   op: smm-gdtp     #) lgdt

   cr0 ax mov  1 # al or  ax cr0 mov   \ Enter protected mode
   op: here 7 + smm-handler - +smm  h# 18 #)  far jmp
   32-bit

   \ Reload segment registers with protected mode bits
   op: h# 20 # ax mov
   ax ds mov  ax es mov  ax fs mov  ax gs mov  ax ss mov

   \ Turn on paging
   smm-pdir +smm   #)  ax  mov
   ax cr3  mov	\ Set Page Directory Base Register
   cr0 ax mov  h# 8000.0000 # ax or  ax cr0 mov	 \ Turn on Paging Enable bit

\ Beginning of Forth-specific stuff
   smm-forth-origin +smm #)  bx  mov
   smm-forth-up     +smm #)  up  mov
   smm-forth-entry  +smm #)  ip  mov

   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0  sp  mov
   'user rp0  rp  mov

   'user smi-sp0  sp  xchg
   'user smi-rp0  rp  xchg

   sp  'user sp0  mov
   rp  'user rp0  mov


   cld
c;
code (smi-return)   \ This code field must be relocated after copying to SMM memory
   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0  sp  mov
   'user rp0  rp  mov

   'user smi-sp0  sp  xchg
   'user smi-rp0  rp  xchg

   sp  'user sp0  mov
   rp  'user rp0  mov

   \ End of Forth-specific stuff

   \ Turn off paging
   cr0 ax mov  h# 8000.0000 invert # ax and  ax cr0 mov	 \ Turn off Paging Enable bit

   cr0 ax mov  1 invert # al and  ax cr0 mov   \ Enter real mode

   \ Return to the boosted code-16 address space
   smm-save-seg d# 50 + +smm #)  cs  rsdc
   16-bit
   op:  here 5 +  smm-base - #) jmp  \ Decrease IP while increasing the segment register

   \ Reload data segment registers
   cs: smm-gdt h# 10 + #)  ss  rsdc
   cs: smm-gdt h# 10 + #)  ds  rsdc

   op: smm-save-gdt #) lgdt

   smm-sp #)  sp  mov
   op: ax pop  ax cr3 mov

   op: ax        pop
   h# cf8 #  dx  mov   \ Save/restore PCI config address
   op: ax    dx  out

   op: popa

   op: smm-save-esp #)  sp  mov

   smm-save-seg d# 40 + #)  ss  rsdc
   smm-save-seg d# 30 + #)  gs  rsdc
   smm-save-seg d# 20 + #)  fs  rsdc
   smm-save-seg d# 10 + #)  es  rsdc
   smm-save-seg d# 00 + #)  ds  rsdc

   rsm
end-code
here smm-handler - constant /smm-handler

: smi-return  ( -- )  [ ' (smi-return) smm-handler -  +smm ] literal  execute  ;
defer handle-smi  ' noop is handle-smi
create smm-exec  ] handle-smi smi-return [

: setup-smi  ( -- )
   \ This is how you would map the SMM region to physical memory at 4000.0000
   \ This is a Base Mask Offset descriptor - the base address
   \ is 4000.0000 and to that is added the offset c00e.0000
   \ to give the address 000e.0000 in the GLMC address space.
   \ The mask is ffff.f000 , i.e. 4K

   \ This is unnecessary if the SMM memory is in a region that is
   \ already mapped with a descriptor
   \ h# 2.c00e0.40000.fffff. h# 1000.0026 msr!

   \ Put 4K SMM memory at 000f.f000 in the processor linear address space
   \ Cacheable in SMM mode, non-cacheable otherwise
   \ Depends on smm-base and smm-size
   h# 000ff.0.00.000ff.1.01. h# 180e msr!

   \  Base     Limit
\   smm-base  smm-size 1-  h# 133b msr!
   \ The limit here must be large enough to cover the code address
   \ between the time that we reenter real mode and the time we
   \ reestablish the boosted descriptor.
   smm-base  -1  h# 133b msr!   \ Big limit

   smm-base smm-header + 0   h# 132b msr!  \ Offset of SMM Header

   h# 18.  h# 1301 msr!       \ Enable IO and software SMI

   \ Unnecessary if already in mapped memory
   \ smm-base dup  smm-size  -1 mmu-map

   smm-handler smm-base  /smm-handler  move

   \ Relocate the code field of the code word that is embedded in the sequence
   ['] (smi-return) smm-handler -  +smm  ( cfa-adr )
   dup ta1+ swap token!

   set-smm-descs
   cr3@ smm-pdir +smm l!

   origin smm-forth-origin +smm l!
   smm-exec smm-forth-entry +smm l!
   up@ smm-forth-up +smm l!
   h# 800 +smm smi-sp0 !
   h# c00 +smm smi-rp0 !
;

: smi-interact  ( -- )  ." In SMI" cr  quit  ;
' smi-interact is handle-smi

: enable-virtual-pci  ( -- )
   h# 5000.2012 msr@  swap h# 8002 or   swap  h# 5000.2002 msr!  \ Virtualize devices f and 1
   h# 5000.2002 msr@  swap 8 invert and swap  h# 5000.2002 msr!  \ Enable SSMI for config accesses
;

code smi  smint  c;
