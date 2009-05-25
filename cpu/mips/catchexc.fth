purpose: Exception handling for MIPS
\ See license at end of file

defer enterforth-hook ' noop is enterforth-hook

only forth also hidden also  forth definitions
headerless

: enterforth  ( -- )
   state-valid on
   my-self to %saved-my-self
   enterforth-hook
   handle-breakpoint
;

: (breakpoint-trap?)  exception# 3 =  ;
' (breakpoint-trap?) to breakpoint-trap?

: .go-message  ( -- )
   \ Restarting is only possible if the state that was first saved
   \ is from a restartable exception.
   state-valid @  -1 =  already-go? and  if
      restartable? on
      ." Type  'go' to resume" cr
   then
;

: .entry  ( -- )
   [ also hidden ]
   talign		\ ... in case dp is misaligned

   aborted? @  if
      aborted? off  hex cr  ." Keyboard interrupt" cr  .go-message   exit
   then
   [ previous ]
;
' .entry is .exception

\ create debug-break
[ifdef] debug-break
: ?report  ( char -- )
   " h# bfd0.0000 v0 set" evaluate
   " begin   v0 h# 3fd v1 lbu   v1 h# 20 v1 andi  v1 0 <> until  nop" evaluate
   ( char )  " v1 set   v1 v0 h# 3f8 sb  " evaluate
   " begin   v0 h# 3fd v1 lbu   v1 h# 20 v1 andi  v1 0 <> until  nop" evaluate
;

: putbyte ( $a0 -- )
   " $a0 h# f $a0 andi  $a0 h# 30 $a0 addi" evaluate
   " begin   v0 h# 3fd v1 lbu   v1 h# 20 v1 andi  v1 0 <> until  nop" evaluate
   " $a0 v0 h# 3f8 sb  " evaluate
   " begin   v0 h# 3fd v1 lbu   v1 h# 20 v1 andi  v1 0 <> until  nop" evaluate
;
: dot ( a0 -- )
   " h# bfd0.0000 v0 set  $a0 t2 move" evaluate
   " t2 d# 28 $a0 srl  putbyte" evaluate
   " t2 d# 24 $a0 srl  putbyte" evaluate
   " t2 d# 20 $a0 srl  putbyte" evaluate
   " t2 d# 16 $a0 srl  putbyte" evaluate
   " t2 d# 12 $a0 srl  putbyte" evaluate
   " t2 d#  8 $a0 srl  putbyte" evaluate
   " t2 d#  4 $a0 srl  putbyte" evaluate
   " t2 0     $a0 srl  putbyte" evaluate
;
[else]
: ?report  ( char -- )  drop  ;
[then]

