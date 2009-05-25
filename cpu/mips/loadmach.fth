purpose: Load file for MIPS machine-specific words
\ See license at end of file

start-module
assembler? [if]
fload ${BP}/cpu/mips/assem.fth
fload ${BP}/cpu/mips/code.fth
fload ${BP}/forth/lib/loclabel.fth
[else]
transient  fload ${BP}/cpu/mips/assem.fth  resident
fload ${BP}/cpu/mips/code.fth
transient  fload ${BP}/forth/lib/loclabel.fth     resident
[then]

fload ${BP}/cpu/mips/disassem.fth	\ Exports (dis , pc , dis1 , +dis

fload ${BP}/forth/lib/instdis.fth

fload ${BP}/cpu/mips/decompm.fth

: be-l!  ( l adr -- )  >r lbsplit r@ c! r@ 1+ c!  r@ 2+ c! r> 3 + c!  ;
: be-l,  ( l -- )  here set-swap-bit  here  4 allot  be-l!  ;
: be-l@  ( adr -- n )  >r r@ 3 + c@ r@ 2+ c@ r@ 1+ c@ r> c@ bljoin  ;
: be-w@  ( adr -- w )  dup 1+ c@  swap c@  bwjoin  ;

fload ${BP}/cpu/mips/objsup.fth
fload ${BP}/forth/lib/objects.fth
also hidden
alias reasonable-ip? reasonable-ip?
previous
end-module

fload ${BP}/cpu/mips/cpustate.fth
fload ${BP}/cpu/mips/register.fth

fload ${BP}/forth/lib/savedstk.fth
fload ${BP}/forth/lib/rstrace.fth
fload ${BP}/cpu/mips/ftrace.fth
fload ${BP}/cpu/mips/ctrace.fth

fload ${BP}/cpu/mips/debugm.fth	\ Forth debugger support
fload ${BP}/forth/lib/debug.fth		\ Forth debugger

[ifdef] notyet
also bug
alias   set-package    set-package
alias unset-package  unset-package
previous
[then]

fload ${BP}/cpu/mips/cpubpsup.fth	\ Breakpoint support
fload ${BP}/forth/lib/breakpt.fth

[ifdef] notyet
fload ${BP}/cpu/mips/dfill.fth	\ Memory fill words
fload ${BP}/cpu/mips/memtest.fth
[then]

\ fload ${BP}/cpu/mips/fentry.fth	\ I don't think we need this...
fload ${BP}/cpu/mips/call.fth

transient fload ${BP}/forth/lib/binhdr.fth	resident
transient fload ${BP}/cpu/mips/savefort.fth	resident

alias $save-forth $save-forth

fload ${BP}/cpu/mips/lmove.fth

fload ${BP}/cpu/mips/r4000cp0.fth

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
