purpose: Client interface handler code
\ See license at end of file

d# 12 /n* buffer: cif-reg-save

\ Patch the following constants as needed in architecture-dependent code
 0 constant sr-or-mask   \ For turning on  Status Register bits
-1 constant sr-and-mask  \ For turning off Status Register bits

headerless
code cif-return
   tos   v0   move		\ Return value
   'user cif-reg-save  $at  lw  \ Address of register save area in $at
   $at 0 /n*  s0  lw
   $at 1 /n*  s1  lw
   $at 2 /n*  s2  lw
   $at 3 /n*  s3  lw
   $at 4 /n*  s4  lw
   $at 5 /n*  s5  lw
   $at 6 /n*  s6  lw
   $at 7 /n*  s7  lw
   $at 8 /n*  s8  lw
   $at 9 /n*  ra  lw
   $at d# 11 /n*  t0  lw   d# 12 t0 mtc0  \ Status register

   ra $0 jalr
   $at d# 10 /n*  sp  lw
end-code

: cif-exec  ( args ... -- )
   sr@  sr-and-mask and  sr-or-mask or  sr!
   do-cif
   cif-return
;

headers
: cif-caller  ( -- adr )  cif-reg-save  9 na+  @  ;

headerless
label cif-handler
   \ Registers:
   \ a0			argument array pointer
   \ s0-s8,sp,ra	must be preserved
   \ k0,k1		Don't touch
   \ others		scratch


   ra                $a3   move	\ Save ra
   here 8 +                bal  \ ra = Absolute address of next instruction
   here origin - 4 + $a2   set  \ a2 = relative address of this instruction
   ra   $a2          $a2   subu \ a2 = address of Forth kernel
   $a3  ra  move                \ Restore ra


   'body main-task    	    $a1  li	\ a1: main-task-pfa (relative)
   $a1 $a2                  $a1  addu	\ a1: main-task-pfa (absolute)
   
   $a1 0                    $a1  lw	\ a1: user area
   $a1 'user# cif-reg-save  $at  lw	\ at: register save area address
   s0  $at 0 /n*  sw			\ Save registers
   s1  $at 1 /n*  sw
   s2  $at 2 /n*  sw
   s3  $at 3 /n*  sw
   s4  $at 4 /n*  sw
   s5  $at 5 /n*  sw
   s6  $at 6 /n*  sw
   s7  $at 7 /n*  sw
   s8  $at 8 /n*  sw
   ra  $at 9 /n*  sw
   sp  $at d# 10 /n*  sw
   d# 12 t0 mfc0  t0 $at d# 11 /n*  sw  \ Status register

   $a2     base move
   $a1     up   move			\ Set user pointer
   $a0     tos  move			\ Set top of stack register to arg
   
   'user rp0  rp  lw			\ Set return stack pointer
   'user sp0  sp  lw			\ Set data stack pointer
   \ Don't adjust the stack pointer to account for the top of stack register,
   \ because the stack (actually the TOS register) contains one entry, the
   \ cif-struct pointer.

   np@ origin-     np  set		\ Set the NEXT pointer
   np  base        np  addu

   'body cif-exec  ip  li		\ Set interpreter pointer
   ip base         ip  addu		\ Relocate it to an absolute address
c;

0 value callback-stack

headers
: callback-call  ( args vector -- )  callback-stack sp-call 2drop  ;

\ Force allocation of buffer
stand-init: CIF buffers
   cif-reg-save drop
   h# 1000 dup alloc-mem + to callback-stack
;

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
