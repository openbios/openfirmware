: >seg:off  ( linear -- offset segment )  lwsplit  d# 12 lshift  ;
: seg:off!  ( linear adr -- )  >r  >seg:off  r@ wa1+ w!  r> w!  ;
: seg:off>  ( offset segment -- linear )  4 lshift +  ;
: seg:off@  ( adr -- linear )  dup w@ swap wa1+ w@  seg:off>  ;

[ifdef] syslinux-loaded
h#  8 constant rm-cs
h# 18 constant rm-ds
h# 20 constant pm-cs
h# 28 constant pm-ds
: fix-gdt ;
[then]
[ifdef] preof-loaded
h# 38 constant rm-cs
h# 30 constant rm-ds
h# 10 constant pm-cs
h# 18 constant pm-ds
: fix-gdt
   gdtr@  gdt-pa  swap 1+  move
   h# ffff gdt-pa h# 38 + l!     \ Limit ffff
   h# 9a00 gdt-pa h# 3c + l!     \ Base 00000, 16-bit code
   gdt-pa  gdtr@ nip h# 3f max 1+  gdtr!
;
[then]


h# 0.0000 constant rm-base
: +rm  ( offset -- adr )  rm-base +  ;

\ Place for the initial registers upon entry to real mode.
\ The real-mode stack pointer will start here
h# f00 +rm constant 'rm-regs
\ (00) 4 * 2: GS,FS,ES,DS
\ (08) 8 * 4: EDI,ESI,EBP,ESP,EBX,EDX,ECX,EAX
\ (28) 1 * 4: CS:IP of return address
\ (2c) 1 * 2: flags
\ size is 2e

h# f30 +rm constant 'rm-idt \ For loading RM IDT with LIDT
h# f36 +rm constant 'rm-int \ Incoming interrupt number
h# f38 +rm constant 'rm-sp  \ SS:SP For loading RM SP with LSS
h# f3c +rm constant 'pm-sp  \ Save/restore area for PM SP
h# f40 +rm constant 'pm-gdt \ For loading PM GDT with LGDT
h# f48 +rm constant 'pm-idt \ For loading PM IDT with LGDT

h# f50 +rm constant 'rm-to-pm
h# fa0 +rm constant 'pm-to-rm
h# ff0 +rm constant 'rm-enter

: caller-regs  'rm-sp seg:off@  ;
struct
  2 field >rm-gs
  2 field >rm-fs
  2 field >rm-es
  2 field >rm-ds
  4 field >rm-edi
  4 field >rm-esi
  4 field >rm-ebp
  4 field >rm-exx
  4 field >rm-ebx
  4 field >rm-edx
  4 field >rm-ecx
  4 field >rm-eax
  4 field >rm-retaddr
  2 field >rm-flags
drop

: rm-ah@  caller-regs >rm-eax 1+ c@  ;
: rm-ah!  caller-regs >rm-eax 1+ c!  ;
: rm-al@  caller-regs >rm-eax c@  ;
: rm-al!  caller-regs >rm-eax c!  ;
: rm-ax@  caller-regs >rm-eax w@  ;
: rm-ax!  caller-regs >rm-eax w!  ;

: rm-bh@  caller-regs >rm-ebx 1+ c@  ;
: rm-bh!  caller-regs >rm-ebx 1+ c!  ;
: rm-bl@  caller-regs >rm-ebx c@  ;
: rm-bl!  caller-regs >rm-ebx c!  ;
: rm-bx@  caller-regs >rm-ebx w@  ;
: rm-bx!  caller-regs >rm-ebx w!  ;

: rm-ch@  caller-regs >rm-ecx 1+ c@  ;
: rm-ch!  caller-regs >rm-ecx 1+ c!  ;
: rm-cl@  caller-regs >rm-ecx c@  ;
: rm-cl!  caller-regs >rm-ecx c!  ;
: rm-cx@  caller-regs >rm-ecx w@  ;
: rm-cx!  caller-regs >rm-ecx w!  ;

