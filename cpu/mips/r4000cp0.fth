purpose: Coprocessor 0 registers for MIPS R4000 series
\ See license at end of file

code index!  ( #ticks -- )  0 tos mtc0  sp tos pop  c;
code index@  ( -- #ticks )  tos sp push  0 tos mfc0  c;
code random@  ( -- #ticks )  tos sp push  1 tos mfc0  c;
code entrylo0!  ( #ticks -- )  2 tos mtc0  sp tos pop  c;
code entrylo0@  ( -- #ticks )  tos sp push  2 tos mfc0  c;
code entrylo1!  ( #ticks -- )  3 tos mtc0  sp tos pop  c;
code entrylo1@  ( -- #ticks )  tos sp push  3 tos mfc0  c;
code context!  ( #ticks -- )  4 tos mtc0  sp tos pop  c;
code context@  ( -- #ticks )  tos sp push  4 tos mfc0  c;
code pagemask!  ( #ticks -- )  5 tos mtc0  sp tos pop  c;
code pagemask@  ( -- #ticks )  tos sp push  5 tos mfc0  c;
code wired!  ( #ticks -- )  6 tos mtc0  sp tos pop  c;
code wired@  ( -- #ticks )  tos sp push  6 tos mfc0  c;
code badvaddr@  ( -- #ticks )  tos sp push  8 tos mfc0  c;
code count!  ( #ticks -- )  9 tos mtc0  sp tos pop  c;
code count@  ( -- #ticks )  tos sp push  9 tos mfc0  c;
code entryhi!  ( n -- )  d# 10 tos mtc0  sp tos pop  c;
code entryhi@  ( -- n )  tos sp push  d# 10 tos mfc0  c;
code compare!  ( n -- )  d# 11 tos mtc0  sp tos pop  c;
code compare@  ( -- n )  tos sp push  d# 11 tos mfc0  c;
code sr!  ( n -- )  d# 12 tos mtc0  sp tos pop  c;
code sr@  ( -- n )  tos sp push  d# 12 tos mfc0  c;
code cause!  ( n -- )  d# 13 tos mtc0  sp tos pop  c;
code cause@  ( -- n )  tos sp push  d# 13 tos mfc0  c;
code epc!  ( n -- )  d# 14 tos mtc0  sp tos pop  c;
code epc@  ( -- n )  tos sp push  d# 14 tos mfc0  c;
code prid@  ( -- n )  tos sp push  d# 15 tos mfc0  c;
code config!  ( n -- )  d# 16 tos mtc0  sp tos pop  c;
code config@  ( -- n )  tos sp push  d# 16 tos mfc0  c;
code lladdr!  ( n -- )  d# 17 tos mtc0  sp tos pop  c;
code lladdr@  ( -- n )  tos sp push  d# 17 tos mfc0  c;
code watchlo!  ( n -- )  d# 18 tos mtc0  sp tos pop  c;
code watchlo@  ( -- n )  tos sp push  d# 18 tos mfc0  c;
code watchhi!  ( n -- )  d# 19 tos mtc0  sp tos pop  c;
code watchhi@  ( -- n )  tos sp push  d# 19 tos mfc0  c;
code xcontext!  ( n -- )  d# 20 tos mtc0  sp tos pop  c;
code xcontext@  ( -- n )  tos sp push  d# 20 tos mfc0  c;
code perr!  ( n -- )  d# 26 tos mtc0  sp tos pop  c;
code perr@  ( -- n )  tos sp push  d# 26 tos mfc0  c;
code cacherr@  ( -- n )  tos sp push  d# 27 tos mfc0  c;
code taglo!  ( n -- )  d# 28 tos mtc0  sp tos pop  c;
code taglo@  ( -- n )  tos sp push  d# 28 tos mfc0  c;
code taghi!  ( n -- )  d# 29 tos mtc0  sp tos pop  c;
code taghi@  ( -- n )  tos sp push  d# 29 tos mfc0  c;
code errorepc!  ( n -- )  d# 30 tos mtc0  sp tos pop  c;
code errorepc@  ( -- n )  tos sp push  d# 30 tos mfc0  c;

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
