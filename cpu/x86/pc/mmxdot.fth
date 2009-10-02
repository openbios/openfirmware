\ See license at end of file
purpose: Assemble a call to the mm0dot routine, preserving general registers

: mmxsave  ( -- )  " ax mm7 movd" eval   ;
: mmxrestore  ( -- )  " mm7 ax movd" eval  ;
: mmxarg  ( ea -- )   " mm0 movd"  eval  ;   \ Put numeric argument in mm0
: mmx#arg  ( immed -- )   " # ax mov  ax mm0 movd"  eval  ;
: mmx#arg1  ( immed -- )   " # ax mov  ax mm1 movd"  eval  ;
: mmxcall  ( name$ -- )
   here asm-base - asm-origin + d# 10 + " # ax mov" eval   \ 5 bytes - return address in ax
   eval  " #) jmp" eval                                   \ 5 bytes
;
: mmxdot   ( ea -- )
   mmxsave
   mmxarg
   " mm0dot" mmxcall
   mmxrestore
;
: #mmxdot   ( immed -- )
   mmxsave
   mmx#arg  " mm0dot" mmxcall
   mmxrestore
;
: mmxemit   ( char-ea -- )
   mmxsave
   mmxarg  " mm0emit" mmxcall
   mmxrestore
;
: #mmxemit   ( immed-char -- )
   mmxsave
   mmx#arg  " mm0emit" mmxcall
   mmxrestore
;
: #mmxdump   ( adr-immed len-immed -- )
   mmxsave
   mmx#arg1  mmx#arg  " mm0dump" mmxcall
   mmxrestore
;
: mmxdump   ( adr-ea len-immed -- )
   mmxsave        ( adr-ea len-immed )
   \ Do ea arg first in case it refers to ax; otherwise mmx#arg1 would clobber ax
   >r mmx#arg r>  ( len-immed )
   mmx#arg1  " mm0dump" mmxcall
   mmxrestore
;
: #mmxcfg-dump   ( adr-immed len-immed -- )
   mmxsave
   mmx#arg1  mmx#arg  " mm0cfg-dump" mmxcall
   mmxrestore
;
: mmxcr  ( -- )  carret #mmxemit  linefeed #mmxemit  ;

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
