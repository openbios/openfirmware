\ See license at end of file
purpose: Call MMU node methods

0 value pagesize
headerless
0 value pageshift

headers
variable mmu-node   ' mmu-node  " mmu" chosen-variable

: $call-mmu-method ( ??? method$ -- ???  )  mmu-node @  $call-method  ;

: mmu-translate  ( virt -- false | phys.. mode true )
   " translate" $call-mmu-method
;

: mmu-map  ( phys.. virt size mode -- )  " map" $call-mmu-method  ;
: mmu-claim  ( [ virt ] size align -- base )  " claim" $call-mmu-method  ;
: mmu-release  ( virt size -- )  " release" $call-mmu-method  ;
: mmu-unmap  ( virt size -- )  " unmap" $call-mmu-method  ;

: mmu-lowbits   ( adr1 -- lowbits  )  pagesize  1-     and  ;
: mmu-highbits  ( adr1 -- highbits )  pagesize  round-down  ;

: >physical  ( virt -- phys.. )
   >r r@ mmu-translate  if  drop r> drop  else  r>  then
;

defer memory?  ( phys.. -- flag )
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
