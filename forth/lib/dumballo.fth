\ See license at end of file
\ A simple memory allocator
\ Memory is allocated from the space between the top of the dictionary
\ and the parameter stack.   The first memory to be allocated is just below
\ the parameter stack area, and succeding allocations proceed downward from
\ there.
\ The advantage of this over ALLOT is that allot consumes dictionary
\ space which must be stored in a file if a SAVE-FORTH is performed,
\ whereas ALLOC-MEM grabs some unitialized memory at run time.
\ Growing down below the stack only works if the system's memory management
\ will automatically grow the stack.  If not, a different scheme must
\ be used (perhaps just ALLOT).

decimal

\ headerless
variable next-free-mem
 
: dumb-init-malloc  (s -- )  sp0 @  ps-size -   aligned next-free-mem !   ;

\ Allocates "#bytes" of storage and returns it's starting address
: dumb-alloc-mem (s #bytes -- address )
   aligned  next-free-mem @ swap -  dup next-free-mem !
;

\ Frees the memory only if it was the last thing that was allocated,
\ thus preventing overwriting something else.
: dumb-free-mem  (s address #bytes -- )
   swap next-free-mem @  =  if  aligned next-free-mem +!  else  drop  then
;

: install-dumb-alloc  ( -- )
   dumb-init-malloc
   ['] dumb-alloc-mem    ['] alloc-mem    (is
   ['] dumb-free-mem     ['] free-mem     (is
;
\ headers
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
