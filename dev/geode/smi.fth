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

label int-entry
   16-bit
   al  h# 30 #  out  iret  nop
   al  h# 31 #  out  iret  nop
   al  h# 32 #  out  iret  nop
   al  h# 33 #  out  iret  nop
   al  h# 34 #  out  iret  nop
   al  h# 35 #  out  iret  nop
   al  h# 36 #  out  iret  nop
   al  h# 37 #  out  iret  nop
   al  h# 38 #  out  iret  nop
   al  h# 39 #  out  iret  nop
   al  h# 3a #  out  iret  nop
   al  h# 3b #  out  iret  nop
   al  h# 3c #  out  iret  nop
   al  h# 3d #  out  iret  nop
   al  h# 3e #  out  iret  nop
   al  h# 3f #  out  iret  nop
end-code
here int-entry -  constant /int-entry


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
2     rm-data smm-save-ds    \ Temporary DS
2     rm-data smm-save-ss    \ Saved SS

0     rm-data  smm-sp        \ Real-mode sp after saving registers
/l    pm-data  smm-cr3       \ Alternate name, for use by Forth
/l    pm-data  smm-cf8       \ Alternate name, for use by Forth

0     pm-data  caller-regs
4 /w* pm-data  smm-sregs     \ GS, FS, ES, DS
8 /l* pm-data  smm-gregs     \ EDI, ESI, EBP, Exx, EBX, EDX, ECX, EAX
0     rm-data  smm-stack

/l    pm-data  smm-retaddr   \ EIP
/l    pm-data  smm-rmeflags  \ EFLAGS

0     pm-data  smm-rmidt     \ IDT
8     pm-data  rm-buf


h# 30 pm-stack smm-header    \ Top address where hardware puts the SMM info frame

/int-entry pm-data 'int10-dispatch

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
   cs: ds  smm-save-ds           #)  mov
   cs: smm-gdt smm-d16 + #)  ds  rsdc
   \ Now we can use the data segment
   es  smm-save-seg d# 10 +  #)  svdc
   fs  smm-save-seg d# 20 +  #)  svdc
   gs  smm-save-seg d# 30 +  #)  svdc
   ss  smm-save-seg d# 40 +  #)  svdc
\  cs  smm-save-seg d# 50 +  #)  svdc       \ So we can get back to the boost segment

   ss  smm-save-ss           #)  mov
   smm-gdt smm-d16 + #)  ss  rsdc

   op: sp  smm-save-esp #)  mov
   smm-stack #  sp  mov      \ Now we have a stack

   op: pusha
   smm-save-ds #)  ax  mov
   ax  push
   es push  fs push  gs push


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
   cli

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

   gs pop  fs pop  es pop
   ax pop  ax smm-save-ds #) mov
   op: popa

   op: smm-save-esp #)  sp  mov

   smm-save-ss #)  ss  mov

   smm-save-seg d# 40 + #)  ss  rsdc
   smm-save-seg d# 30 + #)  gs  rsdc
   smm-save-seg d# 20 + #)  fs  rsdc
   smm-save-seg d# 10 + #)  es  rsdc
   smm-save-seg d# 00 + #)  ds  rsdc
   
\   cs: smm-save-ds #)           ds  mov
   rsm
end-code
here smi-handler - constant /smi-handler