: rm-dh@  caller-regs >rm-edx 1+ c@  ;
: rm-dh!  caller-regs >rm-edx 1+ c!  ;
: rm-dl@  caller-regs >rm-edx c@  ;
: rm-dl!  caller-regs >rm-edx c!  ;
: rm-dx@  caller-regs >rm-edx w@  ;
: rm-dx!  caller-regs >rm-edx w!  ;

: rm-flags@  caller-regs >rm-flags w@  ;
: rm-flags!  caller-regs >rm-flags w!  ;

: rm-set-cf  rm-flags@  1 or  rm-flags!  ;
: rm-clr-cf  rm-flags@  1 or  rm-flags!  ;

\ 80ff0 is the target address of the interrupt vector
\ We use different segment:offset representations of that address in
\ the vector table, so the handler code can determine the vector 
\ number by inspecting the code segment register value
\ 00:  8000:0ff0
\ 01:  8001:0fe0
\ ...
\ ff:  80ff:0000

: make-vector-table  ( -- )
   h# 100 0 do
      h# ff0  i 4 lshift  -    i /l* w!       \ Set offset
      rm-base  4 rshift  i +   i /l* wa1+ w!  \ Set segment
   loop
;

label rm-to-pm
   real-mode

   \ Stack: (high address)
   \ flags                 (from INT)
   \ CS:IP return address  (from INT)
   \ (low) EDI,ESI,EBP,ESP,EBX,EDX,ECX,EAX (high)
   \ (low) GS,FS,ES,DS (high)
   \ CS from interrupt vector, which is the interrupt number

   cs: 'rm-int #) pop        \ Save interrupt vector CS, i.e. the int#

   cli  \ This is unnecessary since we got here from an INT
   cs push   ds pop

   sp 'rm-sp    #) mov
   ss 'rm-sp 2+ #) mov

   op: 'pm-gdt  #) lgdt
   cr0 ax mov  1 # al or  ax cr0 mov   \ Enter protected mode

   here 5 +  rm-to-pm -  'rm-to-pm +  pm-cs #)  far jmp

   protected-mode

   ax ax xor  pm-ds # al mov  ax ds mov  ax es mov  ax gs mov  ax gs mov  ax ss mov
   'rm-idt #) sidt
   'pm-idt #) lidt
   'pm-sp  #) sp mov

   popa
   popf
c;
here rm-to-pm - constant /rm-to-pm

label pm-to-rm
   \ Interrupts must be off.  We don't have a stack at the moment.
   \ We got here via a far jmp to a 16-bit code segment, so we are
   \ using the 16-bit instruction set, but we're not yet in real mode
   \ The assembler uses "real-mode" to mean "16-bit code".
   real-mode

   \ This must be copied to low memory

   ax ax xor   rm-ds #  al  mov  \ 16-bit data segment
   ax ds mov  ax es mov  ax fs mov  ax gs mov  ax ss mov

   'pm-gdt #) sgdt  \ So we can get back
   'pm-idt #) sidt  \ So we can get back
   'rm-idt #) lidt
   cr0 ax mov   h# fe # al and   ax cr0 mov   \ Enter real mode

   here 5 +  pm-to-rm -  'pm-to-rm + >seg:off #)  far jmp  \ Jump to set cs

   \ Now we are running in real mode; fix segments again
   cs ax mov   ax ds mov  ax es mov  ax fs mov  ax gs mov

   'rm-sp #) sp lss  \ Now we are back on the caller stack

   \ Load the 16-bit registers from the rm-regs area
   gs pop  fs pop  es pop  ds pop   op: popa

   iret        \ Now we are back to the caller
end-code
here pm-to-rm - constant /pm-to-rm

code rm-return  ( -- )
   protected-mode
   pushf
   pusha
   sp 'pm-sp #) mov

   cli
   sp sp xor
   'pm-to-rm  rm-cs #) far jmp
end-code

\ This is the common target of all the real-mode interrupt vectors.
\ It lives at 8.0ff0.  Upon entry, the code segment register contains
\ 80xx where xx is the vector number, and the IP contains 0yy0 where
\ yy is ff - vector_number.
label rm-enter
   real-mode
   op: pusha  ds push  es push  fs push  gs push
   cs push                        \ Save the Code Segment value
   'rm-to-pm >seg:off #) far jmp  \ Normalize the CS value
   protected-mode
