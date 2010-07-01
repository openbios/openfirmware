purpose: SMI setup and handler for Intel-compatible system management mode

also assembler definitions
: rsm    ( -- )  prefix-0f  h# aa asm8,  ;
previous definitions

\ Location of the SMM handler code...
\ The general naming convention here is that smm-* refers to
\ addresses within the memory that is set aside for SMI handling.
\ smi-* refers to stuff in the Forth domain.

h#    3.8000 constant smm-base0   \ Default after power up
h#    a.0000 constant smm-base    \ We switch to this - hidden behind the VGA frame buffer
h#    1.0000 constant smm-size

: +smm-offset  h# 8000 +  ;
: +smm  ( segment-relative-adr -- adr )  smm-base +  ;
: -smm  ( adr -- segment-relative-adr )  smm-base -  ;

\ This is a trick for using SMM to handle BIOS INTs.  The problem it solves
\ is that Windows sometimes calls the BIOS from V86 mode instead of real mode.
\ V86 mode prevents easy entry into protected mode (and we want to run OFW
\ in protected mode), so we first trap into SMM by accessing some emulated
\ registers, and run OFW code from SMM protected mode.  The following is a
\ table of "INT handler" instruction sequences indexed by the INT number.

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

\ Data structures for the SMM gateway

h# 28 constant /smm-gdt   \ GDT size - 4 entries plus nonce entry at beginning

\ Protected mode selector values
h#  8 constant smm-c16
h# 10 constant smm-d16
h# 18 constant smm-c32
h# 20 constant smm-d32