: smm-dr7       ( -- l )      smm-header h#  4 - l@  ;
: smm-eflags    ( -- l )      smm-header h#  8 - l@  ;
: smm-cr0       ( -- l )      smm-header h#  c - l@  ;
: smm-eip       ( -- l )      smm-header h# 10 - l@  ;
: smm-next-eip  ( -- l )      smm-header h# 14 - l@  ;
: smm-next-eip! ( l -- )      smm-header h# 14 - l!  ;
: smm-cs-flags  ( -- w )      smm-header h# 16 - w@  ;
: smm-cs-sel    ( -- w )      smm-header h# 18 - w@  ;
: smm-cs-base   ( -- l )      smm-header h# 1c - l@  ;
: smm-ss-flags  ( -- w )      smm-header h# 22 - w@  ;
: smm-flags     ( -- w )      smm-header h# 24 - w@  ;
: smm-io-port   ( -- port# )  smm-header h# 28 - w@  ;
: smm-io-size   ( -- size )   smm-header h# 26 - w@  ;
: smm-io-data   ( -- data )   smm-header h# 2c - l@  ;
: smm-pc        ( -- padr )   smm-eip smm-cs-base +  ;

\ Stacked registers:  0:CR3, 1:portCF8, 2:DI, 3:SI, 4:BP, 5:SP, 6:BX, 7:DX, 8:CX, 9:AX
: smm-config-adr  ( -- adr )
   smm-cf8 @ h# 7fff.fffc and
   smm-io-port 3 and  or
;
\ Address of segment registers
: smm-eax  ( -- adr )  smm-gregs  7 la+  ;
: smm-ebp  ( -- adr )  smm-gregs  2 la+  ;

: >ptable  ( table vadr shift -- table' unmapped? )
   rshift  h# ffc and + l@
   dup h# fff invert and  swap 1 and 0=
;

\ XXX need to handle mapped-at-pde-level
defer smm>physical
: (smm>physical)  ( vadr -- padr )
\   smm-cr0  h# 8000.0000 and  0=  if  exit  then
   cr3@                                  ( vadr pdir )
   over d# 20 >ptable  abort" Unmapped"  ( vadr ptab )
   over d# 10 >ptable  abort" Unmapped"  ( vadr pframe )
   swap h# fff and +
;
' (smm>physical) to smm>physical

: smm-map?  ( vadr -- )  smm>physical  .  ;

\ Programs that write to the caller's data space should use this,
\ as it works when called from paged V86 mode.
: >caller-physical  ( vadr -- padr )
   smm-cr0  h# 8000.0000 and  if  (smm>physical)  then
;

\ Turn address translation on or off for the following commands,
\ so they can be used either for non-paged calling code like
\ early bootloaders or for paged code that calls to us via a
\ real mode gateway.

: use-physical  ( -- )  ['] noop to smm>physical  ;
: use-virtual   ( -- )  ['] (smm>physical) to smm>physical  ;


: smi-return  ( -- )  [ ' (smi-return) smi-handler -  +smm ] literal  execute  ;
defer handle-smi  ' noop is handle-smi
create smm-exec  ] handle-smi smi-return [

false value vpci-debug?
: enable-virtual-pci  ( -- )
   \ Virtualize devices f and 1, or all devices if debugging
   vpci-debug?  if  h# ffff  else  h# 8002  then  >r
   h# 5000.2012 msr@  swap r>  or       swap  h# 5000.2012 msr!
   h# 5000.2002 msr@  swap 8 invert and swap  h# 5000.2002 msr!  \ Enable SSMI for config accesses
;

\ : msr-ack  ( msr# -- )  >r  r@  msr@  r> msr!  ;
code msr-ack  ( msr# -- )  cx pop  rdmsr  wrmsr  c;
code msr@!  ( msr# -- d.value )  cx pop  rdmsr  wrmsr  ax push  dx push  c;
code msr-sense32  ( err-msr# -- false | statbits statbits )
   cx pop  rdmsr wrmsr
   cx dec  rdmsr wrmsr
   ax not  dx ax and  ax push
   0<>  if  ax push  then
c;
code msr-sense32p  ( err-msr# -- false | statbits statbits )
   cx pop  rdmsr wrmsr
   cx dec  rdmsr wrmsr
   dx ax and  ax push
   0<>  if  ax push  then
c;
code msr-sense16  ( err-msr# -- false | statbits statbits )
   cx pop  rdmsr wrmsr
   cx dec  rdmsr wrmsr
   ax dx mov   d# 16 # dx shr
   h# ffff # ax and
   ax not  dx ax and  ax push
   0<>  if  ax push  then
c;
code msr-sense16p  ( err-msr# -- false | statbits statbits )
   cx pop  rdmsr wrmsr
   cx dec  rdmsr wrmsr
   ax dx mov   d# 16 # dx shr
   h# ffff # ax and
   dx ax and  ax push
   0<>  if  ax push  then
c;

alias msr. .msr
: enable-io-smis  ( -- )
   \ XXX these settings need to be folded into the MSR table for resume
   h# 0000.0009.c00fffc0. h# 5101.00e4 msr!  \ Virtualize ACPI registers
   1 h# 5101.0002 msr-clr  \ Enable SSMI in GLIU_GLD_MSR_SMI
   4 h# 5100.0002 msr-set  \ Enable SSMI in GLPCI_GLD_MSR_SMI

   \ Virtual registers
   h#    f030ac18. h# 1000.00e3 msr!   \ AC1C..AC1F
   h# 0.030f.fff0. h# 1000.00e2 msr!   \ 30..3f - for bouncing INTs to SMIs
   h#          80. h# 5140.0002 msr!   \ Port 92 INIT (bit 0 - reset)

   1 h# 1000.2002 msr-clr  \ AC1C generates SMI
   1 h# 1000.2003 msr-set  \ AC1C does not generate ERR
   1 h# 4000.2002 msr-clr

   h# 11 h# 4c00.2002 msr-clr  \   h# 10 h# 4c00.2002 msr-clr

   0. h# 1000.0083 msr!  \ Enable ASMIs in LX GLIU0
   0. h# 5101.0083 msr!  \ Enable ASMIs in 5536 GLIU0

   h# ff00  h# 1000.0082 msr-clr   h# ff00  h# 1000.0083 msr-clr
   h# ff00  h# 4000.0082 msr-clr   h# ff00  h# 4000.0083 msr-clr
   h# 38. h# 1301 msr!
;
\ 10002002 records ac1c accesses in bit 0  (1)
\ 51010002 records 9c00 accesses in bit 32 (1.0000.0000)
\ 51000002 records 9c00 accesses in bit 18 (     4.0000)
\ 4c002002 records 9c00 accesses in bit 20 (    10.0000)
: msr..    ( msr# -- )  dup 8 u.r space msr.  ."   "  ;
: .msr16s  ( msrhigh -- )  dup 8 u.r space msr@  drop 8 u.r ."   "  ;
: .msr2  ( msrhigh -- )
   dup 4 u.r  ." : "  >r
   h# 2002 dup 4 u.r space r@ wljoin  msr.  ."  "
   h# 2003 dup 4 u.r space r@ wljoin  msr.  ."  "
   r> drop  cr
;
: .msr4  ( msrhigh -- )
   dup 4 u.r  ." : "  >r
   h# 2002 dup 4 u.r space r@ wljoin  msr.  ."  "
   h# 2003 dup 4 u.r space r@ wljoin  msr.  ."  "
   h#   83 dup 2 u.r space r@ wljoin  msr@ drop 8 u.r  ."  "
   h#   84 dup 2 u.r space r@ wljoin  msr@ drop 8 u.r  ."  "
   r> drop  cr
;
: .msrs
   h# 5100 .msr2    \ PCI Southbridge  - XXX check RCONFs
   h# 5101 .msr4    \ GLIU

   h# 4c00 .msr2    \ GLCP - interface to 5536
   h# 1000 .msr4
   h# 4000 .msr4
   ."   " h# 1301 msr..   cr
;
: ma
   h# 10002002 msr-ack  h# 10002003 msr-ack 
   h# 40002002 msr-ack  h# 40002003 msr-ack 
   h# 51010002 msr-ack  h# 51010003 msr-ack
   h# 51000002 msr-ack  h# 51000003 msr-ack
   h# 4c002002 msr-ack  h# 4c002003 msr-ack
   \ h# 10000083 msr-ack  h# 40000083 msr-ack \ These have no status bits; nothing to ack
   \ h# 51010083 msr-ack \ This one has status bits, but they are RO
;

: smi-interact  ( -- )  ." In SMI" cr  interact  ;
' smi-interact is handle-smi

: vr-spoof?  ( -- handled? )  false  ;

: pci-smi  ( event-mask -- )
   8 and  0=  if  exit  then
   smm-io-port 3 invert and  h# cfc <>  if  exit  then
   vpci-debug?  if  h# 5000.2012 msr@ 2>r  0. h# 5000.2012 msr!  then

   \ The existing Forth config spoofer does the hard work
   smm-flags 2 and  if  \ Write
      smm-io-data  smm-config-adr   ( data config-adr )
      vpci-debug?  if  ." PW" smm-io-size . over . dup . cr  then
      smm-io-size case
         1 of  config-b!  endof
         3 of  config-w!  endof
         h# f of  config-l!  endof
      endcase
   else
      smm-config-adr                 ( config-adr )
      false  if  ." PR " dup . cr  then
      smm-io-size case
         1 of  config-b@ smm-eax c!  endof
         3 of  config-w@ smm-eax w!  endof
         h# f of  config-l@ smm-eax l!  endof
      endcase
   then
   vpci-debug?  if  2r> h# 5000.2012 msr!  then
;
: smm-eax-c!  ( b -- )  smm-eax c!  ;
: smm-eax-c@  ( -- b )  smm-eax c@  ;
0 value requested-mode
0 value color-depth   \ 1:8bpp 2:XRGB444 3:RGB555 4:RGB565 5:24bpp
0 value refresh-rate
0 value display-enable-reg  \ 01: FlatPanelEna  02: CRTEna  04: FixTimingEna 10: HSYNCDis 20: VSYNCDis
: do-display-enable   ;   \ XXX implement me
0 value ext-offset-low
0 value ext-offset-high
0 value ext-start-addr
: do-mode-switch  ( -- )
   1 and  if  ( XXX )  then
;
0 value crc-status
: start-crc  ( -- )   ( XXX )  ;
: dc-smi  ( event-mask -- )
   h# 10.0000 and 0=  if  exit  then  \ So far we only care about extended CRTC registers
   smm-flags 2 and  if  \ Write
      smm-eax-c@
      h# 3d4 pc@  case
         h# 33 of  start-crc              endof  \ CRC Command
         h# 34 of  drop                   endof  \ CRC Data
         h# 3f of  do-mode-switch         endof  \ Mode Switch start
         h# 40 of  to requested-mode      endof  \ Mode Number
         h# 46 of  to color-depth         endof  \ Extended Color Control
         h# 4f of  to refresh-rate        endof  \ Refresh rate
         h# 50 of  to display-enable-reg  do-display-enable  endof  \ Display Enable
         h# 51 of  to ext-offset-low   endof  \ Ext offset low
         h# 52 of  to ext-offset-high  endof  \ Ext offset high
         h# 54 of  to ext-start-addr   endof  \ Ext start
      endcase
   else                 \ Read
      h# 3d4 pc@  case
         h# 33 of  crc-status            endof  \ CRC Command
         h# 34 of  0                     endof  \ CRC Data
         h# 35 of  [char] A              endof  \ SoftVG ID1
         h# 36 of  [char] M              endof  \ SoftVG ID2
         h# 37 of  2                     endof  \ Major Version
         h# 38 of  d# 10                 endof  \ Minor Version
         h# 3e of  fbsize d# 19 rshift   endof  \ Graphics memory size
         h# 3f of  h# 82                 endof  \ Mode Switch start (Rev2silicon, FlatPanel)
         h# 40 of  requested-mode        endof  \ Mode Number
         h# 46 of  color-depth           endof  \ Extended Color Control
         h# 4f of  refresh-rate          endof  \ Refresh rate
         h# 50 of  display-enable-reg    endof  \ Display Enable
         h# 51 of  ext-offset-low        endof  \ Ext offset low
         h# 52 of  ext-offset-high       endof  \ Ext offset high
         h# 54 of  ext-start-addr        endof  \ Ext start
      endcase
      smm-eax-c!
   then
;

0 [if]
: vs  ( -- handled? )
   smm-io-port h# ac1c =  if
      ." V"
      h# 1000.2002 msr-ack
      \ h# 1000.2003 msr-ack  h# 4c00.2000 msr-ack  \ Don't need this; we suppress ERRs
      true exit
   then
   smm-io-port . cr
   h# 5100.0002 msr-ack  \ Ack in 5536 PCI SouthBridge (       4.0000 bit )
   h# 5101.0002 msr-ack  \ Ack in 5536 GLIU            (  1.0000.0000 bit )
   h# 4c00.2002 msr-ack  \ Ack in LX                   (      10.0000 bit )
   true exit
;
[then]

0 value vr-index
false value vr-debug?

true value vr-locked?

0 value rm-int@

defer handle-bios-call

: enable-softvg  ( -- )
   h# 10 h# 8000.2002 msr-clr  \ Enable SMI for invalid CRTC register
;
: rm-sp  ( -- adr )  smm-save-esp +smm w@  smm-save-ss +smm w@ seg:off>  ;
: do-vr  ( -- )
   \ ." VR "
   smm-io-port h# ac1c =  if
      smm-io-size  h# f  =  if
         smm-eax @  lwsplit  h# fc53 <>  to vr-locked?  ( low-word )
      else
         smm-eax w@  dup h# fc53 =  if  false to vr-locked?  then
      then      
      to vr-index
      exit
   then
   smm-io-size  h# 3 <>  if  true to vr-locked?  exit  then
   smm-flags 2 and  if
      vr-index case
         h#  200 of  ( enable-softvg )  endof
         ( default )
            ." VR Write " vr-index .  smm-eax @ .  cr
            false to exit-interact?  interact
      endcase
   else
      vr-index case
\         h# 200 of  fbsize d# 19 rshift  h# 8300 or  smm-eax w!  endof
         h#  200 of  fbsize d# 20 rshift  h# 8300 or  smm-eax w!  endof
         h#  211 of  d# 1199 smm-eax w!  endof
         h#  217 of  d#  899 smm-eax w!  endof
         h# 1201 of  cpu-mhz smm-eax w!  endof
         ( default )  ." VR Read " dup .   false to exit-interact?  interact
      endcase
   then
;
: gliu0-smi  ( event-mask -- )
   1 and 0=  if  exit  then     \ We only care about virtual register accesses

   smm-io-port h# fff0 and  h# 30 =  if
      smm-io-port h# 20 -  to rm-int@
      rm-sp la1+ >caller-physical w@  smm-rmeflags w!
      handle-bios-call
      smm-rmeflags w@  rm-sp la1+ >caller-physical w!
      exit
   then

   smm-io-port h# fffd and  h# ac1c <>  if  exit  then
   do-vr
;

defer quiesce-devices  ' noop to quiesce-devices

\ We just discard the event about I/O registers because we handle it in sb-smi .
\ We don't have to deal with statistics counters because we don't enable them
: cgliu-smi  ( event-mask -- )  drop  ;

: power-mode  ( value offset -- )
   over 1 and  if                                    ( value offset )
      dup acpi-l@ 1 and  0=  if  quiesce-devices  then   ( value offset )
   then                                              ( value offset )

   over h# 2000 and  if                              ( value offset )
      drop  d# 10 rshift  7 and case                 ( c:power-state )
         5 of  power-off  endof                      ( )
         ( default )  ." Requested power state " dup .
      endcase                                        ( )
   else                                              ( value offset )
      acpi-w!                                        ( )
   then                                              ( )
;

: divil-smi  ( event-mask -- )  h# 80 and  if  bye  then  ;

: sb-smi  ( event-mask -- )
   4 and 0=  if  exit  then     \ We only care about virtualized I/O registers

   smm-flags h# 40 and  if
       ." Flags " smm-flags . 0 acpi-l@ .  8 acpi-l@ . 18 acpi-l@ .  1c acpi-l@ .  cr
\      0 acpi-l@ 1 and  if  0 acpi-l@  0 acpi-l!  exit  else  interact  then
      exit
   then

   smm-io-port h# 9c00 -          ( acpi-offset )
   dup h# 40 u>= if
      drop
      ." I/O " smm-io-port .  interact
      exit
   then                           ( acpi-offset )

[ifdef] notdef
   dup h# 3c =  if                ( acpi-offset )
      drop                        ( )
      smm-flags 2 and  if         
         smm-eax c@  case
            h# a1 =  of  8 acpi-w@  1 or          8 acpi-w!  endof
            h# a2 =  of  8 acpi-w@  1 invert and  8 acpi-w!  endof
         endcase
      then
      exit
   then
[then]

   smm-flags 2 and  if  \ Write   ( acpi-offset offset )
      smm-eax l@  swap            ( value acpi-offset )
      smm-io-size case
         1 of                     ( value acpi-offset )
              acpi-b!
              \ ." W8 " smm-io-port .  smm-eax c@ .  cr  
              \ smm-io-port h# 9c1f =  smm-eax c@ h# c0 =  and  if  debug-me  then
         endof
         3 of                     ( value acpi-offset )
              dup case   ( value acpi-offset [acpi-offset] )
                 \ Workaround for 5536 errata - 16-bit writes to APCI registers
                 \ 0 and 2 corrupt other registers
                 0 of  drop  2 acpi-w@      wljoin  0 acpi-l!  endof
                 2 of  drop  0 acpi-w@ swap wljoin  0 acpi-l!  endof
                 8 of  power-mode  endof
                 ( default: value port-adr acpi-offset )  -rot acpi-w!
              endcase
              \ ." W16 " smm-io-port .  smm-eax w@ . cr
         endof
         h# f of
              dup 8 =  if  power-mode  else  acpi-l!  then
              \ ." W32 " smm-io-port .  smm-eax w@ .  cr
         endof
      endcase
   else                           ( acpi-offset )
      smm-io-size case
         1 of                     ( acpi-offset )
               acpi-b@  smm-eax c!
               \ ." R8 " smm-io-port .  smm-eax c@  .  cr
         endof
         3 of                     ( acpi-offset )
               acpi-w@  smm-eax w!
               \ ." R16 " smm-io-port .  smm-eax w@  .  cr
               \ smm-io-port h# 9c00 =  if  ." ."  then
         endof
         h# f of                  ( acpi-offset )
               acpi-l@  smm-eax l!
               \ smm-io-port  h# 9c10 <>  if  ." R32 " smm-io-port .  smm-eax l@  .  cr  then
         endof
      endcase
   then
;

code smi  smint  c;

variable sbpval
variable sbpadr  sbpadr off
defer sbp-hook

: .9x  push-hex  9 u.r  pop-base  ;
: .smir   ( n -- )   smm-gregs swap la+  l@ .9x  ;
: .smiregs   ( -- )
   ."       EAX      EBX      ECX      EDX      ESI      EDI      EBP      ESP" cr
        7 .smir  4 .smir  6 .smir  5 .smir  1 .smir  0 .smir  2 .smir  smm-save-esp +smm l@ .9x
   cr
   ." CS: " smm-cs-sel 5 u.r
   ."  DS: " smm-sregs 6 + w@ 5 u.r
   ."  ES: " smm-sregs 4 + w@ 5 u.r
   ."  FS: " smm-sregs 2 + w@ 5 u.r
   ."  GS: " smm-sregs 0 + w@ 5 u.r
   ."  SS: " smm-save-ss +smm w@ 5 u.r
   cr
;
: .smipc  ( -- )  ." SMI at " smm-pc .9x cr ;
' .smipc to sbp-hook

: .callto  ( retadr -- )
   dup  ['] smm>physical  catch  if  2drop exit  then  ( retadr pretadr )
   dup 5 - c@ h# e8 <>  if  2drop exit  then           ( retadr pretadr )
   4 - l@ + 9 u.r
;
: smm-trace  ( -- )
   ."      EBP   RETADR   CALLTO" cr
   smm-ebp
   begin  ?dup  while                           ( ebp )
      dup 8 u.r  smm>physical                   ( padr )
      dup la1+ l@ dup 9 u.r  .callto  cr        ( padr )
      l@                                        ( ebp' )
   repeat
;

: fixsbp  ( -- )
   sbpadr @  if
      sbpval @  sbpadr @ smm>physical  w!
      sbpadr off
   then
;

: unboost  ( adr -- adr' )  h# 7fff.ffff and  ;
: sbp  ( adr -- )
   fixsbp
   dup smm>physical w@  sbpval !  dup sbpadr !
   h# 380f swap smm>physical w!
;
: sdis  ( -- )  smm-pc smm>physical dis  ;
: sgo  ( -- )  smm-pc smm-next-eip!   resume  ;

h# 806f1a41 constant 'bioscall
: hack-fix-mode  ( -- )
   'bioscall smm>physical  5  h# 90  fill   \ Nop-out "call hal!HalpBiosCall" that dies
   'bioscall sbp
;

: l!++  ( adr l -- adr' )  over l!  la1+  ;
: w!++  ( adr w -- adr' )  over w!  wa1+  ;

code rm-lidt  ( -- )  smm-rmidt #) lidt  c;

: rm-setup  ( eip -- )
   >seg:off 2>r   ( r: off seg )

   smm-header h# 30 -
   h#      38  l!++          \ SMM_CTL
   0           l!++          \ I/O DATA
   0           l!++          \ I/O ADDRESS, I/O SIZE
   h#  938009  l!++          \ SS_FLAGS, SMM Flags
   h#    ffff  l!++          \ CS_LIMIT
   r@ 4 lshift l!++          \ CS_BASE
   r>  h# 9a wljoin l!++     \ CS_FLAGS.CS_INDEX
   r>          l!++          \ NEXT_IP
   0           l!++          \ CURRENT_IP
   h# 10       l!++          \ CR0
   h# 2        l!++          \ EFLAGS
   h# 400      l!++          \ DR7
   drop

   smm-sregs 4 /w* erase  smm-gregs 8 /l* erase
   0 smm-save-esp +smm  l!

   smm-save-seg +smm
   h# ffff l!++  h# 9300 l!++  0 w!++  \ DS
   h# ffff l!++  h# 9300 l!++  0 w!++  \ ES
   h# ffff l!++  h# 9300 l!++  0 w!++  \ FS
   h# ffff l!++  h# 9300 l!++  0 w!++  \ GS
   h# ffff l!++  h# 9300 l!++  0 w!++  \ SS

   h# ffff smm-rmidt w!  0 smm-rmidt wa1+ l!  \ Limit and base

   \ Interrupts are off because we are in SMM
   rm-lidt
;
\ : rm-init-program   ( eip -- )  rm-init-program  rm-return  ;

-1 value rm-entry-adr
: rm-run  ( eip -- )  to rm-entry-adr  smi  ;

: soft-smi  ( -- )
   rm-entry-adr -1 <>  if
      rm-entry-adr  rm-setup
      -1 to rm-entry-adr
      exit
   then

   sbpadr @  if
      sbpadr @ smm>physical  smm-pc smm>physical <>  if
         ." Not at SMI breakpoint!" cr
         .smipc
         .smiregs
      else
         fixsbp
      then
      sbp-hook
   then

smm-pc 'bioscall =  if  " set-mode12" eval  sgo  else
   smi-interact
then
;
\ smm-flags values in various cases:
\  8080 (VGA) - ac1c read (VR), extended CRT register (dc-smi)
\  8020 (Mem read) - 9cxx (power management) register (sb-smi)
\  8022 (Mem Write) - port 92 write

\ : msr@!  ( msr# -- d.value )  >r r@ msr@  2dup r> msr!  ;
: smi-dispatch  ( -- )
   smm-flags h#  8 and       if   soft-smi  then

\ CPU chip SMIs
   h# 5000.2003 msr-sense16  if    pci-smi  then

\  Commented-out lines are for devices we don't enable for SMIs
   h# 8000.2003 msr-sense32  if     dc-smi  then
\  h# a000.2003 msr-sense32  if     gp-smi  then
\  h# 5400.2003 msr-sense16  if    vip-smi  then
\  h# 5800.2003 msr-sense32  if    aes-smi  then
\  h# 4c00.2003 msr-sense16  if   glcp-smi  then  \ Companion SMI isn't clearable

   h# 1000.2003 msr-sense32  if  gliu0-smi  then  \ Virtual register
\  h# 4000.2003 msr-sense32  if  gliu1-smi  then  \ Incoming cycles

\ Companion chip (5536) SMIs

   h# 5140.0003 msr-sense32p if  divil-smi  then
   h# 5100.0003 msr-sense16p if     sb-smi  then
   h# 5101.0003 msr-sense32  if  cgliu-smi  then
\  h# 5170.0003 msr-sense16  if  cglcp-smi  then

\   smm-flags h# 80 and  if  virtualize-io  then
;
' smi-dispatch is handle-smi

: .dt  ( adr limit -- )
   1+  8 max  8  ?do                     ( gdt-adr )
      dup i + d@  dup  if                ( gdt-adr descr )
         i 3 u.r space .descriptor cr    ( gdt-adr )
      else                               ( gdt-adr descr )
         2drop                           ( gdt-adr )
      then                               ( gdt-adr )
   8 +loop                               ( gdt-adr )
   drop
;

: .smm-gdt  ( -- )
   smm-save-gdt +smm  dup 2+ l@ smm>physical  ( 'gdt gdt-adr )
   swap w@                               ( gdt-adr gdt-limit )
   .dt                                   ( )
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
   enable-io-smis
;

0 [if]
SMI sources:
LX:

+ 5000.2002   Virtual PCI header is 8.0000,  MPCI_ERROR is 17.0000  \ PCI bridge
    clear errors 5000.2003
+ 8000.2002   Display Controller  - many bits, for SoftVGA
    clear errors 8000.2003
* 1000.2002   statistics is 1e.0000, VR is 1.0000
    clear errors 1000.2003
* 4000.2002   statistics is 1e.0000, VR is 1.0000
    clear errors 1000.2003

5536:
+ 5140.0002  16 bits for HLT, SHTDWN, KEL, PIC, PM, KEL_INIT, PORTA_A20, PORTA_INIT, UART1/2, LPC, DMA, KEL_A20, PM2/1_CNT
     clear errors 5140.0003

  5100.0002 (PCI SouthBridge) - VSA just clears the SMIs in this register and uses the next register for dispatch
     clear errors 5100.0003
   
* 5101.0002 (5536 GLIU) - virtual register is 1.0000.0000, statistics is 1e.0000.0000
     clear errors 5101.0003
   
VSA collects events from + and * registers

For the * registers, it uses a common subroutine that ORs together all the
1.0000.0000 bits to make a combined "virtual I/O" event, and saves the
statistics bits for each register separately.

It is important to clear (ack) all the SMI and error bits to prevent re-entering the SMI handler
due to unhandled conditions.

PCI BARs:
  810 0000ac1d  northbridge

  910 fd000000  FB  914 fe000000  GP   918 fe004000 VG   91c  fe008000 DF  920 fe00c000 VIP
      be000000          bc000000  PW       bfff8000 9         bfff0000         bffec000

 a10 fe010000  aes

80007810 000018b1  ISA
80007b10 00001481  AC97
80007c10 fe01a000  ohci
80007d10 fe01b000  ehci

  bar 910
  msr: 0000.1810 fdfff000.fd000111.  \ Video (write through), fbsize
\ msr: 1000.0029 20a7e0fd.ffffd000.  \ fd00.0000 - fdff.ffff mapped to f00.0000 Memsize dependent, fbsize dependent
  msr: 4000.002a 200000fd.ffffd000.  \ frame buffer - fd00.0000 .. fdff.ffff, route to GLIU0, fbsize

  msr: a000.2001 00000000.0fde0000.  \ CBASE field is FB addr + 14M, fbsize

  bar 914
  msr: 0000.1811 fe003000.fe000101.  \ GP registers non-cacheable
  msr: 1000.0022 a00000fe.000ffffc.  \ fe00.0000 - fe00.3fff GP
  msr: 4000.0022 200000fe.000ffffc.  \ fe00.0000 - fe00.03ff GP, route to GLIU0

  bar 918
  msr: 0000.1812 fe007000.fe004101.  \ DC registers non-cacheable
  msr: 1000.002a 801ffcfe.007fe004.  \ fe00.4000 - fe00.7fff mapped to 0 in DC space
  msr: 4000.0024 200000fe.004ffffc.  \ fe00.4000 - fe00.7fff DC, route to GLIU0

  bar 91c
  msr: 0000.1813 fe00b000.fe008101.  \ VP registers non-cacheable
  msr: 1000.0023 400000fe.008ffffc.  \ fe00.8000 - fe00.bfff VP in GLIU1
  msr: 4000.0025 400000fe.008ffffc.  \ fe00.8000 - fe00.bfff VP, route to VP in GLIU1

  bar 920
  msr: 0000.1814 fe00f000.fe00c101.  \ VIP registers non-cacheable
  msr: 1000.0024 400000fe.00cffffc.  \ fe00.8000 - fe00.bfff VIP in GLIU1
  msr: 4000.0026 a00000fe.00cffffc.  \ fe00.c000 - fe00.ffff VIP, route to VIP in GLIU1



  a10
  msr: 0000.1815 fe013000.fe010101.  \ AES registers non-cacheable
  msr: 1000.0025 400000fe.010ffffc.  \ fe01.0000 - fe01.3fff security block in GLIU1
  msr: 4000.002b c00000fe.013fe010.  \ Security Block - fe01.0000 .. fe01.3fff

  bar 7c10
  msr: 5100.0027 fe01a000.fe01a001.  \ OHCI             Rconf
  msr: 5140.0009 fffff001.fe01a000.  \ LBAR_KEL (USB)
  msr: 5120.0008 0000000e.fe01a000.  \ USB OHC Base Address - 5536 page 266  P2D-Range
  msr: 5101.0023 500000fe.01afffff.  \ P2D_BMK Descriptor 0 OHCI

  bar 7d10
  msr: 5100.0028 fe01b000.fe01b001.  \ EHCI
  msr: 5101.0024 400000fe.01bfffff.  \ P2D_BMK Descriptor 1 EHCI
  msr: 5120.0009 0000200e.fe01b000.  \ USB EHC Base Address - 5536 page 266 FLADJ set

  msr: 5100.0029 efc00000.efc00001.  \ UOC
  msr: 5101.0020 400000ef.c00fffff.  \ P2D_BM0 UOC
  msr: 5120.000b 00000002.efc00000.  \ USB UOC Base Address - 5536 page 266


[then]

\  setup-rm-gateway  ( -- ) Init this module
\  caller-regs  ( -- adr )  Base address of incoming registers
\  rm-int@      ( -- n )    Incoming interrupt number
\  rm-buf       ( -- adr )  Base address of a real-mode accessible buffer
\  rm-init-program  ( eip -- )  Setup to enter real mode program on next rm-return
\  rm-return    ( -- )      Resume execution of real-mode caller.  Returns when program does a BIOS INT.
\ Sequence:
\  setup-rm-gateway  ( eip ) rm-enter  begin  handle-bios-call rm-return  again


: setup-rm-gateway  ( -- )
   int-entry  'int10-dispatch  /int-entry move   

   \ Prime with unused interrupt 1f
   h# 100  0  do
      'int10-dispatch h# f la+  i /l*  seg:off!
   loop

   h# 10  0  do
      'int10-dispatch i la+  h# 10 i + /l*  seg:off!
   loop
;


\ : caller-regs  ( -- adr )  smm-sregs  ;
\ : rm-buf  ( -- adr )  smm-rmbuf  ;

\ : doit  setup-smi disk-name open-dev is disk-ih get-mbr usb-quiet  ff 21 pc! h# 380f  h# 7c18 w!  smi ;
