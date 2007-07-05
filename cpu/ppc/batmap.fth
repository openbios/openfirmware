purpose: Block address translation (BAT) mapping setup
\ See license at end of file

\ This code's data structures are shared with the low-level code
\ in batfault.fth and batf601.fth .  See those files for a description.

: >bat-map  ( va -- adr )  h# 380  swap d# 28 rshift ca+  ;
: bat-invalid  ( va -- )  0 swap >bat-map c!  ;
: bat-mapping  ( va -- false | pa wim true )
   >bat-map c@  dup  if  dup 4 >> d# 28 <<  swap h# f and  true  then
;
: bat-set  ( pa wimg va -- )
   -rot swap d# 28 rshift  d# 4 lshift  or  ( va bte )
   swap >bat-map c!
;
: bat-map  ( pa io? va -- )
   \   WIM bits - don't cache,coherent,guarded for I/O,  coherent for memory
   -rot  if  7  else  2  then  rot     ( pa WIMG va )
   bat-set
;
h# 1000.0000 constant /bat-region
: clear-bat-table  ( -- )
   0 h# 37f c!		\ bat entry 0 is next in line for replacement

   \ Invalidate all entries in the bat translation table
   0  0  do  i bat-invalid   /bat-region +loop
;
: setup-real-bat-table  ( -- )
   0 h# 37f c!		\ bat entry 0 is next in line for replacement
   
   \ map first half of address space cacheable, rest non-cacheable.
   0 0 do   i  i 0<  i  bat-map   /bat-region +loop
;

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