end-code
here rm-enter - constant /rm-enter

h# 400 buffer: saved-rm-vectors

0 value rm-prepped?
: prep-rm  ( -- )
   rm-prepped?  if  exit  then   true to rm-prepped?
   fix-gdt
   0  saved-rm-vectors  h# 400  move
   make-vector-table

   rm-enter 'rm-enter   /rm-enter   move
   rm-to-pm 'rm-to-pm   /rm-to-pm   move
   pm-to-rm 'pm-to-rm   /pm-to-rm   move

   h# ffff 'rm-idt w!  0 'rm-idt wa1+ l!  \ Limit and base
;

: rm-init-program  ( pc -- )
   prep-rm
   'rm-regs  h# 2e  erase        ( pc )
   'rm-regs  h# 28 +  seg:off!   ( )
   'rm-regs 'rm-sp seg:off!      \ Initial stack pointer below regs
;

: get-font  ( -- )
   rm-al@ h# 30 =  if
      ." Int 10 get-font called - BH = " rm-bh@ .  cr
   else
      ." Int 10 set-font called"  cr
   then
;

: video-int  ( -- )
   rm-ah@  case
      h#  0  of  ( rm-al@ set-video-mode )  endof  \ Set mode - Should blank the screen
      h#  a  of  rm-al@ emit   endof   \ Write character
      h#  e  of  rm-al@ emit   endof   \ Write character
      h# 11  of  get-font      endof   \ get or set font
      h# 12  of  0 rm-bx!      endof   \ Attribute for blanked lines while scrolling - Wrong, I think
      h# 20  of  endof

      ( default )  ." Unimplemented video int - AH = " dup . cr  rm-set-cf
   endcase
;
: sysinfo-int  ( -- )   h# 26 rm-ax!  ;

