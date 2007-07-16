\ See license at end of file
\ Metacompiler initialization

\ Debugging aids


\ Threshold is the word number to start reporting progress
\ granularity is how often (how many words) to report progress
0 #words !  h# 0 threshold !  h# 10 granularity !

warning off
forth definitions

metaon
meta definitions

\ We want the kernel to be romable, so we put variables in the user area
:-h variable  ( -- )  nuser  ;-h
alias \m  \

initmeta

h# 10000 alloc-mem  target-image  \ Allocate space for the target image

\ org sets the lowest address that is used by Forth kernel.
\ This number is a target token rather than an absolute address.
hex

0.0000 org  0.0000 voc-link-t token-t!

ps-size-t equ ps-size

assembler

\ This is at the first location in the Forth image.

hex
mlabel cld

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
