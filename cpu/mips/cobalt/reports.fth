purpose: Diagnostic display code for early startup
\ See license at end of file

\ For any Galileo-based MIPS system, e.g. Cobalt Raq2
h# bc80.0000 constant ns16550-base

label do-report  ( t7: char -- )
   ns16550-base t6 li
   begin  t6 h# 3fd  $at lbu  $at h# 20 $at andi  $at 0 <> until nop
   t7 t6 h# 3f8 sb
   begin  t6 h# 3fd  $at lbu  $at h# 20 $at andi  $at 0 <> until nop

   ra jr  nop
end-code

\ Kills t6-t7
: report  ( char -- )  " do-report bal  $0 swap  t7 addiu" evaluate  ;

label do-nibble  ( t7: digit -- )
   t7 d# 28 t7 sll     t7 d# 28 t7 srl   \ Discard high bits
   t7 h# a negate  $at  addiu
   $at 0>=  if  nop
      $at ascii A  t7  addiu
   else nop
      t7 ascii 0  t7  addiu
   then

   ns16550-base t6 li
   begin  t6 h# 3fd  $at lbu  $at h# 20 $at andi  $at 0 <> until nop
   t7 t6 h# 3f8 sb
   begin  t6 h# 3fd  $at lbu  $at h# 20 $at andi  $at 0 <> until nop

   ra jr  nop
end-code

label do-dot  ( t8: val -- )
   ra t9 move
   do-nibble bal  t8 d# 28  t7 srl 
   do-nibble bal  t8 d# 24  t7 srl 
   do-nibble bal  t8 d# 20  t7 srl 
   do-nibble bal  t8 d# 16  t7 srl 
   do-nibble bal  t8 d# 12  t7 srl 
   do-nibble bal  t8 d#  8  t7 srl 
   do-nibble bal  t8 d#  4  t7 srl 
   do-nibble bal  t8        t7 move

   bl report
   t9 jr nop
end-code

\ Kills t6-t9
: dot  ( reg -- )  " do-dot bal  t8 move" evaluate  ;

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
