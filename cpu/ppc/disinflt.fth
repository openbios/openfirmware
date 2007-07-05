purpose: Disassemble inflate.bix so it can be re-assembled from Forth
\ See license at end of file

\ Example use:
\ ppcforth tools.dic ${BP}/cpu/powerpc/disinflt.fth >inflate.dis
\
\ The output may require some amount of manual editing...
\ To make inflate.bix:  xcftobin <inflate.out >inflate.bix

hex

4000 buffer: buf
0 value /buf
reading inflate.bix
buf 4000 ifd @ fgets to /buf
ifd @ fclose

: show-relative  ( target -- )
   [ also assembler ] pc [ previous ]  @  -
   push-hex
   ?dup  if  dup  0<  if  ." .-" negate  else  ." .+"  then  ." h#" ul.  then
   pop-base
;
: +u.  ( adr -- adr' )  dup be-l@ 9 u.r  la1+  ;
: dis0  ( 32b -- )
   ?dup  if  disasm  else
      [ also assembler ] pc [ previous ] @

      dup h# 14 +  buf /buf +  u>  if
         buf /buf +  over  do
            ." h# "  i be-l@ u.  ." be-l,  "
         /l +loop   cr
         bye
      then

      \ Typically produces:
      \ Debug:      2041 800b0300        0      49c   inflate
      \                ^                        ^^^   ^^^^^^^
      \         0 for leaf                     code    name
      \          routines                     length          

      cr ." Debug: " la1+  +u.  +u.  +u.  +u.
      dup wa1+  swap be-w@  2dup  ."    "  type cr
      + aligned  4 -
      [ also assembler ] pc [ previous ] !
   then
;
: keep-going  ( adr -- false )  drop false  ;
also assembler
true to numeric-conditionals?
patch dis0 disasm dis1
patch keep-going @ +dis
patch keep-going @ +dis
patch @ keep-going +dis
' show-relative is showaddr
previous

no-page

\ buf 20 + dis
buf dis

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
