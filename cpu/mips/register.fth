purpose: Buffers for saving program state
\ See license at end of file

\ Display and modify the saved state of the CPU.
\
\ This code is highly machine-dependent.
\
\ Requires:
\
\ >state  ( offset -- addr )
\	Returns an address within the processor state array given the
\	offset into that array
\
\ Defines:
\
\ %g0 .. %g7  %o0 .. %o7  %l0 .. %l7  %i0 .. %i7
\ %pc %hi %lo
\ .registers .locals

needs action: objects.fth

also hidden
alias reasonable-ip? reasonable-ip?
previous

decimal

only forth hidden also forth also definitions

: /x*  ( n1 -- n2 )  3 lshift  ;

: >state  ( offset -- adr )  /x*  cpu-state  +  ;

false value x-registers?

3 actions
action:  @ >state x@  x-registers? 0=  if  drop  then  ;
action:  @ >state x-registers?  0=  if  swap s>d rot  then  x!  ; ( is )
action:  @ >state    ; ( addr )
: reg  \ name  ( offset -- )
   create ,
   use-actions
;
: regs  \ name name ...  ( high low -- )
   bounds  ?do  i reg  loop
;

\ This mimics the layout of the sigcontext structure

 0  3 regs  $regmask  $sigmask  $pc

\ 3 16 regs  $0  $1  $2  $3  $4  $5  $6  $7  $8  $9  $10 $11 $12 $13 $14 $15
 3 16 regs  $0  $at $v0 $v1 $a0 $a1 $a2 $a3 $t0 $t1 $t2 $t3 $t4 $t5 $t6 $t7 

\ 19 16 regs  $16 $17 $18 $19 $20 $21 $22 $23 $24 $25 $26 $27 $28 $29 $30 $31
19 16 regs  $s0 $s1 $s2 $s3 $s4 $s5 $s6 $s7 $t8 $t9 $k0 $k1 $gp $sp $s8 $ra
22  4 regs              $up $tos $ip $rp

35 reg $fpowned
36  8 regs  $f0  $f1  $f2  $f3  $f4  $f5  $f6  $f7
44  8 regs  $f8  $f9  $f10 $f11 $f12 $f13 $f14 $f15
52  8 regs  $f16 $f17 $f18 $f19 $f20 $f21 $f22 $f23
60  8 regs  $f24 $f25 $f26 $f27 $f28 $f29 $f30 $f31

68  2 regs  $fcsr  $feir
70  2 regs  $hi    $lo

72  6 regs  $cause  $badvaddr  $badpaddr  $sigset  $triggersave  $ssflags

78  2 regs  exception#  $sigcode
80  3 regs  %saved-my-self  %state-valid  %restartable?
83  1 regs  $sr

d# 84 /x* to /save-area

\ These could be defined as e.g. "addr %restartable?", but that
\ causes problems when compiling with SPIM, which can't execute
\ code words that were recently incrementally compiled.
: saved-my-self  ( -- addr )  d# 80 >state  ;
: state-valid    ( -- addr )  d# 81 >state  ;
: restartable?   ( -- addr )  d# 82 >state  ;
: ?saved-state  ( -- )
   state-valid @  0=  abort" No program state has been saved in this session."
;

: .lx  ( l -- )  push-hex  9 u.r  pop-base  ;
: .xx  ( d -- )  push-hex  d# 17 ud.r pop-base  ;

: .registers ( -- )
   ?saved-state
   ??cr
."       $pc      $hi      $lo      $sr" cr
         $pc .lx  $hi .lx  $lo .lx  $sr .lx
cr cr
."        $0      $at      $v0      $v1      $a0      $a1      $a2      $a3" cr
          $0 .lx  $at .lx  $v0 .lx  $v1 .lx  $a0 .lx  $a1 .lx  $a2 .lx  $a3 .lx
cr cr
."       $t0      $t1      $t2      $t3      $t4      $t5      $t6      $t7" cr
         $t0 .lx  $t1 .lx  $t2 .lx  $t3 .lx  $t4 .lx  $t5 .lx  $t6 .lx  $t7 .lx
cr cr
."       $s0      $s1      $s2      $s3      $s4      $s5      $s6      $s7" cr
         $s0 .lx  $s1 .lx  $s2 .lx  $s3 .lx  $s4 .lx  $s5 .lx  $s6 .lx  $s7 .lx
cr cr
."       $t8      $t9      $k0      $k1      $gp      $sp      $s8      $ra" cr
         $t8 .lx  $t9 .lx  $k0 .lx  $k1 .lx  $gp .lx  $sp .lx  $s8 .lx  $ra .lx
cr cr
;

: .xregisters ( -- )
   ?saved-state
   x-registers?  >r  true to x-registers?
   ??cr
."               $pc              $hi              $lo              $sr"     cr
                 $pc .xx          $hi .xx          $lo .xx          $sr .xx
cr cr
."                $0              $at              $v0              $v1" cr
                  $0 .xx          $at .xx          $v0 .xx          $v1 .xx
cr cr
."               $a0              $a1              $a2              $a3" cr
                 $a0 .xx          $a1 .xx          $a2 .xx          $a3 .xx
cr cr
."               $t0              $t1              $t2              $t3" cr
                 $t0 .xx          $t1 .xx          $t2 .xx          $t3 .xx
cr cr
."               $t4              $t5              $t6              $t7" cr
                 $t4 .xx          $t5 .xx          $t6 .xx          $t7 .xx
cr cr
."               $s0              $s1              $s2              $s3" cr
                 $s0 .xx          $s1 .xx          $s2 .xx          $s3 .xx
cr cr
."               $s4              $s5              $s6              $s7" cr
                 $s4 .xx          $s5 .xx          $s6 .xx          $s7 .xx
cr cr
."               $t8              $t9              $k0              $k1" cr
                 $t8 .xx          $t9 .xx          $k0 .xx          $k1 .xx
cr cr
."               $gp              $sp              $s8              $ra" cr
                 $gp .xx          $sp .xx          $s8 .xx          $ra .xx
cr cr
   r> to x-registers?
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
