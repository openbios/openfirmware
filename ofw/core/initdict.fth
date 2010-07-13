\ See license at end of file
purpose: Dynamic allocation of dictionary space

\ For use in virtual-memory systems in which the Forth dictionary does
\ not have memory preallocated to it, this file establishes a mechanism
\ for allocating physical memory to the dictionary "on demand".

headerless

0 value hard-limit	\ Absolute maximum top of dictionary (virtual)

\ Called when ALLOT can't satisfy the request.  Allocates some more
\ physical memory for the dictionary, maps it in, and updates limit
\ to include the new memory.

: extend-dictionary  ( size -- size )
   dup  pad + d# 100 +                            ( size top-adr )
   dup  hard-limit  >  if  allot-abort  then      ( size top-adr )
   pagesize round-up   limit - >r                 ( size r: size' )
   r@ pagesize mem-claim                          ( size phys.. r: size' )
   limit r@ mem-mode  mmu-map                     ( size r: size' )
   limit r> +  hard-limit min  is limit           ( size )
;

\ Initially, the dictionary growth space extends from here to limit,
\ and "plenty" of space is available there.  After we have initialized
\ the memory allocators and the MMU, we give back anything we're not
\ using, by setting hard-limit to the old limit and setting limit to
\ the next page boundary above here.  Later, if we need more dictionary
\ space, allot (via allot-error which we set to execute extend-dictionary)
\ will dynamically allocate additional physical pages as needed.

: reclaim  ( virt len -- )
   >r                             ( virt r: len )
   dup mmu-translate  if          ( virt phys.. mode r: len )
      drop                        ( virt phys.. r: len )
      r@ mem-release              ( virt r: len )
      r> mmu-unmap                ( )
   else                           ( virt r: len )
      r> 2drop
   then                           ( )
;
: init-dictionary  ( -- )
   limit pagesize round-down  to hard-limit

   \ Put the non-page-aligned fragment above hard-limit in the heap
   hard-limit limit over -    ( adr len )
   dup  if  add-memory  else  2drop  then

   here  pagesize round-up    to limit

   \ Put the page-aligned unused growth space in the page pool
   limit  hard-limit  over - reclaim

   \ Unmap the page that is below the dictionary
   fw-virt-base   origin pagesize round-down  over -  mmu-unmap

   ['] extend-dictionary is allot-error
;
stand-init: Reclaim dictionary
   init-dictionary
;
headers
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
