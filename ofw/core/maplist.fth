\ See license at end of file
purpose: Physical to virtual translations list management

\ The goal is to define the following external methods:
\ map  ( physical virtual size mode -- )
\ unmap  ( virtual size -- )
\ modify  ( virtual size mode -- )
\ translate  ( virtual -- false | physical mode true )

\ This code manages the set of active virtual-to-physical translations.
\ The set is represented as a linked list.  Each list node represents
\ an active translation consisting of a set of physically and virtually
\ contiguous pages with the same mapping mode.  The list is sorted in
\ ascending order of beginning virtual address.
\ Except during the process of changing the list, the list obeys the
\ following rules:
\   1) Nodes are disjoint in virtual space.
\   2) The list is minimal, in that no pair of nodes can be coalesced
\      into a single node without changing the translation.
\ During the process of changing the list, the above rules are relaxed,
\ but list must still obey the following rule:
\   a) If there are nodes whose virtual ranges overlap, each such node
\      must be instantaneously consistent and much represent a translation
\      range that was valid either before or after the change.  It is
\      not permissible for a node to temporarily create a mapping that
\      neither existed before the change nor will exist afterwards, nor
\      is it permissible for a mapping that existed before and will
\      exist afterward to temporarily "disappear" from the list.
\ The intended reason is that, in the event that a translation-cache fault
\ occurs during the process of changing the list, the fault handler will
\ never see blatantly incorrect information in the list.
\
\ The code below assumes that the fault handler searches the list starting
\ at the beginning (i.e. starting with lower virtual addresses).  The order
\ in which nodes are added to the list during the changing process takes this
\ assumption into account.  However, it is unclear whether or not this matters.

\ Interfaces to processor-dependent function

headerless
'#adr-cells @  2 =  [if]
create phys2
2 constant #phys
: pick-phys  ( phys.lo..hi n*x n -- phys.lo..hi n*x phys.lo..hi )
   1+ dup >r pick r> pick
