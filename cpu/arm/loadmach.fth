purpose: Load file for machine-dependent Forth tools
\ See license at end of file

assembler? [if]
fload ${BP}/cpu/arm/assem.fth
fload ${BP}/cpu/arm/code.fth
fload ${BP}/forth/lib/loclabel.fth
[else]
transient  fload ${BP}/cpu/arm/assem.fth  resident
fload ${BP}/cpu/arm/code.fth
transient  fload ${BP}/forth/lib/loclabel.fth     resident
[then]

fload ${BP}/cpu/arm/decompm.fth

\needs $save-forth  transient  fload ${BP}/cpu/arm/savefort.fth  resident
\ alias $save-forth $save-forth

fload ${BP}/cpu/arm/disassem.fth	\ Exports (dis , pc , dis1 , +dis
fload ${BP}/forth/lib/instdis.fth

fload ${BP}/cpu/arm/objsup.fth
fload ${BP}/forth/lib/objects.fth

fload ${BP}/cpu/arm/call.fth		\ C subroutine calls

fload ${BP}/forth/lib/rstrace.fth
fload ${BP}/cpu/arm/debugm.fth	\ Forth debugger support
fload ${BP}/forth/lib/debug.fth		\ Forth debugger

fload ${BP}/cpu/arm/cpustate.fth
fload ${BP}/cpu/arm/register.fth

fload ${BP}/forth/lib/savedstk.fth
fload ${BP}/cpu/arm/ftrace.fth
fload ${BP}/cpu/arm/ctrace.fth

start-module				\ Breakpointing
fload ${BP}/cpu/arm/cpubpsup.fth	\ Breakpoint support
fload ${BP}/forth/lib/breakpt.fth
\ fload ${BP}/cpu/arm/catchexc.fth
end-module

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
