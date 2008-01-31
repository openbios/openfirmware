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

h# 30 constant /smm-gdt

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
   smm-base smm-size 1- code16 h# 10 set-descr
   smm-base smm-size 1- data16 h# 18 set-descr
   0 -1 code32 h# 20 set-descr
   0 -1 data32 h# 28 set-descr
   /smm-gdt 1-   smm-gdtp +smm      w!  \ GDT limit
   smm-gdt +smm  smm-gdtp +smm wa1+ l!  \ GDT base
;

nuser smi-sp0
nuser smi-rp0

label smm-handler
   16-bit

   cs: ds  smm-save-seg d# 00 +  #)  svdc
   cs: smm-gdt h# 18 + #)  ds  rsdc   \ GDT reference
   \ Now we can use the data segment
   es  smm-save-seg d# 10 +  #)  svdc
   fs  smm-save-seg d# 20 +  #)  svdc
   gs  smm-save-seg d# 30 +  #)  svdc
   ss  smm-save-seg d# 40 +  #)  svdc
   cs  smm-save-seg d# 50 +  #)  svdc       \ So we can get back to the boost segment

   smm-gdt h# 18 + #)  ss  rsdc  \ GDT reference

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
   op: here 7 + smm-handler - +smm  h# 20 #)  far jmp  \ GDT reference
   32-bit

   \ Reload segment registers with protected mode bits
   op: h# 28 # ax mov   \ GDT reference
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

   here 7 +  smm-handler -  h# 08 #)  far jmp     \ Get into the boosted segment
   16-bit

   cr0 ax mov  1 invert # al and  ax cr0 mov   \ Exit protected mode

   \ Reload data segment registers
   cs: smm-gdt h# 18 + #)  ss  rsdc   \ GDT reference
   cs: smm-gdt h# 18 + #)  ds  rsdc   \ GDT reference

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

   enable-virtual-pci
;

: smi-interact  ( -- )  ." In SMI" cr  quit  ;
' smi-interact is handle-smi

: smm-cs-base   ( -- l )      smm-header h# 1c - +smm l@  ;
: smm-eip       ( -- l )      smm-header h# 10 - +smm l@  ;
: smm-next-eip  ( -- l )      smm-header h# 14 - +smm l@  ;
: smm-flags     ( -- w )      smm-header h# 24 - +smm w@  ;
: smm-io-port   ( -- port# )  smm-header h# 28 - +smm w@  ;
: smm-io-size   ( -- size )   smm-header h# 26 - +smm w@  ;
: smm-io-data   ( -- data )   smm-header h# 2c - +smm l@  ;
: smm-config-adr  ( -- adr )
   smm-sp +smm w@ +smm la1+ @ h# 7fff.fffc and
   smm-io-port 3 and  or
;
: smm-eax       ( -- adr )  smm-sp +smm w@ +smm 9 la+  ;

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
