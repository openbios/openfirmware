purpose: Display and modify the saved program state
\ See license at end of file

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
\ register names
\ .registers

needs action: objects.fth

decimal
headerless

only forth hidden also forth also definitions

d# 112 /l*  constant /save-area

: state-valid   ( -- addr )  d# 40 /l* >state  ;
: ?saved-state  ( -- )
   state-valid @  0=  abort" No program state has been saved in this session."
;

: clear-save-area  ( -- )  0 >state /save-area erase  ;

: >vmem ;

3 actions
action:  @ ?saved-state  >state @  ;
action:  @               >state !  ; ( is )
action:  @               >state    ; ( addr )
: reg  \ name  ( offset -- )
   create /l* ,
   use-actions
;
: regs  \ name name ...  ( start #regs -- )
   bounds  ?do  i reg  loop
;
3 actions
action:  @ ?saved-state  >state 2@  ;
action:  @               >state 2!  ; ( is )
action:  @               >state     ; ( addr )
: freg  \ name  ( offset -- )
   create /l* ,
   use-actions
;
: fregs  \ name name ...  ( start #regs -- )
   2* bounds  ?do  i freg  2 +loop
;


headers
 0  8 regs  %r0  %r1  %r2  %r3  %r4  %r5  %r6  %r7
 8  8 regs  %r8  %r9  %r10 %r11 %r12 %r13 %r14 %r15

16  8 regs  %r16 %r17 %r18 %r19 %r20 %r21 %r22 %r23
24  8 regs  %r24 %r25 %r26 %r27 %r28 %r29 %r30 %r31
20 12 regs  t0  t1  t2  t3  t4  t5 rbase up  tos ip  rp  sp

32  6 regs  %xer %lr  %ctr %pc   %msr  %cr
35  2 regs                 %srr0 %srr1

38  1 regs  exception#
39  3 regs  %saved-my-self  %state-valid  %restartable?  

42  8 fregs  %f0  %f1  %f2  %f3  %f4  %f5  %f6  %f7
58  8 fregs  %f8  %f9  %f10 %f11 %f12 %f13 %f14 %f15
74  8 fregs  %f16 %f17 %f18 %f19 %f20 %f21 %f22 %f23
90  8 fregs  %f24 %f25 %f26 %f27 %f28 %f29 %f30 %f31

106     reg  %fpscr
106    freg  f-tmp

108 4  regs  %sprg0 %sprg1 %sprg2 %sprg3

\ Following words defined here to satisfy the
\ references to these "variables" anywhere else
: saved-my-self ( -- addr )  addr %saved-my-self  ;
: restartable?  ( -- addr )  addr %restartable?  ;

headerless
: .lx  ( l -- )  base @ >r hex  9 u.r  r> base !  ;

headers
: .registers ( -- )
   ?saved-state
   ??cr
."        pc      msr      ctr       lr      xer       cr"     cr
         %pc .lx %msr .lx %ctr .lx  %lr .lx %xer .lx  %cr .lx
cr cr
."        r0       r1       r2       r3       r4       r5       r6       r7" cr
         %r0 .lx  %r1 .lx  %r2 .lx  %r3 .lx  %r4 .lx  %r5 .lx  %r6 .lx  %r7 .lx
cr cr
."        r8       r9      r10      r11      r12      r13      r14      r15" cr
         %r8 .lx  %r9 .lx %r10 .lx %r11 .lx %r12 .lx %r13 .lx %r14 .lx %r15 .lx
cr cr
."       r16      r17      r18      r19      r20      r21      r22      r23" cr
        %r16 .lx %r17 .lx %r18 .lx %r19 .lx %r20 .lx %r21 .lx %r22 .lx %r23 .lx
cr cr
."       r24      r25      r26      r27      r28      r29      r30      r31" cr
        %r24 .lx %r25 .lx %r26 .lx %r27 .lx %r28 .lx %r29 .lx %r30 .lx %r31 .lx
cr cr
."     sprg0    sprg1    sprg2    sprg3     srr0     srr1" cr
      %sprg0 .lx %sprg1 .lx %sprg2 .lx %sprg3 .lx %srr0 .lx %srr1 .lx
cr cr
;

headerless
: ud.r  ( d #columns -- )  >r  <# #s #>  r> over - spaces  type  ;
: .fx  ( d -- )  base @ >r hex  d# 17 ud.r   r> base !  ;

headers
: .fregisters ( -- )
   ??cr
   %msr h# 2000 and  0=  if
      ." Floating point registers were not saved because the floating point" cr
      ." unit was not enabled at the time the registers were saved." cr
      exit
   then
   ." fpcsr " %fpscr .lx  cr
   ." f0-3   :"    %f0 .fx   %f1 .fx   %f2 .fx   %f3 .fx  cr
   ." f4-7   :"    %f4 .fx   %f5 .fx   %f6 .fx   %f7 .fx  cr
   ." f8-11  :"    %f8 .fx   %f9 .fx  %f10 .fx  %f11 .fx  cr
   ." f12-15 :"   %f12 .fx  %f13 .fx  %f14 .fx  %f15 .fx  cr
   ." f16-19 :"   %f16 .fx  %f17 .fx  %f18 .fx  %f19 .fx  cr
   ." f20-23 :"   %f20 .fx  %f21 .fx  %f22 .fx  %f23 .fx  cr
   ." f24-27 :"   %f24 .fx  %f25 .fx  %f26 .fx  %f27 .fx  cr
   ." f28-31 :"   %f28 .fx  %f29 .fx  %f30 .fx  %f31 .fx  cr
;

only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
