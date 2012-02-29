purpose: Common code to managed saved program state
\ See license at end of file

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

\ GP regs  PSR  state-stuff
d# 16       1+      4 +    

[ifdef] save-fp-regs
8 3 *  +
[then]

/l*  constant /save-area

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

[ifdef] save-fp-regs
: l@+  ( adr -- l adr' )  dup l@ swap la1+  ;
: l!-  ( l adr -- adr' )  tuck l! -1 la+  ;
3 actions
action:  @ ?saved-state  >state l@+ l@+ l@+  ;
action:  @               >state 2 la+ l!- l!- l!-  ; ( is )
action:  @               >state     ; ( addr )
: freg  \ name  ( offset -- )
   create /l* ,
   use-actions
;
: fregs  \ name name ...  ( start #regs -- )
   3 * bounds  ?do  i freg  3 +loop
;
[then]

headers
[ifdef] new-frame
 0  1 regs  psr

 1  8 regs  r0  r1  r2  r3  r4  r5  r6  r7
 9  8 regs  r8  r9  r10 r11 r12 r13 r14 r15

10  4 regs      up  tos rp  ip
14  3 regs                      sp  lr  pc
16  1 regs                              rpc
[else]
 0  8 regs  r0  r1  r2  r3  r4  r5  r6  r7
 8  8 regs  r8  r9  r10 r11 r12 r13 r14 r15

 9  4 regs      up  tos rp  ip
13  3 regs                      sp  lr  pc
15  1 regs                              rpc

16  1 regs  psr
[then]

17  1 regs  exception-psr
18  3 regs      %saved-my-self  %state-valid  %restartable?  

[ifdef] save-fp-regs
21  8 fregs f0  f1  f2  f3  f4  f5  f6  f7
[then]

\ Following words defined here to satisfy the
\ references to these "variables" anywhere else
: saved-my-self ( -- addr )  addr %saved-my-self  ;
: restartable?  ( -- addr )  addr %restartable?  ;

headerless
: .lx  ( l -- )  base @ >r hex  9 u.r  r> base !  ;

: .mode  ( n -- )
   case
   h# 10  of  ." User32"  endof
   h# 11  of  ." FIQ32"  endof
   h# 12  of  ." IRQ32"  endof
   h# 13  of  ." SVC32"  endof
   h# 17  of  ." Abort32"  endof
   h# 1b  of  ." Undef32"  endof
   h# 1f  of  ." System32"  endof
   endcase
;
headers
: .psr  ( -- )
   psr " nzcv~~~~~~~~~~~~~~~~~~~~ift~~~~~" show-bits
   ." _" psr h# 1f and  .mode
;
: .registers ( -- )
   ?saved-state
   ??cr
."        r0       r1       r2       r3       r4       r5       r6       r7" cr
          r0 .lx   r1 .lx   r2 .lx   r3 .lx   r4 .lx   r5 .lx   r6 .lx   r7 .lx
cr cr
."        r8    r9/up  r10/tos r11/rp/fp  r12/ip   r13/sp   r14/lr       pc" cr
          r8 .lx   r9 .lx  r10 .lx  r11 .lx  r12 .lx  r13 .lx  r14 .lx  r15 .lx
cr cr
."        PSR = " .psr
cr
;

headerless
only forth also hidden also  forth definitions

: enterforth  ( -- )
   state-valid on
   my-self to %saved-my-self
   handle-breakpoint
;

also arm-assembler definitions
: 'state  ( "name" -- )
   r0 drop rb-field
   [ also forth ]
   safe-parse-word  ['] forth $vfind  0= abort" Bad saved register name"
   >body @
   [ previous ]
   set-offset
;
previous definitions

h# e600.0010 value breakpoint-opcode

\ The is the first half of the state restoration procedure.  It executes
\ in normal state (e.g user state when running under an OS)
code (restart  ( -- )
   \ Restore the Forth stacks.

   \ Establish the Data and Return stacks
   ldr     rp,'user rp0
   ldr     sp,'user sp0

   \ Restore the Forth Data and Return stacks from the save area.

   \ Data Stack
   ldr     r3,'user sp0
   dec     r3,`ps-size #`	\ Address of data stack area
   ldr     r0,'user pssave	\ Address of data stack save area
   mov     r1,`ps-size /l / #`	\ Size of data stack area in longwords

   begin
      ldr     r2,[r0],1cell
      str     r2,[r3],1cell
      subs    r1,r1,#1
   0= until

   \ Return Stack
   ldr     r3,'user rp0
   dec     r3,`rs-size #`	\ Address of return stack area
   ldr     r0,'user rssave	\ Address of return stack save area
   mov     r1,`rs-size /l / #`	\ Size of return stack area in longwords

   begin
      ldr     r2,[r0],1cell
      str     r2,[r3],1cell
      subs    r1,r1,#1
   0= until

   \ The following code communicates with the first part of "save-state".
   \ See the description there.


   \ Remember offset
   here  'code (restart drop  - >r

   \ Take another trap, so we can fix up the PC's in the signal handler
   breakpoint-opcode asm,	\ Undefined instruction

end-code

r> constant restart-offset

\ This is the second half of the state saving procedure.  It executes
\ in normal state (not exception state).

label finish-save

   \ Find the user area
   adr     up,'body main-task	\ Get user pointer address
   ldr     up,[up]		\ Get user pointer

   \ Establish the Data and Return stacks

   \ Copy the entire Forth Data and Return stacks areas to a save area.

   \ Data Stack
   ldr     r3,'user sp0
   dec     r3,`ps-size #`	\ Address of data stack area
   ldr     r0,'user pssave    	\ Address of data stack save area
   mov     r1,`ps-size /l / #`	\ Size of data stack area in longwords

   begin
      ldr     r2,[r3],1cell
      str     r2,[r0],1cell
      subs    r1,r1,#1  
   0= until

   ldr     sp,'user sp0

   \ Return Stack
   ldr     r3,'user rp0
   dec     r3,`rs-size #`	\ Address of return stack area
   ldr     r0,'user rssave	\ Address of return stack save area
   mov     r1,`rs-size /l / #`	\ Size of return stack area in longwords

   begin
      ldr     r2,[r3],1cell
      str     r2,[r0],1cell
      subs    r1,r1,#1
   0= until

   ldr     rp,'user rp0

   \ Adjust the stack pointer to account for the top of stack register
   inc     sp,1cell

   \ Restart the Forth interpreter.

   \ Execute enterforth
   adr     ip,'body enterforth
c;

label restart-common
   \ Entry: r13: cpu-state  others: scratch

   \ In the early part of this code, we don't have to be too careful
   \ about register usage, because we will eventually restore all the
   \ registers to saved values.

   mov     r0,r13		\ Get cpu-state address into r0

   ldr     r3,'state r13	\ Get r13 for return mode
   ldr     r4,'state r14	\ Get r14 for return mode

   mrs     r2,cpsr        	\ Get PSR for this mode
   ldr     r1,'state psr	\ Get PSR for return mode
   msr     spsr,r1        	\ Put it in place

   tst     r1,#0xf		\ Check for user mode
   orreq   r1,r1,#0xf		\ Set system mode if previous mode was user
   orr     r1,r1,#0x80		\ Disable interrupts
   msr	   cpsr,r1        	\ Get into the return mode

   mov     r13,r3          	\ Set r13 in return mode
   mov     r14,r4		\ Set r14 in return mode

   msr     cpsr,r2        	\ Get back into undef mode

   ldr     r14,'state pc	\ Get PC for return mode

   ldmia   r0,{r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12}  \ Restore

   \ Set the saved PC to point to the rest of the state save
   \ routine, then return from interrupt.

   movs    pc,r14		\ Return from exception
end-code

label save-common
   str     r14,'state pc	\ Save PC from previous context
   
   mrs     r2,cpsr		\ Get PSR from this context
   str     r2,'state exception-psr	\ Save exception PSR

   mrs     r1,spsr        	\ Get PSR from previous context
   str     r1,'state psr	\ Save it

   orr     r3,r1,#0x80		\ Disable interrupts
   tst     r3,#0xf  		\ Check for user mode
   orreq   r3,r3,#0xf 	 	\ Set system mode if previous mode was user
   msr     cpsr,r3        	\ Get into the old mode

   str     r13,'state r13	\ Save r13 from the old mode
   str     r14,'state r14  	\ Save r14 from the old mode

   msr     cpsr,r2        	\ Get back into undef mode

   \ When we enter Forth, we want interrupts to be enabled if they were
   \ enabled before the exception occurred, unless the exception was caused
   \ by an unexpected interrupt.
   and     r1,r1,#0x80		\ Get interrupt disable bit from previous mode
   bic     r2,r2,#0x80		\ Clear interrupt disable bit
   and     r3,r2,#0xf		\ Get mode type bits
   cmp     r3,#2		\ Interrupt? (unexpected or user-abort)
   cmpeq   r4,#0		\ User-abort? (r4 != 0 if user abort)
   orreq   r2,r2,#0x80		\ Set interrupt disable bit if unexp. int.
   orrne   r2,r2,r1		\ Merge old int. dis. bit into new mode

   bic     r2,r2,#0x1f		\ Clear mode bits
   orr     r2,r2,#0x13		\ Set SVC32 mode
   msr     spsr,r2		\ Put it in SPSR so the return below puts
				\ us back into the right mode for Forth

   \ Set the saved PC to point to the rest of the state save
   \ routine, then return from interrupt.

   adr     r14,'body finish-save

   movs    pc,r14    		\ Return from exception
end-code

string-array exception-name
( 00 )  ," Reset"
( 01 )  ," Undefined Instruction"
( 02 )  ," Software Interrupt"
( 03 )  ," Prefetch Abort"
( 04 )  ," Data Abort"
( 05 )  ," Address Exception"
( 06 )  ," Interrupt"
( 07 )  ," Fast Interrupt"
end-string-array

hex
create mode>exception
\      0     1     2     3     4     5     6     7
      ff c,  7 c,  6 c,  2 c, ff c, ff c, ff c,  4 c,  

\      8     9     a     b     c     d     e     f
      ff c, ff c, ff c,  1 c, ff c, ff c, ff c, ff c,

: exception#  ( -- )
   exception-psr h# f and  mode>exception +  c@
;

: (.exception) ( -- )
   exception#  dup 7 <  if
      exception-name count type
   else
      ." Bogus exception # " .h
   then
   cr
;
' (.exception) is .exception

[ifdef] notdef
\ Very simple handler, useful before the full breakpoint mechanism is installed
: print-breakpoint
   .exception  \ norm
   interactive? 0=  if bye then  \ Restart only if a human is at the controls
   ??cr quit
;
' print-breakpoint is handle-breakpoint
[then]

defer install-handler  ( handler exception# -- )
defer catch-exception  ( exception# -- )

headers
: catch-exceptions  ( -- )
   /save-area alloc-mem is cpu-state
   ps-size    alloc-mem is pssave
   rs-size    alloc-mem is rssave

   clear-save-area

   1 catch-exception   \ Undefined instruction
\  2 catch-exception   \ Software interrupt
   3 catch-exception   \ Prefetch abort
   4 catch-exception   \ Data abort
   5 catch-exception   \ 26-bit address exceptions
   6 catch-exception   \ Interrupt
   7 catch-exception   \ Fast Interrupt
;

headers

only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
