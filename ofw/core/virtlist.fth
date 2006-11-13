\ See license at end of file
purpose: Virtual address space allocator

\ allocate-virtual  ( phys space size -- phys space adr )
\	Allocates at least "size" bytes of virtual memory.  The actual
\	allocation size is "size" rounded up to a multiple of the page size.

headers
list: fwvirt	\ Virtual memory available list
list: osvirt	\ Virtual memory that the OS can use but the firmware can't

headerless

: (claim-virt-callback)
   ( aln|adr size  aln size max min -- aln|adr size false | virt true )
   4 " claim-virt"  ($callback)  if                 ( adr size )
      \ There was no "claim-virt" callback, so we return false to
      \ indicate that the firmware should proceed.
      false                                       ( adr size false )
   else                                           ( adr size  [ virt ] err? n )
      \ There was a "claim-virt" callback.  If it succeeded, we return
      \ the result under true to indicate that the operation has
      \ been performed.  If it failed, we throw the error because we
      \ are no longer in charge of allocation services.
      drop throw                                  ( aln size virt )
      nip nip true
   then      
;
: alloc-virt-callback?  ( aln size -- aln size false | virt true )
   2dup  -1 0  (claim-virt-callback)
;
: claim-virt-callback?  ( adr size -- adr size false | virt true )
   2dup  pagesize -rot swap dup  (claim-virt-callback)
;
: release-virt-callback?  ( adr size -- true | adr size false )
   2dup 2  " release-virt"  ($callback)  if       ( adr size )
      \ There was no "release-virt" callback, so we return false to
      \ indicate that the firmware should proceed.
      false                                       ( adr size false )
   else                                           ( adr size  err? n )
      \ There was a "release-virt" callback.  If it failed, oh well.
      \ Discard the arguments and return true to indicate that the
      \ operation has been done.
      2drop 2drop true
   then      
;

\ Frees the virtual address range "adr len"

: noreclaim-free-virtual  ( adr len -- )
   >page-boundaries
   over  fw-virt-base  dup fw-virt-size +  within  if  ( adr len )
      fwvirt
   else                                          ( adr len )
      osvirt
   then                                          ( adr len memorylist )
   ['] 2drop  is ?splice                         ( adr len memorylist )
   free-memrange
;

headers
\ Frees virtual memory, but not the physical memory behind it
: free-virtual-only  ( adr len -- )
   >page-boundaries
   noreclaim-free-virtual
;

\ Allocates at least "size" bytes of virtual memory for mapping the
\ physical address "phys".
: allocate-aligned-virtual ( phys space alignment size -- phys space virt-adr )
   \ Minumum granularity of memory chunks is 1 page
   swap pagesize round-up
   swap pagesize round-up                  ( phys space alignment+ size+ )

   alloc-virt-callback?  if  exit  then    ( phys space alignment+ size+ )

   2dup fwvirt allocate-memrange  if       ( phys space aln size )
      osvirt allocate-memrange             ( phys space [ adr ] error? )
      abort" Insufficient virtual memory"  ( phys space adr )
   else                                    ( phys space aln size adr )
      nip nip                              ( phys space adr )
   then 
;

: allocate-virtual  ( phys space size -- phys space virt )
   1 swap allocate-aligned-virtual
;
headerless
: claim-virtual  ( adr size -- adr )
   over >r  >page-boundaries                          ( adr,len' )

   claim-virt-callback?  if  drop r>  exit  then      ( adr,len' )

   \ Look first in the monitor's piece list
   fwvirt  ['] contained?  find-node                  ( adr,len' prev next|0 )
   dup  0=  if
      \ If not found in the monitor's virtual list, look in
      \ the OS's virtual list.
      2drop
      osvirt  ['] contained?  find-node               ( adr,len' prev next|0 )
   then
   dup 0=  abort" Virtual address already used"       ( adr,len' prev next )

   is next-node  is prev-node                         ( adr,len' )

   \ There are 4 cases to consider in removing the requested virtual
   \ address range from the list:
   \ (1) The requested range exactly matches the list node range
   \ (2) The requested range is at the beginning of the list node range
   \ (3) The requested range is at the end of the list node range
   \ (4) The requested range is in the middle of the list node range

   \ Remember the range of the node to be deleted
   next-node node-range                                ( adr,len' node-a,l )

   \ Remove the node from the list
   prev-node delete-after  memrange free-node          ( adr,len' node-a,l )

   \ Give back any left-over portion at the beginning
   over 4 pick over -                        ( adr,len' node-a,l begin-a,l )
   dup  if  noreclaim-free-virtual  else  2drop  then  ( adr,len' node-a,l )

   \ Give back any left-over portion at the end
   2over +  -rot  +   over -                           ( adr,len' end-a,l )
   dup  if  noreclaim-free-virtual  else  2drop  then  ( adr,len' )

   2drop                                               ( )
   r>                                                  ( adr )
;

: add-os-piece  ( start-adr end-adr -- )
   2dup =  if  2drop  exit  then
   over -  set-node  osvirt  insert-after
;

headers
external

: claim  ( [ virt ] size align -- base )
   ?dup  if                          ( size align )
      \ Alignment should be next power of two
      swap allocate-aligned-virtual  ( base )
   else                              ( virt size )
      claim-virtual                  ( base )
   then                              ( base )
;
: release  ( virt size -- )
   release-virt-callback?  if  exit  then
   free-virtual-only
;

pagesize constant pagesize

headerless
\ : range>reg  ( start end -- )  over - 0 swap  encode-reg  ;
: make-virt-memlist  ( adr len node-adr -- adr len' false )
   node-range   ( lo size  )
   >r encode-int encode+
   r> encode-int encode+
   false
;

headers

5 actions
action:  drop  
   0 0  encode-bytes        \ "prime" the property-encoded array

   \ Append the pieces from the non-PROM virtual memory list
   osvirt  ['] make-virt-memlist  find-node  2drop   ( adr len )

   \ Append the pieces from the virtual memory free list
   fwvirt  ['] make-virt-memlist  find-node  2drop   ( adr len )

   over here - allot                              ( adr len )
;
action:  drop 2drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

   " available" make-property-name  use-actions
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
