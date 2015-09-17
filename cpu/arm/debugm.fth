purpose: Machine-dependent support routines for Forth debugger.
\ See license at end of file

hex

headerless
\ It doesn't matter what address this returns because it is only used
\ as an argument to slow-next and fast-next, which do nothing.
: low-dictionary-adr  ( -- adr )  origin  ( init-user-area + )  ;

nuser debug-next  \ Pointer to "next"
vocabulary bug   bug also definitions
nuser 'debug   \ code field for high level trace
nuser <ip      \ lower limit of ip
nuser ip>      \ upper limit of ip
nuser cntx     \ how many times thru debug next

\ Since we use a shared "next" routine, slow-next and fast-next are no-op's
alias slow-next 2drop  ( high low -- )
alias fast-next 2drop  ( high low -- )

label normal-next
   ldr   pc,[ip],1cell
end-code

label debnext
   ldr     r0,'user <ip
   cmp     ip,r0
   u>= if
      ldr     r0,'user ip>
      cmp     ip,r0
      u< if
         ldr     r0,'user cntx
         inc     r0,#1
	 str     r0,'user cntx
         cmp     r0,#2
	 = if
            mov     r0,#0
            str     r0,'user cntx
            adr     r0,'body normal-next
            str     r0,'user debug-next
            ldr     pc,'user 'debug
         then
      then
   then
   ldr     pc,[ip],1cell
end-code

\ Fix the next routine to use the debug version
: pnext   ( -- )
   [ also arm-assembler ]
   debnext  up@  put-branch
   [ previous ]
;

\ Turn off debugging
: unbug   ( -- )  normal-next @  up@ instruction!  ;

headers

forth definitions
unbug

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
