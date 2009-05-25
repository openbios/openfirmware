purpose: After a crash, displays a backtrace of C stack frames.
\ See license at end of file

\ This is difficult to do in the MIPS C environment, because the
\ return address is sometimes in a register and sometimes on the stack.

only forth also hidden also forth definitions
needs (rstrace rstrace.fth
needs >saved savedstk.fth
only forth also hidden also forth definitions

: imatch?  ( adr match mask -- adr flag )  2 pick l@ and =  ;
: jal?   ( adr -- adr flag )  h# 0c00.0000 h# fc00.0000 imatch?  ;
: jalr?  ( adr -- adr flag )  h# 0000.0009 h# fc00.003f imatch?  ;
: bal?   ( adr -- adr flag )  h# 4010.0000 h# fc1c.0000 imatch?  ;

: >jr-target  ( adr -- target-adr )
   \ Get the value of the register in the rs field
   l@  d# 21 >>  h# 1f and  2 << >state @
;
: >j-target  ( adr -- target )
   dup l@  h# 03ff.ffff and  2 <<  swap h# f000.0000 and  or
;
: >br-target  ( br-adr -- target )
   dup  l@  d# 16 <<  d# 14 >>a  +  la1+
;
: 9u.r  ( u -- )  push-hex 9 u.r pop-base  ;

\ True if adr points to an "addiu sp,sp,-N" instruction
: stack-push?  ( adr -- flag )  l@ h# ffff8000 and  h# 27bd8000 =  ;

\ Adjust the stack pointer if necessary
: adjust-sp  ( sp pc -- sp' )
   dup stack-push?  if                     ( sp pc )
      l@ h# ffff and w->n  -               ( sp' )
   else                                    ( sp pc )
      drop                                 ( sp )
   then                                    ( sp' )
;

\ Given the address from which a function was called, display the
\ name or address of the function and adjust the stack pointer
\ to the value that it had upon entry to that function.
: .function  ( call-adr -- start-adr )
   jal?   if  >j-target   dup showaddr  exit  then
   jalr?  if  >jr-target  dup showaddr  exit  then  \ leaf context only...
   bal?   if  >br-target  dup showaddr  exit  then
   drop  ."    ??????"  0
;
: .args  ( -- )  \ Show C function arguments
   ."  ( "  $a0 .x   $a1 .x   $a2 .x   $a3 .x  ." ... )"
;

: .called  ( call-adr -- )  ."  called from "  showaddr  cr  ;

: .leaf-call  ( ra -- start-adr )  dup .function  .args  swap .called  ;

: save-ra?  ( adr -- flag )  l@ h# ffff0000 and  h# afbf0000 =  ;

h# 8000.0000 value mem-base  \ Change this to debug userland code

: reasonable-adr?  ( n -- flag )
   dup 3 and  if  drop false exit  then
   mem-base  dup h# 1000.0000 +  within
;

: up1  ( sp ra -- sp' ra' )
   \ Upon entry, ra is the return address - i.e. an address inside a
   \ function.  We determine the start of that function and display
   \ its address, then find the new return address and adjust the stack
   \ pointer.  It would be nice to display the arguments too, but that's
   \ not so easy.

   \ The current version of GCC starts non-leaf functions with
   \ "addiu sp,sp,-N", so look backward for such an instruction.
   begin
      /l -
      dup reasonable-adr? 0=  if  drop 0 exit  then
      dup stack-push?
   until                                     ( sp start-adr )

   dup showaddr  ."  "                       ( sp start-adr )

   \ Find the instruction that saves the return address on the stack
   dup  /l -
   begin  la1+  dup save-ra?  until          ( sp start-adr save-ra-adr )

   \ Find the saved return address
   l@ h# ffff and w->n                       ( sp start-adr stack-offset )
   2 pick + >saved l@                        ( sp start-adr ra )

   >r adjust-sp  r>                          ( sp ra )
   dup 8 - .called
;

: ctrace  ( -- )   \ C stack backtrace
   ." Most-recently-called function: " cr
   $ra  8 -  .leaf-call      ( sp start-adr )

   $sp swap adjust-sp        ( sp' )

   $ra  begin  dup reasonable-adr?  while  up1  repeat   ( sp' ra' )
   2drop
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
