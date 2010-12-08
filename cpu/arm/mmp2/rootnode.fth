purpose: Methods for root node
\ See license at end of file

: root-map-in  ( phys len -- virt )
   " /" " map-in" execute-device-method drop
;
: root-map-out  ( virt len -- )
   " /" " map-out" execute-device-method drop
;

dev /
extend-package

1 encode-int  " #address-cells"  property
1 encode-int  " #size-cells"  property

hex

\ Static methods
: decode-unit  ( adr len -- phys )  push-hex  $number  if  0  then  pop-base  ;
: encode-unit  ( phys -- adr len )  push-hex  (u.)  pop-base  ;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys size -- virt )
   drop
;
: map-out  ( virtual size -- )
   2drop
;

: dma-range  ( -- start end )  dma-base   dup dma-size +  ;

h# 0 constant dma-map-mode		\ XXX what should this be?

\ Used with "find-node" to locate a physical memory node containing
\ enough memory in the DMA range.
\ We first compute the intersection between the memory piece and the
\ range reachable by DMA.  If the regions are disjoint, then ok-high
\ will be (unsigned) less than ok-low.  We then subtract ok-low from
\ ok-high to give the (possibly negative) size of the intersection.
: in-range?  ( size mem-low mem-high range-low range-high -- flag )
   rot umin -rot              ( size min-high mem-low mem-high )
   umax                       ( size min-high max-low )
   - <=                       ( flag )
;

: dma-ok?  ( size node-adr -- size flag )
   node-range				 ( size mem-adr mem-len )
   over +                                ( size mem-adr mem-end )

   3dup dma-range in-range?  if          ( size mem-adr mem-end )
      2drop true exit                    ( size true )
   then                                  ( size mem-adr mem-end )

   2drop false                           ( size false )
;

\ Find an available physical address range suitable for DMA.  This word
\ doesn't actually claim the memory (that is done later), but simply locates
\ a suitable range that can be successfully claimed.
: find-dma-address  ( size -- true | adr false )
   " physavail" memory-node @ $call-method  	( list )
   ['] dma-ok?  find-node is next-node  drop	( size' )
   next-node 0=  if  drop true exit  then	( size' )
   next-end                                     ( size mem-end )
   dma-range                                    ( size mem-end range-l,h )
   nip umin  swap -   false		        ( adr false )
;

headers
: dma-alloc  ( size -- virt )
   pagesize round-up

   \ Locate a suitable physical range
   dup  find-dma-address  throw			( size' phys )

   \ Claim it
   over 0  mem-claim				( size' phys )

[ifdef] virtual-mode
   \ Get a virtual range
   over pagesize  mmu-claim			( size' phys virt )

   \ Map the physical and virtual ranges
   dup >r					( size' phys virt )
   rot dma-map-mode				( phys virt size' mode )
   mmu-map					( )
   r>						( virt )
[else]
   nip
[then]
;
: dma-free  ( virt size -- )
   pagesize round-up				( virt size' )
[ifdef] virtual-mode
   over mmu-translate 0= abort" Freeing unmapped dma memory"  drop
						( virt size phys )
   -rot tuck                                    ( phys size  virt size )
   2dup mmu-unmap  mmu-release			( phys size )
[then]
   mem-release					( )
;

: dma-map-in   ( virt size cacheable -- devaddr )
   drop   2dup flush-d$-range  drop   ( virt )
;
: dma-map-out  ( virt devaddr size -- )  nip flush-d$-range  ;

\ : dma-sync  ( virt devaddr size -- )  nip flush-d$-range  ;
\ : dma-push  ( virt devaddr size -- )  nip flush-d$-range  ;
\ : dma-pull  ( virt devaddr size -- )  nip flush-d$-range  ;
: dma-sync  ( virt devaddr size -- )  3drop  ;
: dma-push  ( virt devaddr size -- )  3drop  ;
: dma-pull  ( virt devaddr size -- )  3drop  ;

finish-device

device-end

\ Call this after the system-mac-address is determined, which is typically
\ done near the end of the probing process.
: set-system-id  ( -- )
   system-mac-address  dup  if        ( adr 6 )
      " /" find-device                ( adr 6 )

      \ Convert the six bytes of the MAC address into a string of the
      \ form 0NNNNNNNNNN, where N is an uppercase hex digit.
      push-hex                        ( adr 6 )

      <#  bounds  swap 1-  ?do        ( )
         i c@  u# u#  drop            ( )
      -1 +loop                        ( )
      0 u# u#>                        ( adr len )

      2dup upper                      ( adr len )  \ Force upper case

      pop-base                        ( adr len )

      encode-string  " system-id"  property   ( )

      device-end
   else
      2drop
   then
;
headers

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
