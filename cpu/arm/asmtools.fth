purpose: Tools for creating disembodied assembly code sequences
\ See license at end of file

[ifndef] set-transize
fload ${BP}/forth/lib/transien.fth
true is suppress-transient?	\ Disable transient definitions for now
[then]

\needs suppress-headerless?  fload ${BP}/forth/lib/headless.fth

[ifndef] arm-assembler
fload ${BP}/cpu/arm/assem.fth
fload ${BP}/cpu/arm/code.fth
fload ${BP}/forth/lib/loclabel.fth
[then]

also forth definitions
: c$,  ( adr len -- )
   1+  here swap note-string dup allot move 4 (align)
;
previous definitions

[ifdef] notyet
also arm-assembler definitions
\needs $-to-r3 fload ${BP}/cpu/powerpc/asmmacro.fth

: $find-dropin,  ( adr len -- )
   $-to-r3					\ Assemble string and skip it
   " find-dropin bl *" evaluate			\ and call find routine
;
previous definitions
[then]

false value transient-labels?
0 value asm-origin
0 value asm-base
: pad-to  ( n -- )
   begin  dup  here asm-base -  asm-origin +   u>  while  0 c,  repeat  drop
;
: align-to  ( boundary -- )
   here asm-base -  swap round-up  pad-to
;

[ifndef] enable-transient?
: enable-transient  ( -- )
   suppress-transient?  if
      unused 4 /  d# 1000  set-transize
      false is suppress-transient?
      false is suppress-headerless?
   then
;
[then]
enable-transient

: tconstant  ( value "name" -- )
   transient? 0= dup >r  if  transient  then
   constant
   r> if  resident  then
;
: label  ( "name" -- )
   transient-labels?  if
      here  tconstant
      [ also assembler ] init-labels [ previous ]  !csp entercode
   else
      label
   then
;

: set-asm-origin  ( -- )
   here to asm-base
   0 to asm-origin
;

0 0 2value old-asms
: start-assembling  ( -- )
   \ Use "is" instead of "to" in the next line because "to" is a PowerPC
   \ assembly mnemonic (trap on overflow).
   [ also assembler also helpers ]
      ['] asm@ behavior   ['] asm! behavior  to old-asms
      ['] le-l@ is asm@  ['] le-l! is asm!
   [ previous previous ]
   set-asm-origin
   true to transient-labels?
;
: end-assembling  ( -- )
   [ also assembler also helpers ]
      old-asms  is asm!   is asm@
   [ previous previous ]
   false to transient-labels?
;

\ LICENSE_BEGIN
\ Copyright (c) 1995 FirmWorks
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
