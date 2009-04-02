\ See license at end of file
purpose: Stand-alone boot code for running ix86 version Forth

\ create debug-startup

\ Boot code (cold and warm start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.  The warm start code is executed when Forth
\ is re-entered, perhaps as a result of an exception.

[ifdef] debug-startup
: ascii-chars " 0123456789abcdef" drop ;
: hdot  ( n -- )
   7 0 do  0 h# 10 um/mod  loop  8 0 do  ascii-chars + c@ emit  loop  space
;
[then]

hex
warning @  warning off 
: stand-init-io  ( -- )
   stand-init-io
   dict-limit to limit
   inituarts install-uart-io
   ['] noop          ['] bye    (is
   ['] RAMbase       is lo-segment-base
   ['] here          is lo-segment-limit
   ['] here          is hi-segment-base
   ['] here          is hi-segment-limit

   ['] reset-all     is bye
   0 is #args
   true is flat?
   ['] 2drop         is sync-cache
;
warning !

[ifdef] debug-startup
\ diagnostic macros
\ Assembler macro to assemble code to send the character "char" to COM1
: report  ( char -- )
   " begin   h# 3fd # dx mov   dx al in  h# 20 # al and   0<> until" evaluate
   ( char )  " # al mov  h# 3f8 # dx mov  al dx out  " evaluate
   " begin   h# 3fd # dx mov   dx al in  h# 20 # al and   0<> until" evaluate
;
: nreport  ( -- )  \ print 4-bit value in bl
   " begin  h# 3fd # dx mov   dx al in   h# 20 # al and   0<> until" evaluate
   " bl al mov  h# 0f # ax and  h# 30 # ax add  h# 3f8 # dx mov  al dx out  "
   evaluate
;
: dotbyte   ( - )     \ print byte in bl
      "  bx 4 # ror " eval  nreport
      "  bx 4 # rol " eval  nreport
      h# 20 nreport
;

label putchar  ( al:char -- )
   dx push  bx push
   ax bx mov
   begin   h# 3fd # dx mov   dx al in  h# 20 # al and   0<> until
   bx ax mov  h# 3f8 # dx mov  al dx out
   begin   h# 3fd # dx mov   dx al in  h# 20 # al and   0<> until
   bx pop  dx pop
   ret
end-code

label puthexit  ( ax:nibble -- )
   h# f #  ax  and
   9 # ax cmp  > if
      char a d# 10 - #  ax  add
   else
      char 0 #  ax  add
   then
   putchar #) call
   ret
end-code

label dot  ( ax:value -- )
   bx push  cx push
   ax bx mov
   8 # cx mov
   begin
      bx 4 # rol
      bx ax mov
      puthexit #) call
      cx dec
   0= until
   h# 20 # ax mov
   putchar #) call
   cx pop bx pop
   ret
end-code

\ *** NOTE: dot is too big to be put inside a control structure ***
: mdot   ( reg - )     \ print 32-bit value in reg
   " ax push   bx push   cx push   dx push" eval
   " bx mov" eval	\ trashes ax,bx,cx,dx
\   " 0 # cx mov begin" eval
   8 0 do
      "  bx 4 # rol " eval  nreport
   loop
\ XXX doesn't cx need to be decremented?
\   " d# 8 # cx cmp >= until" eval
   h# 20 report
   " dx pop   cx pop   bx pop   ax pop" eval
;
fload ${BP}/cpu/x86/pc/egareport.fth
[else]
: report  ( char -- )  drop  ;
: v-report  ( char -- )  drop  ;
: mdot  ( reg -- )  drop  ;
[then]

\ Boot code (cold start).  The cold start code is executed
\ when Forth is initially started.  Its job is to initialize the Forth
\ virtual machine registers.

label prom-cold-code  ( -- )

   \ We assume that the machine is already in protected mode, with a
   \ linear mapping.  DS = ES = SS = FS = GS.  The descriptor referenced
   \ by CS maps the same memory as the DS descriptor.
   \ Interrupts are off.

   cld

\ carret report
\ linefeed report
ascii c report

\ Get the origin address
   here 5 + #) call   here origin -  ( offset )
   bx  pop
   ( offset ) #  bx  sub	\ Origin in bx

\ Copy the initial User Area image to the RAM copy
   init-user-area #  si  mov	\ Init-up pointer in bx
   bx si add                    \ add origin
   prom-main-task #  di  mov	\ Destination of copy
   user-size #       cx  mov
   rep byte movs

ascii s report

   prom-main-task #      up  mov        \ Set User Area Pointer

\ The User Area is now initialized
   up        'user up0   mov	\ Set the up0 user variable

\ Set the value of flat? so later code knows that we are running
\ in a single address space, i.e. Forth is not in a private segment.

   true #  ax  mov   ax  'user flat?  mov

   prom-main-task #  rp  mov	\ Initialize the Return Stack Pointer
   rp        'user rp0   mov    \ Set the rp0 user variable
   rp        ax          mov
   rs-size # ax          sub

\ Establish the Parameter Stack
   ax        sp          mov
   sp        'user sp0   mov	\ Set the sp0 user variable

\   ps-size # ax          sub
\   ax  'user next-free-mem   mov        \ Set heap pointer

    'user dp-loc    ax    mov
    ax        'user dp    mov    \ Initialize the dictionary pointer

\ ascii s report
h# 20 report

\ Enter Forth
   make-odd
   'body cold dup #  ip  mov
   -4 allot token,
c;

: patchboot  ( -- )
   prom-main-task ['] main-task >body !

   here origin -  RAMbase +  is dp-loc

   \ Set offset field of branch at origin
   prom-cold-code origin 5 + -  origin 1+ !
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
