: >seg:off  ( linear -- offset segment )  lwsplit  d# 12 lshift  ;
: seg:off!  ( linear adr -- )  >r  >seg:off  r@ wa1+ w!  r> w!  ;
: seg:off>  ( offset segment -- linear )  4 lshift +  ;
: seg:off@  ( adr -- linear )  dup w@ swap wa1+ w@  seg:off>  ;

h#  8 constant rm-cs
h# 18 constant rm-ds
h# 20 constant pm-cs
h# 28 constant pm-ds

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
: rm-dh@  caller-regs >rm-edx 1+ c@  ;
: rm-dh!  caller-regs >rm-edx 1+ c!  ;
: rm-dl@  caller-regs >rm-edx c@  ;
: rm-dl!  caller-regs >rm-edx c!  ;
: rm-dx@  caller-regs >rm-edx w@  ;
: rm-dx!  caller-regs >rm-edx w!  ;

: rm-set-cf  caller-regs >rm-flags dup w@  1 or  swap w!  ;
: rm-clr-cf  caller-regs >rm-flags dup w@  1 or  swap w!  ;

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
   \ CS for vector

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

: handle-bios-call  ( -- )
   'rm-sp seg:off@  w@  h# ff and   ( int# )
   'rm-sp w@ 2+ 'rm-sp w!           ( int# )
   ." Interrupt " . cr
   interact
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
