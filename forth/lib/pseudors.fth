\ See license at end of file
\ pseudors.fth 1.2 94/09/04

headerless
d# 16 cells  circular-stack: pseudo-rs
headers
: >r  ( n -- )
   state @  if  compile >r  else  pseudo-rs push  then
; immediate
: r>  ( -- n )
   state @  if  compile r>  else  pseudo-rs pop  then
; immediate
: r@  ( -- n )
   state @  if  compile r@  else  pseudo-rs top@  then
; immediate
: 2>r  ( n -- )
   state @  if  compile 2>r  else  swap pseudo-rs push  pseudo-rs push  then
; immediate
: 2r>  ( -- n )
   state @  if  compile 2r>  else  pseudo-rs pop  pseudo-rs pop  swap  then
; immediate
: 2r@  ( -- n )
   state @  if  compile 2r@  else
      pseudo-rs pop  pseudo-rs top@  swap dup pseudo-rs push
   then
; immediate
headers
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
