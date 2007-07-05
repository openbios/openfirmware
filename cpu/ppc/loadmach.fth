purpose: Load file for machine-dependent Forth tools
\ See license at end of file

assembler? [if]
fload ${BP}/cpu/ppc/assem.fth
fload ${BP}/cpu/ppc/code.fth
fload ${BP}/forth/lib/loclabel.fth
[else]
transient  fload ${BP}/cpu/ppc/assem.fth  resident
fload ${BP}/cpu/ppc/code.fth
transient  fload ${BP}/forth/lib/loclabel.fth     resident
[then]

fload ${BP}/cpu/ppc/decompm.fth

: be-l,  ( l -- )  here 4 note-string  allot  be-l!  ;

[ifndef] partial-no-heads	transient  [then]
fload ${BP}/forth/lib/binhdr.fth
fload ${BP}/cpu/ppc/savefort.fth
\ alias save-forth save-forth
[ifndef] partial-no-heads	resident  [then]

fload ${BP}/forth/lib/instdis.fth

fload ${BP}/cpu/ppc/objsup.fth
fload ${BP}/forth/lib/objects.fth

fload ${BP}/cpu/ppc/call.fth		\ C subroutine calls

fload ${BP}/cpu/ppc/cpustate.fth
fload ${BP}/cpu/ppc/register.fth

fload ${BP}/forth/lib/savedstk.fth
fload ${BP}/forth/lib/rstrace.fth
fload ${BP}/cpu/ppc/ftrace.fth
fload ${BP}/cpu/ppc/ctrace.fth

fload ${BP}/cpu/ppc/debugm.fth		\ Forth debugger support
fload ${BP}/forth/lib/debug.fth		\ Forth debugger

start-module				\ Breakpointing
fload ${BP}/cpu/ppc/cpubpsup.fth	\ Breakpoint support
fload ${BP}/forth/lib/breakpt.fth
end-module

fload ${BP}/cpu/ppc/msr.fth		\ Stuff in the Machine State Register
fload ${BP}/cpu/ppc/spr.fth		\ Various special registers
fload ${BP}/cpu/ppc/catchexc.fth

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
