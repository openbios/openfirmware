purpose: Machine/implementation-dependent definitions for the decompiler
\ See license at end of file

decimal
headerless

only forth also hidden also  definitions
: dictionary-base  ( -- adr )  origin  ;

: ram/rom-in-dictionary?  ( adr -- flag )
   dup  #talign 1-  and  0=  if
      dup  lo-segment-base lo-segment-limit  within
      swap hi-segment-base hi-segment-limit  within  or
   else
      drop false
   then
;

' ram/rom-in-dictionary? is in-dictionary?

\ True if adr is a reasonable value for the interpreter pointer
: reasonable-ip?  ( adr -- flag )
   dup  in-dictionary?  if  ( ip )
      #talign 1- and 0=  \ must be token-aligned
   else
      drop false
   then
;
only forth also definitions
headers

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
