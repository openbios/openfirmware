purpose: Burnin diagnostic for AMD K6 and similar CPUs
\ See license at end of file

hex

also assembler definitions
: finit  ( -- )  9b asm8, db asm8, e3 asm8,  ;
: fldpi  ( -- )  d9 asm8, eb asm8,  ;
: fldl   ( disp mr rmid -- )  dd asm8, 0 mem,  ;
: fmull  ( disp mr rmid -- )  dc asm8, 1 mem,  ;
: faddp  ( -- )  de asm8, c1 asm8,  ;
: fsubp  ( -- )  de asm8, e1 asm8,  ;
: fcompp   ( -- )  de asm8, d9 asm8,  ;
: fstswax  ( -- )  9b asm8, df asm8, e0 asm8,  ;

\ Returns an addressing mode that refers to the end of the datum
: 'user+8  ( -- offset reg )  'user  swap 8 + swap  ;

previous definitions


dev /cpu

d# 10 constant default#passes
d# 10,000,000 constant spins/pass
0         value #cnt
7fff.ffff value #half
0000.0000 value #half2
ffff.ffff 3fdf.ffff 2value #e
ffff.ffff 3fef.ffff 2value #rt

code burnK6  ( count -- error? )
   ecx pop                            \ Loop count

   finit
   esi push

   'user #half  edx  mov              \ DX: '#half
   eax eax xor                        \ AX: 0
   eax ebx mov                        \ BX: 0
   -1 [eax]  esi  lea                 \ Index = -1
   fldpi
   nop nop

   begin
      'user+8 #rt   [esi] *8       fldl    \ Account for -1 index
      'user+8 #e    [esi] *8       fmull
      'user+8 #half [esi] *8  edx  add
      75 c, 0 c,                           \ jnz .+2
      faddp
      'user+8 #rt   [esi] *8       fldl
      ebx dec
      'user+8 #half [esi] *8  edx  sub
      eb c, 0 c,                           \ jmp .+2
      'user+8 #e    [esi] *8       fmull
      ebx inc
      'user+8 #cnt  [esi] *8       dec
      fsubp
   loopa

   esi pop

   ebx ebx test  0<>  if  1 # ebx mov  then
   'user #half edx cmp  <>  if  2 # ebx or  then
   fldpi
   fcompp                             \ compare ST(0) and ST(1) and pop them
   fstswax
   sahf 0<>  if  4 #  ebx  or  then

   ebx push
c;

: selftest  ( -- error? )
   my-args  dup  if
      push-decimal
      $number abort" Argument to /cpu selftest must be a decimal number"
      pop-base
   else
      2drop
      default#passes
   then

   dup .d ." passes of CPU Burnin.  Press a key to abort." cr
   0  ?do
      (cr  ." Pass "  i .d
      spins/pass  burnk6  if  true exit  then
      key?  if  key drop cr  leave  then
   loop
   false
;

device-end

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
