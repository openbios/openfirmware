\ See license at end of file

\ Processor-dependent definitions for breakpoints on the 386/486 CPU

hex
only forth also definitions

headerless
: bp-address-valid?  ( adr -- flag )  drop true  ;

: .instruction  ( -- )  %eip pc!dis1  ;

true value hardware-step?   \ True if the environment permits hardware single-step

also hidden also definitions

headerless
th cc  constant breakpoint-opcode		\ Illegal instruction
: breakpoint-trap?  ( -- flag )  int# 3 =  int# 1 =  or  ;

nuser step-adr	\ Dummy address used to signify single stepping

: at-breakpoint?  ( adr -- flag )  c@  breakpoint-opcode =  ;
: put-breakpoint  ( adr -- )
\   dup %eip 1+ =  if   \ Single step
   dup step-adr =  if         \ Single step
      drop %eflags h# 100 or  to %eflags
   else
      breakpoint-opcode swap c!
      %eflags h# 100 invert and  to %eflags
   then
;
alias op@ c@
alias op! c!

\ Another way to do this would be to step once using the trace bit, then
\ set a breakpoint on the return address.  The problem with that solution
\ is the possibility of a call through a task gate, which might turn off
\ tracing.  It is also unclear whether or not it works with INT instructions.

\ : op8@  ( adr -- adr' byte )  dup 1+ swap c@  ;
create sizes 0 c, 1 c, 4 c,
: skip-r/m  ( r/m-adr -- end-adr' )
   dup 1+ swap c@                        ( adr' r/m-byte )
   dup 0 3 bits  swap 6 2 bits >r        ( adr' r/m ) ( r: mod )
   r@  3 =  if  r> 2drop exit  then      ( adr' r/m ) \ register direct
   4 =  if                               ( adr' )     \ Handle s-i-b byte
      dup 1+ swap c@  0 3 bits  5 =  
      r@ 0= and if  			 ( adr' )     \ d32 + scaled index
         4 +  r> drop  exit              ( adr'' )
      then                               ( adr'' )
   then                                  ( adr'' )
   sizes r> + c@ +                       ( adr''' )   \ Add displacement
;

\ Looks for call instructions and figures out the length of their
\ addressing mode bytes.  Returns the address following those addressing
\ mode bytes, or step-adr if the instruction is not a call or if following-
\ jsrs is true.

: jmp-indirect?  ( -- false | pc1 pc2 true )
   %eip c@  h# fe and  h# c2 =  if   \ RET NEAR
      %esp l@  0  true  exit
   then

   %eip c@  h# ff and  if
      %eip 1+ c@  3 rshift 7 and  2 5 between  if
         ." Single-stepping indirect call/jmp doesn't work in software breakpoint mode" cr
      then
   then
   false
;

: find-successors  ( -- pc1 pc2 )
   hardware-step?  if  step-adr 0  exit  then

   jmp-indirect?  if  exit  then

   ['] cr behavior >r  ['] type behavior >r
   ['] noop to cr  ['] 2drop to type
   [ also disassembler ] %eip pc!dis1  pc @  branch-target @  [ previous ]
   r> to type  r> to cr
;

: next-instruction  ( following-jsrs? -- next-adr 0|branch_target )
   if
      \ We are following jsrs, so we want the target address
      \ of call instructions.
      find-successors                         ( adr1 adr2 )
   else
      \ We are not following jsrs, so we want the address right after
      \ the instruction, not the address within the called subroutine.

      %eip dup 1+ swap  c@                  ( %eip opcode )
      case                                    ( %eip+1 opcode )
         h# 0cc of       0 exit  endof			\ INT 3
	 h# 0cd of  1 +  0 exit  endof			\ INT imm8
	 h# 0ce of       0 exit  endof			\ INTO
         h# 0e8 of  4 +  0 exit  endof			\ CALL rel32
         h# 09a of  6 +  0 exit  endof			\ CALL ptr16:32
         h# 0ff of                            ( %eip+1 ) \ CALL indirect
            dup c@  3 3 bits  case          ( %eip+1 ttt ) \ r/m ttt field
               3 of  7 +       0 exit  endof		\ CALL m16:32
               2 of  skip-r/m  0 exit  endof		\ CALL r/m32
            endcase			      ( %eip+1 )
         endof
      endcase				      ( %eip+1 ) 
      drop                                    ( )
      find-successors                         ( adr1 adr2 )
   then                                       ( adr1 adr2 )
;

code goto  ( adr -- )
   ret
end-code
: return-adr  ( -- adr )  %esp >saved le-l@  ;
: leaf-return-adr  ( -- adr )  return-adr  ;
: loop-exit-adr  ( -- adr )
   true abort" loop-exit-adr is not implemented"
;

: bumppc  ( -- )  0 next-instruction drop to rpc  ;
only forth also definitions
headers
: set-pc  ( adr -- )  dup to rpc  ;

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