0 value disk-ih
: disk-read-sectors  ( adr sector# #sectors -- #read )
   " read-blocks" disk-ih $call-method
;

0 [if]
h# 200 constant /sector
: disk-seek  ( sector#  -- error? )
   /sector um*                               ( adr len d.byte# )
   " seek"  disk-ih  $call-method  dup  if   ( error? )
      rm-set-cf  4 rm-ah!                    ( error? )
   then                                      ( error? )
;
: disk-read  ( adr #sectors -- #sectors-read )
   /sector *                       ( adr #bytes )
   " read" disk-ih $call-method    ( #bytes-read )
   /sector /                       ( #sectors-read )
;
[then]

: check-drive  ( -- error? )
   rm-dl@  h# 80 <>  if  rm-set-cf  7 rm-ah!  true exit  then
   disk-ih  if  false exit  then
\   " disk:0" open-dev to disk-ih
   " /ide@0" open-dev to disk-ih
   disk-ih  dup 0=  if  rm-set-cf  h# aa rm-ah!   then   
;
: read-sectors  ( -- )
   check-drive  if  exit  then
   disk-ih  0=  if  rm-set-cf  h# aa rm-ah! exit  then
   rm-ch@  rm-cl@ 6 rshift  bwjoin  ( cylinder# )
   h# ff *   rm-dh@ +               ( trk# )     \ 255 heads
   h# 3f *  rm-cl@ h# 3f and 1-  +  ( sector# )  \ 63 is max sector#

   rm-bx@  caller-regs >rm-es w@  seg:off>  ( sector# adr )
   swap  rm-al@                             ( adr sector# #sectors )
   disk-read-sectors  rm-al!

\   disk-seek  if  exit  then
\   rm-bx@  caller-regs >rm-es w@  seg:off>  rm-al@  ( adr #sectors )
\   disk-read  rm-al!
;
: drive-params  ( -- )
   check-drive  if  exit  then
\   " size" disk-ih $call-method       ( d.#bytes )
\   /sector um/mod  nip                ( #sectors )
   " #blocks" disk-ih $call-method    ( #sectors )
   h# 3f /                            ( #tracks )
   h# ff / 1-                         ( maxcyl )  \ Max 255 heads is traditional
   wbsplit                            ( maxcyl.lo maxcyl.hi )
   3 min  6 lshift  h# 3f or  rm-cl!  ( maxcyl.lo )  \ High cyl, max sector
   rm-ch!                             ( ) \ Low byte of max cylinder
   h# fe rm-dh!                       ( ) \ Max head number
   h# 01 rm-dl!                       ( ) \ Number of drives
   rm-clr-cf
;

: lba-read  ( -- )
   check-drive  if  exit  then
   caller-regs >rm-esi w@  caller-regs >rm-ds w@  seg:off>  ( packet-adr )
   >r  r@ 4 + seg:off@  r@ 8 + l@  r@ 2+ w@  disk-read-sectors  r> 2+ w!
\   dup 8 + l@   ( packet-adr sector# )
\   disk-seek  if  drop exit  then  ( packet-adr )
\   dup 4 + seg:off@  over 2+ w@    ( packet-adr adr #sectors )
\   disk-read
\   swap 2+ w!   
;

: check-disk-extensions  ( -- )
   check-drive  if  0 rm-bx! exit  then
   rm-bx@  h# 55aa <>  if  exit  then
   h# aa55 rm-bx!
   h# 20 rm-ah!  1 rm-cx!
;

: disk-int  ( -- )  \ INT 13 handler
   rm-ah@ case
      h# 02  of  read-sectors   endof
      h# 08  of  drive-params   endof
      h# 41  of  check-disk-extensions  endof
      h# 42  of  lba-read  endof
      ( default )  ." Unsupported disk INT 13 - AH = " dup . cr
   endcase
;

: memory-limit  ( -- limit )
   " /memory" find-package 0= abort" No /memory node"  ( phandle )
   " available" rot get-package-property abort" No available property"  ( $ )
   -1 >r                              ( $ )  ( r: limit )
   begin  dup 0>  while               ( $ )
      decode-int >r decode-int  r> +  ( $ piece-end )
      dup 1meg u<=  if  drop   else   ( $ piece-end )
         r> umin >r                   ( $ )  ( r: limit' )
      then                            ( $ )
   repeat                             ( $ )
   2drop  r>                          ( limit )
;

: /1k  d# 10 rshift  ;
: bigmem-16bit  ( -- )
   memory-limit
   dup h# 100.0000  min  h# 10.0000 -  0 max  /1k  dup rm-ax!  rm-cx!
   h# 100.0000 -  0 max  d# 16 rshift  dup rm-bx!  rm-dx!
;
: bigmem-int  ( -- )
   rm-clr-cf
   rm-al@ case
      h# 01 of  bigmem-16bit   endof
\     h# 20 of  system-memory-map  endof
\     h# 81 of  pm-system-memory-map  endof
      ( default )  rm-set-cf
         ." Unsupported Bigmem int 15 AH=e8 AL=" dup . cr
   endcase
;

: apm  ( -- )
   ." APM not supported yet" cr
   rm-set-cf  h# 86 rm-ah!
;

create sysconf  8 w,  h# fc c,  1 c,  0 c,  h# 70 c,  0 c,  0 c,
: get-conf  ( -- )
   sysconf 'rm-regs 8 move
   'rm-regs >seg:off  0 caller-regs >rm-es w!  rm-bx!  
;

: system-int  ( -- )  \ INT 15 handler
   rm-ah@ case
      h# 53 of  apm  endof
      h# 86 of  rm-dx@  rm-cx@ wljoin us  endof  \ Delay microseconds
      h# 8a of  memory-limit h# 400.0000 - 0 max  /1k  lwsplit rm-dx! rm-ax!  endof
      h# 88 of  h# fffc rm-ax!  endof  \ Extended memory - at least 64 MB
      h# c0 of  get-conf  endof
      h# c1 of  rm-set-cf h# 86 rm-ah!  endof
      h# e8 of  bigmem-int  endof
      ( default )  rm-set-cf
         ." Unsupported INT 15 AH=" dup . cr
   endcase
;

: poll-key  ( -- )
   key?  if
      key rm-al!  0 rm-ah!   \ ASCII in AL, scancode in AH
      rm-flags@ h# 40 invert and rm-flags!
   else
      rm-flags@ h# 40 or rm-flags!
   then
;

: keyboard-int  ( -- )  \ INT 15 handler
   rm-ah@ case
      1 of  poll-key  endof
      2 of  0 rm-al!  endof  \ Claim that no shift keys are active
      ( bit 7:sysrq  6:capslock  5:numlock 4:scrlock 3:ralt 2:rctrl 1:lalt 0:lctrl )
      ( default )  ." Keyboard INT called with AH = " dup . cr
   endcase
;

: cfgadr  ( -- adr )
   caller-regs >rm-edi c@  rm-bx@ 8 lshift or
;
: pcibios-installed  ( -- )
   h# 20494350 caller-regs >rm-edx !   \ "PCI " in little-endian
   1 rm-al!                            \ Config method 1
   h# 201 rm-bx!                       \ Version 2.1
   1 rm-cl!                            \ Number of last PCI bus - XXX get this from PCI node
;
: pcibios  ( -- )
   rm-clr-cf
   rm-ah@ case
      h# 01 of  pcibios-installed  endof
\     h# 02 of  find-pci-device ( cx:devid dx:vendid si:index -> bh:bus# bl:devfn )   endof  
\     h# 03 of  find-pci-class-code ( ecx:0,classcode si:index -> bh:bus# bl:devfn )  endof
\     h# 06 of  pci-special-cycle  ( bh:bus# edx:special_cycle_data )  endof
      h# 08 of  cfgadr config-b@ rm-cl!  endof
      h# 09 of  cfgadr config-w@ rm-cx!  endof
      h# 0a of  cfgadr config-l@ caller-regs >rm-ecx l!  endof
      h# 0b of  rm-cl@  cfgadr config-b!  endof
      h# 0c of  rm-cx@  cfgadr config-w!  endof
      h# 0d of  caller-regs >rm-ecx l@ cfgadr config-l!  endof
 \    h# 0e of  pci-int-rout  endof
 \    h# 0f of  set-pci-int   endof

      ( default )     h# 81 rm-ah!     rm-set-cf
         ." Unimplemented PCI BIOS INT - AH = " dup . cr
   endcase
;

: get-timer-ticks  ( -- )
   get-msecs d# 55 /  lwsplit  rm-cx!  rm-dx!
   0 rm-al!  \ Should be nonzero if midnight happened since last call
;

: int-1a  ( -- )
   rm-ah@  case
      h#  0  of  get-timer-ticks  endof
      h# b1  of  pcibios          endof
      ( default )  ." Unimplemented INT 1a - AH = " dup .  rm-set-cf
   endcase
;

: showint
  ." INT " 'rm-int w@ .  ." AH " rm-ah@ .  ." AL " rm-al@ .  cr
;

: handle-bios-call  ( -- )
   'rm-int w@  case
      h# 10  of  video-int     endof
      h# 11  of  sysinfo-int   endof
      h# 13  of  disk-int      endof
showint 
      h# 12  of  h# a0000 /1k rm-ax!  endof  \ Low memory size
      h# 15  of  system-int    endof
      h# 16  of  keyboard-int  endof
      h# 1a  of  int-1a        endof
      ( default )  ." Interrupt " dup . cr  interact
   endcase
;
: rm-go   ( -- )
   \ Load boot image at 7c00
   h# 7c00 rm-init-program
   begin
      rm-return
      handle-bios-call
   again
;
label xx  h# 99 # al mov  al h# 80 # out  begin again  end-code
here xx - constant /xx
: put-xx  ( adr -- )  xx swap /xx move  ;
: get-mbr
   " /ide@0" open-dev >r
   h# 7c00 h# 3f 1 " read-blocks" r@ $call-method .
   r> close-dev
;
: .lreg  ( adr -- adr' )  4 -  dup l@ 9 u.r   ;
: .wreg  ( adr -- adr' )  2 -  dup w@ 5 u.r   ;
: .caller-regs  ( -- )
   ."        AX       CX       BX       DX       SP       BP       SI       DI" cr
   caller-regs >rm-eax 4 +  8 0 do  .lreg  loop  cr
   cr
   ."    DS   ES   FS   GS       PC  FLAGS" cr
   4 0 do  .wreg  loop  
   caller-regs >rm-retaddr seg:off@ 9 u.r  2 spaces
   caller-regs >rm-flags w@ 5 u.r cr
;
