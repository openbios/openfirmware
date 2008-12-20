purpose: Memory test primitives in assembly language
\ See license at end of file

headers
\needs mask  nuser mask  mask on
headerless

\ Report the progress through low-level tests
0 0 2value test-name
: show-status  ( adr len -- )  to test-name  ;

code lfill  ( adr len l -- )
				\ tos: pattern
   ldmia   sp!,{r0,r1}		\ r0: len, r1: adr

   ahead begin			\ Fill
      str     tos,[r0,r1]
   but then
      decs    r0,1cell
   0< until

   pop   tos,sp
c;

code masked-ltest  ( adr len l mask -- error? )
   mov     r4,tos		\ r4: mask
   ldmia   sp!,{r0,r1,r2}	\ r0: l, r1: len, r2: adr
   and     r0,r0,r4		\ Mask l
   mvn     tos,#0		\ tos: failure code (in case of mismatch)

   ahead begin			\ Test
      ldr     r3,[r2,r1]		\ Get data from memory
      and     r3,r3,r4		\ mask memory data
      cmp     r3,r0		\ Test under mask
      nxtne			\ Exit if mismatch
   but then
      decs    r1,1cell
   0< until

   mov  tos,#0
c;

: mem-bits-test  ( membase memsize -- fail-status )
   "     Data bits test" show-status
   2dup  h# 5a5a5a5a  lfill
   2dup  h# 5a5a5a5a  mask @  masked-ltest  if  2drop true  exit  then

   2dup  h# a5a5a5a5  lfill
         h# a5a5a5a5  mask @  masked-ltest
;

code afill  ( adr len -- )
   pop    r0,sp			\ tos: len, r0: adr

   ahead begin			\ Fill
      add     r1,r0,tos		\ Compute address
      str     r1,[r0,tos]	\ Store it at the location
   but then
      decs    tos,1cell		\ Decrement index
   0< until

   pop   tos,sp
c;

code masked-atest  ( adr len mask -- mismatch? )
   mov     r4,tos		\ r4: mask
   ldmia   sp!,{r0,r1}		\ r0: len, r1: adr
   mvn     tos,#0		\ tos: failure code (in case of mismatch)

   ahead begin			\ Check
      add     r2,r0,r1		\ Compute pattern
      and     r2,r2,r4		\ under mask
      ldr     r3,[r0,r1]	\ Get data from memory
      and     r3,r3,r4		\ under mask
      cmp     r3,r2		\ Compare
      nxtne			\ Exit if mismatch
   but then
      decs    r0,1cell
   0< until

   mov     tos,#0
c;

: address=data-test  ( membase memsize -- status )
   "     Address=data test" show-status

   2dup afill  mask @ masked-atest
;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