;
: phys>page#  ( phys.lo..hi -- page# )
   bits/cell pageshift - lshift    ( phys.lo page#.hi )
   swap pageshift rshift  or       ( page# )
;
: page#>phys  ( page# -- phys.lo..hi )
   dup pageshift lshift               ( page# p.lo )
   swap bits/cell pageshift - rshift  ( p.lo p.hi )
;
: dup-phys  ( phys.lo..hi -- phys.lo..hi phys.lo..hi )  2dup  ;
: drop-phys  ( phys.lo..hi -- )  2drop  ;
: align-phys  ( phys.lo..hi -- )  swap pagesize round-down swap  ;
[else]
: phys>page#  ( phys -- page# )  pageshift rshift  ;
: page#>phys  ( page# -- phys )  pageshift lshift  ;
: align-phys  ( phys -- )  pagesize round-down  ;
1 constant #phys
alias pick-phys  pick ( phys n*x n -- phys n*x phys )
alias dup-phys dup ( phys -- phys phys )
alias drop-phys drop  ( phys -- )
[then]

\ Remove mappings for the indicated range from hardware translation resources
defer shootdown-range  ( virtual len -- )  ' 2drop to shootdown-range

\ Translate default mode codes into system-dependent mode codes
defer map-mode  ( phys.. mode -- mode' )
: no-map-mode  ( phys.. mode -- mode' )  >r drop-phys r>  ;
' no-map-mode to map-mode


\ Address of the translation list head node.  The translation list must be
\ stored in memory that translation fault trap handlers can access easily.
\ Memory allocated by "list:" does not necessarily suffice, so we allow
\ the system-dependent code to handle the allocation of this resource.
0 value translations

\ System-independent code follows

memrange node-length	\ Translation nodes are extensions of memrange nodes,
			\ which contain ">adr" and ">size" fields.  This
			\ allows us to share, or at least adapt easily,
			\ memrange list management routines.
   /n field >page#
   /n field >mode
nodetype: translation-node

: find-first-node  ( adr -- )
   1  translations  ['] contained?  find-node   ( adr 1 prev next )
   dup 0=  abort" Range not mapped"             ( adr 1 prev next )
   is next-node  is prev-node  2drop            ( )
;

0 value anchor-node   \ The node that precedes the spanned nodes to be released
0 value pre-range-node  \ The node that precedes the request range

: translate-callback?  ( virt -- virt false | phys.. mode true )
   vector @  0=  if  false exit  then   ( virtual )
   >r                                           ( r: virt )
   r@ pagesize round-down  1                    ( virt' nargs r: virt )
   " translate" ($callback)  if                 ( r: virt )
      \ There was no "translate" callback, so we return false to
      \ indicate that the firmware should perform the function
      r> false                                  ( virt false )
   else                                         ( mode phys.. err? n r: virt )
      \ There was a "translate" callback.  If it succeeded, we return
      \ the results under true to indicate that the operation has been
      \ performed.  If it failed, we throw the error because we are no
      \ longer in charge of address translation services.
      drop throw                                ( mode phys.. r: virt )
      r> pagesize 1- and                        ( mode phys.. virt-offset )
[ifdef] phys2
      rot +  swap rot                           ( phys..' mode )
[else]
      + swap                                    ( phys' mode )
[then]
      true                                      ( phys..' mode true )
   then
;
headers
external
: translate  ( virtual -- false | physical mode true )
   translate-callback?  ?dup  if  exit  then
   1  translations  ['] contained?  find-node   ( virtual 1 prev next|0 )
   dup  if                                      ( virtual 1 prev next )
      >r 2drop                                  ( virtual )
      r@ >adr @ -                               ( offset )
      r@ >page# @  page#>phys                   ( offset phys.lo..hi )
[ifdef] phys2
      -rot + swap                               ( phys.lo..hi' )
[else]
      +                                         ( phys' )
[then]
      r> >mode @  true                          ( phys.lo..hi mode true )
   else                                         ( virtual 1 prev 0 )
      4drop false	                        ( false )
   then
;

headerless
\ Shorten the old node to exclude the request range.
: shorten-node  ( adr -- )
   pre-range-node >adr @ -  pre-range-node >size !   ( )
;
\ Insert after the old node a new node mapping the request range,
\ then shorten the old node.
: new-node-after  ( mode adr len -- )
   translation-node allocate-node >r           ( mode adr len )
   r@ >size !  dup r@ >adr !                   ( mode adr )

   swap r@ >mode !                             ( adr )   

   dup  next-node >adr @  -  pageshift rshift  ( adr page-offset )
   next-node >page# @  +  r@ >page# !          ( adr )

   r@ next-node insert-after                   ( adr )
   r> is anchor-node
   next-node is pre-range-node

   \ Shorten the old node to exclude the request range.
   shorten-node                                ( )
;
: ?new-tail-node  ( adr len -- adr len )
   \ If the ending addresses are not the same...
   2dup +  next-node node-range +  <>  if         ( adr len )
      \ Insert after the old node a new node mapping the tail of the
      \ old node range.
      2dup +                                      ( adr len  new-adr )
      translation-node allocate-node >r           ( adr len  new-adr )

      dup r@ >adr !                               ( adr len  new-adr )
      next-node node-range +  over -              ( adr len  new-adr new-len )
      r@ >size !                                  ( adr len  new-adr )

      next-node >mode @  r@ >mode !               ( adr len  new-adr )

      next-node >adr @ -  pageshift rshift        ( adr len  page#-offset )
      next-node >page# @  +  r@ >page# !          ( adr len )

      r> next-node insert-after                   ( adr len )
   then                                           ( adr len )
;
\ Return the total range of address space mapped by the indicated node
\ and all following nodes whose ranges are contiguous.
: contiguous-range  ( node -- adr len )
   >r
   r@ node-range                         ( adr len0 )
   begin  r> >next-node >r  r@  while    ( adr len )
      2dup +  r@ >adr @  =  while        ( adr len )
      r@ >size @ +                       ( adr len' )
   repeat then                           ( adr len )
   r> drop                               ( adr len )
;
: ?contiguous  ( adr len -- adr len )
   next-node contiguous-range (contained?)
   0= abort" Entire range not mapped"   ( adr len )
;
: fix-last-node  ( adr len -- adr len )
   2dup +  1- 1                                   ( adr len end-1 1 )
   translations ['] contained?  find-node         ( adr len end-1 1 p n )
   dup  if                                        ( adr len end-1 1 p n )
      next-node >r                                ( adr len )
      to next-node  3drop                         ( adr len )
      ?new-tail-node                              ( adr len )
      r> to next-node                             ( adr len )
   else                                           ( adr len end-1 1 p 0 )
      4drop		                              ( adr len )
   then
;
: delete-overlapped-nodes  ( end-adr -- )
   begin
      anchor-node delete-after            ( end deleted-node )
      dup node-range                      ( end deleted-node adr len )
      rot translation-node free-node      ( end adr len )
      \ Stop when we have deleted the first node that contains the end
      \ address of the request range.
      +  over - 0>=                       ( end last-one? )
   until                                  ( end )
   drop
;
: modify-beginning  ( mode adr len -- )
   \ If the node and request beginning addresses are the same ...
   over  next-node >adr @  =  if                  ( mode adr len )
      \ The beginning addresses are the same.
      \ Change the mode and length of the old node to map the request range.
      \ If the new size is smaller (i.e. a contained range), set the size
      \ before the mode, to avoid having the new mode apply outside its range.
      \ If the new size is larger (i.e. a spanning range), set the size
      \ after the mode, to avoid having the old mode apply outside its range.

      nip                                                         ( mode len )
      dup  next-node >size @  <  if  dup next-node >size !  then  ( mode len )
      swap next-node >mode !                                      ( len )
      dup  next-node >size @  >  if  dup next-node >size !  then  ( len )
      drop                                                        ( )
      prev-node is pre-range-node
      next-node is anchor-node
   else                                           ( mode adr len )
      \ The beginning addresses are different.
      \ Insert after the old node a new node mapping the request range 
      \ and shorten the old node to exclude the request range.
      new-node-after
   then                                           ( )
;
: modify-contained-range  ( mode adr len -- )
   2 pick  next-node >mode @  =  if
      \ The mode is already correct, so we can bail out
      3drop exit
   then                                           ( mode adr len )

   \ Handle possible leftover piece at the end of the old node
   ?new-tail-node                                 ( mode adr len )

   \ Fix the beginning of the node
   modify-beginning
;
: modify-spanning-range  ( mode adr len -- )
   \ Handle a modify request that spans more than one translations node
   ?contiguous

   \ Handle possible leftover piece at the end of the last node
   fix-last-node                                  ( mode adr len )

   \ Save end address for later
   2dup + >r                                      ( mode adr len )  ( r: end )

   \ Fix the beginning of the first node
   modify-beginning

   \ Delete following nodes that have been superseded (i.e. those that
   \ overlap the request range).
   r> delete-overlapped-nodes             ( )
;
: ?splice-nodes  ( prev next -- )
   \ If either node is non-existent, there's no need to splice
   2dup and  0=  if  2drop exit  then

   to next-node  to prev-node
   \ Try to coalesce adjacent nodes
   prev-node node-range +  next-node >adr @ =  if  \ Adjacent in virtual space?
      prev-node >page# @  prev-node >size @  pageshift rshift +
      next-node >page# @  =  if                    \ ... and in physical space?
         prev-node >mode @  next-node >mode @  =  if   \ ... and same mode

            \ Increase the size of the first node to include the second
            next-node >size @  prev-node >size +!

            \ Delete the second node
            prev-node delete-after  translation-node free-node
         then
      then
   then
;
: ?splice-modified  ( -- )
   \ Try to splice at the end of the modified range
   anchor-node dup >next-node ?splice-nodes

   \ Try to splice at the beginning of the modified range
   pre-range-node anchor-node ?splice-nodes
;
: (modify)  ( mode adr len -- )
   \ Cases:
   \ a) The request range is contained within a single node range
   \      If the mode on that node is the same as the request mode, we're done.
   \      Otherwise, we may have to carve the node into 2 or 3 subnodes and
   \      change the mode on one of them.  We do this as follows.  The
   \      sequence is intended to ensure that translations that are
   \      not part of the request range never "disappear" from the list,
   \      even temporarily.  Duplications may exist temporarily, but if
   \      so, the first duplicate must contain "correct" information as
   \      of before the modification.
   \         If the ending addresses are different, insert after the old
   \      node a new node mapping the tail of the old node range.
   \         Then, if the node and request beginning addresses are different,
   \      insert after the old node a new node mapping the request range
   \      and shorten the old node to exclude the request range.  Otherwise,
   \      change the length, then the mode, of the old node to that of the
   \      request range.
   \ b) The request range spans multiple nodes (in this case it is an
   \    error if those nodes are not adjacent; but they will have different
   \    modes, or they wouldn't be separate modes).
   \         If the ending addresses of the request range and the last
   \      overlapping node differ, insert after that last node a new node
   \      mapping the tail of the last node's range.
   \         Then, if the beginning addresses of the request range and the
   \      first overlapping node are the same, change that node's mode, then
   \      increase its length to include the entire request range.
   \      Otherwise, create a new node describing the entire request region,
   \      insert it after the old node, then reduce the old node's length
   \      to exclude the request range.
   \         Then release all following nodes that overlap the request range.

   over find-first-node                          ( mode adr len )
   
   next-node contained?  if                      ( mode adr len )
      modify-contained-range                     ( )
   else                                          ( mode adr len )
      modify-spanning-range                      ( )
   then
   ?splice-modified
;

headers
: modify  ( virtual size mode -- )
   over 0=  if  3drop exit  then	( virtual size mode )
   >r  over translate                   ( virtual size mode  f | phys omode t )
   0= abort" modify: Not mapped"        ( virtual size  phys.. omode )
   drop r>  map-mode                    ( virtual size  phys.. new-mode )
   -rot  >page-boundaries               ( mode adr len )
   2dup 2>r                             ( mode adr len )
   (modify)                             ( )
   2r> shootdown-range
;

headerless
: make-range-node  ( phys.lo..hi mode adr len -- new-node )
   translation-node allocate-node >r           ( phys.lo..hi mode adr len )
   r@ >size !  r@ >adr !  r@ >mode !           ( phys.lo..hi )
   phys>page#  r@ >page# !
   r>
;
: higher?  ( adr node -- adr flag )  >adr @  over u>  ;

\ True if the node's address is contained within the range adr,len
\ This assumes that the node's address is >= adr
: overlap?  ( adr len node -- adr len flag )
   >adr @  2 pick  2 pick  over +  within
;

: (map)  ( phys.lo..hi mode adr len -- )
   \ Create the new node
   2dup 2>r  make-range-node to anchor-node   2r>   ( adr len )

   \ Split the last overlapping node if necessary
   fix-last-node                                    ( adr len )

   \ Find the place in the list where the new node should be placed
   over 1  translations  ['] contained?  find-node  ( adr len adr 1 prev nx|0 )
   dup  if                                          ( adr len adr 1 prev next )
      to next-node  to prev-node  2drop             ( adr len )
      over  next-node >adr @  =  if                 ( adr len )
         \ The containing node will be entirely subsumed
         prev-node to pre-range-node                ( adr len )
      else                                          ( adr len )
         \ The containing node must be shortened
         next-node to pre-range-node                ( adr len )
      then                                          ( adr len )
   else                                             ( adr len adr 1 prev 0 )
      4drop					    ( adr len )
      \ Find the predecessor node
      over  translations  ['] higher?  find-node    ( adr len adr prev next|0 )
      to next-node  to pre-range-node  drop         ( adr len )
   then                                             ( adr len )

   \ Put the new node in the list
   anchor-node pre-range-node insert-after          ( adr len )

   \ Shorten the first overlapping node if necessary (so it's not overlapping)
   next-node pre-range-node =  if                   ( adr len )
      over shorten-node                             ( adr len )
   then                                             ( adr len )

   \ Delete any nodes that still overlap
   begin
      anchor-node >next-node                        ( adr len node )
   ?dup  while                                      ( adr len node )
   overlap?  while                                  ( adr len )
      anchor-node delete-after  translation-node free-node   ( adr len )
   repeat then                                      ( adr len )
   2drop

   \ Coalesce any newly-adjacent nodes
   ?splice-modified
;

: map-callback?  ( phys.. mode adr len -- true | phys.. mode adr len false ) 
   vector @  0=  if  false exit  then   ( phys.. mode adr len )
   2 pick  over  3 pick                 ( phys.. mode adr len   mode len adr )
   6 pick-phys 3 #phys +                ( ... mode len adr phys.. nargs )
   " map" ($callback)  if               ( phys.. mode adr len )
      \ There was no "map" callback, so we return "false" to indicate
      \ that the normal "map" should proceed
      false                             ( phys.. mode adr len false )
   else                                 ( phys.. mode adr len error? nrets )
      \ There was a "map" callback.  If it succeeded, we discard the
      \ arguments and return true to indicate that the operation has
      \ been performed.  If it failed, we throw the error because we
      \ aren't permitted to do any mapping after the client has taken over.
      drop throw                        ( phys.. mode adr len )
      3drop drop-phys  true
   then
;

headers
external
: map  ( phys.. virtual size mode -- )
   over 0=  if  3drop drop-phys exit  then	( phys.. virt size mode )
   -rot 2>r  				( phys.. mode ) ( r: virt,size )
   >r  align-phys                       ( phys..' ) ( r: virt,size mode )
   dup-phys  r>  map-mode		( phys.. mode' ) ( r: virt,size )
   2r>  >page-boundaries		( phys.. mode adr len )

   map-callback?  if  exit  then        ( phys.. mode adr len )

   2dup 2>r				( phys.. mode adr len ) ( r: adr,len )
   (map)				( ) ( r: adr,len )
   2r> shootdown-range			( )
;

headerless
: unmap-beginning  ( adr len -- )
   \ If the node and request beginning addresses are the same ...
   over  next-node >adr @  =  if                      ( adr len )
      \ The beginning addresses are the same; delete the node
      2drop                                               ( )
      prev-node delete-after  translation-node free-node  ( )
      prev-node is pre-range-node
      prev-node is anchor-node
   else                                               ( adr len )
      next-node is pre-range-node
      next-node is anchor-node
      \ The beginning addresses are different.
      \ Shorten the old node to exclude the request range.
      drop shorten-node                               ( )
   then                                               ( )
   \ Leave prev-node pointing to the node preceding the
   \ unmapped range
;

\ Handle an unmap request that is contained within one translations node
: unmap-contained-range  ( adr len -- )
\ Handle possible leftover piece at the end of the old node
   ?new-tail-node
   unmap-beginning
;

\ Handle an unmap request that spans more than one translations node
: unmap-spanning-range  ( adr len -- )
   ?contiguous

   \ Handle possible leftover piece at the end of the last node
   fix-last-node                              ( adr len )

   2dup  unmap-beginning                      ( adr len )

   \ Delete following nodes that have been superseded (i.e. those that
   \ overlap the request range).
   + delete-overlapped-nodes                  ( )
;
: (unmap)  ( adr len -- )
   \ The cases for overlap between the request ranges are similar
   \ to those of (modify), but (unmap) is slightly easier because
   \ nodes just go away instead of having their modes changed.

   over find-first-node                       ( adr len )

   next-node contained?  if                   ( adr len )
      unmap-contained-range
   else                                       ( adr len )
      unmap-spanning-range
   then
;

: unmap-callback?  ( virt len -- true | virt len false )
   vector @  0=  if  false exit  then   ( virt len )
   dup  2 pick  2                       ( virt len  len virt nargs )
   " unmap" ($callback)  if             ( virt len )
      \ There was no "unmap" callback, so we return "false" to indicate
      \ that the normal "unmap" should proceed
      false                             ( virt len false )
   else                                 ( virt len error? nrets )
      \ There was an "unmap" callback.  If it succeeded, we discard the
      \ arguments and return true to indicate that the operation has
      \ been performed.  If it failed, we throw the error because we
      \ are no longer in charge of address translation services.
      drop throw                        ( virt len )
      2drop true                        ( true )
   then
;
headers
external
: unmap  ( virtual len -- )
   dup 0=  if  2drop exit  then
   >page-boundaries                           ( adr,len' )
   unmap-callback?  if  exit  then            ( adr,len' )
   2dup 2>r                                   ( adr len )
   (unmap)                                    ( )
   2r> shootdown-range                        ( )
;

: open  ( -- true )  true  ;
: close  ( -- )  ;
headerless

: +int  ( adr len n -- adr' len' )  encode-int encode+  ;

headers
0 encode-int  0 +int  " existing" property

headerless
[ifdef] notdef
: ?add-range  ( adr len begin end -- adr' len' )
   2dup <>  if  >r >r r@ +int  r> r> swap - +int  else  2drop  then
;
: holes  ( adr len last-end node -- adr' len' last-end' flag )
   >r  r@ >adr @  ?add-range  r> node-range +  false
;

headers
5 actions
action:  drop  
   0 0 encode-bytes                              ( adr 0 )
   0  translations  ['] holes find-node  2drop   ( adr len last-end )
   0 ?add-range                                  ( adr len )
   dup negate allot   \ release memory           ( adr len )
;
action:  3drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

" available" make-property-name  use-actions
[then]

headerless
\ Don't use encode-phys directly in this word, as it leaves us
\ vulnerable if someone misuses "my-self." Instead always use the
\ static parent to determine #adr-cells.
: mappings  ( adr len node -- adr' len' flag )
   >r r@ >adr @ +int  r@ >size @ +int             ( adr len ) ( r: node )
   r@ >page# @  page#>phys
   ( encode-phys ) '#adr-cells @ encode-ints
   encode+    					  ( adr len ) ( r: node )
   r> >mode @ +int
   false
;

headers
5 actions
action:  drop  
   0 0 encode-bytes                              ( adr 0 )
   translations  ['] mappings find-node  2drop   ( adr len )
   dup negate allot   \ relase memory            ( adr len )
;
action:  3drop  ;
action:  ;
action:  drop  ;
action:  drop  ;

" translations" make-property-name  use-actions

headers
\ Define the display format for the translations property
also known-int-properties definitions
: translations     ( -- n )  '#adr-cells @  3 +  ;
previous definitions
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
