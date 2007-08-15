purpose: Load file for machine-dependent Forth tools
\ See license at end of file

assembler? [if]
fload ${BP}/cpu/x86/assem.fth
fload ${BP}/cpu/x86/code.fth
fload ${BP}/forth/lib/loclabel.fth
[else]
transient  fload ${BP}/cpu/x86/assem.fth  resident
fload ${BP}/cpu/x86/code.fth
transient  fload ${BP}/forth/lib/loclabel.fth     resident
[then]
fload ${BP}/cpu/x86/asmspec.fth	\ Special registers

fload ${BP}/cpu/x86/decompm.fth

: be-l,  ( l -- )  here set-swap-bit  here  4 allot  be-l!  ;

[ifndef] partial-no-heads       transient   [then]
fload ${BP}/cpu/x86/saveexp.fth
fload ${BP}/cpu/x86/savefort.fth
\ alias $save-forth $save-forth
[ifndef] partial-no-heads	resident  [then]

[ifdef] resident-packages
fload ${BP}/cpu/x86/disassem.fth
[else]
autoload: disassem.fth
defines: dis
defines: +dis
defines: pc!dis1
[then]

fload ${BP}/forth/lib/instdis.fth

fload ${BP}/cpu/x86/objsup.fth
fload ${BP}/forth/lib/objects.fth

fload ${BP}/cpu/x86/cpustate.fth
fload ${BP}/cpu/x86/register.fth

fload ${BP}/forth/lib/savedstk.fth
fload ${BP}/forth/lib/rstrace.fth
fload ${BP}/cpu/x86/ftrace.fth
\ fload ${BP}/cpu/x86/ctrace.fth
fload ${BP}/cpu/x86/showcras.fth

forth-debug? [if]
fload ${BP}/cpu/x86/debugm.fth	\ Forth debugger support
fload ${BP}/forth/lib/debug.fth	\ Forth debugger
[then]

start-module			 \ Breakpointing
fload ${BP}/cpu/x86/cpubpsup.fth \ Breakpoint support
fload ${BP}/forth/lib/breakpt.fth
fload ${BP}/cpu/x86/Linux/catchexc.fth  \ OS signal handling
end-module

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
