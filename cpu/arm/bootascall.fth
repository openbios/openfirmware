\ See license at end of file
purpose: Return from "booted" programs as if they were Forth words

variable rp-var
variable sp-var
rs-size buffer: rs-buf
ps-size buffer: ps-buf

code save-forth-state  ( -- )
   \ Copy the entire Forth data stack and return stack areas to a save area.

   \ Copy Data Stack
   set  r0,`'user# sp-var`
   str  sp,[up,r0]                 \ Save data stack pointer

   ldr  r1,'user sp0               \ Top of data stack area
   dec  r1,`ps-size                \ Bottom of data stack area

   set  r0,`'user# ps-buf`
   ldr  r2,[up,r0]                 \ Address of data stack save area

   mov  r3,`ps-size #`             \ Size of data stack area
   begin
      decs r3,4
      ldr  r0,[r1,r3]
      str  r0,[r2,r3]
   0= until


   \ Return Stack
   set  r0,`'user# rp-var`
   str  rp,[up,r0]                 \ Save return stack pointer

   ldr  r1,'user rp0               \ Top of return stack area
   dec  r1,`rs-size                \ Bottom of return stack area

   set  r0,`'user# rs-buf`
   ldr  r2,[up,r0]                 \ Address of return stack save area

   mov  r3,`rs-size #`             \ Size of return stack area
   begin
      decs r3,4
      ldr  r0,[r1,r3]
      str  r0,[r2,r3]
   0= until
c;

: undo-boot-return  ( -- )
   ['] (quit) to user-interface
;

code resume-forth-state  ( -- )
   mrs   r0,cpsr
   orr   r0,r0,#0x80   \ Set interrupt disable bit
   msr   cpsr,r0

   \ Restore Data Stack
   set  r0,`'user# sp-var`
   ldr  sp,[up,r0]                 \ Save data stack pointer

   ldr  r1,'user sp0               \ Top of data stack area
   dec  r1,`ps-size                \ Bottom of data stack area

   set  r0,`'user# ps-buf`
   ldr  r2,[up,r0]                 \ Address of data stack save area

   mov  r3,`ps-size #`             \ Size of data stack area
   begin
      decs r3,4
      ldr  r0,[r2,r3]
      str  r0,[r1,r3]
   0= until


   \ Restore Return Stack
   set  r0,`'user# rp-var`
   ldr  rp,[up,r0]                 \ Save return stack pointer

   ldr  r1,'user rp0               \ Top of return stack area
   dec  r1,`rs-size                \ Bottom of return stack area

   set  r0,`'user# rs-buf`
   ldr  r2,[up,r0]                 \ Address of return stack save area

   mov  r3,`rs-size #`             \ Size of return stack area
   begin
      decs r3,4
      ldr  r0,[r2,r3]
      str  r0,[r1,r3]
   0= until

   mrs   r0,cpsr
   bic   r0,r0,#0x80   \ Clear interrupt disable bit
   msr   cpsr,r0

   pop   ip,rp
c;

0 value saved-go-hook
: boot-as-call(  ( -- )
   ps-buf drop rs-buf drop
   ['] go-hook behavior to saved-go-hook
   ['] save-forth-state to go-hook
   ['] resume-forth-state to user-interface
;
: )boot-as-call  ( -- )
   saved-go-hook to go-hook
   ['] (quit) to user-interface
;
ps-buf drop rs-buf drop

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
