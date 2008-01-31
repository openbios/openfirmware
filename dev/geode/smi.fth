purpose: SMI setup and handler for Geode LX

also assembler definitions

: smint  ( -- )  prefix-0f  h# 38 asm8,  ;
: rsm    ( -- )  prefix-0f  h# aa asm8,  ;
: svdc  ( sr m80 -- )  prefix-0f  h# 78 asm8,  rot r/m,  ;
: rsdc  ( m80 sr -- )  prefix-0f  h# 79 asm8,  r/m,   ;

previous definitions

\ The general naming convention here is that smm-* refers to
\ addresses within the memory that is set aside for SMI handling.
\ smi-* refers to stuff in the Forth domain.

h#    f.f000 constant smm-base
h#      1000 constant smm-size  \ We use about 3K of this, 2K for stacks
: +smm  ( segment-relative-adr -- adr )  smm-base +  ;
: -smm  ( adr -- segment-relative-adr )  smm-base -  ;

h# 28 constant /smm-gdt
h#  8 constant smm-c16
h# 10 constant smm-d16
h# 18 constant smm-c32
h# 20 constant smm-d32

\ For stuff that grows down - add the offset first
: rm-stack ( offset len "name" -- offset' )  + dup      constant  ;
: pm-stack ( offset len "name" -- offset' )  + dup +smm constant  ;

\ For individual data items - add the offset afterwards
: pm-data  ( offset len "name" -- offset' )  over +smm constant  +  ;
: rm-data  ( offset len "name" -- offset' )  over      constant  +  ;

\ Layout of SMM memory area:
0                            \ Entry/exit handler code goes here, at the origin
h# 180 rm-data smm-gdt       \ The GDT is embedded in the code wad
                             \ The handler code takes about h# 160 bytes

\ The following locations are for saving/restoring registers
\ d# 60 rm-data smm-save-seg   \ 6 10-byte segment registers
d# 50 rm-data smm-save-seg   \ 6 10-byte segment registers
/l    rm-data smm-save-esp   \ Caller's stack pointer
6     rm-data smm-save-gdt   \ Caller's GDT pointer

0         pm-data  smm-regs  \ Alternate name, for use by Forth
0         rm-data  smm-sp    \ Real-mode sp after saving registers
d# 10 /l* rm-stack smm-stack \ CR3, portCF8, 8 general registers

h# 30 pm-stack smm-header     \ Top address where hardware puts the SMM info frame

\ These locations are set once at installation time.  The entry code reads them.
[ifdef] virtual-mode
/l  pm-data smm-pdir         \ Page directory pointer so we can enable paging
[then]
/l  pm-data smm-forth-base   \ Base address of the Forth dictionary
/l  pm-data smm-forth-up     \ Base address of the Forth user area
/l  pm-data smm-forth-entry  \ Entry address of Forth SMI handler
/l  pm-data smm-save-sp0     \ Exchanged with sp0 user variable
/l  pm-data smm-save-rp0     \ Exchanged with rp0 user variable

h# 400 pm-stack smm-sp0      \ SMM Forth data stack
h# 400 pm-stack smm-rp0      \ SMM Forth return stack
drop

label smi-handler
   16-bit
  
   \ GDT (with jump tucked in at the beginning)
   \ We put the GDT right at the beginning and use the first entry (which
   \ cannot be used as a selector) for a 2-byte jmp and the 6-byte GDT pointer
   here /smm-gdt + #) jmp           \ Jump past GDT - 2 bytes
   /smm-gdt 1- w,   smm-base l,     \ GDT pointer - limit.w base.l

   smm-base smm-size 1- code16 format-descriptor  swap l, l,  \  8 - smm-c16
   smm-base smm-size 1- data16 format-descriptor  swap l, l,  \ 10 - smm-d16
   0                 -1 code32 format-descriptor  swap l, l,  \ 18 - smm-c32
   0                 -1 data32 format-descriptor  swap l, l,  \ 20 - smm-d32
   \ End of GDT

   cs: ds  smm-save-seg d# 00 +  #)  svdc
   cs: smm-gdt smm-d16 + #)  ds  rsdc
   \ Now we can use the data segment
   es  smm-save-seg d# 10 +  #)  svdc
   fs  smm-save-seg d# 20 +  #)  svdc
   gs  smm-save-seg d# 30 +  #)  svdc
   ss  smm-save-seg d# 40 +  #)  svdc
\   cs  smm-save-seg d# 50 +  #)  svdc       \ So we can get back to the boost segment

   smm-gdt smm-d16 + #)  ss  rsdc

   op: sp  smm-save-esp #)  mov
   smm-stack #  sp  mov      \ Now we have a stack

   op: pusha

   h# cf8 #  dx   mov   \ Save/restore PCI config address
   op: dx    ax   in
   op: ax         push

   cr3 ax mov  op: ax push
   \ The real-mode stack pointer is now at a known location

\ Get into protected mode using the same segments 
\ Don't bother with the IDT; we won't enable interrupts
   op: smm-save-gdt #) sgdt
   op: smm-gdt 2+ #) lgdt

   cr0 ax mov  1 # al or  ax cr0 mov   \ Enter protected mode
   op: here 7 + smi-handler - +smm smm-c32 #)  far jmp
   32-bit

   \ Reload segment registers with protected mode bits
   op: smm-d32 # ax mov
   ax ds mov  ax es mov  ax fs mov  ax gs mov  ax ss mov

[ifdef] virtual-mode
   \ Turn on paging
   smm-pdir #)  ax  mov
   ax cr3  mov	\ Set Page Directory Base Register
   cr0 ax mov  h# 8000.0000 # ax or  ax cr0 mov	 \ Turn on Paging Enable bit
[then]

\ Beginning of Forth-specific stuff
   smm-forth-base  #)  bx  mov
   smm-forth-up    #)  up  mov
   smm-forth-entry #)  ip  mov

   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0 sp mov  smm-save-sp0 #) sp xchg  sp 'user sp0 mov
   'user rp0 rp mov  smm-save-rp0 #) rp xchg  rp 'user rp0 mov

   cld
c;
code (smi-return)   \ This code field must be relocated after copying to SMM memory
   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0 sp mov  smm-save-sp0 #) sp xchg  sp 'user sp0 mov
   'user rp0 rp mov  smm-save-rp0 #) rp xchg  rp 'user rp0 mov

   \ End of Forth-specific stuff

[ifdef] virtual-mode
   \ Turn off paging
   cr0 ax mov  h# 8000.0000 invert # ax and  ax cr0 mov	 \ Turn off Paging Enable bit
[then]

   here 7 +  smi-handler -  smm-c16 #)  far jmp     \ Get into the boosted segment
   16-bit

   smm-d16 # ax mov  ax ss mov  ax ds mov      \ Reload data and stack segments

   cr0 ax mov  1 invert # al and  ax cr0 mov   \ Exit protected mode

   \ Reload data segment registers
\   cs: smm-gdt smm-d16 + #)  ss  rsdc
\   cs: smm-gdt smm-d16 + #)  ds  rsdc

   op: smm-save-gdt #) lgdt

   smm-sp #  sp  mov
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
here smi-handler - constant /smi-handler

: smi-return  ( -- )  [ ' (smi-return) smi-handler -  +smm ] literal  execute  ;
defer handle-smi  ' noop is handle-smi
create smm-exec  ] handle-smi smi-return [

: enable-virtual-pci  ( -- )
   h# 5000.2012 msr@  swap h# 8002 or   swap  h# 5000.2012 msr!  \ Virtualize devices f and 1
   h# 5000.2002 msr@  swap 8 invert and swap  h# 5000.2002 msr!  \ Enable SSMI for config accesses
;

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
   smm-base  smm-size 1-  h# 133b msr!

   smm-header 0   h# 132b msr!  \ Offset of SMM Header

   h# 18.  h# 1301 msr!       \ Enable IO and software SMI

   \ Unnecessary if already in mapped memory
   \ smm-base dup  smm-size  -1 mmu-map

   smi-handler smm-base  /smi-handler  move

   \ Relocate the code field of the code word that is embedded in the sequence
   ['] (smi-return) smi-handler -  +smm  ( cfa-adr )
   dup ta1+ swap token!

[ifdef] virtual-mode
   cr3@ smm-pdir l!
[then]

   origin smm-forth-base l!
   smm-exec smm-forth-entry l!
   up@ smm-forth-up l!
   smm-sp0 smm-save-sp0 !
   smm-rp0 smm-save-rp0 !

   enable-virtual-pci
;

: smi-interact  ( -- )  ." In SMI" cr  quit  ;
' smi-interact is handle-smi

\ : smm-cs-base   ( -- l )      smm-header h# 1c - l@  ;
\ : smm-eip       ( -- l )      smm-header h# 10 - l@  ;
\ : smm-next-eip  ( -- l )      smm-header h# 14 - l@  ;
: smm-flags     ( -- w )      smm-header h# 24 - w@  ;
: smm-io-port   ( -- port# )  smm-header h# 28 - w@  ;
: smm-io-size   ( -- size )   smm-header h# 26 - w@  ;
: smm-io-data   ( -- data )   smm-header h# 2c - l@  ;
\ Stacked registers:  0:CR3, 1:portCF8, 2:DI, 3:SI, 4:BP, 5:SP, 6:BX, 7:DX, 8:CX, 9:AX
: smm-config-adr  ( -- adr )
   smm-regs la1+ @ h# 7fff.fffc and
   smm-io-port 3 and  or
;
: smm-eax       ( -- adr )  smm-regs 9 la+  ;

: vr-spoof?  ( -- handled? )  false  ;
: config-spoof?  ( -- handled? )
   smm-io-port 3 invert and  h# cfc <>  if  false exit  then

   \ The existing Forth config spoofer does the hard work
   smm-flags 2 and  if  \ Write
      smm-io-data  smm-config-adr   ( data config-adr )
      smm-io-size case
         1 of  config-b!  endof
         3 of  config-w!  endof
         f of  config-l!  endof
      endcase
   else
      smm-config-adr                 ( config-adr )
      smm-io-size case
         1 of  config-b@ smm-eax c!  endof
         3 of  config-w@ smm-eax w!  endof
         f of  config-l@ smm-eax l!  endof
      endcase
   then
   true
;
: virtualize-io  ( -- )
   smm-flags h# 80 and  0=  if  exit  then
   config-spoof?  if  exit  then
   vr-spoof?  if  exit  then
;
: soft-smi  smi-interact  ;
: smi-dispatch  ( -- )
   smm-flags h# 80 and  if  virtualize-io  then
   smm-flags h#  8 and  if  soft-smi       then
;
' smi-dispatch is handle-smi

code smi  smint  c;
