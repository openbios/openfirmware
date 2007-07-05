purpose: Use client callbacks, if installed, for address translation
\ See license at end of file

warning off
: map  ( phys.. virtual size mode -- )
   vector @  0=  if  map exit  then
[ifdef] 2-address-cells
   \ ??? is the operand order correct?  Other possibilities are:
   \ dup  2 pick  4 pick  6 pick  8 pick
   \ 4 pick  4 pick  4 pick  4 pick  4 pick
   dup  2 pick  4 pick  7 pick  7 pick  5 " map"  ['] $callback catch  if
      3drop 3drop 2drop  map
   else                            ( phys.lo phys.hi virtual size mode 0 )
      3drop 3drop
   then
[else]
   dup  2 pick  4 pick  6 pick  4  " map"  ['] $callback catch  if
      3drop 3drop drop  map
   else                            ( phys virtual size mode 0 )
      3drop 2drop
   then
[then]
;
: translate  ( virtual -- false | physical mode true )
   vector @  0=  if  translate exit  then
   dup 1  " translate"  ['] $callback  catch  if   ( virtual x x x x )
      2drop 2drop  translate  exit
   then              ( false 1 | phys.. mode true n )
   drop
;
: unmap  ( virtual len -- )
   vector @  0=  if  unmap exit  then
   dup 2 pick  2  " unmap"  ['] $callback  catch  if  ( virt len x x x x x )
      2drop 3drop  unmap  exit
   then              ( virt len #returns )
   3drop
;
warning on

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
