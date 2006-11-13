\ See license at end of file
\ Decodes and displays the saved processor state.
\ Requires:
\
\ registers
\ %eax %ebx %es etc
\ rssave
\ pssave
\ .exception
\ .flags
\ 
\ Defines:
\
\ .registers
\ .stack
\ .rs
\ .instruction
\ showcrash

only forth also hidden also definitions
: .lx  ( n -- )  base @ >r hex  9 u.r  r> base !  ;
: .wx  ( n -- )  base @ >r hex  5 u.r  r> base !  ;
: show8  ( adr -- )  8 /l*  bounds  do i le-l@ .lx  /l +loop  cr  ;

only forth hidden also forth also definitions

: .rs  ( -- )
   \ Don't display the return stack unless the return stack pointer
   \ appears to be valid.  For instance, if the exception occurred
   \ while executing C code, rp will actually be the C frame pointer,
   \ which has nothing to do with the Forth return stack.
   rrp  in-return-stack?
   if
      ." Return Stack:" cr    td 70 rmargin !
      rssave-end  rrp >saved
      ?do  i le-l@ .lx  ?cr  exit? if leave then  /l +loop  cr
   then
;

\ To display the stack "in-place" :
\   sp th 20 bounds ?do  i l@ .lx ?cr /l +loop  cr
: .stack  ( -- )
   rsp  in-data-stack?
   if
      ." Data Stack:" cr    td 70 rmargin !
      pssave-end  rsp >saved  ( stack-display-end stack-display-start )
   else
      ." Stack (top 0x40 bytes):" cr   td 70 rmargin !
      rsp  th 40  bounds
   then   ( end-adr start-adr )
   ?do  i le-l@ .lx ?cr  exit? if leave then  /l +loop  ??cr
;

: 1bit  ( n -- n' bit )  dup swap 1 <<  swap d# 31 >>a  ;
: 2bits  ( n -- n' bits )  dup swap 2 <<  swap d# 30 >>  ;
: on/off  ( flag -- )  if  ." ON"  else  ." off"  then  ;
: col  ( -- )  d# 20 to-column  ;
: showbit  ( n -- n' )  col bit on/off  cr  ;
: .flags-verbose  ( n -- )
   d# 15 <<
   ." V8086 Mode"  showbit
   ." Resume" showbit
   1bit drop
   ." Nested Task" showbit
   ." I/O Privilege Level"  col 2bits . cr
   ." Overflow" showbit
   ." Direction" showbit
   ." Interrupt Enable" showbit
   ." Trap" showbit
   ." Sign" showbit
   ." Zero" showbit
   1bit drop
   ." Auxiliary Carry" showbit
   ." Parity" showbit
   1bit drop
   ." Carry" showbit
   drop
;
: showc  ( n char -- n' )  >r 1bit r> swap  if  upc  then  emit  ;
: .flags  ( n -- )
   d# 14 <<
   ascii v showc
   ascii r showc
   1bit drop
   ascii n showc
   2bits (.) type
   ascii o showc
   ascii d showc
   ascii i showc
   ascii t showc
   ascii s showc
   ascii z showc
   1bit drop
   ascii a showc
   1bit drop
   ascii p showc
   1bit drop
   ascii c showc
   drop
;
: .registers ( -- )
   ." EIP: "  %eip .x  ."   Flags: " %eflags dup .x .flags
   ( ."   CR3: " %cr3 .x )  cr
   cr
 ."         EAX      ECX      EDX      EBX      ESP      EBP      ESI      EDI"
   cr
   ."   " addr %eax show8
   cr
   ."   ES: " %es .x  ."   CS: " %cs .x  ."   SS: " %ss .x  ."   DS: " %ds .x
   ."   FS: " %fs .x  ."   GS: " %gs .x  cr
   cr
;
: showcrash  ( -- )
   .exception  ."   at "   .registers  .stack
   ( ctrace )
   ." Forth Call Trace:" cr  ftrace
;
\ : .instruction ( -- )  rpc [ disassembler ] pc !  dis1  ;

\ needs (rstrace rstrace.f
\ only forth hidden also forth definitions
\ : crash-rstrace  ( -- )
\    ip .traceline
\    rssave  #rssave  bounds  (rstrace
\ ;

only forth also definitions
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
