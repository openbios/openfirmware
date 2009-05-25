purpose: Initialize the metacompiler for MIPS
\ See license at end of file

\ Metacompiler initialization

\ Debugging aids

0 #words ! d# 1000 threshold ! 10 granularity !

warning off
forth definitions
: unixname bl word
  drop
\ ". cr
;

metaon
meta definitions
\ show? on

\ We want the kernel to be romable, so we put variables in the user area
:-h variable  ( -- )  nuser  ;-h
alias \m  \

initmeta

th 11000 alloc-mem  target-image  \ Allocate space for the target image

\ org sets the lowest address that is used by Forth kernel.
hex

0.0000 org  0.0000
   voc-link-t token-t!

200 equ ps-size

assembler

\ This is at the first location in the Forth image.

\ init-forth is the initialization entry point.  It should be called
\ exactly once, with arguments (dictionary_start, dictionary_size).
\ init-forth sets up some global variables which allow Forth to locate
\ its RAM areas, including the data stack, return stack, user area,
\ cpu-state save area, and dictionary.

hex
mlabel cld
   9000 bra	\ The address will be fixed later.
   nop		\ Delay slot
   nop
   nop

meta

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
