purpose: Displays a backtrace of saved C stack frames.
\ See license at end of file

only forth also hidden also forth definitions
: 9.r  ( adr -- )  push-hex  9 u.r  pop-base  ;
defer .subname  ' 9.r is .subname

: .subroutine  ( lr -- )  \ Show soubroutine address
   4 -  dup l@  h# 0f00.0000 and  h# 0b00.0000  =  if  \ BAL instruction?
      dup l@  8 <<  6 >>a  +  .subname  exit
   then
   drop  ."    ??????"  \ perhaps an indirect call
;
: .args  ( -- )  \ Show C subroutine arguments
   ."  ("  r0 9.r  r1 9.r  r2 9.r  r3 9.r  ."  ... )"
;
: .c-call  ( lr -- )
   ." Subroutine "  dup l@ .subroutine  ."  called from "  4 -  .subname  cr
;
: ctrace  ( -- )   \ C stack backtrace
\ XXX we should look at the first instruction in the subroutine
\ to determine whether it is using the FP or non-FP protocol.
\ Without an FP it will be rather tricky to find the saved PCs, but
\ at least we might be able to avoid going off into the ozone.
   push-hex
   ." PC at " pc .subname cr
   ." Last leaf: " lr .subroutine  .args  cr
   ." Call-chain:" cr
   r11  begin   ( frame-pointer )
      dup 0<>  over in-return-stack? 0=  and
   while
      >saved  dup -1 l+ l@ .c-call
      -3 la+ l@                        ( next-fp )
   repeat      
   pop-base
;
\ compiler options: /swst or /noswst
\ Non-leaf:
\ Preamble
\ +0000 0x000080cc: 0xe1a0c00d  .... :  * mov      r12,r13
\ +0004 0x000080d0: 0xe92dd800  ..-. :    stmdb    r13!,{r11,r12,r14,pc}
\ +0008 0x000080d4: 0xe24cb004  ..L. :    sub      r11,r12,#4
\ SW stack checking goes here if enabled
\ ...
\ +000c 0x000080d8: 0xeb000001  .... :    bl       foo
\ +0010 0x000080dc: 0xe3a00000  .... :    mov      r0,#0
\ ...
\ Postamble
\ +0014 0x000080e0: 0xe91ba800  .... :    ldmdb    r11,{r11,r13,pc}

\ The stack frame then looks like:
\
\     (previous SP) --->
\			&code after preamble (i.e. entry-adr + 0xc)
\     (new FP (r11))--->
\			return address
\			previous SP
\			previous FP
\			saved Rm
\			...
\			saved Rn
\     (new SP (r13))--->

\ Leaf:
\ foo
\ +0000 0x000080e4: 0xe1a0f00e  .... :    mov      pc,r14


\ compiler options: /nofp
\ main
\ +0000 0x000080cc: 0xe92d4000  .@-. :    stmdb    r13!,{r14}
\ 
\ +0004 0x000080d0: 0xeb000001  .... :    bl       foo
\ +0008 0x000080d4: 0xe3a00000  .... :    mov      r0,#0
\ 
\ +000c 0x000080d8: 0xe8bd8000  .... :    ldmia    r13!,{pc}
\ foo
\ +0000 0x000080dc: 0xe1a0f00e  .... :    mov      pc,r14

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
