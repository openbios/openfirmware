purpose: Low-level handler for alarm interrupt 
\ See license at end of file

headerless

\ Interfaces to system-dependent routines
defer set-tick-limit  ( #msecs -- )	    \ Setup tick interrupt source
defer init-dispatcher ( -- )
defer dispatch-interrupt  ' noop to dispatch-interrupt
defer dispatch-exceptions  ( exception# -- )  ' drop to dispatch-exceptions

0 value intsave
h# 1300 d# 34 /x* +  constant /intstack

\ The interrupt save/stack area is laid out as follows:
\ 0000   - register save area  (size d# 34 /x*)
\ 0110   - data stack area     (size h#1100)
\ 1210   - return stack area   (size h#200)
\ 1410   - <end>
\
\ The register save area, which is exported to the client program via the
\ "tick" callback, contains the following registers, all from the interrupted
\ context:
\ 00  - $1
\ ...
\ 60  - $25
\ 64  - $28
\ ...
\ 70  - $at
\
\ When the interrupt handler returns, the complete context is restored from
\ the save area.  The client program can cause a context switch by modifying
\ these saved valued.

hex

: ?call-os  ( -- )  intsave " tick"  ($callback1)  ;

0 value ge-return-loc
code ge-return  ( -- )

   \ At the first indication of a keyboard abort, we branch to the
   \ Forth entry trap handler.  We do the actual branch after we have
   \ restored all the state, so it appears as if Forth were entered
   \ directly from the program that was running, rather than through
   \ the exception handler.

   0              k0  set		\ Clear derived abort flag
   'user aborted? s0  lw		\ Get abort flag
   1              s1  set
   s0  s1  =  if
      nop				\ delay slot
      \ Don't abort in the middle of the terminal emulator, because
      \ it's not reentrant.
      'user terminal-locked?  s1  lw
      s1 0 =  if
         nop				\ delay slot
         s0 1 s0  addi
         s0 'user aborted? sw
         1    k0  set			\ Set derived abort flag
      then
   then

   \ Restore registers
   'user intsave k1  lw			\ Address of interrupt save area
   k1 d# 32 /x* t0 ld
   k1 d# 33 /x* t1 ld
   t0 mtlo   t1 mthi

   d# 12 t2 mfc0	\ Get status register
   t2 d# 28  t2  srl	\ Shift coprocessor status bits down
   t2 h# 02  t2  andi	\ Mask bit 1 (coprocessor 1 - Floating point)
   t2 $0 <>  if		\ Skip if coprocessor disabled
      nop		\ Delay
      k1 d# 34 /x* t2 ld
      d# 31 t2 ctc1
   then

   d# 25 0  do
      k1  i /x* ( offset )  $0 1+ i + ( reg# )  ld
   loop
   4  0  do
      k1  i d# 25 + /x* ( offset )  $0 d# 28 + i + ( reg# )  ld
   loop

   \ Now the registers are back to the state that existed upon entry to
   \ the exception handler.  We can use only k0 and k1 in the following code.

   k0  0 =  if
      nop				\ delay slot
      eret				\ Return to interrupted code
      nop
   then

   here origin- to ge-return-loc
   1.0001  k1  set	\ will be save-state address (force 2 instructions)
   -1      k0  set
   k1          jr			\ Jump to save-state
   nop

end-code

\ We implement this in the following way, instead of just having
\ a value named getmsecs, so that other tasks can use get-msecs
\ This way is faster too, since the "+!" in the interrupt handler
\ routine is faster than "to".
variable msec-counter
[ifdef] local
: getmsecs  ( -- n )  main-task msec-counter local @  ;
[else]
: getmsecs  ( -- n )  msec-counter @  ;
[then]

0 value tick-increment

: intr-timer  ( -- )
   ms/tick msec-counter +!
   check-alarm
   count@ tick-increment + compare!
;

string-array exception-code
," Interrupt"
," TLB modified exception"
," TLB exception (load or instruction fetch)"
," TLB exception (store)"
," Address error exception (load or instruction fetch)"
," Address error exception (store)"
," Bus error exception (instuction fetch)"
," Bus error exception (data reference: load or store)"
," system call exception"
," Breakpoint exception"
," Reserved instruction exception"
," Coprocessor unusable exception"
," Arithmetic overflow exception"
," Trap exception"
," Undefined exception"
," Floating point exception"
," " ," " ," " ," " ," " ," " ," "
," Reference to WatchHi/WatchLo address"
," " ," " ," " ," " ," " ," " ," " ," "
end-string-array

: (.exception)  ( exception-code -- )
    dup exception-code
    dup c@  if  nip ".  else  drop ." Unknown exception " .x   then
    cr
;
' (.exception) to dispatch-exceptions

defer intr-sw0  ' noop to intr-sw0
defer intr-sw1  ' noop to intr-sw1
defer intr-hw0  ' noop to intr-hw0
defer intr-hw1  ' noop to intr-hw1
defer intr-hw2  ' noop to intr-hw2
defer intr-hw3  ' noop to intr-hw3
defer intr-hw4  ' noop to intr-hw4

: dispatch-interrupts  ( -- )
   cause@  8 >> h# ff and
   dup h#  1 and  if  intr-sw0 cause@ h# ffff.feff and cause!  then
   dup h#  2 and  if  intr-sw1 cause@ h# ffff.fdff and cause!  then
   dup h#  4 and  if  intr-hw0  then
   dup h#  8 and  if  intr-hw1  then
   dup h# 10 and  if  intr-hw2  then
   dup h# 20 and  if  intr-hw3  then
   dup h# 40 and  if  intr-hw4  then
   h# 80 and  if  intr-timer  then
;

defer ge-handler-hook  ' noop to ge-handler-hook
: ge-handler  ( -- )
   ge-handler-hook
   cause@  2 >> h# 1f and ?dup  if
      dispatch-exceptions
   else
      dispatch-interrupts
   then
   ge-return  
;

0 value ge-preamble-loc
label ge-preamble  ( -- )

   \ If breakpoint exception, transfer control to save-state immediately.
   d# 13 k1     mfc0		\ Get CAUSE
   k1 h# 7c k1  andi		\ Get exception code
   9 2 <<   k0  set		\ Breakpoint exception
   k0 k1 =  if
      nop
      here origin- to ge-preamble-loc
      1.0001  k1  set	\ will be save-state address (force 2 instructions)
      3       k0  set
      k1      jr		\ Jump to save-state
      nop
   then

   \ Find address of interrupt save area
   ra   k0  move		\ Save ra
   here 8 +                bal  \ ra = Absolute address of next instruction
   here origin - 4 + k1    set  \ k1 = relative address of this instruction
   ra   k1           k1    subu \ k1 address of Forth kernel
   k0   ra  move                \ Restore ra

   'body main-task   k0  set    \ User pointer address: main-task
   k1  k0            k0  addu
   k0  0             k0  lw
   k0 'user# intsave k0  addiu	\ User pointer
   k0  0   k0            lw	\ Address of interrupt save area

   \ Save registers
   d# 25 0  do
      $0 1+ i + ( reg# )  k0  i /x* ( offset )  sd
   loop
   4  0  do
      $0 d# 28 + i + ( reg#)  k0  i d# 25 + /x* ( offset )  sd
   loop
   t0 mflo  t1 mfhi

   d# 12 t2 mfc0	\ Get status register
   t2 d# 28  t2  srl	\ Shift coprocessor status bits down
   t2 h# 02  t2  andi	\ Mask bit 1 (coprocessor 1 - Floating point)
   t2 $0 <>  if		\ Skip if coprocessor disabled
      nop		\ Delay
      d# 31 t2 cfc1
   then

   t0 k0 d# 32 /x* sd
   t1 k0 d# 33 /x* sd
   t2 k0 d# 34 /x* sd

   \ Set up Forth stacks
   k0 /intstack rp  addiu	\ Return stack pointer
   rp h# -204   sp  addi	\ Data stack pointer

   k1   base  move
   'body main-task  up  set
   base  up   up        addu
   up    0    up        lw

   np@ origin-  np  set
   np  base     np  addu

   'body ge-handler ip set
   ip base ip addu
c;

: set-tick-limit  ( #msecs -- )
   dup to ms/tick
   ms-factor * dup to tick-increment 
   count@ + compare!
   sr@ h# 8000 or sr!
;

: (Disable-interrupts)  ( -- )  sr@ h# ffff.fffe and sr!  ;
' (disable-interrupts) to disable-interrupts
: (enable-interrupts)  ( -- )  sr@ 1 or sr!  ;
' (enable-interrupts) to enable-interrupts

label default-handler
   begin  again  nop
end-code

code clear-floating-point  ( -- )
   d# 12 t0 mfc0	\ Get status register
   t0 d# 28  t0  srl	\ Shift coprocessor status bits down
   t0 h# 02  t0  andi	\ Mask bit 1 (coprocessor 1 - Floating point)
   t0 $0 <>  if		\ Skip if coprocessor disabled
      nop		\ Delay
      d# 31 $0 ctc1	\ Clear floating point if it's enabled
   then
c;

defer tlb-handler   ' default-handler to tlb-handler
defer xtlb-handler  ' default-handler to xtlb-handler
defer cache-handler ' default-handler to cache-handler
" Implement TLB and cache error handlers" ?reminder
: catch-exceptions  ( -- )
   [ also hidden ]
   tlb-handler   0  install-handler
   xtlb-handler  1  install-handler
   cache-handler 2  install-handler
   ge-preamble   3  install-handler	\ General exception

   \ Interrupts can come in on either vector 3 (offset h#180) or vector 4
   \ (offset h#200), depending on the setting of the IV bit (bit 23) in the
   \ CP0 Cause register.  If that bit is clear, interrupts share vector 3
   \ with exceptions.  If that bit is set, exceptions use vector 3 and
   \ interrupts use vector 4.  We wish to operate correctly with either
   \ setting, so we install the same handler at both locations.
   ge-preamble   4  install-handler	\ Interrupt

   sr@ h# 40.0000 invert and sr!	\ BEV = normal
   [ previous ]
;
: install-alarm  ( -- )
   ['] getmsecs to get-msecs
   /intstack alloc-mem to intsave
   intsave /intstack erase	\ Paranoia
   disable-interrupts
      init-dispatcher
      clear-floating-point
      catch-exceptions
      d# 1 set-tick-limit
   enable-interrupts        \ Turn interrupts on
;

stand-init:  Fixup ge-preamble and ge-return
   \ Fix up save-state in interrupt-return
   save-state  ge-return-loc    origin+  fix-set32
   save-state  ge-preamble-loc  origin+  fix-set32
;

headers

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