0 value (restart-loc
code (restart  ( -- )

   \ Restore the Forth stacks.
   \ Establish the Data and Return stacks
   'user rp0  rp  lw
   'user sp0  sp  lw
   \ Account for the presence of the top of stack register
   sp /n   sp   addiu

   \ Restore the Forth Data and Return stacks from the save area.

   \ Data Stack
   'user sp0    t3  lw
   'user pssave t0  lw		\ Address of data stack save area
   ps-size      t1  set		\ Size of data stack area
   t0 t1        t1  add		\ End address of data stack save area
   begin
      t1 -4  t1  addiu		\ Advance save area pointer
      t1     t2  get            \ Read word from save area
      t3 -4  t3  addiu		\ Advance stack pointer
   t1 t0 = until
      t2     t3  put		\ Write word to stack

   \ Return Stack
   'user rp0    t3  lw
   'user rssave t0  lw		\ Address of return stack save area
   rs-size      t1  set		\ Size of return stack area
   t0 t1        t1  add		\ End address of stack save area
   begin
      t1 -4  t1  addiu		\ Advance save area pointer
      t1     t2  get            \ Read word from save area
      t3 -4  t3  addiu		\ Advance stack pointer
   t1 t0 = until
      t2     t3  put		\ Write word to stack

   \ Have to turn off interrupts temporarily until we are done with
   \ using k0 and k1 because interrupt handling needs them too.

   d# 12 t0 mfc0
   h# ffff.fffe t1 set
   t1 t0 t1 and
   d# 12 t1 mtc0
   nop nop nop nop

   \ Now it's safe to use k0 and k1

   \ Restore registers
   here origin- to (restart-loc
   1.0001  k1  set	\ Will be address of cpu-state (force 2 instructions)

   $0  k1 addr %state-valid cpu-state -  sd	\ Unlock cpu-state

   k1 addr $lo   cpu-state - t0  ld    t0 mtlo
   k1 addr $hi   cpu-state - t0  ld    t0 mthi

   d# 12 t0 mfc0	\ Get status register
   t0 d# 28  t0  srl	\ Shift coprocessor status bits down
   t0 h# 02  t0  andi	\ Mask bit 1 (coprocessor 1 - Floating point)
   t0 $0 <>  if		\ Skip if coprocessor disabled
      nop
      k1 addr $fcsr cpu-state - t0  ld    d# 31 t0 ctc1
   then

   d# 26 0  do
      k1  i 3 + /x* ( offset ) $0 i + ( reg# )   ld
   loop
   d# 4 0  do
      k1  i 3 + d# 28 + /x* ( offset ) $0 i d# 28 + + ( reg# )   ld
   loop

   k1  addr $sr cpu-state -  k0  ld   
   k1  addr $pc cpu-state -  k1  ld

[ifdef] debug-break
bl ?report
k1 $a0 move dot
bl ?report
[then]

   k1  jr
   d# 12 k0 mtc0		\ Restore Status Register
   nop

end-code
' (restart is restart
' (restart is restart-step

headerless
0 value save-state-loc
headers

label reenter  ( base -- )
ascii ~ ?report

   'body main-task  up  li	\ User pointer address
   base  up   up        addu
   up    0    up        lw

   \ Establish the Data and Return stacks
   \ Copy the entire Forth Data and Return stacks areas to a save area.
   \ Data Stack
   'user sp0    sp  lw
   sp           t3  move
   'user pssave t0  lw		\ Address of data stack save area
   ps-size      t1  set		\ Size of data stack area
   t0 t1        t1  add		\ End address of data stack save area
   begin
      t3 -4  t3  addiu		\ Advance data stack pointer
      t1 -4  t1  addiu		\ Advance save area pointer
      t3     t2  get		\ Read word from stack
   t1 t0 = until
      t2     t1  put		\ Write word to save area

   \ Account for the presence of the top of stack register
   sp /n   sp   addiu
   
   \ Return Stack
   'user rp0    rp  lw
   
   rp           t3  move
   'user rssave t0  lw		\ Address of return stack save area
   rs-size      t1  set		\ Size of return stack area
   t0 t1        t1  add		\ End address of data stack save area
   begin
      t3 -4  t3  addiu		\ Advance data stack pointer
      t1 -4  t1  addiu		\ Advance save area pointer
      t3     t2  get		\ Read word from stack
   t1 t0 = until
      t2     t1  put		\ Write word to save area

ascii ! ?report

   \ Reenter forth
   np@ origin-  np  set
   np  base     np  addu

[ifdef] debug-break
carret ?report
linefeed ?report
sp $a0 move dot bl ?report
rp $a0 move dot bl ?report
up $a0 move dot bl ?report
base $a0 move dot bl ?report
np $a0 move dot bl ?report
[then]

   'body enterforth ip  set
   ip base ip           addu

[ifdef] debug-break
ip $a0 move dot
[then]
c;  

\ exception# = -1 if entered from interrupt-return
\               3 if breakpoint exception
label save-state  ( k0: exception# -- )
   here origin- to save-state-loc
   1.0001  k1  set	\ Will be address of cpu-state (force 2 instructions)
   k0  k1  addr exception# cpu-state -  sd	\ Save exception#

   k1  addr %state-valid cpu-state -    k0   ld
   k0 0 =  if	\ Save only if we don't already have valid state
      nop

      \ Save general registers
      d# 32 0  do
         $0 i + ( reg# )  k1  i 3 + /x* ( offset )  sd
      loop

ascii X ?report

      d# 12 k0 mfc0	\ Get status register
      k0 d# 28  k0  srl	\ Shift coprocessor status bits down
      k0 h# 02  k0  andi	\ Mask bit 1 (coprocessor 1 - Floating point)
      k0 $0 <>  if		\ Skip if coprocessor disabled
         nop
      \ Save floating point registers
         d# 32 0  do
            i ( freg# )  k0  mfc1
            k0  k1 i d# 36 + /x* ( offset )  sd
         loop

         d# 31 t0 cfc1  nop  t0  k1  addr $fcsr  cpu-state -  sd
      then

      \ Save special registers
      t0  mflo       nop  t0  k1  addr $lo    cpu-state -  sd
      t0  mfhi       nop  t0  k1  addr $hi    cpu-state -  sd

      \ Save CP0 registers
      d# 13  t0  mfc0    t0  k1  addr $cause      cpu-state -  sd
      d#  8  t0  mfc0    t0  k1  addr $badvaddr   cpu-state -  sd
      d# 26  t0  mfc0    t0  k1  addr $badpaddr   cpu-state -  sd
      d# 14  t0  mfc0    t0  k1  addr $pc         cpu-state -  sd

      \ Clear the EXL bit in the status register because we're going
      \ back to exception level 0.
      d# 12  t0  mfc0    $0 2 t1 addiu  $0 t1 t1 nor  t0 t1 t0 and
                         t0  k1  addr $sr         cpu-state -  sd
   then

ascii Y ?report

   \ Find the base address
   here 8 +               bal   \ ra = Absolute address of next instruction
   here origin - 4 + base set   \ base = relative address of this instruction
   ra       base     base subu  \ Base address of Forth kernel

[ifdef] debug-break
bl ?report
base $a0 move dot
bl ?report
[then]

   'body reenter  t0  set
   t0  base  t0  addu
   d# 14     t0  mtc0		\ Set EPC
   nop nop nop nop		\ Delay before eret

[ifdef] debug-break
t0 $a0 move  dot
bl ?report
d# 14 $a0 mfc0  dot
[then]

   eret
   nop

end-code

hidden also
stand-init: Fixup save-state;  Allocate save stacks
   uasave drop
   ps-size alloc-mem to pssave
   rs-size alloc-mem to rssave
   cpu-state  save-state-loc origin+  fix-set32
   cpu-state  (restart-loc   origin+  fix-set32

   restartable? off
;
only forth also definitions




\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