\ For stuff that grows down - add the offset first
: smm-data ( offset "name" -- offset' )       constant  ;
: pm-data  ( offset "name" -- offset' )  +smm constant  ;

\ Layout of SMM memory area:
\ h# 8000 smm-data smm-gdt         \ Entry/exit handler code at the entry offset
                                 \ The GDT is embedded in the code wad
                                 \ The handler code takes about h# 160 bytes

\ h# f400 pm-data smm-sp0          \ SMM Forth data   stack - h# 400 bytes
\ h# f800 pm-data smm-rp0          \ SMM Forth return stack - h# 400 bytes

\ h# fc00  pm-data 'int10-dispatch \ Array of instruction sequences for bouncing INTs through SMI

\ fcxx - fcff available

\ These locations are set once at installation time.  The entry code reads them.
h# fd00 pm-data smm-pdir         \ Page directory pointer so we can enable paging
h# fde4 pm-data smm-forth-base   \ Base address of the Forth dictionary
h# fde8 pm-data smm-forth-up     \ Base address of the Forth user area
h# fdec pm-data smm-forth-entry  \ Entry address of Forth SMI handler
h# fdf0 pm-data smm-save-sp0     \ Exchanged with sp0 user variable
h# fdf4 pm-data smm-save-rp0     \ Exchanged with rp0 user variable

\ The following locations are for saving/restoring registers

h# fdf8 pm-data  smm-save-cf8    \ Saved value of PCI config index

\ The following locations are defined by the CPU

\ h# fe00 .. 7ef7 - reserved

h# fef8 smm-data smm-smbase
h# fefc smm-data smm-revid
h# fff0 smm-data smm-io-restart
h# ff02 smm-data smm-hlt-restart

h# ff04 smm-data smm-io-restart-edi
h# ff08 smm-data smm-io-restart-ecx
h# ff0c smm-data smm-io-restart-esi
h# ff10 smm-data smm-io-restart-eip

h# ff28 smm-data smm-cr4

h# ff30 smm-data smm-es-limit
h# ff34 smm-data smm-es-base
h# ff38 smm-data smm-es-access

h# ff3c smm-data smm-cs-limit
h# ff40 smm-data smm-cs-base
h# ff44 smm-data smm-cs-access

h# ff48 smm-data smm-ss-limit
h# ff4c smm-data smm-ss-base
h# ff50 smm-data smm-ss-access

h# ff54 smm-data smm-ds-limit
h# ff58 smm-data smm-ds-base
h# ff5c smm-data smm-ds-access

h# ff60 smm-data smm-fs-limit
h# ff64 smm-data smm-fs-base
h# ff68 smm-data smm-fs-access

h# ff6c smm-data smm-gs-limit
h# ff70 smm-data smm-gs-base
h# ff74 smm-data smm-gs-access

h# ff78 smm-data smm-ldtr-limit
h# ff7c smm-data smm-ldtr-base
h# ff80 smm-data smm-ldtr-access

h# ff84 smm-data smm-gdtr-limit
h# ff88 smm-data smm-gdtr-base
h# ff8c smm-data smm-gdtr-access

h# ff90 smm-data smm-idtr-limit
h# ff94 smm-data smm-idtr-base
h# ff98 smm-data smm-idtr-access

h# ff9c smm-data smm-tr-limit
h# ffa0 smm-data smm-tr-base
h# ffa4 smm-data smm-tr-access

h# ffa8 smm-data smm-es
h# ffac smm-data smm-cs
h# ffb0 smm-data smm-ss
h# ffb4 smm-data smm-ds
h# ffb8 smm-data smm-fs
h# ffbc smm-data smm-gs
h# ffc0 smm-data smm-ldtr
h# ffc4 smm-data smm-tr
h# ffc8 smm-data smm-dr7
h# ffcc smm-data smm-dr6
h# ffd0 smm-data smm-eax
h# ffd4 smm-data smm-ecx
h# ffd8 smm-data smm-edx
h# ffdc smm-data smm-ebx
h# ffe0 smm-data smm-esp
h# ffe4 smm-data smm-ebp
h# ffe8 smm-data smm-esi
h# ffec smm-data smm-edi
h# fff0 smm-data smm-eip
h# fff4 smm-data smm-eflags
h# fff8 smm-data smm-cr3
h# fffc smm-data smm-cr0

\ Layout of saved registers, used by biosints.fth

: caller-regs  ( -- adr )  smm-es +smm  ;

0 value rm-regs

struct
  4 field >rm-es
  4 field >rm-cs
  4 field >rm-ss
  4 field >rm-ds
  4 field >rm-fs
  4 field >rm-gs
  d# 16 +  \ LDTR, TR, DR7, DR6
  4 field >rm-eax
  4 field >rm-ecx
  4 field >rm-edx
  4 field >rm-ebx
  4 field >rm-esp
  4 field >rm-ebp
  4 field >rm-esi
  4 field >rm-edi
  4 field >rm-eip
  4 field >rm-eflags
constant /rm-regs

\ The basic SMI gateway.  This code lives at (is copied to) smm-base + h# 8000.
\ It executes when the processor enters System Management Mode (SMM)
\ for whatever reason.  It saves a bunch of state, sets up the world
\ so Forth code can run (in 32-bit protected mode), and runs the Forth
\ handler - typically "smi-dispatch" (via smm-exec and handle-smi).

create smm-gdt-template
   /smm-gdt 1- w,   smm-gdt l,       \ GDT pointer - limit.w base.l
   0 w,

   smm-base smm-size 1- code16 format-descriptor  swap l, l,  \  8 - smm-c16
   smm-base smm-size 1- data16 format-descriptor  swap l, l,  \ 10 - smm-d16
   0                 -1 code32 format-descriptor  swap l, l,  \ 18 - smm-c32
   0                 -1 data32 format-descriptor  swap l, l,  \ 20 - smm-d32
   \ End of GDT


label smi-handler
   16-bit

0 [if]
   \ GDT (with jump tucked in at the beginning)
   \ We put the GDT right at the beginning and use the first entry (which
   \ cannot be used as a selector) for a 2-byte jmp and the 6-byte GDT pointer
   here /smm-gdt + #) jmp                          \ Jump past GDT - 2 bytes

   /smm-gdt 1- w,   smm-base +smm-offset l,       \ GDT pointer - limit.w base.l

   smm-base smm-size 1- code16 format-descriptor  swap l, l,  \  8 - smm-c16
   smm-base smm-size 1- data16 format-descriptor  swap l, l,  \ 10 - smm-d16
   0                 -1 code32 format-descriptor  swap l, l,  \ 18 - smm-c32
   0                 -1 data32 format-descriptor  swap l, l,  \ 20 - smm-d32
   \ End of GDT
[then]

   cs ax mov  ax ds mov

wbinvd

0 [if]
\ Get into protected mode using the same segments 
\ Don't bother with the IDT; we won't enable interrupts
   op: smm-gdt 2+ #) lgdt
[else]
   ad: op: smm-gdt smm-base - #) lgdt
[then]

\ ascii a report

   cr0 ax mov  1 # al or  ax cr0 mov   \ Enter protected mode

   op: here 7 + smi-handler -  +smm +smm-offset   smm-c32 #)  far jmp
   32-bit

   \ Reload segment registers with protected mode selectors
   op: smm-d32 # ax mov
   ax ds mov  ax es mov  ax fs mov  ax gs mov  ax ss mov

[ifdef] virtual-mode
   \ Turn on paging
   smm-pdir #)  ax  mov   ax cr3  mov	\ Set Page Directory Base Register
   cr4 ax mov  h# 0000.0010 # ax or  ax cr4 mov	 \ Turn on PSE bit (allow 4M pages)
   cr0 ax mov  h# 8000.0000 # ax or  ax cr0 mov	 \ Turn on Paging Enable bit
[then]

   h# cf8 #  dx   mov   \ Save PCI config address
   dx        ax   in
   ax  smm-save-cf8 #)  mov

\ Beginning of Forth-specific stuff
   smm-forth-base  #)  bx  mov
   smm-forth-up    #)  up  mov
   smm-forth-entry #)  ip  mov

   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0 sp mov  smm-save-sp0 #) sp xchg  sp 'user sp0 mov
   'user rp0 rp mov  smm-save-rp0 #) rp xchg  rp 'user rp0 mov

   cld
c;

\ When the Forth SMI handler finishes, it calls (smi-return) to return
\ to the context that invoked the SMI.  This is the inverse of smi-handler.

code (smi-return)   \ This code field must be relocated after copying to SMM memory
   cli

   \ Exchange the stack and return stack pointer with the smi versions
   'user sp0 sp mov  smm-save-sp0 #) sp xchg  sp 'user sp0 mov
   'user rp0 rp mov  smm-save-rp0 #) rp xchg  rp 'user rp0 mov

   \ End of Forth-specific stuff

   smm-save-cf8 #)  ax  mov     \ Restore PCI config address
   h# cf8 #  dx  mov
   ax    dx  out

[ifdef] virtual-mode
   \ Turn off paging
   cr0 ax mov  h# 8000.0000 invert # ax and  ax cr0 mov	 \ Turn off Paging Enable bit
[then]

   here 7 +  smi-handler - +smm-offset  smm-c16 #)  far jmp     \ Get into the boosted segment
   16-bit

   \ Now we are in protected mode executing from a 16-bit code segment
   \ whose selector has a base of A0000.

   smm-d16 # ax mov  ax ss mov  ax ds mov      \ Reload data and stack segments

   cr0 ax mov  1 invert # al and  ax cr0 mov   \ Exit protected mode
   here 5 +  smi-handler - +smm-offset  smm-base 4 rshift #)  far jmp    \ Set CS for real mode

   wbinvd

   rsm
end-code
here smi-handler - constant /smi-handler

: smm@  ( offset -- n )  +smm @  ;
: smm!  ( n offset -- )  +smm !  ;

\ Address of segment registers
: 'smm-eax  ( -- adr )  smm-eax +smm  ;

\ Finds a page table or page directory entry
\ Implementation factor of (smm>physical)
: >ptable  ( table vadr shift -- table' unmapped? )
   rshift  h# ffc and + l@
   dup h# fff invert and  swap 1 and 0=
;
\ Finds a page table or page directory entry
\ Implementation factor of (smm>physical)
: >ptable64  ( table vadr shift -- table' unmapped? )
   rshift  h# ff8 and + l@               \ Ignore high word for now
   dup h# fff invert and  swap 1 and 0=
;

\ Converts a virtual address to a physical address via the page tables
\ This is used by debugging tools, so that we can look at OS resources
\ via their virtual addresses while we are running with paging disabled.
\ XXX need to handle mapped-at-pde-level
defer smm>physical
: ?unmapped  ( unmapped? -- )
\  abort" Unmapped"  
   if   ." Unmapped " debug-me  then  
;
: vadr>pframe64  ( vadr pdpt -- padr )
   over d# 27 >ptable64  ?unmapped  ( vadr pdir )
   over d# 18 >ptable64  ?unmapped  ( vadr ptab )
   over d#  9 >ptable64  ?unmapped  ( vadr pframe )
;
: vadr>pframe32  ( vadr pdir -- vadr pframe )
   over d# 20 >ptable  ?unmapped  ( vadr ptab )
   over d# 10 >ptable  ?unmapped  ( vadr pframe )
;

: (smm>physical)  ( vadr -- padr )
   smm-cr3 smm@                          ( vadr pdir )
   smm-cr4 smm@ h# 20 and  if  \ Physical Address Extension enabled
      vadr>pframe64
   else
      vadr>pframe32
   then
   swap h# fff and +

;

' (smm>physical) to smm>physical

: smm-map?  ( vadr -- )  smm>physical  .  ;

\ Linear address of the EIP, accounting for the code segment value
\ This is the return address in the SMM handler's 0-based memory map.
: smm-eip-la  ( -- adr )  smm-eip smm@  smm-cs-base smm@ +  ;

\ Programs that write to the caller's data space should use this,
\ as it works when called from paged V86 mode.
: >caller-physical  ( vadr -- padr )
   smm-cr0 smm@  h# 8000.0000 and  if  (smm>physical)  then
;

\ Turn address translation on or off for the following commands,
\ so they can be used either for non-paged calling code like
\ early bootloaders or for paged code that calls to us via a
\ real mode gateway.

: use-physical  ( -- )  ['] noop to smm>physical  ;
: use-virtual   ( -- )  ['] (smm>physical) to smm>physical  ;

\ Some simple glue code to help make the transition from assembly language
\ to Forth and back.

: smi-return  ( -- )  [ ' (smi-return) smi-handler -  +smm +smm-offset  ] literal  execute  ;
defer handle-smi  ' noop is handle-smi
create smm-exec  ] handle-smi smi-return [

\ Set to true to display brief messages showing every entry to SMM
false value smi-debug?

\ Set to true to invoke the Forth debugger when the OS tries to suspend (S3)
false value resume-debug?

\ This is a stub SMI handler that just invokes the Forth command
\ interpreter so you can poke around.  Normally handle-smi calls
\ smi-dispatch to do all the virtualization work, instead of this.

: smi-interact  ( -- )  ." In SMI" cr  interact  ;
' smi-interact is handle-smi

: smm-eax-c!  ( b -- )  'smm-eax c!  ;
: smm-eax-c@  ( -- b )  'smm-eax c@  ;

0 value rm-int@

defer handle-bios-call

: rm-sp  ( -- adr )  smm-esp +smm w@  smm-ss +smm w@ seg:off>  ;

\ bios-int-smi is for accesses to the 0x30..0x3f I/O port bank that we "steal" for
\ bouncing BIOS INTs into SMM.

: caller-32bit?  ( -- flag )  smm-cs-access smm@ h# 4000 and  ;

: caller-sp  ( -- laddr )
   caller-32bit?  if  smm-esp smm@  else  rm-sp  then
;

: bios-int-smi  ( -- )
   caller-32bit?  if  noop exit  then
   \ Handle BIOS INTs that were bounced into SMM by accessing
   \ I/O ports 0x30..0x3f
   h# 58 acpi-w@  dup h# fff0 and  h# 30  =  if   \ Via
      h# 20 -  to rm-int@
      caller-sp la1+ >caller-physical w@  smm-eflags +smm w!
      \ Bias by -2 to point to INT instruction
[ifdef] notyet
      rm-sp >caller-physical l@ 2-  smm-eip l!
[then]
      handle-bios-call
      smm-eflags +smm w@  caller-sp la1+ >caller-physical w!
      exit
   else
      drop
   then
;

\ This hook can be set to turn off devices that the firmware uses.
\ It is called when the OS takes responsibility for power management
\ by writing a 1 to bit 0 of the ACPI PM1_CNT .

defer quiesce-devices  ' noop to quiesce-devices

\ This is a gateway to get into real mode by going through SMM .
\ It's used to implement the ACPI "resume from S3" semantics that
\ require jumping to a given address in real mode.

: #smint  ( n -- )  h# 2f acpi-b!  ;  \ Via

: rm-run  ( 'gregs eip -- )  swap to rm-regs  rm-regs >rm-eip !  h# f0 #smint  ;

defer suspend-devices  ' noop to suspend-devices
defer resume-devices   ' noop to resume-devices

defer freeze-ps2    ' noop to freeze-ps2
defer unfreeze-ps2  ' noop to unfreeze-ps2

\ SMI breakpoints - simple (but very useful) debugging tool.

variable sbpval
variable sbpadr  sbpadr off
defer sbp-hook

: .9x  push-hex  9 u.r  pop-base  ;
: .smir   ( offset -- )   smm@ .9x  ;
: .smis   ( offset -- )   smm@ 5 u.r  ;


\ Displays the saved register values

: .smiregs   ( -- )
   ."       EAX      EBX      ECX      EDX      ESI      EDI      EBP      ESP" cr
     smm-eax .smir  smm-ebx .smir  smm-ecx .smir  smm-edx .smir
     smm-esi .smir  smm-edi .smir  smm-ebp .smir  smm-esp .smir
   cr
   ." CS: "  smm-cs .smis
   ."  DS: " smm-ds .smis
   ."  ES: " smm-es .smis
   ."  FS: " smm-fs .smis
   ."  GS: " smm-gs .smis
   ."  SS: " smm-ss .smis
   cr
;
: .smipc  ( -- )  ." SMI at " smm-eip .smir cr ;
' .smipc to sbp-hook

: .callto  ( retadr -- )
   dup  ['] smm>physical  catch  if  2drop exit  then  ( retadr pretadr )
   dup 5 - c@ h# e8 <>  if  2drop exit  then           ( retadr pretadr )
   4 - l@ + 9 u.r
;

\ Displays a subroutine call backtrace.  This pretty dependent on compiler
\ code generation rules, so it might not work in some cases.

: smm-trace  ( -- )
   ."      EBP   RETADR   CALLTO" cr
   smm-ebp smm@
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

\ Set an SMI breakpoint at "adr".  You can only set one breakpoint.
\ "adr" is either virtual or physical depending on whether you have
\ previously executed "use-physical" or "use-virtual"

: sbp  ( adr -- )
   fixsbp
   dup smm>physical w@  sbpval !  dup sbpadr !
   h# 380f swap smm>physical w!
;

\ Disassemble starting from the breakpoint address

: sdis  ( -- )  smm-eip smm@ smm>physical dis  ;

\ Resume execution of the breakpointed code

: sgo  ( -- )  ( smm-eip smm@ smm-next-eip! )  resume  ;

: l!++  ( adr l -- adr' )  over l!  la1+  ;
: w!++  ( adr w -- adr' )  over w!  wa1+  ;

\ rm-setup fudges the saved SMM state so that, instead of returning
\ to the context that invoked the SMI, the next exit from SMM returns
\ to the address "eip" in real mode.  This is an implementation
\ factor of the "rm-run" mechanism.

: set-segment  ( base limit access 'seg-save -- )
   >r               ( base limit access )
   r@ 8 + smm!      ( base limit )  \ Set access rights field
   r@ smm!          ( base )        \ Set limit field
   r> 4 + smm!      ( )       \ Set base field
;
: set-data-segment  ( base 'seg-save -- )
   \   >r  h# ffff  h# 4093  r> set-segment
   >r  h# ffffffff  h# 0092  r> set-segment
;

: rm-setup  ( -- )
   rm-regs >rm-eip @  >seg:off  ( off seg )
   swap smm-eip smm!            ( seg )
   dup smm-cs smm!              ( seg )
   4 lshift h# ffff  h# 009a  smm-cs-limit set-segment

   rm-regs >rm-ds w@  dup smm-ds-limit set-data-segment   smm-ds smm!
   rm-regs >rm-es w@  dup smm-es-limit set-data-segment   smm-es smm!
   rm-regs >rm-fs w@  dup smm-fs-limit set-data-segment   smm-fs smm!
   rm-regs >rm-gs w@  dup smm-gs-limit set-data-segment   smm-gs smm!
   rm-regs >rm-ss w@  dup smm-ss-limit set-data-segment   smm-ss smm!

   0 h#  3ff h# 82  smm-idtr-limit  set-segment
   0 h# ffff h# 83  smm-tr-limit    set-segment     0 smm-tr   smm!
   0       0 h# 82  smm-ldtr-limit  set-segment     0 smm-ldtr smm!   

   \ gdtr - leave alone, GDT shouldn't matter in real mode
   \ cr3  - leave alone, PDE base shouldn't matter with paging disabled

   h#       10  smm-cr0    smm!  \ Paging and Protected Mode off
   h#       10  smm-cr4    smm!  \ Page size extension on
   h# ffff0ff0  smm-dr6    smm!  \ Value after init (status register)
   h#      400  smm-dr7    smm!  \ Value after init - no breakpoints set

   0 smm-tr smm!

   0 smm-io-restart smm!  \ Clear IO-restart and HLT-restart

   rm-regs >rm-eflags @  2 or  smm-eflags smm!  \ 2 bit is "Must Be One"

   rm-regs >rm-esp @  smm-esp smm!
   rm-regs >rm-eax @  smm-eax smm!
   rm-regs >rm-ebx @  smm-ebx smm!
   rm-regs >rm-ecx @  smm-ecx smm!
   rm-regs >rm-edx @  smm-edx smm!
   rm-regs >rm-ebp @  smm-ebp smm!
   rm-regs >rm-esi @  smm-esi smm!
   rm-regs >rm-edi @  smm-edi smm!
;
\ : rm-init-program   ( eip -- )  rm-init-program  rm-return  ;

\ Handler for software SMIs, i.e. for explicit execution of the
\ SMINT instruction.  It's used for things like the rm-run facility
\ and SMI breakpoints.

: soft-smi  ( -- )
   smi-debug?  if  ." SOFT" cr  then
   h# 2f acpi-b@ h# f0 =  if
      rm-setup
      exit
   then

[ifdef] notyet
   smm-pc smm-eip l!   \ So .caller-regs will work
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
[then]

\   h# 2f acpi-b@ case
\      1 of  ." Entered from ACPI _PTS "  endof
\      2 of  ." Entered from ACPI _WAK "  endof
\      ( default )  ." Entered with argument 0x" dup .x 
\   endcase
\   ." - type 'resume' to return" cr

   smi-interact
;

\ smi-dispatch is the top-level dispatcher for SMIs.  It looks
\ at various MSRs to determine the SMI cause and invokes the
\ corresponding subordinate handlers.

: smi-dispatch  ( -- )
   h# 28 acpi-w@                            ( events )
   dup h# 0040 and  if  soft-smi      then  ( events )
   dup h# 8000 and  if  bios-int-smi  then  ( events )
   h# 28 acpi-w!   \ Ack all events         ( )

   h# 2d acpi-b@ h# 2d acpi-b!  \ Ack the SMI
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

\ Debugging tool for displaying the saved Global Descriptor Table

: .smm-gdt  ( -- )
   smm-gdtr-base smm@ smm>physical  ( 'gdt gdt-adr )
   swap w@                          ( gdt-adr gdt-limit )
   .dt                              ( )
;

\ setup-rm-gateway initializes the real mode interrupt vector table
\ so that real mode code can call BIOS INTs.

\  setup-rm-gateway  ( -- ) Init this module
\  caller-regs  ( -- adr )  Base address of incoming registers
\  rm-int@      ( -- n )    Incoming interrupt number
\  rm-buf       ( -- adr )  Base address of a real-mode accessible buffer
\  rm-init-program  ( eip -- )  Setup to enter real mode program on next rm-return
\  rm-return    ( -- )      Resume execution of real-mode caller.  Returns when program does a BIOS INT.
\ Sequence:
\  setup-rm-gateway  ( eip ) rm-enter  begin  handle-bios-call rm-return  again

: setup-rm-gateway  ( -- )  \ XXX These config registers probably need to be fixed up during resume
   h# 0030 h# 885e config-w!                       \ Set up PCS1 IO trap on ports 30-3f
   h# 8864 config-b@  h# f0 or  h# 8864 config-b!  \ 16-byte range for PCS1
   h# 8866 config-b@  h# 02 or  h# 8866 config-b!  \ Enable PCS1

 \  h# 88e4 config-b@  h# 40 or  h# 88e4 config-b!  \ Enable PCS0 multifunction
   h# 88e5 config-b@  h# 04 or  h# 88e5 config-b!  \ Enable PCS1 multifunction

   h# 2b acpi-b@ h# 80 or  h# 2b acpi-b!           \ Enable SMI on access to PCS1

   int-entry  'int10-dispatch  /int-entry move   

   \ Prime the interrupt vector table with unused interrupt 1f
   h# 100  0  do
      'int10-dispatch h# f la+  i /l*  seg:off!
   loop

   \ Set interrupts 10-1f to go to entries 0-f in the int10-dispatch table
   h# 10  0  do
      'int10-dispatch i la+  h# 10 i + /l*  seg:off!
   loop
;

\ Test routine that just puts an 'S' on the serial port when an SMI happens
label show-smi
   16-bit
   ascii S report

   \ Via specific
   acpi-io-base h# 28 + # dx mov  dx al in  al dx out  \ Ack all events
   acpi-io-base h# 2d + # dx mov  dx al in  al dx out  \ ACK SMI
   rsm
end-code
here show-smi - constant /show-smi

label move-smbase
   16-bit
\  ascii s report

   \ Move SMBASE to the a0000 location
   op: smm-base # ax mov
   op: cs: ax smm-smbase #)  mov

   \ Via specific
   acpi-io-base h# 28 + # dx mov  dx al in  al dx out  \ Ack all events
   acpi-io-base h# 2d + # dx mov  dx al in  al dx out  \ ACK SMI
   rsm
end-code
here move-smbase - constant /move-smbase

: via-relocate-smi  ( -- )
\   show-smi 0 +smm  /show-smi move
   move-smbase smm-base0  /move-smbase move
   h# 2c acpi-w@     1 or h# 2c acpi-w!       \ Global SMI enable
   h# 2a acpi-b@ h# 40 or h# 2a acpi-b!       \ Enable SMI on access to software SMI register
   0 #smint                                   \ Trigger SMI
;

: smi-access-fb  ( -- )
   h#  383 config-b@ 2 or h#  383 config-b!   \ Direct SMM mode data accesses to A/Bxxxx range to frame buffer
;
: smi-unaccess-fb  ( -- )
   h#  383 config-b@ 2 invert and h#  383 config-b!   \ Restore SMM mode data accesses to A/Bxxxx range to memory
;
\ Call this to enable SMI support
: setup-smi  ( -- )
   h#  383 config-b@ 1 or h#  383 config-b!   \ Enable A/Bxxxx range as memory instead of frame buffer

   h#  386 config-b@ 1 or h#  386 config-b!   \ Enable compatible SMM
   h# 8fe6 config-b@ 3 or h# 8fe6 config-b!   \ Enable compatible and high SMM

[ifdef] virtual-mode
   cr3@ smm-pdir l!
[then]

   origin smm-forth-base l!
   smm-exec smm-forth-entry l!
   up@ smm-forth-up l!
   smm-sp0 smm-save-sp0 !
   smm-rp0 smm-save-rp0 !

   smm-gdt-template  smm-gdt  /smm-gdt  move
   smi-handler  smm-base +smm-offset  /smi-handler  move

   \ Relocate the code field of the code word that is embedded in the sequence
   ['] (smi-return) smi-handler -  +smm +smm-offset  ( cfa-adr )
   dup ta1+ swap token!

   via-relocate-smi

   h#  383 config-b@ 1 invert and h#  383 config-b!   \ Hide A/Bxxxx range behind frame buffer
;

0 [if]
: bios-release-smi  ( -- )
   h# 2a acpi-b@ h# 20 or h# 2a acpi-b!       \ Enable SMI on BIOS Release
   4 4 acpi-w!                                \ Trigger BIOS Release
;
[then]
