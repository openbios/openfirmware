\ See license at end of file
purpose: Load files for audio diagnostics

headers

d# 30 constant bit/fraction

: log2  0 begin swap u2/ ?dup while swap 1+ repeat  ;

: sdump ( adr len -- )
   bounds  ?do
      i 8 u.r space
      i d# 32  bounds  do
         i <w@ 5 .r space
      4 +loop cr
   d# 32 +loop
;

defer d.f2>n.f
defer q.f2>d.f
defer q.f2>d.0

fload ${BP}/forth/lib/ilog2.fth			\ more precise log2 function
fload ${BP}/dev/mediagx/cx5530/diag/i386op.fth	\ operations in i386 assembly
fload ${BP}/dev/mediagx/cx5530/diag/quad.fth	\ quad data and operations

bit/fraction d# 30 =  [if]
fload ${BP}/dev/mediagx/cx5530/diag/scale30.fth	\ scaling operations
[else]
fload ${BP}/dev/mediagx/cx5530/diag/scale16.fth	\ scaling operations
[then]
1 bit/fraction << constant scaled-1

fload ${BP}/dev/mediagx/cx5530/diag/sqrt.fth	\ sq and sqrt
bit/fraction d# 30 =  [if]
fload ${BP}/dev/mediagx/cx5530/diag/sine30.fth	\ sin, cos and tan
[else]
fload ${BP}/dev/mediagx/cx5530/diag/sine.fth	\ sin, cos and tan
[then]

fload ${BP}/dev/mediagx/cx5530/diag/complexd.fth \ double complex data and ops
fload ${BP}/dev/mediagx/cx5530/diag/fft.fth	\ fft algorithm

defer bar
: foo  ( n -- )  get-msecs swap 0  do  bar  loop  get-msecs swap - .d  ;

headers
hex
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
