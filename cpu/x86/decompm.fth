\ See license at end of file
\ Machine/implementation-dependent definitions

decimal

only forth also hidden also definitions
headerless
: dictionary-base  ( -- adr )  origin 16 +  user-size +  ;

: ram/rom-in-dictionary?  ( adr flag -- )
   dup  #align 1- and  0=  if
	  dup  lo-segment-base lo-segment-limit  within
	  swap hi-segment-base hi-segment-limit  within  or
   else
	  drop false
   then
;

: reasonable-ip?  ( ip -- flag )  in-dictionary?  ;


\ Decompiler extension for 32-bit literals
: .llit      ( ip -- ip' )  ta1+ dup l@ n.  la1+  ;  
: skip-llit  ( ip -- ip' )  ta1+ la1+  ;  
' (llit)  ' .llit  ' skip-llit  install-decomp

headers
only forth also definitions
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
