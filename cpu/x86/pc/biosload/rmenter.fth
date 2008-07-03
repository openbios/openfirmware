\ Exports:
\  setup-rm-gateway  ( -- ) Init this module
\  caller-regs  ( -- adr )  Base address of incoming registers
\  rm-int@      ( -- n )    Incoming interrupt number
\  rm-buf       ( -- adr )  Base address of a real-mode accessible buffer
\  rm-init-program  ( eip -- )  Setup to enter real mode program on next rm-return
\  rm-return    ( -- )      Resume execution of real-mode caller.  Returns when program does a BIOS INT.
\ Sequence:
\  setup-rm-gateway  ( eip ) rm-enter  begin  handle-bios-call rm-return  again
\ An alternate way would be:
\  setup-rm-gateway  ['] handle-bios-call ( eip ) rm-enter
\ Then a BIOS INT would invoke handle-bios-call, which would return by calling rm-return

\ h# 9.0000 constant rm-base
h# f.0000 constant rm-base
h#   ff00 constant rm-base2

\ 'ebda constant new-gdt-pa
h# e.8000 constant new-gdt-pa


[ifdef] syslinux-loaded
h#  8 constant rm-cs
h# 18 constant rm-ds
h# 20 constant pm-cs
h# 28 constant pm-ds
: fix-gdt 
   \ 16-bit 64K code segment starting at rm-base
   rm-base lbsplit                   ( adr.0 adr.1 adr.2 adr.3 )
   2swap h# ffff -rot bwjoin wljoin  ( adr.2 adr.3 desc.lo )
   -rot                              ( desc.lo adr.2 adr.3 )
   >r  h# 9a 0  r>   bljoin          ( desc.lo desc.hi )
   gdtr@ drop rm-cs + d!             ( )

   \ 16-bit 64K data segment starting at rm-base
   rm-base lbsplit                   ( adr.0 adr.1 adr.2 adr.3 )
   2swap h# ffff -rot bwjoin wljoin  ( adr.2 adr.3 desc.lo )
   -rot                              ( desc.lo adr.2 adr.3 )
   >r  h# 93 0  r>   bljoin          ( desc.lo desc.hi )
   gdtr@ drop rm-ds + d!             ( )
;
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

[ifdef] rom-loaded
h# 38 constant rm-cs
h# 30 constant rm-ds
h# 60 constant pm-cs
h# 68 constant pm-ds
: fix-gdt 
   \ 16-bit 64K code segment starting at rm-base
   rm-base lbsplit                   ( adr.0 adr.1 adr.2 adr.3 )
   2swap h# ffff -rot bwjoin wljoin  ( adr.2 adr.3 desc.lo )
   -rot                              ( desc.lo adr.2 adr.3 )
   >r  h# 9a 0  r>   bljoin          ( desc.lo desc.hi )
   gdtr@ drop rm-cs + d!             ( )

   \ 16-bit 64K data segment starting at rm-base
   rm-base lbsplit                   ( adr.0 adr.1 adr.2 adr.3 )
   2swap h# ffff -rot bwjoin wljoin  ( adr.2 adr.3 desc.lo )
   -rot                              ( desc.lo adr.2 adr.3 )
   >r  h# 93 0  r>   bljoin          ( desc.lo desc.hi )
   gdtr@ drop rm-ds + d!             ( )
;
[then]

: +rm  ( offset -- adr )  rm-base +  rm-base2 +  ;

\ Place for the initial registers upon entry to real mode.
\ The real-mode stack pointer will start here, so the registers
\ can be loaded by popping the stack

h# 00 +rm constant 'rm-regs
'rm-regs value rm-buf

\ (00) 4 * 2: GS,FS,ES,DS
\ (08) 8 * 4: EDI,ESI,EBP,ESP,EBX,EDX,ECX,EAX
\ (28) 1 * 4: CS:IP of return address
\ (2c) 1 * 2: flags
\ size is 2e

h# 30 +rm constant 'rm-idt \ For loading RM IDT with LIDT
h# 36 +rm constant 'rm-int \ Incoming interrupt number
h# 38 +rm constant 'rm-sp  \ SS:SP For loading RM SP with LSS
h# 3c +rm constant 'pm-sp  \ Save/restore area for PM SP
h# 40 +rm constant 'pm-gdt \ For loading PM GDT with LGDT
h# 48 +rm constant 'pm-idt \ For loading PM IDT with LGDT

h# 50 +rm constant 'rm-to-pm
h# a0 +rm constant 'pm-to-rm
h# f0 +rm constant 'rm-enter

: caller-regs  'rm-sp seg:off@  ;

: rm-int@  'rm-int w@  h# ff and  ;

h# 80 constant /vectors

/vectors buffer: saved-rm-vectors
/vectors buffer: saved-ofw-vectors


\ 90ff0 is the target address of the interrupt vector
\ We use different segment:offset representations of that address in
\ the vector table, so the handler code can determine the vector 
\ number by inspecting the code segment register value
\ 00:  nn00:mff0
\ 01:  nn01:mfe0
\ ...
\ ff:  nnff:m000

: grab-rm-vector  ( vector# -- )
   >r
   'rm-enter lwsplit             ( low16 high16 )
   swap  r@ 4 lshift  -  swap    ( vec.offset high16 )     
   d# 12 lshift  r@ +  wljoin    ( vec.seg:off )
   r> /l* l!                     \ Set segment
;
: ungrab-rm-vector  ( vector# -- )
   saved-rm-vectors over la+ l@   ( vector# value )
   swap /l* l!
;
: make-vector-table  ( -- )
   h# 100 0 do  i grab-rm-vector  loop
;

label rm-to-pm
   16-bit

   \ Stack: (high address)
   \ flags                 (from INT)
   \ CS:IP return address  (from INT)
   \ (low) EDI,ESI,EBP,ESP,EBX,EDX,ECX,EAX (high)
   \ (low) GS,FS,ES,DS (high)
   \ CS from interrupt vector, which is the interrupt number

   cli  \ This is unnecessary since we got here from an INT
   cs push   ds pop

   'rm-int >off  #) pop        \ Save interrupt vector CS, i.e. the int#

   sp 'rm-sp    >off  #) mov
   ss 'rm-sp 2+ >off  #) mov

   op: 'pm-gdt  >off  #) lgdt
   cr0 ax mov  1 # al or  ax cr0 mov   \ Enter protected mode

   \ We are still running in 16-bit mode, but the target address might
   \ not fit in 16 bits, so we need the operand override to force the
   \ ptr16:32 target form.

\   ad:  here 7 +  rm-to-pm -  'rm-to-pm +  pm-cs #)  far jmp
   op:  here 7 +  rm-to-pm -  'rm-to-pm +  pm-cs #)  far jmp
   32-bit

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
   16-bit

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
   32-bit
   pushf
   pusha
   sp 'pm-sp #) mov

   cli
   sp sp xor
   'pm-to-rm >off  rm-cs #) far jmp
end-code

: rm-init-program  ( pc -- )
   'rm-regs  h# 2e  erase        ( pc )
   'rm-regs  h# 28 +  seg:off!   ( )
   'rm-regs 'rm-sp seg:off!      \ Initial stack pointer must be below regs
;



\ This is the common target of all the real-mode interrupt vectors.
\ It lives at 9.fff0.  Upon entry, the code segment register contains
\ 80xx where xx is the vector number, and the IP contains 0yy0 where
\ yy is ff - vector_number.
label rm-enter
   16-bit
   op: pusha  ds push  es push  fs push  gs push
   cs push                        \ Save the Code Segment value
   'rm-to-pm >seg:off #) far jmp  \ Normalize the CS value
end-code
here rm-enter - constant /rm-enter

: restore-vector  ( int# -- )
   saved-rm-vectors  over la+ l@   swap /l* l!
;

: move-gdt  ( -- )
   gdtr@ 1+                    ( gdt-adr gdt-len )

   new-gdt-pa                  ( gdt-adr gdt-len new-gdt-adr )

   swap  2dup 2>r  move   2r>  ( new-gdt gdt-len )
   1- gdtr!
;

: bios-vectors  ( -- )
   0  saved-ofw-vectors  /vectors  move
   saved-rm-vectors  0  /vectors move
;
: ofw-vectors  ( -- )
\   0  saved-ofw-vectors  /vectors  move
   saved-ofw-vectors  0 /vectors move
;
[ifndef] rom-loaded
: regs>bios  ( -- )
   caller-regs bios-regs d# 40 move
   rm-flags@ bios-flags l!
   rm-int@  /l* @  bios-target !
;
: bios>regs  ( -- )
   bios-regs caller-regs d# 40 move
   bios-flags l@ rm-flags!
;
: use-bios  ( -- )
   bios-vectors
   ?prep-bios-call
   regs>bios
   }bios
   bios>regs
   ofw-vectors
;
[then]
: setup-rm-gateway  ( -- )
   fix-gdt

   move-gdt

   rm-enter 'rm-enter   /rm-enter   move
   rm-to-pm 'rm-to-pm   /rm-to-pm   move
   pm-to-rm 'pm-to-rm   /pm-to-rm   move

   0  saved-rm-vectors  /vectors  move

[ifdef] syslinux-loaded
    7 h# 1.0004 config-w!

    h# 10 grab-rm-vector  \ Video
    h# 11 grab-rm-vector  \ Sysinfo
    h# 12 grab-rm-vector  \ Low memory size
    h# 13 grab-rm-vector  \ Disk I/O
    h# 15 grab-rm-vector  \ Various system stuff
    h# 16 grab-rm-vector  \ Keyboard
    h# 1a grab-rm-vector  \ PCI BIOS
[else]
   make-vector-table

[ifndef] rom-loaded
   saved-rm-vectors     8 la+ l@  0     8 la+ l!  \ Use BIOS timer tick handler
   saved-rm-vectors h# 1c la+ l@  0 h# 1c la+ l!  \ Timer handler chain
[then]
[then]

   h# ffff 'rm-idt w!  0 'rm-idt wa1+ l!  \ Limit and base
;

defer handle-bios-call
: rm-run  ( adr -- )
   rm-init-program
   begin
      rm-return
      handle-bios-call
   again
;
